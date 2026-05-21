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

# ── Step 4: tmux config ──────────────────────────────────
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

# ── Step 5: bashrc additions ─────────────────────────────
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
echo "  3. Hermes:   hermes chat (interactive) or hermes gateway run (24/7)"
echo "  4. Wiki:     Start adding sources to ~/wiki/raw/"
echo "  5. tmux:     Next terminal will auto-start into tmux"
echo ""
echo "  To update config on this machine:"
echo "    cd ~/agentic-os && git pull && ./install.sh"
echo ""
echo "  To clone onto a new machine:"
echo "    git clone <url> ~/agentic-os && ~/agentic-os/install.sh --bashrc"
echo ""
