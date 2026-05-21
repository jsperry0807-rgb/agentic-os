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

# Auto-start tmux (if not already inside tmux and in an interactive shell)
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -n "$PS1" ]; then
    tmux new-session -A -s main
fi
