#!/usr/bin/env python3
"""Godot GDScript Language Server(LSP) 클라이언트.

실행 중인 Godot 에디터의 LSP 서버(기본 127.0.0.1:6005)에 접속해
GDScript 코드를 정적으로 검증한다. 게임을 실행하지 않고도 문법 오류,
타입 오류, 미사용 변수 같은 경고를 확인할 수 있다.

전제 조건:
  - Godot 에디터가 대상 프로젝트를 연 상태로 실행 중이어야 한다.
    (LSP 진단은 에디터 프로세스 안에서만 생성된다)
  - Editor Settings → Network → Language Server → Enable Smart Resolve 활성
  - 기본 포트 6005. 다른 포트면 --port로 지정한다.

사용법:
  # 파일 진단 (가장 많이 쓴다)
  python3 gdscript_lsp.py diagnose res://scripts/player.gd
  python3 gdscript_lsp.py diagnose scripts/player.gd --project /path/to/project

  # 여러 파일 한 번에
  python3 gdscript_lsp.py diagnose res://a.gd res://b.gd

  # 변경된 GDScript 전부 (git 기준)
  python3 gdscript_lsp.py diagnose --changed

  # 문서 심볼 목록 (클래스/함수/변수 구조 파악)
  python3 gdscript_lsp.py symbols res://scripts/player.gd

  # 특정 위치의 타입/문서 정보
  python3 gdscript_lsp.py hover res://scripts/player.gd 42 10

  # 정의로 이동
  python3 gdscript_lsp.py definition res://scripts/player.gd 42 10

  # 자동완성 후보
  python3 gdscript_lsp.py complete res://scripts/player.gd 42 10

  # 연결 확인
  python3 gdscript_lsp.py ping

종료 코드:
  0  진단 결과에 오류 없음 (경고는 있을 수 있음)
  1  오류(severity=error)가 하나 이상 발견됨
  2  LSP 연결 실패 또는 실행 오류
"""

from __future__ import annotations

import argparse
import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path
from typing import Any
from urllib.parse import quote, unquote, urlparse

DEFAULT_HOST = os.environ.get("GODOT_LSP_HOST", "127.0.0.1")
DEFAULT_PORT = int(os.environ.get("GODOT_LSP_PORT", "6005"))
DEFAULT_TIMEOUT = float(os.environ.get("GODOT_LSP_TIMEOUT", "15"))

SEVERITY_NAMES = {1: "error", 2: "warning", 3: "info", 4: "hint"}

SYMBOL_KINDS = {
    1: "file", 2: "module", 3: "namespace", 4: "package", 5: "class",
    6: "method", 7: "property", 8: "field", 9: "constructor", 10: "enum",
    11: "interface", 12: "function", 13: "variable", 14: "constant",
    15: "string", 16: "number", 17: "boolean", 18: "array", 19: "object",
    20: "key", 21: "null", 22: "enum_member", 23: "struct", 24: "event",
    25: "operator", 26: "type_parameter",
}

COMPLETION_KINDS = {
    1: "text", 2: "method", 3: "function", 4: "constructor", 5: "field",
    6: "variable", 7: "class", 8: "interface", 9: "module", 10: "property",
    11: "unit", 12: "value", 13: "enum", 14: "keyword", 15: "snippet",
    16: "color", 17: "file", 18: "reference", 19: "folder", 20: "enum_member",
    21: "constant", 22: "struct", 23: "event", 24: "operator",
    25: "type_parameter",
}


class LspError(RuntimeError):
    pass


# ─────────────────────────────────────────────────────────────
# 경로 유틸
# ─────────────────────────────────────────────────────────────

def find_project_root(start: Path | None = None) -> Path:
    """project.godot이 있는 디렉터리를 위로 올라가며 찾는다."""
    current = (start or Path.cwd()).resolve()
    for candidate in [current, *current.parents]:
        if (candidate / "project.godot").is_file():
            return candidate
    raise LspError(
        "project.godot을 찾을 수 없습니다. --project로 프로젝트 경로를 지정하세요."
    )


def to_abs_path(path_str: str, project_root: Path) -> Path:
    """res:// 경로나 상대 경로를 절대 경로로 변환한다."""
    if path_str.startswith("res://"):
        return (project_root / path_str[len("res://"):]).resolve()
    candidate = Path(path_str)
    if candidate.is_absolute():
        return candidate.resolve()
    # 현재 디렉터리 기준 → 없으면 프로젝트 루트 기준
    cwd_based = (Path.cwd() / candidate).resolve()
    if cwd_based.exists():
        return cwd_based
    return (project_root / candidate).resolve()


def to_res_path(abs_path: Path, project_root: Path) -> str:
    try:
        return "res://" + abs_path.resolve().relative_to(project_root).as_posix()
    except ValueError:
        return str(abs_path)


def path_to_uri(path: Path) -> str:
    return "file://" + quote(str(path.resolve()).replace(os.sep, "/"), safe="/:")


def uri_to_path(uri: str) -> Path:
    parsed = urlparse(uri)
    return Path(unquote(parsed.path))


# ─────────────────────────────────────────────────────────────
# LSP 클라이언트
# ─────────────────────────────────────────────────────────────

class GodotLspClient:
    """짧게 살아있는 LSP 클라이언트.

    Godot의 LSP 워크스페이스는 모든 클라이언트가 공유하는 싱글턴이다.
    연결을 오래 유지하면 사용자의 VS Code 같은 다른 LSP 클라이언트와
    간섭할 수 있으므로, 매 작업마다 접속 → 처리 → 종료한다.
    """

    def __init__(self, host: str, port: int, project_root: Path,
                 timeout: float = DEFAULT_TIMEOUT) -> None:
        self.host = host
        self.port = port
        self.project_root = project_root
        self.timeout = timeout
        self.sock: socket.socket | None = None
        self.buffer = b""
        self.next_id = 1

    # ── 연결 ────────────────────────────────────────────
    def __enter__(self) -> "GodotLspClient":
        self.connect()
        self.initialize()
        return self

    def __exit__(self, *exc_info: Any) -> None:
        self.close()

    def connect(self) -> None:
        try:
            self.sock = socket.create_connection(
                (self.host, self.port), timeout=self.timeout
            )
            self.sock.settimeout(self.timeout)
        except OSError as exc:
            raise LspError(
                f"Godot LSP({self.host}:{self.port})에 접속할 수 없습니다: {exc}\n"
                "  - Godot 에디터가 이 프로젝트를 연 상태로 실행 중인지 확인하세요.\n"
                "  - Editor Settings → Network → Language Server에서 포트를 확인하세요."
            ) from exc

    def close(self) -> None:
        if self.sock is not None:
            try:
                self.sock.close()
            except OSError:
                pass
            self.sock = None

    # ── 저수준 송수신 ───────────────────────────────────
    def _send(self, payload: dict[str, Any]) -> None:
        if self.sock is None:
            raise LspError("소켓이 연결되어 있지 않습니다.")
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        header = f"Content-Length: {len(body)}\r\n\r\n".encode("ascii")
        self.sock.sendall(header + body)

    def _read_message(self, deadline: float) -> dict[str, Any]:
        """Content-Length 헤더가 붙은 메시지 하나를 읽는다."""
        while True:
            header_end = self.buffer.find(b"\r\n\r\n")
            if header_end != -1:
                header_text = self.buffer[:header_end].decode("ascii", "replace")
                length = 0
                for line in header_text.split("\r\n"):
                    if line.lower().startswith("content-length:"):
                        length = int(line.split(":", 1)[1].strip())
                body_start = header_end + 4
                if len(self.buffer) >= body_start + length:
                    body = self.buffer[body_start:body_start + length]
                    self.buffer = self.buffer[body_start + length:]
                    return json.loads(body.decode("utf-8"))
            if time.monotonic() > deadline:
                raise LspError("LSP 응답 대기 시간이 초과되었습니다.")
            assert self.sock is not None
            self.sock.settimeout(max(0.1, deadline - time.monotonic()))
            try:
                chunk = self.sock.recv(65536)
            except socket.timeout as exc:
                raise LspError("LSP 응답 대기 시간이 초과되었습니다.") from exc
            if not chunk:
                raise LspError("LSP 연결이 예기치 않게 끊어졌습니다.")
            self.buffer += chunk

    def request(self, method: str, params: dict[str, Any]) -> Any:
        request_id = self.next_id
        self.next_id += 1
        self._send({
            "jsonrpc": "2.0", "id": request_id,
            "method": method, "params": params,
        })
        deadline = time.monotonic() + self.timeout
        while True:
            message = self._read_message(deadline)
            if message.get("id") == request_id:
                if "error" in message:
                    raise LspError(f"{method} 실패: {message['error']}")
                return message.get("result")
            # 다른 알림은 무시하고 계속 읽는다

    def notify(self, method: str, params: dict[str, Any]) -> None:
        self._send({"jsonrpc": "2.0", "method": method, "params": params})

    # ── 핸드셰이크 ──────────────────────────────────────
    def initialize(self) -> dict[str, Any]:
        result = self.request("initialize", {
            "processId": os.getpid(),
            "rootUri": path_to_uri(self.project_root),
            "rootPath": str(self.project_root),
            "capabilities": {
                "textDocument": {
                    "publishDiagnostics": {"relatedInformation": True},
                    "completion": {"completionItem": {"snippetSupport": False}},
                    "hover": {"contentFormat": ["markdown", "plaintext"]},
                    "documentSymbol": {"hierarchicalDocumentSymbolSupport": True},
                },
            },
        })
        self.notify("initialized", {})
        return result or {}

    def did_open(self, abs_path: Path) -> str:
        uri = path_to_uri(abs_path)
        text = abs_path.read_text(encoding="utf-8")
        self.notify("textDocument/didOpen", {
            "textDocument": {
                "uri": uri, "languageId": "gdscript",
                "version": 1, "text": text,
            },
        })
        return uri

    # ── 기능 ────────────────────────────────────────────
    def diagnose(self, abs_path: Path) -> list[dict[str, Any]]:
        """파일을 열고 publishDiagnostics 푸시를 기다린다.

        Godot은 오류가 없어도 빈 배열을 푸시하므로, 타임아웃은
        곧 LSP 자체의 문제(에디터가 인덱싱 중 등)를 뜻한다.
        """
        uri = self.did_open(abs_path)
        deadline = time.monotonic() + self.timeout
        while True:
            message = self._read_message(deadline)
            if message.get("method") != "textDocument/publishDiagnostics":
                continue
            params = message.get("params") or {}
            if uri_to_path(params.get("uri", "")) != abs_path.resolve():
                # 다른 파일의 진단이면 계속 기다린다
                if params.get("uri") != uri:
                    continue
            return params.get("diagnostics") or []

    def symbols(self, abs_path: Path) -> list[dict[str, Any]]:
        uri = self.did_open(abs_path)
        result = self.request("textDocument/documentSymbol",
                              {"textDocument": {"uri": uri}})
        return result or []

    def hover(self, abs_path: Path, line: int, column: int) -> dict[str, Any] | None:
        uri = self.did_open(abs_path)
        return self.request("textDocument/hover", {
            "textDocument": {"uri": uri},
            "position": {"line": line - 1, "character": column - 1},
        })

    def definition(self, abs_path: Path, line: int, column: int) -> Any:
        uri = self.did_open(abs_path)
        return self.request("textDocument/definition", {
            "textDocument": {"uri": uri},
            "position": {"line": line - 1, "character": column - 1},
        })

    def complete(self, abs_path: Path, line: int, column: int) -> list[dict[str, Any]]:
        uri = self.did_open(abs_path)
        result = self.request("textDocument/completion", {
            "textDocument": {"uri": uri},
            "position": {"line": line - 1, "character": column - 1},
        })
        if isinstance(result, dict):
            return result.get("items") or []
        return result or []


# ─────────────────────────────────────────────────────────────
# 출력 포맷
# ─────────────────────────────────────────────────────────────

def normalize_diagnostics(res_path: str,
                          diagnostics: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """LSP 진단을 1-based 행/열을 쓰는 평평한 딕셔너리 목록으로 바꾼다."""
    entries: list[dict[str, Any]] = []
    for diag in diagnostics:
        rng = diag.get("range") or {}
        start = rng.get("start") or {}
        end = rng.get("end") or {}
        message = diag.get("message", "")
        # Godot은 경고 종류를 "(UNUSED_VARIABLE): ..." 형태로 메시지 앞에 붙인다.
        # LSP의 code 필드는 항상 0이므로 여기서 뽑아 쓴다.
        code = ""
        if message.startswith("(") and "):" in message:
            head, _, tail = message.partition("):")
            candidate = head[1:]
            if candidate and candidate.replace("_", "").isalnum():
                code = candidate
                message = tail.strip()
        entries.append({
            "file": res_path,
            "line": int(start.get("line", 0)) + 1,
            "column": int(start.get("character", 0)) + 1,
            "end_line": int(end.get("line", 0)) + 1,
            "end_column": int(end.get("character", 0)) + 1,
            "severity": SEVERITY_NAMES.get(diag.get("severity", 1), "error"),
            "code": code,
            "message": message,
        })
    return entries


def render_diagnostics(res_path: str, entries: list[dict[str, Any]]) -> str:
    if not entries:
        return f"  {res_path}: 문제 없음"
    lines = [f"  {res_path}"]
    for e in entries:
        marker = "✗" if e["severity"] == "error" else "!"
        code = f" [{e['code']}]" if e["code"] else ""
        lines.append(
            f"    {marker} {e['line']}:{e['column']} "
            f"{e['severity']}{code}: {e['message']}"
        )
    return "\n".join(lines)


def changed_gdscript_files(project_root: Path) -> list[str]:
    """git 기준으로 변경된 .gd 파일 목록을 반환한다."""
    files: set[str] = set()
    for args in (
        ["git", "diff", "--name-only", "--diff-filter=ACMR"],
        ["git", "diff", "--name-only", "--cached", "--diff-filter=ACMR"],
        ["git", "ls-files", "--others", "--exclude-standard"],
    ):
        try:
            out = subprocess.run(
                args, cwd=project_root, capture_output=True, text=True, check=False
            ).stdout
        except OSError:
            continue
        for name in out.splitlines():
            if name.strip().endswith(".gd"):
                files.add(name.strip())
    return sorted(files)


# ─────────────────────────────────────────────────────────────
# 명령 처리
# ─────────────────────────────────────────────────────────────

def cmd_ping(args: argparse.Namespace, project_root: Path) -> int:
    with GodotLspClient(args.host, args.port, project_root, args.timeout) as client:
        caps = client.initialize()
        print(f"Godot LSP 연결 성공: {args.host}:{args.port}")
        print(f"프로젝트: {project_root}")
        server_info = caps.get("serverInfo") or {}
        if server_info:
            print(f"서버: {server_info.get('name', '?')} "
                  f"{server_info.get('version', '')}")
    return 0


def cmd_diagnose(args: argparse.Namespace, project_root: Path) -> int:
    targets = list(args.paths)
    if args.changed:
        targets.extend(changed_gdscript_files(project_root))
    if not targets:
        print("진단할 파일이 없습니다.", file=sys.stderr)
        return 0

    all_entries: list[dict[str, Any]] = []
    outputs: list[str] = []
    missing: list[str] = []

    with GodotLspClient(args.host, args.port, project_root, args.timeout) as client:
        for target in targets:
            abs_path = to_abs_path(target, project_root)
            if not abs_path.is_file():
                missing.append(target)
                outputs.append(f"  {target}: 파일을 찾을 수 없음")
                continue
            res_path = to_res_path(abs_path, project_root)
            entries = normalize_diagnostics(res_path, client.diagnose(abs_path))
            all_entries.extend(entries)
            outputs.append(render_diagnostics(res_path, entries))

    error_count = sum(1 for e in all_entries if e["severity"] == "error")
    warning_count = sum(1 for e in all_entries if e["severity"] == "warning")

    if args.json:
        print(json.dumps({
            "files": len(targets),
            "missing": missing,
            "errors": error_count,
            "warnings": warning_count,
            "diagnostics": all_entries,
        }, ensure_ascii=False, indent=2))
    else:
        print(f"GDScript 진단 ({len(targets)}개 파일)")
        print("\n".join(outputs))
        print(f"\n오류 {error_count}개, 경고 {warning_count}개")

    return 1 if error_count > 0 else 0


def cmd_symbols(args: argparse.Namespace, project_root: Path) -> int:
    abs_path = to_abs_path(args.path, project_root)
    with GodotLspClient(args.host, args.port, project_root, args.timeout) as client:
        symbols = client.symbols(abs_path)

    if args.json:
        print(json.dumps(symbols, ensure_ascii=False, indent=2))
        return 0

    def render(items: list[dict[str, Any]], depth: int = 0) -> None:
        for item in items:
            kind = SYMBOL_KINDS.get(item.get("kind", 0), "?")
            rng = item.get("range") or item.get("location", {}).get("range") or {}
            line = int((rng.get("start") or {}).get("line", 0)) + 1
            detail = item.get("detail") or ""
            suffix = f"  — {detail}" if detail else ""
            print(f"{'  ' * depth}{line:>5}  {kind:<10} {item.get('name', '')}{suffix}")
            children = item.get("children") or []
            if children:
                render(children, depth + 1)

    print(f"{to_res_path(abs_path, project_root)} 심볼")
    render(symbols)
    return 0


def cmd_hover(args: argparse.Namespace, project_root: Path) -> int:
    abs_path = to_abs_path(args.path, project_root)
    with GodotLspClient(args.host, args.port, project_root, args.timeout) as client:
        result = client.hover(abs_path, args.line, args.column)

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    if not result:
        print("hover 정보 없음")
        return 0
    contents = result.get("contents")
    if isinstance(contents, dict):
        print(contents.get("value", ""))
    elif isinstance(contents, list):
        for item in contents:
            print(item.get("value", "") if isinstance(item, dict) else item)
    else:
        print(contents)
    return 0


def cmd_definition(args: argparse.Namespace, project_root: Path) -> int:
    abs_path = to_abs_path(args.path, project_root)
    with GodotLspClient(args.host, args.port, project_root, args.timeout) as client:
        result = client.definition(abs_path, args.line, args.column)

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    if not result:
        print("정의를 찾을 수 없음")
        return 0
    locations = result if isinstance(result, list) else [result]
    for loc in locations:
        uri = loc.get("uri") or loc.get("targetUri", "")
        rng = loc.get("range") or loc.get("targetRange") or {}
        line = int((rng.get("start") or {}).get("line", 0)) + 1
        col = int((rng.get("start") or {}).get("character", 0)) + 1
        print(f"{to_res_path(uri_to_path(uri), project_root)}:{line}:{col}")
    return 0


def cmd_complete(args: argparse.Namespace, project_root: Path) -> int:
    abs_path = to_abs_path(args.path, project_root)
    with GodotLspClient(args.host, args.port, project_root, args.timeout) as client:
        items = client.complete(abs_path, args.line, args.column)

    if args.json:
        print(json.dumps(items, ensure_ascii=False, indent=2))
        return 0
    for item in items[:args.limit]:
        kind = COMPLETION_KINDS.get(item.get("kind", 0), "?")
        detail = item.get("detail") or ""
        suffix = f"  — {detail}" if detail else ""
        print(f"  {kind:<12} {item.get('label', '')}{suffix}")
    if len(items) > args.limit:
        print(f"  ... 외 {len(items) - args.limit}개")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Godot GDScript LSP 클라이언트",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--host", default=DEFAULT_HOST, help="LSP 호스트")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="LSP 포트")
    parser.add_argument("--project", default=None, help="프로젝트 루트 경로")
    parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT,
                        help="요청 타임아웃(초)")
    parser.add_argument("--json", action="store_true", help="JSON으로 출력")

    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("ping", help="LSP 연결 확인")

    p_diag = sub.add_parser("diagnose", help="문법·타입 진단")
    p_diag.add_argument("paths", nargs="*", help="res:// 또는 상대 경로")
    p_diag.add_argument("--changed", action="store_true",
                        help="git 기준 변경된 .gd 파일 전부")

    p_sym = sub.add_parser("symbols", help="문서 심볼 목록")
    p_sym.add_argument("path")

    p_hover = sub.add_parser("hover", help="위치의 타입·문서 정보")
    p_hover.add_argument("path")
    p_hover.add_argument("line", type=int, help="1부터 시작하는 행 번호")
    p_hover.add_argument("column", type=int, help="1부터 시작하는 열 번호")

    p_def = sub.add_parser("definition", help="정의 위치")
    p_def.add_argument("path")
    p_def.add_argument("line", type=int)
    p_def.add_argument("column", type=int)

    p_comp = sub.add_parser("complete", help="자동완성 후보")
    p_comp.add_argument("path")
    p_comp.add_argument("line", type=int)
    p_comp.add_argument("column", type=int)
    p_comp.add_argument("--limit", type=int, default=40)

    return parser


def main(argv: list[str]) -> int:
    args = build_parser().parse_args(argv)
    try:
        project_root = (Path(args.project).resolve() if args.project
                        else find_project_root())
        handlers = {
            "ping": cmd_ping,
            "diagnose": cmd_diagnose,
            "symbols": cmd_symbols,
            "hover": cmd_hover,
            "definition": cmd_definition,
            "complete": cmd_complete,
        }
        return handlers[args.command](args, project_root)
    except LspError as exc:
        print(f"오류: {exc}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
