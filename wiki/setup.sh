#!/usr/bin/env bash
set -euo pipefail

# LLM Wiki — portable setup script
# Run this on a new machine to initialize the wiki.

WIKI_DIR="${WIKI_DIR:-$HOME/wiki}"

echo "==> Setting up LLM Wiki at $WIKI_DIR"

mkdir -p "$WIKI_DIR"/{raw,{wiki/{entities,concepts,syntheses,assets},schemas}}

# Create placeholder files if they don't exist
if [ ! -f "$WIKI_DIR/wiki/index.md" ]; then
  cat > "$WIKI_DIR/wiki/index.md" << EOF
---
type: index
created: $(date +%Y-%m-%d)
updated: $(date +%Y-%m-%d)
---

# Wiki Index

## Entities

_No pages yet._

## Concepts

_No pages yet._

## Syntheses

_No pages yet._
EOF
fi

if [ ! -f "$WIKI_DIR/wiki/log.md" ]; then
  cat > "$WIKI_DIR/wiki/log.md" << EOF
---
type: log
created: $(date +%Y-%m-%d)
---

# Changelog

## [$(date +%Y-%m-%d)] init | Wiki initialized on new machine
EOF
fi

echo "==> Wiki structure ready at $WIKI_DIR"
echo "==> Schema: \`$WIKI_DIR/schemas/schema.md\`"
echo "==> Point your agent there for maintenance rules."
