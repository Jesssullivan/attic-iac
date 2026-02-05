#!/usr/bin/env bash
# Setup script for git hooks
# Run this once after cloning the repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Setting up git hooks for attic-cache..."

# Configure git to use .githooks directory
cd "$REPO_ROOT"
git config core.hooksPath .githooks

# Make hooks executable
chmod +x "$SCRIPT_DIR/pre-commit"
chmod +x "$SCRIPT_DIR/commit-msg"

echo ""
echo "Git hooks installed successfully!"
echo ""
echo "Hooks enabled:"
echo "  - pre-commit: Secret detection, CLAUDE file blocking, auto-formatting"
echo "  - commit-msg: Auto-removes Co-Authored-By, conventional commit warnings"
echo ""
echo "To disable hooks temporarily, use: git commit --no-verify"
echo "To uninstall hooks: git config --unset core.hooksPath"
