#!/bin/sh
set -eu

REPO_RAW_BASE="${KATANA_MACSPEAKER_RAW_BASE:-https://raw.githubusercontent.com/aifunmobi/Katana_MacSpeaker/main}"
BIN_DIR="${KATANA_MACSPEAKER_BIN_DIR:-$HOME/.local/bin}"
DESKTOP_DIR="${KATANA_MACSPEAKER_DESKTOP_DIR:-$HOME/Desktop}"
BIN_PATH="$BIN_DIR/katana-macspeaker"
LAUNCHER_PATH="$DESKTOP_DIR/boss.command"

die() {
  printf 'katana-macspeaker install: %s\n' "$*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

if [ "$(uname -s)" != "Darwin" ]; then
  die "this installer is for macOS"
fi

need_command curl
need_command mkdir
need_command chmod
need_command mktemp

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/katana-macspeaker.XXXXXX")"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT HUP TERM

printf 'Installing Katana_MacSpeaker\n'
printf '  binary:   %s\n' "$BIN_PATH"
printf '  launcher: %s\n' "$LAUNCHER_PATH"

curl -fsSL --retry 3 --output "$TMP_DIR/katana-macspeaker" "$REPO_RAW_BASE/dist/katana-macspeaker"
curl -fsSL --retry 3 --output "$TMP_DIR/boss.command" "$REPO_RAW_BASE/dist/boss.command"

mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"

cp "$TMP_DIR/katana-macspeaker" "$BIN_PATH"
cp "$TMP_DIR/boss.command" "$LAUNCHER_PATH"
chmod +x "$BIN_PATH" "$LAUNCHER_PATH"

if command -v xattr >/dev/null 2>&1; then
  xattr -d com.apple.quarantine "$BIN_PATH" >/dev/null 2>&1 || true
  xattr -d com.apple.quarantine "$LAUNCHER_PATH" >/dev/null 2>&1 || true
fi

printf '\nInstalled.\n'
printf 'Turn on/connect your Katana, then double-click:\n'
printf '  %s\n' "$LAUNCHER_PATH"
printf '\nOr run:\n'
printf '  %s\n' "$BIN_PATH"
