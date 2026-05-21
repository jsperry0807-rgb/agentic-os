#!/usr/bin/env bash
set -euo pipefail

# Evolution Heartbeat — Daily research + wiki lint + memory sync
# Designed to run from cron. Logs to ~/wiki/heartbeat/ and agentmemory.
#
# Usage:
#   ./evolution-heartbeat.sh                # Full heartbeat
#   ./evolution-heartbeat.sh --research     # Research only
#   ./evolution-heartbeat.sh --lint         # Lint only
#   ./evolution-heartbeat.sh --dry-run      # Show what would be done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
WIKI_DIR="${WIKI_DIR:-$HOME/wiki}"
HEARTBEAT_DIR="$WIKI_DIR/heartbeat"
RAW_DIR="$WIKI_DIR/raw"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
LOGFILE="$HEARTBEAT_DIR/$TIMESTAMP.md"
DRY_RUN=false

RESEARCH_TOPICS=(
    "open-source ai agents"
    "agentic frameworks 2026"
    "mcp servers best practices"
    "local memory solutions llm"
)

mkdir -p "$HEARTBEAT_DIR" "$RAW_DIR"

log() { echo "[$TIMESTAMP] $*"; }
log_heartbeat() { echo "$*" >> "$LOGFILE"; }

save_to_memory() {
    local summary="$1"
    local category="${2:-evolution-heartbeat}"
    if command -v npx &>/dev/null; then
        npx -y @agentmemory/mcp memory_save \
            --content "$summary" \
            --category "$category" \
            --key "$TIMESTAMP" \
            2>/dev/null || true
    fi
}

run_research() {
    local web_research="$SCRIPT_DIR/web-research.js"
    if [[ ! -f "$web_research" ]]; then
        log "web-research.js not found — skipping"
        return
    fi
    log "Research — ${#RESEARCH_TOPICS[@]} topics"
    for topic in "${RESEARCH_TOPICS[@]}"; do
        if $DRY_RUN; then
            log_heartbeat "  [DRY-RUN] Research: $topic"
        else
            log "  Researching: $topic"
            local safe_name="${topic// /-}"
            node "$web_research" "https://duckduckgo.com/?q=${topic// /+}" \
                --save --name "heartbeat-${safe_name}-${TIMESTAMP}" 2>/dev/null \
                && log_heartbeat "  Done: $topic" \
                || log_heartbeat "  Failed: $topic"
        fi
    done
}

run_lint() {
    if [[ ! -f "$WIKI_DIR/schemas/schema.md" ]]; then
        log "Wiki schema missing — skipping lint"
        return
    fi
    log "Lint phase"
    local issues=0
    if [[ -d "$RAW_DIR" ]]; then
        while IFS= read -r -d '' f; do
            local age=$(( ( $(date +%s) - $(stat -c %Y "$f") ) / 86400 ))
            if (( age > 7 )); then
                log_heartbeat "  Stale: $(basename "$f") ($age days)"
                ((issues++)) || true
            fi
        done < <(find "$RAW_DIR" -name '*.md' -type f -print0 2>/dev/null)
    fi
    while IFS= read -r -d '' f; do
        if (( $(wc -l < "$f") <= 1 )); then
            log_heartbeat "  Empty: $(basename "$f")"
            ((issues++)) || true
        fi
    done < <(find "$WIKI_DIR" -name '*.md' -type f -not -path '*/heartbeat/*' -print0 2>/dev/null)
    (( issues == 0 )) && log_heartbeat "  Clean" || log_heartbeat "  $issues issue(s)"
}

run_self_update() {
    if $DRY_RUN; then log_heartbeat "  [DRY-RUN] git pull $REPO_DIR"; return; fi
    if [[ -d "$REPO_DIR/.git" ]]; then
        GIT_MASTER=1 git -C "$REPO_DIR" pull --ff-only 2>/dev/null \
            && log_heartbeat "  Pulled updates" || log_heartbeat "  No updates"
    fi
}

case "${1:-all}" in
    --research) RESEARCH_ONLY=true ;;
    --lint)     LINT_ONLY=true ;;
    --dry-run)  DRY_RUN=true ;;
esac

log "Evolution Heartbeat — $TIMESTAMP"
log_heartbeat "# Evolution Heartbeat — $TIMESTAMP"

if [[ -z "${LINT_ONLY:-}" ]]; then run_research; fi
if [[ -z "${RESEARCH_ONLY:-}" ]]; then run_lint; fi
if [[ -z "${LINT_ONLY:-}" && -z "${RESEARCH_ONLY:-}" ]]; then run_self_update; fi

summary=$(tail -n 10 "$LOGFILE" 2>/dev/null || echo "empty")
save_to_memory "## Heartbeat: $TIMESTAMP\n$summary" "evolution-heartbeat"

$DRY_RUN && log "DRY RUN — no changes" || log "Heartbeat done. Log: $LOGFILE"
