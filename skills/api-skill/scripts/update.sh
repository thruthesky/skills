#!/usr/bin/env bash
# api-skill 을 최신으로 바꾼다 — 스킬을 update 인자로 부르거나 사용자가 "/api-skill update" 라고 하면 실행한다.
#
# Claude Code 플러그인(~/.claude/plugins/…)이면 마켓플레이스 목록을 받고, 설치된 범위(user·project·local)마다
#   claude plugin update 를 실행한다. project·local 범위는 그 프로젝트 폴더에서 실행해야 찾는다. 새 판은 Claude Code 를 다시 시작하면 적용된다.
# 폴더로 설치한 스킬(~/.agents/skills/api-skill, ~/.claude/skills/api-skill 등)이면 GitHub 의
#   thruthesky/skills 저장소 묶음을 받아 그 안의 skills/api-skill 로 이 폴더를 통째로 바꾼다.
# 원본 저장소(thruthesky/skills) 안의 스킬이면 작업 트리가 깨끗하고 main 일 때만 git pull --ff-only 한다.
# 받을 묶음은 API_SKILL_TARBALL 로 바꿀 수 있다 (주소 또는 로컬 파일 — 시험용).
#   시험 묶음 만들기: git -C <skills 체크아웃> archive --prefix=skills-main/ HEAD | gzip > /tmp/skills.tar.gz
set -euo pipefail

NAME="api-skill"
REPO="thruthesky/skills"
MARKETPLACE="thruthesky-skills"
BRANCH="main"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
URL="${API_SKILL_TARBALL:-https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH}"
MEMBER="skills-$BRANCH/skills/$NAME" # 묶음 안의 스킬 폴더

version_of() { sed -n 's/^  version: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p' "$1/SKILL.md" | head -1; }
is_skill() { [ -f "$1/SKILL.md" ] && grep -q "^name: $NAME$" "$1/SKILL.md"; }

is_skill "$SKILL_DIR" || { echo "스킬 폴더를 확인할 수 없다 — $SKILL_DIR" >&2; exit 1; }

# 옛 이름(travel-api-skill)으로 설치한 폴더가 남아 있으면 옛 내용으로 답할 수 있다 — 지우지는 않고 알린다.
warn_old() {
  for d in "$HOME/.claude/skills/travel-api-skill" "$HOME/.agents/skills/travel-api-skill"; do
    [ -d "$d" ] && echo "(알림) 옛 이름의 스킬 폴더가 남아 있다 — $d . 같은 질문에 옛 내용(여행지 100곳)으로 답할 수 있으니 지운다: rm -rf \"$d\""
  done
  return 0
}

# Claude Code 플러그인은 Claude Code 가 관리한다. 폴더를 직접 바꾸지 않고 claude plugin 명령으로 바꾼다.
case "$SKILL_DIR" in
  */.claude/plugins/*)
    old="$(version_of "$SKILL_DIR")"
    if ! command -v claude >/dev/null 2>&1 || ! command -v node >/dev/null 2>&1; then
      echo "Claude Code 플러그인으로 설치된 스킬이다 — $NAME ${old:-?}. claude·node 명령이 없어 직접 실행한다:" >&2
      echo "  claude plugin marketplace update $MARKETPLACE && claude plugin update $NAME@$MARKETPLACE" >&2
      exit 1
    fi
    echo "Claude Code 플러그인 — 마켓플레이스 목록을 받고 $NAME 을 최신으로 바꾼다 (지금 ${old:-?})"
    claude plugin marketplace update "$MARKETPLACE"
    # 설치된 곳: 한 줄에 「범위<TAB>프로젝트 폴더」 (user 범위는 폴더가 비어 있다)
    installs="$(claude plugin list --json | node -e '
      let s = ""; process.stdin.on("data", (d) => (s += d)).on("end", () => {
        const all = JSON.parse(s); const list = Array.isArray(all) ? all : all.plugins ?? [];
        for (const p of list) if (p.id === process.argv[1]) console.log(`${p.scope}\t${p.projectPath ?? ""}`);
      });' "$NAME@$MARKETPLACE")"
    failed=0
    if [ -z "$installs" ]; then
      claude plugin update "$NAME@$MARKETPLACE" || failed=1
    else
      while IFS=$'\t' read -r scope project; do
        if [ -n "$project" ] && [ -d "$project" ]; then
          (cd "$project" && claude plugin update "$NAME@$MARKETPLACE" --scope "$scope") || failed=1
        else
          claude plugin update "$NAME@$MARKETPLACE" --scope "$scope" || failed=1
        fi
      done <<< "$installs"
    fi
    new="$(claude plugin list --json | node -e '
      let s = ""; process.stdin.on("data", (d) => (s += d)).on("end", () => {
        const all = JSON.parse(s); const list = Array.isArray(all) ? all : all.plugins ?? [];
        console.log(list.filter((p) => p.id === process.argv[1]).map((p) => p.version).sort().pop() ?? "");
      });' "$NAME@$MARKETPLACE")"
    warn_old
    if [ "$failed" = 1 ]; then echo "일부 범위를 바꾸지 못했다 — 위 출력을 본다" >&2; exit 1; fi
    if [ "${old:-}" = "${new:-}" ]; then echo "이미 최신이다 — $NAME ${new:-?}"
    else echo "갱신했다 — $NAME ${old:-?} → ${new:-?}. Claude Code 를 다시 시작하면 새 판이 적용된다."; fi
    exit 0
    ;;
esac

# 원본 저장소 안이면 git 으로 관리한다. 고치던 것이 있거나 main 이 아니면 건드리지 않는다.
if top="$(git -C "$SKILL_DIR" rev-parse --show-toplevel 2>/dev/null)" \
  && [ "$(cd "$top" && pwd -P)/skills/$NAME" = "$SKILL_DIR" ] \
  && git -C "$top" remote get-url origin 2>/dev/null | grep -q "$REPO"; then
  old="$(version_of "$SKILL_DIR")"
  if [ -n "$(git -C "$top" status --porcelain)" ] || [ "$(git -C "$top" branch --show-current)" != "$BRANCH" ]; then
    echo "원본 저장소($top) 안의 스킬인데 고치던 것이 있거나 $BRANCH 브랜치가 아니라서 그대로 둔다 — 정리한 뒤: git -C \"$top\" pull --ff-only"
    warn_old
    exit 0
  fi
  git -C "$top" pull --ff-only --quiet
  new="$(version_of "$SKILL_DIR")"
  warn_old
  if [ "$old" = "$new" ]; then echo "이미 최신이다 — $NAME ${new:-?} ($top)"; else echo "갱신했다 — $NAME ${old:-?} → ${new:-?} ($top)"; fi
  exit 0
fi

# 새 폴더는 스킬 폴더와 같은 디스크에 풀어야 mv 한 번으로 바꿀 수 있다.
parent="$(dirname "$SKILL_DIR")"
tmp="$(mktemp -d "$parent/.$NAME.new.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

case "$URL" in
  http://* | https://*) curl -fsSL "$URL" -o "$tmp/skills.tar.gz" ;;
  *) cp "$URL" "$tmp/skills.tar.gz" ;;
esac
tar -xzf "$tmp/skills.tar.gz" -C "$tmp" --strip-components=2 "$MEMBER"
is_skill "$tmp/$NAME" || { echo "받은 묶음에 $MEMBER 이 없거나 올바르지 않다 — $URL" >&2; exit 1; }

old="$(version_of "$SKILL_DIR")"
new="$(version_of "$tmp/$NAME")"
if diff -rq -x .DS_Store "$SKILL_DIR" "$tmp/$NAME" >/dev/null 2>&1; then
  warn_old
  echo "이미 최신이다 — $NAME ${old:-?} ($SKILL_DIR)"
  exit 0
fi

# 옛 폴더를 옆으로 옮기고 새 폴더를 그 자리에 둔다. 실패하면 옛 폴더를 되돌린다.
backup="$tmp/old"
mv "$SKILL_DIR" "$backup"
if ! mv "$tmp/$NAME" "$SKILL_DIR"; then
  mv "$backup" "$SKILL_DIR"
  echo "바꾸지 못해 원래대로 되돌렸다 — $SKILL_DIR" >&2
  exit 1
fi
warn_old
echo "갱신했다 — $NAME ${old:-?} → ${new:-?} ($SKILL_DIR)"
echo "새 내용은 다음 대화부터 적용된다. 지금 대화에서 쓰려면 SKILL.md 를 다시 읽는다."
