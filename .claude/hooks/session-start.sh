#!/bin/bash
# SessionStart hook for Claude Code cloud sessions: installs the graphify CLI
# (needed by the PreToolUse `graphify hook-guard` hooks) and the dev
# environment used for tests and linting.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"

# Editable install of the CLI from this checkout; --force keeps it idempotent.
uv tool install --force -e . >/dev/null

# Project venv (.venv) with the dev group: pytest, ruff, pyright, ...
uv sync --frozen

# Build the code map (graphify-out/, gitignored) so the hook-guard nudges have a
# graph to point at. AST-only: no LLM/API calls, no tokens. Output goes to stderr
# so it stays out of the session context; a failure must not block the session.
graphify update . >&2 || echo "graphify update failed; run it manually" >&2

echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> "${CLAUDE_ENV_FILE:-/dev/null}"
