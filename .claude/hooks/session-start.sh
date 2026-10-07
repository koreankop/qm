#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

NODE_VERSION="$(tr -d '[:space:]' < .node-version)"
NODE_HOME="$HOME/.local/node-v${NODE_VERSION}"

if [ ! -x "$NODE_HOME/bin/node" ]; then
  arch="$(uname -m)"
  case "$arch" in
    x86_64) arch="x64" ;;
    aarch64) arch="arm64" ;;
  esac
  mkdir -p "$NODE_HOME"
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${arch}.tar.xz" \
    | tar -xJ --strip-components=1 -C "$NODE_HOME"
fi

export PATH="$NODE_HOME/bin:$PATH"

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$NODE_HOME/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

npm install --no-audit --no-fund
npm run build:connector-sdk
