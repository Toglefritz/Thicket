#!/bin/zsh
#
# Installs the Thicket git hooks into the specified project directory.
#
# Usage:
#   ./integrations/git/install.sh /path/to/your/project

set -e

if [[ -z "$1" ]]; then
  echo "Usage: $0 <project-directory>"
  exit 1
fi

PROJECT_DIR="$1"
HOOKS_DIR="$PROJECT_DIR/.git/hooks"

if [[ ! -d "$PROJECT_DIR/.git" ]]; then
  echo "Error: $PROJECT_DIR is not a git repository."
  exit 1
fi

if [[ ! -f "$PROJECT_DIR/.thicket/project.json" ]]; then
  echo "Warning: No .thicket/project.json found. Run the setup wizard first."
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

cp "$SCRIPT_DIR/post-commit" "$HOOKS_DIR/post-commit"
chmod +x "$HOOKS_DIR/post-commit"

echo "Installed Thicket post-commit hook in $HOOKS_DIR"
