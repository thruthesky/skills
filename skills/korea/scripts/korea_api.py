#!/usr/bin/env python3
"""Korea SNS API 클라이언트 — 게시글/댓글 CRUD 스크립트.

사용법:
  python3 korea_api.py create --api-key KEY --title "제목" --content "내용" [--category-id 3] [--site-id 1]
  python3 korea_api.py update --api-key KEY --id 1 --title "새제목" --content "새내용"
  python3 korea_api.py delete --api-key KEY --id 1
  python3 korea_api.py get    --api-key KEY --id 1
  python3 korea_api.py list   --api-key KEY [--page 1] [--per-page 10] [--category free]

  # 댓글
  python3 korea_api.py comment-create --api-key KEY --post-id 1 --content "댓글"
  python3 korea_api.py comment-update --api-key KEY --comment-id 1 --content "수정"
  python3 korea_api.py comment-delete --api-key KEY --comment-id 1
"""

import argparse
import json
import sys
import urllib.request
import urllib.error
import urllib.parse

BASE_URL = "https://withcenter.com/api/v1"


def api_request(method: str, path: str, api_key: str, data: dict | None = None, params: dict | None = None) -> dict:
    """API 요청을 보내고 JSON 응답을 반환한다."""
    url = f"{BASE_URL}{path}"

    if params:
        filtered = {k: v for k, v in params.items() if v is not None}
        if filtered:
            url += "?" + urllib.parse.urlencode(filtered)

    body = json.dumps(data).encode() if data else None

    req = urllib.request.Request(url, data=body, method=method)
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


def cmd_create(args):
    """게시글 생성."""
    data = {"title": args.title, "content": args.content}
    if args.category_id:
        data["category_id"] = args.category_id
    if args.site_id:
        data["site_id"] = args.site_id

    result = api_request("POST", "/posts", args.api_key, data=data)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_update(args):
    """게시글 수정."""
    data = {}
    if args.title:
        data["title"] = args.title
    if args.content:
        data["content"] = args.content
    if args.category_id:
        data["category_id"] = args.category_id

    if not data:
        print('{"message": "수정할 내용이 없습니다."}')
        sys.exit(1)

    result = api_request("PUT", f"/posts/{args.id}", args.api_key, data=data)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_delete(args):
    """게시글 삭제."""
    result = api_request("DELETE", f"/posts/{args.id}", args.api_key)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_get(args):
    """게시글 상세 조회."""
    result = api_request("GET", f"/posts/{args.id}", args.api_key)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_list(args):
    """게시글 목록 조회."""
    params = {
        "page": args.page,
        "per_page": args.per_page,
        "category": args.category,
        "site_id": args.site_id,
        "order_by": args.order_by,
    }
    result = api_request("GET", "/posts", args.api_key, params=params)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_comment_create(args):
    """댓글 생성."""
    data = {"content": args.content}
    if args.parent_id:
        data["parent_id"] = args.parent_id

    result = api_request("POST", f"/posts/{args.post_id}/comments", args.api_key, data=data)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_comment_update(args):
    """댓글 수정."""
    data = {"content": args.content}
    result = api_request("PATCH", f"/comments/{args.comment_id}", args.api_key, data=data)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_comment_delete(args):
    """댓글 삭제."""
    result = api_request("DELETE", f"/comments/{args.comment_id}", args.api_key)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def main():
    parser = argparse.ArgumentParser(description="Korea SNS API 클라이언트")
    parser.add_argument("--api-key", required=True, help="API 키")
    sub = parser.add_subparsers(dest="command", required=True)

    # 게시글 생성
    p = sub.add_parser("create", help="게시글 생성")
    p.add_argument("--title", required=True)
    p.add_argument("--content", required=True)
    p.add_argument("--category-id", type=int)
    p.add_argument("--site-id", type=int)

    # 게시글 수정
    p = sub.add_parser("update", help="게시글 수정")
    p.add_argument("--id", required=True, type=int)
    p.add_argument("--title")
    p.add_argument("--content")
    p.add_argument("--category-id", type=int)

    # 게시글 삭제
    p = sub.add_parser("delete", help="게시글 삭제")
    p.add_argument("--id", required=True, type=int)

    # 게시글 조회
    p = sub.add_parser("get", help="게시글 상세 조회")
    p.add_argument("--id", required=True, type=int)

    # 게시글 목록
    p = sub.add_parser("list", help="게시글 목록 조회")
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

    # 댓글 수정
    p = sub.add_parser("comment-update", help="댓글 수정")
    p.add_argument("--comment-id", required=True, type=int)
    p.add_argument("--content", required=True)

    # 댓글 삭제
    p = sub.add_parser("comment-delete", help="댓글 삭제")
    p.add_argument("--comment-id", required=True, type=int)

    args = parser.parse_args()

    commands = {
        "create": cmd_create,
        "update": cmd_update,
        "delete": cmd_delete,
        "get": cmd_get,
        "list": cmd_list,
        "comment-create": cmd_comment_create,
        "comment-update": cmd_comment_update,
        "comment-delete": cmd_comment_delete,
    }
    commands[args.command](args)


if __name__ == "__main__":
    main()
