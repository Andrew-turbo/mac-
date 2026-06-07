#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${MAC_SLIM_MANAGER_REPO_URL:-https://github.com/Andrew-turbo/mac-.git}"
INSTALL_DIR="${MAC_SLIM_MANAGER_DIR:-$HOME/.mac-slim-manager}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "MacSlimManager can only run on macOS."
  exit 1
fi

if ! command -v git >/dev/null 2>&1 || ! command -v swift >/dev/null 2>&1; then
  if command -v xcode-select >/dev/null 2>&1; then
    xcode-select --install 2>/dev/null || true
  fi

  echo "Apple command line tools are required."
  echo "Finish the installer that just opened, then rerun the same one-line command."
  exit 1
fi

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "Updating MacSlimManager..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "Downloading MacSlimManager..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
exec ./tools/run.sh
