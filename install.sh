#!/usr/bin/env bash
# install.sh — set up claude-copilot launcher + isolated settings.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CLAUDE_COPILOT_HOME:-$HOME/.config/claude-copilot}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

mkdir -p "${CONFIG_DIR}" "${BIN_DIR}"

# 1) Settings (don't overwrite an existing one).
if [ -f "${CONFIG_DIR}/settings.json" ]; then
  echo "[install] keeping existing ${CONFIG_DIR}/settings.json"
else
  cp "${REPO_DIR}/settings.example.json" "${CONFIG_DIR}/settings.json"
  echo "[install] wrote ${CONFIG_DIR}/settings.json"
fi

# 2) Launcher symlink.
ln -sf "${REPO_DIR}/bin/claude-copilot" "${BIN_DIR}/claude-copilot"
chmod +x "${REPO_DIR}/bin/claude-copilot"
echo "[install] linked ${BIN_DIR}/claude-copilot -> ${REPO_DIR}/bin/claude-copilot"

# 3) copilot-api gateway.
if command -v copilot-api >/dev/null 2>&1; then
  echo "[install] copilot-api already installed: $(command -v copilot-api)"
elif command -v bun >/dev/null 2>&1; then
  echo "[install] installing copilot-api via bun ..."
  bun add -g @jeffreycao/copilot-api@latest
elif command -v npm >/dev/null 2>&1; then
  echo "[install] installing copilot-api via npm ..."
  npm i -g @jeffreycao/copilot-api@latest
else
  echo "[install] WARNING: neither bun nor npm found; install copilot-api manually."
fi

case ":$PATH:" in
  *":${BIN_DIR}:"*) : ;;
  *) echo "[install] NOTE: add ${BIN_DIR} to your PATH." ;;
esac

cat <<'EOF'

Done. Next:
  1) claude-copilot auth      # one-time browser logins (Copilot + Codex)
  2) claude-copilot models    # verify
  3) claude-copilot           # launch Claude Code on Copilot/Codex

Optional shell completion:
  zsh:  source <(claude-copilot completion zsh)
  bash: source <(claude-copilot completion bash)
  fish: claude-copilot completion fish | source
EOF
