#!/usr/bin/env bash
set -euo pipefail

# Hermes 24/7 Daemon — tmux-based persistent gateway
# Starts Hermes gateway in a detached tmux session.
# Safe to run on shell login (checks for existing session).
#
# Usage:
#   ./hermes-daemon.sh          # Start (or attach to existing)
#   ./hermes-daemon.sh stop     # Stop gracefully
#   ./hermes-daemon.sh status   # Check if running

SESSION_NAME="hermes-daemon"
HERMES_CMD="hermes gateway run"

start() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "Hermes daemon already running in tmux session '$SESSION_NAME'."
        echo "  Attach: tmux attach -t $SESSION_NAME"
        echo "  Detach: Ctrl+B, D"
        return 0
    fi

    echo "Starting Hermes gateway in tmux session '$SESSION_NAME'..."
    tmux new-session -d -s "$SESSION_NAME" "$HERMES_CMD"
    sleep 2

    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "Hermes daemon started successfully."
        echo "  Attach: tmux attach -t $SESSION_NAME"
        echo "  Detach: Ctrl+B, D"
        echo "  Stop:   $0 stop"
    else
        echo "Failed to start Hermes daemon."
        return 1
    fi
}

stop() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "Stopping Hermes daemon..."
        tmux send-keys -t "$SESSION_NAME" C-c
        sleep 2
        tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
        echo "Hermes daemon stopped."
    else
        echo "Hermes daemon not running."
    fi
}

status() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "Hermes daemon: RUNNING"
        echo "  Session: $SESSION_NAME"
        echo "  Attach:  tmux attach -t $SESSION_NAME"
    else
        echo "Hermes daemon: STOPPED"
    fi
}

case "${1:-start}" in
    start)   start ;;
    stop)    stop ;;
    status)  status ;;
    restart) stop; sleep 1; start ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac
