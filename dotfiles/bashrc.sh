# ============================================
# Agentic OS — bashrc additions
# Appended by ~/agentic-os/install.sh
# ============================================

# OpenCode PATH
export PATH="$HOME/.opencode/bin:$PATH"

# Hermes PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/.hermes/node/bin"

# Agentic OS Wiki
export WIKI_DIR="$HOME/wiki"

# Playwright / Browser Automation
# On unsupported distros (e.g. Ubuntu 26.04), override platform and library path
export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="${PLAYWRIGHT_HOST_PLATFORM_OVERRIDE:-ubuntu24.04-x64}"
export PLAYWRIGHT_MCP_EXECUTABLE_PATH="${PLAYWRIGHT_MCP_EXECUTABLE_PATH:-$HOME/.cache/ms-playwright/chromium-1224/chrome-linux64/chrome}"
export PLAYWRIGHT_MCP_BROWSER="${PLAYWRIGHT_MCP_BROWSER:-chromium}"
# Inject Firefox-bundled shared libs for Chromium on unsupported distros
FIREFOX_LIB_DIR="$HOME/.cache/ms-playwright/firefox-1522/firefox"
if [ -d "$FIREFOX_LIB_DIR/libnspr4.so" ] && [[ ":$LD_LIBRARY_PATH:" != *":$FIREFOX_LIB_DIR:"* ]]; then
  export LD_LIBRARY_PATH="$FIREFOX_LIB_DIR:${LD_LIBRARY_PATH:-}"
fi
unset FIREFOX_LIB_DIR

# Composio — Tool Integrations for AI Agents
# Get your API key at https://dashboard.composio.dev (Settings → API Keys)
export COMPOSIO_API_KEY="${COMPOSIO_API_KEY:-}"
# Composio CLI (installed by install.sh)
export PATH="$HOME/.composio/bin:$PATH"

# Auto-start tmux (if not already inside tmux and in an interactive shell)
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -n "$PS1" ]; then
    tmux new-session -A -s main
fi
