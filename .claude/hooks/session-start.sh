#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

NODE_VERSION="$(tr -d '[:space:]' < .node-version)"
NODE_HOME="$HOME/.local/node-v${NODE_VERSION}"
PATH_LINE="export PATH=\"$NODE_HOME/bin:\$PATH\""

install_node() {
  local arch tarball tmp
  case "$(uname -m)" in
    x86_64) arch="x64" ;;
    aarch64) arch="arm64" ;;
    *) echo "unsupported architecture: $(uname -m)" >&2; return 1 ;;
  esac
  tarball="node-v${NODE_VERSION}-linux-${arch}.tar.xz"
  tmp="$(mktemp -d "$HOME/.local/node-install.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  curl -fsSL -o "$tmp/$tarball" "https://nodejs.org/dist/v${NODE_VERSION}/$tarball"
  curl -fsSL -o "$tmp/SHASUMS256.txt" "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"
  (cd "$tmp" && grep " $tarball\$" SHASUMS256.txt | sha256sum -c -)
  mkdir "$tmp/node"
  tar -xJf "$tmp/$tarball" --strip-components=1 -C "$tmp/node"
  rm -rf "$NODE_HOME"
  mv "$tmp/node" "$NODE_HOME"
}

mkdir -p "$HOME/.local"
if ! "$NODE_HOME/bin/node" "$NODE_HOME/lib/node_modules/npm/bin/npm-cli.js" --version >/dev/null 2>&1; then
  install_node
fi

export PATH="$NODE_HOME/bin:$PATH"

if [ -n "${CLAUDE_ENV_FILE:-}" ] && ! grep -qxF "$PATH_LINE" "$CLAUDE_ENV_FILE" 2>/dev/null; then
  echo "$PATH_LINE" >> "$CLAUDE_ENV_FILE"
fi

npm ci --no-audit --no-fund
npm run build:connector-sdk
