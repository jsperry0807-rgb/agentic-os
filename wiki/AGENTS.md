# LLM Wiki — Agent Context

This is a personal wiki maintained entirely by AI agents.
Part of the Agentic OS setup (~/agentic-os/).

## For OpenCode / Sisyphus

When working on a project, check `~/wiki/wiki/` for relevant context.
Read `wiki/index.md` first to find relevant pages.

## For Hermes

- **Source ingestion**: New files in `raw/` should be processed via the Ingest operation
- **Scheduled lint**: Run via cron periodically to keep the wiki healthy
- **Identity**: See ~/agentic-os/hermes/SOUL.md for your full role

## Maintenance

Rules are in `schemas/schema.md`. The wiki is a git repo at ~/wiki/ for portability.
Setup script at ~/agentic-os/install.sh bootstraps everything.
