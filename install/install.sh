#!/usr/bin/env bash
# Thin launcher: finds a Python 3 interpreter and runs install/install.py with
# the same arguments (--full, --support-only, --dry-run). The Python file is the
# only installer implementation; keep this launcher free of install logic.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for python_command in python3 python; do
  if command -v "$python_command" >/dev/null 2>&1; then
    exec "$python_command" "$SCRIPT_DIR/install.py" "$@"
  fi
done

echo "Python 3.8 or newer is required. Install Python 3 or run install/install.py with an available Python 3 interpreter." >&2
exit 1
