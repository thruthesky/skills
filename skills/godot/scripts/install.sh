#!/usr/bin/env bash
#
# install.sh — Godot 에디터 없이 빌드·설치·실행한다.
#
#   install.sh                       사용 가능한 장치를 번호로 보여주고 고르게 한다
#   install.sh 1                     목록의 1번을 바로 고른다
#   install.sh R58X609XXYV           Android 시리얼을 직접 지정
#   install.sh 00008140-001C24C9…    iOS UDID 를 직접 지정
#   install.sh macos                 이 맥에서 빌드·실행
#
#   install.sh <선택> --release      릴리즈 빌드로
#   install.sh <선택> --skip-build   빌드 생략, 설치·실행만
#   install.sh <선택> --console      실행 로그를 터미널에 붙여서 본다
#   install.sh <선택> --no-launch    설치만 하고 실행하지 않는다
#   install.sh <선택> --path ~/game  프로젝트 경로 지정 (기본: 현재 폴더에서 위로 탐색)
#   install.sh --list                목록만 보고 끝낸다
#
# 어느 플랫폼인지는 고른 장치가 정한다. preset 이름·패키지 ID·산출물 경로는
# export_presets.cfg 에서 직접 읽으므로 프로젝트마다 고칠 필요가 없다.
#
set -euo pipefail

# ── 출력 ────────────────────────────────────────────────────────────────
step() { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✅\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m⚠️\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[1;31m❌\033[0m %s\n' "$*" >&2; exit 1; }

# ── 인자 파싱 ───────────────────────────────────────────────────────────
SELECTION=""
BUILD_MODE="debug"
SKIP_BUILD=0
CONSOLE=0
LAUNCH=1
LIST_ONLY=0
PROJECT_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --release)    BUILD_MODE="release" ;;
    --debug)      BUILD_MODE="debug" ;;
    --skip-build) SKIP_BUILD=1 ;;
    --console)    CONSOLE=1 ;;
    --no-launch)  LAUNCH=0 ;;
    --list)       LIST_ONLY=1 ;;
    --path)       shift; PROJECT_ARG="${1:-}" ;;
    -h|--help)    awk 'NR>1 { if (/^#/) { sub(/^# ?/, ""); print } else exit }' "$0"; exit 0 ;;
    -*)           die "알 수 없는 옵션: $1" ;;
    *)            SELECTION="$1" ;;
  esac
  shift
done

# ── 장치 수집 ───────────────────────────────────────────────────────────
# 각 항목은  플랫폼<TAB>기기ID<TAB>표시이름  한 줄이다.

macos_entry() {
  [ "$(uname -s)" = "Darwin" ] || return 0
  printf 'macos\tlocal\t이 맥에서 실행 (%s)\n' "$(uname -m)"
}

android_entries() {
  command -v adb >/dev/null 2>&1 || return 0
  adb devices -l 2>/dev/null | awk 'NR>1 && $2=="device" {
    serial = $1; model = ""
    for (i = 3; i <= NF; i++) if ($i ~ /^model:/) { model = substr($i, 7); gsub(/_/, " ", model) }
    if (model == "") model = "Android 기기"
    printf "android\t%s\t%s\n", serial, model
  }'
}

# devicectl 이 available 로 판정한 것만 — 설치가 실제로 가능한 기기다
ios_entries() {
  command -v xcrun >/dev/null 2>&1 || return 0
  xcrun devicectl list devices 2>/dev/null | awk '
    {
      uuid = ""; ui = 0
      for (i = 1; i <= NF; i++)
        if ($i ~ /^[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}$/) { uuid = $i; ui = i }
      if (uuid == "" || $(ui + 1) != "available") next
      model = ""
      for (i = ui + 2; i <= NF; i++) {
        if (i == ui + 2 && $i ~ /^\(/) continue          # (paired) 는 건너뛴다
        model = model (model == "" ? "" : " ") $i
      }
      if (model == "") model = "iOS 기기"
      printf "ios\t%s\t%s — %s\n", uuid, $1, model
    }'
}

collect_devices() { { macos_entry; ios_entries; android_entries; } 2>/dev/null | awk 'NF'; }

DEVICES=$(collect_devices)

print_menu() {
  echo "사용 가능한 장치:"
  echo
  printf '%s\n' "$DEVICES" | awk -F'\t' '{
    label = toupper(substr($1,1,1)) substr($1,2)
    if ($1 == "macos")   label = "macOS"
    if ($1 == "ios")     label = "iOS"
    if ($1 == "android") label = "Android"
    printf "  \033[1;36m%d)\033[0m  %-9s %s\n", NR, label, $3
    if ($2 != "local") printf "        %*s\033[90m%s\033[0m\n", 9, "", $2
  }'
  echo
  # 연결이 없는 플랫폼은 왜 안 보이는지 알려 준다
  printf '%s\n' "$DEVICES" | grep -q '^ios'     || echo "  (iOS 기기 없음 — USB 연결 후 '이 컴퓨터를 신뢰' 를 누른다)"
  printf '%s\n' "$DEVICES" | grep -q '^android' || echo "  (Android 기기 없음 — USB 디버깅을 켜고 연결한다)"
}

if [ "$LIST_ONLY" -eq 1 ]; then print_menu; exit 0; fi

# ── 선택 해석 ───────────────────────────────────────────────────────────
# 번호 → 목록에서, 그 외 → 기기 ID·플랫폼 이름으로 직접 매칭
resolve_selection() {
  local sel="$1"
  if printf '%s' "$sel" | grep -Eq '^[0-9]+$'; then
    printf '%s\n' "$DEVICES" | awk -F'\t' -v n="$sel" 'NR == n { print; found = 1 } END { exit !found }'
    return
  fi
  case "$sel" in
    macos|macOS|mac) printf '%s\n' "$DEVICES" | awk -F'\t' '$1 == "macos" { print; exit }'; return ;;
  esac
  printf '%s\n' "$DEVICES" | awk -F'\t' -v id="$sel" '$2 == id { print; found = 1 } END { exit !found }'
}

if [ -z "$SELECTION" ]; then
  print_menu
  if [ ! -t 0 ]; then
    echo "번호를 인자로 준다:  $(basename "$0") 1"
    exit 0
  fi
  echo
  printf '번호 선택 [1]: '
  read -r SELECTION || SELECTION=""
  [ -n "$SELECTION" ] || SELECTION="1"
  echo
fi

ENTRY=$(resolve_selection "$SELECTION") || {
  print_menu >&2
  die "'$SELECTION' 에 해당하는 장치가 없다. 위 번호나 기기 ID 를 쓴다."
}

PLATFORM=$(printf '%s' "$ENTRY" | cut -f1)
DEVICE_ID=$(printf '%s' "$ENTRY" | cut -f2)
DEVICE_LABEL=$(printf '%s' "$ENTRY" | cut -f3)
ok "선택: $PLATFORM — $DEVICE_LABEL"

# ── 프로젝트 루트 찾기 ──────────────────────────────────────────────────
find_project_root() {
  local dir="${1:-$PWD}"
  dir=$(cd "$dir" 2>/dev/null && pwd) || return 1
  while [ "$dir" != "/" ]; do
    [ -f "$dir/project.godot" ] && { echo "$dir"; return 0; }
    dir=$(dirname "$dir")
  done
  return 1
}

ROOT=$(find_project_root "${PROJECT_ARG:-$PWD}") \
  || die "project.godot 을 찾지 못했다. Godot 프로젝트 안에서 실행하거나 --path 로 지정한다."
cd "$ROOT"
ok "프로젝트: $ROOT"

PRESETS="$ROOT/export_presets.cfg"
[ -f "$PRESETS" ] || die "export_presets.cfg 가 없다. 먼저 export preset 을 만든다."

# ── export_presets.cfg 파싱 ─────────────────────────────────────────────
# $1: platform 값("Android"/"iOS"/"macOS"), $2: 읽을 키
preset_get() {
  awk -v want="$1" -v key="$2" '
    /^\[preset\.[0-9]+\]$/ { cur = $0; gsub(/[^0-9]/, "", cur); next }
    /^\[preset\.[0-9]+\.options\]$/ { cur = $0; gsub(/[^0-9]/, "", cur); next }
    /^[A-Za-z]/ {
      eq = index($0, "=")
      if (eq == 0 || cur == "") next
      k = substr($0, 1, eq - 1)
      v = substr($0, eq + 1)
      gsub(/^[ \t]+|[ \t\r]+$/, "", v)
      gsub(/^"|"$/, "", v)
      data[cur "\x01" k] = v
      if (k == "platform" && !(v in first)) first[v] = cur
    }
    END { if (want in first) print data[first[want] "\x01" key] }
  ' "$PRESETS"
}

# ── 플랫폼별 preset 값 ──────────────────────────────────────────────────
GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"
[ -n "$GODOT_BIN" ] || die "godot 실행 파일을 찾지 못했다. GODOT_BIN 환경변수로 경로를 지정한다."

case "$PLATFORM" in
  android)
    PRESET_NAME=$(preset_get "Android" "name")
    PACKAGE_ID=$(preset_get "Android" "package/unique_name")
    EXPORT_PATH=$(preset_get "Android" "export_path")
    [ -n "$PRESET_NAME" ] || die "export_presets.cfg 에 platform=\"Android\" preset 이 없다."
    [ -n "$PACKAGE_ID" ]  || die "Android preset 에 package/unique_name 이 없다."
    [ -n "$EXPORT_PATH" ] || EXPORT_PATH="builds/android/${PRESET_NAME}.apk"
    ARTIFACT="$ROOT/$EXPORT_PATH"
    ;;
  ios)
    PRESET_NAME=$(preset_get "iOS" "name")
    PACKAGE_ID=$(preset_get "iOS" "application/bundle_identifier")
    EXPORT_PATH=$(preset_get "iOS" "export_path")
    PROJECT_ONLY=$(preset_get "iOS" "application/export_project_only")
    [ -n "$PRESET_NAME" ] || die "export_presets.cfg 에 platform=\"iOS\" preset 이 없다."
    [ -n "$PACKAGE_ID" ]  || die "iOS preset 에 application/bundle_identifier 가 없다."
    [ -n "$EXPORT_PATH" ] || EXPORT_PATH="builds/ios/${PRESET_NAME}.ipa"
    if [ "$PROJECT_ONLY" = "true" ]; then
      die "iOS preset 의 application/export_project_only 가 true 다.
   이러면 Godot 이 Xcode 프로젝트만 만들고 멈춰서 .ipa 가 나오지 않는다.
   export_presets.cfg 에서 false 로 바꾼다."
    fi
    IOS_OUT_DIR="$ROOT/$(dirname "$EXPORT_PATH")"
    ;;
  macos)
    PRESET_NAME=$(preset_get "macOS" "name")
    PACKAGE_ID=$(preset_get "macOS" "application/bundle_identifier")
    EXPORT_PATH=$(preset_get "macOS" "export_path")
    [ -n "$PRESET_NAME" ] || die "export_presets.cfg 에 platform=\"macOS\" preset 이 없다."
    [ -n "$EXPORT_PATH" ] || EXPORT_PATH="builds/macos/${PRESET_NAME}.app"
    ARTIFACT="$ROOT/$EXPORT_PATH"
    ;;
esac

# ── 빌드 ────────────────────────────────────────────────────────────────
if [ "$SKIP_BUILD" -eq 0 ]; then
  step "빌드 중 — $PLATFORM / $BUILD_MODE / preset \"$PRESET_NAME\""
  mkdir -p "$(dirname "$ROOT/$EXPORT_PATH")" artifacts/logs
  "$GODOT_BIN" --headless --path "$ROOT" --import --quit >/dev/null 2>&1 || true
  "$GODOT_BIN" --headless --path "$ROOT" \
    "--export-$BUILD_MODE" "$PRESET_NAME" "$EXPORT_PATH" \
    --log-file "artifacts/logs/install-$PLATFORM-$BUILD_MODE.log" \
    || die "빌드 실패. artifacts/logs/install-$PLATFORM-$BUILD_MODE.log 를 확인한다.
   iOS 에서 오류 본문이 비어 있으면 아이콘 → Team ID → bundle id → ios.zip 템플릿 순으로 점검한다."
fi

# iOS 는 export_path 옆에 .ipa 가 떨어진다
if [ "$PLATFORM" = "ios" ]; then
  ARTIFACT=$(find "$IOS_OUT_DIR" -maxdepth 1 -name '*.ipa' -print 2>/dev/null | head -1)
  [ -n "$ARTIFACT" ] || die ".ipa 를 찾지 못했다: $IOS_OUT_DIR
   서명 설정(app_store_team_id·code_sign_identity_debug)을 확인한다."
fi

[ -e "$ARTIFACT" ] || die "설치할 파일이 없다: $ARTIFACT"
ok "산출물: $ARTIFACT ($(du -sh "$ARTIFACT" | cut -f1))"

# ── 설치 · 실행 ─────────────────────────────────────────────────────────
case "$PLATFORM" in
  android)
    step "설치 중 — $PACKAGE_ID"
    adb -s "$DEVICE_ID" install -r "$ARTIFACT" | tail -2

    if [ "$LAUNCH" -eq 1 ]; then
      step "실행 중"
      adb -s "$DEVICE_ID" shell monkey -p "$PACKAGE_ID" \
        -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
      ok "기기 화면을 확인한다."
      if [ "$CONSOLE" -eq 1 ]; then
        step "로그 (Ctrl+C 로 중지)"
        adb -s "$DEVICE_ID" logcat -c
        adb -s "$DEVICE_ID" logcat -s godot:V GodotEngine:V AndroidRuntime:E DEBUG:V
      else
        echo "   로그: adb -s $DEVICE_ID logcat -s godot"
      fi
    fi
    ;;

  ios)
    step "설치 중 — $PACKAGE_ID"
    xcrun devicectl device install app --device "$DEVICE_ID" "$ARTIFACT" \
      | grep -E 'bundleID|installationURL' || true

    if [ "$LAUNCH" -eq 1 ]; then
      step "실행 중"
      if [ "$CONSOLE" -eq 1 ]; then
        # 앱이 끝날 때까지 로그를 붙잡는다. Ctrl+C 로 중지.
        xcrun devicectl device process launch \
          --device "$DEVICE_ID" --terminate-existing --console "$PACKAGE_ID"
      else
        xcrun devicectl device process launch \
          --device "$DEVICE_ID" --terminate-existing "$PACKAGE_ID" | tail -1
        ok "기기 화면을 확인한다."
        echo "   로그: $(basename "$0") $DEVICE_ID --skip-build --console"
      fi
    fi
    ;;

  macos)
    # export_path 가 .zip 이면 풀어서 .app 을 꺼낸다
    APP="$ARTIFACT"
    case "$ARTIFACT" in
      *.zip)
        step "압축 해제"
        (cd "$(dirname "$ARTIFACT")" && unzip -oq "$(basename "$ARTIFACT")")
        APP=$(find "$(dirname "$ARTIFACT")" -maxdepth 1 -name '*.app' -print | head -1)
        [ -n "$APP" ] || die ".app 을 찾지 못했다: $(dirname "$ARTIFACT")"
        ;;
    esac

    # 서명 없이 빌드하면 Gatekeeper 가 막는다 — 내가 만든 빌드에만 쓴다
    xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

    if [ "$LAUNCH" -eq 1 ]; then
      BIN=$(find "$APP/Contents/MacOS" -maxdepth 1 -type f -perm -u+x -print 2>/dev/null | head -1)
      [ -n "$BIN" ] || die "실행 바이너리를 찾지 못했다: $APP/Contents/MacOS"
      if [ "$CONSOLE" -eq 1 ]; then
        step "실행 중 (로그 붙임 — Ctrl+C 로 중지)"
        "$BIN"
      else
        step "실행 중"
        open "$APP"
        ok "창을 확인한다."
        echo "   로그: $(basename "$0") macos --skip-build --console"
      fi
    else
      ok "빌드만 완료: $APP"
    fi
    ;;
esac
