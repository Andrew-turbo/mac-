#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "MacSlimManager can only run on macOS."
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "Swift was not found. Install Apple's command line tools first:"
  echo "  xcode-select --install"
  exit 1
fi

echo "Starting MacSlimManager..."
swift run MacSlimManager
