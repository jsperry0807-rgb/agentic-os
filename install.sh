#!/usr/bin/env bash
set -euo pipefail

# Agentic OS — Portable Installer
# Clones the agent stack: OpenCode + OhMyOpenCode + Hermes + LLM Wiki
# Usage: ./install.sh [--bashrc] [--help]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

# ── Colors ──────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}==>${NC} $1"; }
ok()    { echo -e "${GREEN}  ✓${NC} $1"; }
warn()  { echo -e "${YELLOW}  !${NC} $1"; }
err()   { echo -e "${RED}  ✗${NC} $1"; }

# ── Preflight ────────────────────────────────────────────
info "Agentic OS — Portable Installer"
echo ""

# Check for required tools
MISSING=""
command -v git    >/dev/null 2>&1 || MISSING="$MISSING git"
command -v tmux   >/dev/null 2>&1 || warn "tmux not found (install after setup)"
command -v node   >/dev/null 2>&1 || warn "node not found (needed for OpenCode)"
command -v python3 >/dev/null 2>&1 || warn "python3 not found (needed for Hermes)"

if [ -n "$MISSING" ]; then
    err "Missing core tools:$MISSING"
    echo "  Install them first, then re-run this script."
fi

# ── Step 1: OpenCode config ──────────────────────────────
info "Installing OpenCode configuration..."

OPENCODE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

# Only copy if source is newer or target doesn't exist
if [ ! -f "$OPENCODE_CONFIG_DIR/opencode.jsonc" ] || [ "$SCRIPT_DIR/config/opencode.jsonc" -nt "$OPENCODE_CONFIG_DIR/opencode.jsonc" ]; then
    cp "$SCRIPT_DIR/config/opencode.jsonc" "$OPENCODE_CONFIG_DIR/opencode.jsonc"
    ok "opencode.jsonc installed"
else
    ok "opencode.jsonc already up to date"
fi

if [ ! -f "$OPENCODE_CONFIG_DIR/oh-my-openagent.json" ] || [ "$SCRIPT_DIR/config/oh-my-openagent.json" -nt "$OPENCODE_CONFIG_DIR/oh-my-openagent.json" ]; then
    cp "$SCRIPT_DIR/config/oh-my-openagent.json" "$OPENCODE_CONFIG_DIR/oh-my-openagent.json"
    ok "oh-my-openagent.json installed"
else
    ok "oh-my-openagent.json already up to date"
fi

# ── Step 2: Hermes SOUL.md ──────────────────────────────
info "Installing Hermes identity..."

HERMES_DIR="${HERMES_DIR:-$HOME/.hermes}"
if [ -d "$HERMES_DIR" ]; then
    # Install SOUL.md — Hermes auto-discovers this
    if [ -f "$HERMES_DIR/SOUL.md" ]; then
        cp "$HERMES_DIR/SOUL.md" "$HERMES_DIR/SOUL.md.bak.$(date +%s)"
        warn "backed up existing SOUL.md"
    fi
    cp "$SCRIPT_DIR/hermes/SOUL.md" "$HERMES_DIR/SOUL.md"
    ok "Hermes SOUL.md installed"

    # Enable web and browser toolsets
    if command -v hermes &> /dev/null; then
        hermes tools enable web 2>/dev/null && ok "Hermes web tools enabled" || warn "could not enable web tools"
        hermes tools enable browser 2>/dev/null && ok "Hermes browser tools enabled" || warn "could not enable browser tools"
    fi
else
    warn "Hermes not installed — install it first, then re-run to copy SOUL.md"
    echo "  https://github.com/NousResearch/hermes-agent"
fi

# ── Step 3: LLM Wiki ─────────────────────────────────────
info "Setting up LLM Wiki..."

if [ -d "$HOME/wiki" ] && [ ! -L "$HOME/wiki" ]; then
    warn "$HOME/wiki already exists and is not a symlink — leaving as-is"
    warn "  to use the packaged wiki: rm -rf $HOME/wiki && re-run install.sh"
else
    # Symlink the packaged wiki into home
    ln -sfn "$SCRIPT_DIR/wiki" "$HOME/wiki"
    ok "wiki symlinked: $SCRIPT_DIR/wiki → $HOME/wiki"

    # Run wiki bootstrap
    bash "$SCRIPT_DIR/wiki/setup.sh"
fi

# ── Step 4: Playwright browsers ──────────────────────────
info "Installing Playwright browsers for web research..."

if command -v playwright-mcp &> /dev/null; then
    # Install browsers using playwright-mcp (handles platform overrides gracefully)
    PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="${PLAYWRIGHT_HOST_PLATFORM_OVERRIDE:-ubuntu24.04-x64}" \
      playwright-mcp install-browser 2>&1 | tail -5
    ok "Playwright browsers installed"
else
    warn "playwright-mcp not found — install it: npm install -g @playwright/mcp"
    warn "  then re-run: playwright-mcp install-browser"
fi

# Make all hermes scripts executable
for f in web-research.js hermes-daemon.sh evolution-heartbeat.sh wiki-search.js; do
    chmod +x "$SCRIPT_DIR/hermes/$f" 2>/dev/null
done
ok "hermes scripts are executable"

# Symlink hermes scripts to ~/.local/bin/
mkdir -p "$HOME/.local/bin"
ln -sf "$SCRIPT_DIR/hermes/web-research.js" "$HOME/.local/bin/web-research"
ln -sf "$SCRIPT_DIR/hermes/wiki-search.js" "$HOME/.local/bin/wiki-search"
ln -sf "$SCRIPT_DIR/hermes/hermes-daemon.sh" "$HOME/.local/bin/hermes-daemon"
ln -sf "$SCRIPT_DIR/hermes/evolution-heartbeat.sh" "$HOME/.local/bin/evolution-heartbeat"
ok "scripts symlinked to ~/.local/bin/"

# ── Step 5: agentmemory MCP ──────────────────────────────
info "Installing agentmemory (persistent memory layer)..."

if npm ls -g @agentmemory/agentmemory &>/dev/null; then
    ok "agentmemory already installed: $(npx -y @agentmemory/agentmemory --version 2>&1 | head -1)"
else
    npm install -g @agentmemory/agentmemory 2>&1 | tail -3
    ok "agentmemory installed (v0.9.21+)"
fi
ok "MCP shim ready: npx -y @agentmemory/mcp"
ok "To start full server (51 tools): agentmemory"
ok "Data dir: ${AGENTMEMORY_DATA_DIR:-$HOME/.agentmemory}"

# ── Step 6: Composio CLI ─────────────────────────────────
info "Installing Composio CLI for tool integrations..."

if command -v composio &> /dev/null; then
    ok "Composio CLI already installed: $(composio --version 2>&1 | head -1)"
else
    COMPOSIO_VERSION="${COMPOSIO_VERSION:-@composio/cli@0.2.31-beta.256}"
    COMPOSIO_URL="https://github.com/ComposioHQ/composio/releases/download/${COMPOSIO_VERSION}/composio-linux-x64.zip"
    COMPOSIO_BIN_DIR="$HOME/.composio/bin"
    mkdir -p "$COMPOSIO_BIN_DIR"
    if command -v python3 &> /dev/null; then
        curl -fsSL -o /tmp/composio.zip "$COMPOSIO_URL" 2>/dev/null \
          && python3 -c "import zipfile; zipfile.ZipFile('/tmp/composio.zip').extractall('/tmp/composio-extract')" 2>/dev/null \
          && cp /tmp/composio-extract/composio-linux-x64/composio "$COMPOSIO_BIN_DIR/" \
          && chmod +x "$COMPOSIO_BIN_DIR/composio" \
          && ok "Composio CLI installed to $COMPOSIO_BIN_DIR/composio" \
          || warn "Composio CLI install failed — install manually: curl -fsSL https://composio.dev/install | bash"
        rm -rf /tmp/composio.zip /tmp/composio-extract
    else
        warn "python3 required for Composio CLI install — install manually: curl -fsSL https://composio.dev/install | bash"
    fi
fi
ok "Composio ready. Login with: composio login (or set COMPOSIO_API_KEY for Connect MCP)"

# ── Step 7: API Keys ──────────────────────────────────────
info "Setting up API keys..."
ENV_FILE="$SCRIPT_DIR/.env"

prompt_api_key() {
    local var_name="$1"
    local description="$2"
    local default="${3:-}"

    if [ -n "$default" ]; then
        warn "$var_name already set (from .env or environment)"
        return
    fi

    echo ""
    echo -e "  ${CYAN}$description${NC}"
    echo -n "  Enter $var_name (leave blank to skip): "
    read -r input_key
    echo ""

    if [ -n "$input_key" ]; then
        echo "${var_name}=${input_key}" >> "$ENV_FILE"
        export "${var_name}=${input_key}"
        ok "$var_name saved to .env"
    else
        warn "$var_name skipped — set later in $ENV_FILE or export it in ~/.bashrc"
    fi
}

# Load existing .env values to avoid re-prompting
if [ -f "$ENV_FILE" ]; then
    set -a; source "$ENV_FILE"; set +a
fi

# Check env/terminal for existing values
CURRENT_COMPOSIO="${COMPOSIO_API_KEY:-}"
prompt_api_key "COMPOSIO_API_KEY" "Composio API key (needed for tool integrations: GitHub, Gmail, Slack via MCP)" "$CURRENT_COMPOSIO"

# Secure the .env file
if [ -f "$ENV_FILE" ]; then
    chmod 600 "$ENV_FILE"
    ok ".env secured (chmod 600)"
fi

# ── Step 8: Evolution Heartbeat (cron) ────────────────────
info "Setting up Evolution Heartbeat cron job..."

HEARTBEAT_SCRIPT="$SCRIPT_DIR/hermes/evolution-heartbeat.sh"
if command -v crontab &> /dev/null; then
    # Check if already registered
    if crontab -l 2>/dev/null | grep -q "$HEARTBEAT_SCRIPT"; then
        ok "Heartbeat cron already registered"
    else
        # Add daily at 6am
        (crontab -l 2>/dev/null || true; echo "0 6 * * * $HEARTBEAT_SCRIPT --research") | crontab -
        ok "Heartbeat cron registered (daily at 6am — only research, no lint)"
        warn "Edit the cron schedule: crontab -e"
        warn "Lint runs on $0 without --research flag — run manually: evolution-heartbeat --lint"
    fi
else
    warn "crontab not available — heartbeat won't auto-schedule"
    warn "  To run manually: $HEARTBEAT_SCRIPT"
    warn "  Or add to your own scheduler (systemd timers, launchd, etc.)"
fi

# ── Step 9: tmux config ──────────────────────────────────
info "Installing tmux config..."

TMUX_CONF_SRC="$SCRIPT_DIR/dotfiles/tmux.conf"
if [ -f "$TMUX_CONF_SRC" ]; then
    if [ ! -f "$HOME/.tmux.conf" ]; then
        cp "$TMUX_CONF_SRC" "$HOME/.tmux.conf"
        ok ".tmux.conf installed"
    else
        warn ".tmux.conf already exists — merge manually from $TMUX_CONF_SRC"
    fi
fi

# ── Step 10: bashrc additions ─────────────────────────────
if [ "$1" == "--bashrc" ]; then
    info "Adding bashrc entries..."

    BASHRC="$HOME/.bashrc"
    if [ -f "$BASHRC" ]; then
        # Check if already added
        if grep -q "Agentic OS" "$BASHRC" 2>/dev/null; then
            ok "bashrc already has Agentic OS entries"
        else
            cat "$SCRIPT_DIR/dotfiles/bashrc.sh" >> "$BASHRC"
            ok "bashrc entries appended (review with: tail -20 $BASHRC)"
        fi
    else
        cp "$SCRIPT_DIR/dotfiles/bashrc.sh" "$BASHRC"
        ok ".bashrc created from template"
    fi
else
    echo ""
    info "Skip bashrc. Run with --bashrc to append PATH/tmux entries:"
    echo "  $0 --bashrc"
fi

# ── Done ──────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Agentic OS installation complete${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  What's next:"
echo "  1. Restart your shell or: source ~/.bashrc"
echo "  2. OpenCode: opencode (starts TUI with OhMyOpenCode)"
echo "  3. Hermes:   hermes chat (interactive)"
echo "     Daemon:   hermes-daemon           (24/7 tmux session)"
echo "  4. Wiki:     Start adding sources to ~/wiki/raw/"
echo "     Search:   wiki-search \"query\""
echo "  5. Heartbeat: evolution-heartbeat     (daily research + wiki lint)"
echo "     Cron:     Runs at 6am — edit with: crontab -e"
echo "  6. tmux:     Next terminal will auto-start into tmux"
echo "  7. Memory:   agentmemory MCP shim auto-connects via 7 core tools"
echo "     Full server (51 tools): agentmemory (background process)"
echo "     Viewer:                http://localhost:3113"
echo ""
echo "  Memory-backed agent handoff active:"
echo "     Hermes saves session summaries → agentmemory"
echo "     OpenCode reads past decisions ← agentmemory"
echo ""
echo "  To update config on this machine:"
echo "    cd ~/agentic-os && git pull && ./install.sh"
echo ""
echo "  To clone onto a new machine:"
echo "    git clone <url> ~/agentic-os && ~/agentic-os/install.sh --bashrc"
echo ""
