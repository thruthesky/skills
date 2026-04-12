#!/usr/bin/env python3
"""Korea SNS API 클라이언트 — 완전한 콘텐츠 관리 스크립트.

사용법:
  # 회원가입
  python3 korea_api.py --api-key "" register --email "user@example.com" --password "pass123" [--display-name "이름"]

  # 로그인하여 API 키 획득
  python3 korea_api.py --api-key "" login --email "user@example.com" --password "pass"

  # 내 정보 조회
  python3 korea_api.py --api-key KEY me

  # 프로필 수정
  python3 korea_api.py --api-key KEY update-profile [--display-name "이름"] [--bio "소개"]

  # 아바타 업로드
  python3 korea_api.py --api-key KEY upload-avatar --file "/path/to/avatar.jpg"

  # 파일 업로드
  python3 korea_api.py --api-key KEY upload --file "/path/to/image.jpg"

  # 게시글 CRUD
  python3 korea_api.py --api-key KEY create --title "제목" --content "내용" [--category-id 3] [--site-id 1] [--upload-ids "10,11"]
  python3 korea_api.py --api-key KEY update --id 1 --title "새제��" --content "새내용" [--upload-ids "12"]
  python3 korea_api.py --api-key KEY delete --id 1
  python3 korea_api.py --api-key KEY get    --id 1
  python3 korea_api.py --api-key KEY list   [--page 1] [--per-page 10] [--category free] [--site-id 1]

  # 댓글
  python3 korea_api.py --api-key KEY comment-create --post-id 1 --content "댓글" [--parent-id 5] [--upload-ids "10"]
  python3 korea_api.py --api-key KEY comment-update --comment-id 1 --content "수정"
  python3 korea_api.py --api-key KEY comment-delete --comment-id 1

  # 사이트/카테고리
  python3 korea_api.py --api-key KEY sites [--page 1]
  python3 korea_api.py --api-key KEY categories --site-id 1

  # API 문서 조회
  python3 korea_api.py --api-key "" docs [--category post]
"""

import argparse
import json
import mimetypes
import os
import sys
import urllib.request
import urllib.error
import urllib.parse
import uuid
from typing import Optional

DEFAULT_BASE_URL = "https://withcenter.com/api/v1"
# --base-url 옵션으로 변경 가능 (서브사이트: https://apple.withcenter.com/api/v1)
BASE_URL = DEFAULT_BASE_URL


def api_request(method: str, path: str, api_key: str, data: Optional[dict] = None, params: Optional[dict] = None) -> dict:
    """API 요청을 보내고 JSON 응답을 반환한다."""
    url = f"{BASE_URL}{path}"

    if params:
        filtered = {k: v for k, v in params.items() if v is not None}
        if filtered:
            url += "?" + urllib.parse.urlencode(filtered)

    body = json.dumps(data).encode() if data else None

    req = urllib.request.Request(url, data=body, method=method)
    if api_key:
        req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("User-Agent", "KoreaSNS-CLI/1.0")
    if data:
        req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        try:
            return json.loads(error_body)
        except json.JSONDecodeError:
            return {"message": f"HTTP {e.code}: {error_body}"}


def multipart_upload(path: str, api_key: str, file_path: str) -> dict:
    """multipart/form-data로 파일을 업로드한다."""
    url = f"{BASE_URL}{path}"
    boundary = uuid.uuid4().hex

    filename = os.path.basename(file_path)
    mime_type = mimetypes.guess_type(file_path)[0] or "application/octet-stream"

    with open(file_path, "rb") as f:
        file_data = f.read()

    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'
        f"Content-Type: {mime_type}\r\n\r\n"
    ).encode() + file_data + f"\r\n--{boundary}--\r\n".encode()

    req = urllib.request.Request(url, data=body, method="POST")
    if api_key:
        req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("User-Agent", "KoreaSNS-CLI/1.0")
    req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        try:
            return json.loads(error_body)
        except json.JSONDecodeError:
            return {"message": f"HTTP {e.code}: {error_body}"}


def output(result: dict):
    """JSON 결과를 출력한다."""
    print(json.dumps(result, ensure_ascii=False, indent=2))


# --- 인증 ---

def cmd_register(args):
    """회원가입."""
    data = {"email": args.email, "password": args.password}
    if args.display_name:
        data["display_name"] = args.display_name
    result = api_request("POST", "/auth/register", "", data=data)
    output(result)
    if "data" in result and "api_key" in result.get("data", {}):
        print(f"\n# API 키: {result['data']['api_key']}", file=sys.stderr)
        print("# 이후 요청에 --api-key 옵션으로 사용하세요.", file=sys.stderr)


def cmd_login(args):
    """로��인하여 API 키를 획득한다."""
    data = {"email": args.email, "password": args.password}
    result = api_request("POST", "/auth/login", "", data=data)
    output(result)
    if "data" in result and "api_key" in result.get("data", {}):
        print(f"\n# API 키: {result['data']['api_key']}", file=sys.stderr)
        print("# 이후 요청에 --api-key 옵션으로 사용하세요.", file=sys.stderr)


# --- 사용자 ---

def cmd_me(args):
    """내 정보 조회."""
    result = api_request("GET", "/me", args.api_key)
    output(result)


def cmd_update_profile(args):
    """프로필 수정."""
    data = {}
    if args.display_name:
        data["display_name"] = args.display_name
    if args.bio:
        data["bio"] = args.bio
    if args.username:
        data["username"] = args.username
    if not data:
        print('{"message": "수정할 내용이 없습니다."}')
        sys.exit(1)
    result = api_request("PATCH", "/me", args.api_key, data=data)
    output(result)


def cmd_upload_avatar(args):
    """아바타 업로드."""
    result = multipart_upload("/me/avatar", args.api_key, args.file)
    output(result)


# --- 파일 업로드 ---

def cmd_upload(args):
    """파일 업로드."""
    result = multipart_upload("/files/upload", args.api_key, args.file)
    output(result)
    if "data" in result and "id" in result.get("data", {}):
        print(f"\n# 업로드 ID: {result['data']['id']}", file=sys.stderr)
        print("# 게시글/댓글 생성 시 --upload-ids 옵션으로 사용하세요.", file=sys.stderr)


# --- 게시글 ---

def cmd_create(args):
    """���시글 생성."""
    data = {"title": args.title, "content": args.content}
    if args.category_id:
        data["category_id"] = args.category_id
    if args.site_id:
        data["site_id"] = args.site_id
    if args.upload_ids:
        data["upload_ids"] = [int(x.strip()) for x in args.upload_ids.split(",")]
    result = api_request("POST", "/posts", args.api_key, data=data)
    output(result)


def cmd_update(args):
    """게시글 수정."""
    data = {}
    if args.title:
        data["title"] = args.title
    if args.content:
        data["content"] = args.content
    if args.category_id:
        data["category_id"] = args.category_id
    if args.upload_ids:
        data["upload_ids"] = [int(x.strip()) for x in args.upload_ids.split(",")]
    if not data:
        print('{"message": "수정할 내용이 없습니다."}')
        sys.exit(1)
    result = api_request("PUT", f"/posts/{args.id}", args.api_key, data=data)
    output(result)


def cmd_delete(args):
    """게시글 삭제."""
    result = api_request("DELETE", f"/posts/{args.id}", args.api_key)
    output(result)


def cmd_get(args):
    """게시글 상세 조회."""
    result = api_request("GET", f"/posts/{args.id}", args.api_key)
    output(result)


def cmd_list(args):
    """게���글 목록 조회."""
    params = {
        "page": args.page,
        "per_page": args.per_page,
        "category": args.category,
        "site_id": args.site_id,
        "order_by": args.order_by,
    }
    result = api_request("GET", "/posts", args.api_key, params=params)
    output(result)


# --- 댓글 ---

def cmd_comment_create(args):
    """댓글 생성."""
    data = {"content": args.content}
    if args.parent_id:
        data["parent_id"] = args.parent_id
    if args.upload_ids:
        data["upload_ids"] = [int(x.strip()) for x in args.upload_ids.split(",")]
    result = api_request("POST", f"/posts/{args.post_id}/comments", args.api_key, data=data)
    output(result)


def cmd_comment_update(args):
    """��글 수정."""
    data = {"content": args.content}
    if args.upload_ids:
        data["upload_ids"] = [int(x.strip()) for x in args.upload_ids.split(",")]
    result = api_request("PATCH", f"/comments/{args.comment_id}", args.api_key, data=data)
    output(result)


def cmd_comment_delete(args):
    """댓글 삭제."""
    result = api_request("DELETE", f"/comments/{args.comment_id}", args.api_key)
    output(result)


# --- 사이트/카테고리 ---

def cmd_sites(args):
    """사이트 목록 조회."""
    params = {"page": args.page, "per_page": args.per_page}
    result = api_request("GET", "/sites", args.api_key, params=params)
    output(result)


def cmd_categories(args):
    """카테고리 트리 조회."""
    result = api_request("GET", f"/sites/{args.site_id}/categories/tree", args.api_key)
    output(result)


# --- API 문서 ---

def cmd_docs(args):
    """API 문서 조회."""
    params = {}
    if args.category:
        params["category"] = args.category
    result = api_request("GET", "/docs", "", params=params)
    output(result)


def main():
    parser = argparse.ArgumentParser(description="Korea SNS API 클라이언트")
    parser.add_argument("--api-key", required=True, help="API 키")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL,
                        help="API Base URL (기본: https://withcenter.com/api/v1, 서브사이트: https://<도메인>/api/v1)")
    sub = parser.add_subparsers(dest="command", required=True)

    # 회원가입
    p = sub.add_parser("register", help="회원가입")
    p.add_argument("--email", required=True)
    p.add_argument("--password", required=True)
    p.add_argument("--display-name")

    # 로그인
    p = sub.add_parser("login", help="로그인하여 API 키 획득")
    p.add_argument("--email", required=True)
    p.add_argument("--password", required=True)

    # 내 정보
    sub.add_parser("me", help="내 정보 조회")

    # 프로필 수정
    p = sub.add_parser("update-profile", help="프로필 수정")
    p.add_argument("--display-name")
    p.add_argument("--bio")
    p.add_argument("--username")

    # 아바타 업로드
    p = sub.add_parser("upload-avatar", help="아바타 업로드")
    p.add_argument("--file", required=True, help="이미지 파일 경로")

    # 파일 업로드
    p = sub.add_parser("upload", help="파일 업로드")
    p.add_argument("--file", required=True, help="업로드할 파일 경로")

    # 게시글 생성
    p = sub.add_parser("create", help="게시�� 생성")
    p.add_argument("--title", required=True)
    p.add_argument("--content", required=True)
    p.add_argument("--category-id", type=int)
    p.add_argument("--site-id", type=int)
    p.add_argument("--upload-ids", help="쉼표 구분 업로드 ID (예: 10,11)")

    # 게시글 수정
    p = sub.add_parser("update", help="게시글 수정")
    p.add_argument("--id", required=True, type=int)
    p.add_argument("--title")
    p.add_argument("--content")
    p.add_argument("--category-id", type=int)
    p.add_argument("--upload-ids", help="쉼표 구분 업로드 ID")

    # 게시글 삭제
    p = sub.add_parser("delete", help="게시글 삭제")
    p.add_argument("--id", required=True, type=int)

    # 게시글 조회
    p = sub.add_parser("get", help="게시글 상�� 조회")
    p.add_argument("--id", required=True, type=int)

    # 게시글 목록
    p = sub.add_parser("list", help="��시글 목록 조회")
    p.add_argument("--page", type=int, default=1)
    p.add_argument("--per-page", type=int, default=10)
    p.add_argument("--category")
    p.add_argument("--site-id", type=int)
    p.add_argument("--order-by")

    # 댓글 생성
    p = sub.add_parser("comment-create", help="댓글 생성")
    p.add_argument("--post-id", required=True, type=int)
    p.add_argument("--content", required=True)
    p.add_argument("--parent-id", type=int)
    p.add_argument("--upload-ids", help="쉼표 구분 업로드 ID")

    # 댓글 수정
    p = sub.add_parser("comment-update", help="댓글 ��정")
    p.add_argument("--comment-id", required=True, type=int)
    p.add_argument("--content", required=True)
    p.add_argument("--upload-ids", help="쉼표 구분 업로드 ID")

    # 댓글 삭��
    p = sub.add_parser("comment-delete", help="댓글 삭제")
    p.add_argument("--comment-id", required=True, type=int)

    # 사이트 목록
    p = sub.add_parser("sites", help="사이트 목록 조회")
    p.add_argument("--page", type=int, default=1)
    p.add_argument("--per-page", type=int, default=10)

    # 카테고리 트리
    p = sub.add_parser("categories", help="카테고리 트리 조회")
    p.add_argument("--site-id", required=True, type=int)

    # API 문서
    p = sub.add_parser("docs", help="API 문서 조회")
    p.add_argument("--category", help="필터: auth, user, post, comment, file, site, category")

    args = parser.parse_args()

    # --base-url 옵션 적용
    global BASE_URL
    BASE_URL = args.base_url

    commands = {
        "register": cmd_register,
        "login": cmd_login,
        "me": cmd_me,
        "update-profile": cmd_update_profile,
        "upload-avatar": cmd_upload_avatar,
        "upload": cmd_upload,
        "create": cmd_create,
        "update": cmd_update,
        "delete": cmd_delete,
        "get": cmd_get,
        "list": cmd_list,
        "comment-create": cmd_comment_create,
        "comment-update": cmd_comment_update,
        "comment-delete": cmd_comment_delete,
        "sites": cmd_sites,
        "categories": cmd_categories,
        "docs": cmd_docs,
    }
    commands[args.command](args)


if __name__ == "__main__":
    main()
