#!/bin/zsh
set -u

echo "Boss Katana speaker setup"
echo "-------------------------"

HELPER="${KATANA_MACSPEAKER:-}"
SCRIPT_DIR="${0:A:h}"

if [[ -z "$HELPER" ]]; then
  if [[ -x "$SCRIPT_DIR/katana-macspeaker" ]]; then
    HELPER="$SCRIPT_DIR/katana-macspeaker"
  elif command -v katana-macspeaker >/dev/null 2>&1; then
    HELPER="$(command -v katana-macspeaker)"
  elif [[ -x "$HOME/.local/bin/katana-macspeaker" ]]; then
    HELPER="$HOME/.local/bin/katana-macspeaker"
  elif [[ -x "$HOME/bin/katana-macspeaker" ]]; then
    HELPER="$HOME/bin/katana-macspeaker"
  fi
fi

if [[ -z "$HELPER" || ! -x "$HELPER" ]]; then
  echo "Could not find katana-macspeaker."
  echo "Install it first with: make install"
  echo
  read -r "?Press Return to close..."
  exit 1
fi

if pgrep -x eqMac >/dev/null 2>&1; then
  echo "Quitting eqMac so it does not take over the Katana output..."
  osascript -e 'tell application "eqMac" to quit' >/dev/null 2>&1 || true
  sleep 1

  if pgrep -x eqMac >/dev/null 2>&1; then
    pkill -x eqMac >/dev/null 2>&1 || true
    sleep 1
  fi
else
  echo "eqMac is not running."
fi

echo "Waiting for a real BOSS Katana audio output device..."
found=0
for _ in {1..20}; do
  if "$HELPER" --list 2>/dev/null | grep -Ei 'KATANA.*\[BOSS\]' >/dev/null; then
    found=1
    break
  fi
  sleep 1
done

if [[ "$found" != "1" ]]; then
  echo "Could not find a BOSS Katana output device."
  echo "Turn on the amp, connect the USB cable, then run this again."
  echo
  read -r "?Press Return to close..."
  exit 1
fi

echo "Mapping Mac stereo audio to Katana USB channels 3/4..."
if "$HELPER"; then
  echo
  "$HELPER" --list | grep -Ei 'KATANA.*\[BOSS\]' || true
  echo
  echo "Done. Mac audio should now play through the Katana speaker if your model routes USB 3/4 to the speaker path."
  afplay -v 0.25 /System/Library/Sounds/Glass.aiff >/dev/null 2>&1 || true
else
  echo
  echo "The Katana setup command failed."
  echo "Try unplugging/replugging USB, then run this file again."
  echo
  read -r "?Press Return to close..."
  exit 1
fi

echo
read -r "?Press Return to close..."
