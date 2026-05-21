# Agentic OS

A portable, installable agent operating system stack combining **OpenCode + OhMyOpenCode** (multi-agent coding) with **Hermes Agent** (persistent 24/7 research & automation) and an **LLM Wiki** (compounding knowledge base).

## Architecture

```
┌──────────────────────────────────────────────────┐
│                 Agentic OS                        │
│                                                   │
│  ┌──────────────┐   ┌──────────────┐             │
│  │   OpenCode   │   │   Hermes     │             │
│  │  (Sisyphus)  │◄──►  (Persistent)│             │
│  │              │MCP│              │             │
│  │ • Multi-agent│   │ • 24/7       │             │
│  │ • LSP + AST  │   │ • Web search │             │
│  │ • Delegation │   │ • Browser    │             │
│  │ • Refactoring│   │ • Cron/hooks │             │
│  │ • Planning   │   │ • Messaging  │             │
│  └──────┬───────┘   └──────┬───────┘             │
│         └────────┬─────────┘                      │
│                  ▼                                 │
│  ┌──────────────────────────────┐                  │
│  │        LLM Wiki              │                  │
│  │  (compounding knowledge)     │                  │
│  │  ~/wiki/                     │                  │
│  │  ├── raw/    (immutable)     │                  │
│  │  └── wiki/   (LLM-maintained)│                  │
│  └──────────────────────────────┘                  │
└──────────────────────────────────────────────────┘
         │
         ▼
  tmux — persistent terminal layer
```

## Stack

| Layer | Tool | Role |
|---|---|---|
| Coding | **OpenCode** + **OhMyOpenCode** | Multi-agent orchestration (Sisyphus) |
| Agent | **Hermes** | 24/7 persistent research & automation |
| Knowledge | **LLM Wiki** | Compounding markdown knowledge base |
| Terminal | **tmux** | Session persistence |
| Intelligence | **LSP** | Code diagnostics & navigation |
| Bridge | **MCP** | Inter-agent communication |

## Quick Install

On a **new machine**:

```bash
# Prerequisites: node, python3, git

# Install OpenCode
curl -fsSL https://opencode.ai/install | bash

# Install Hermes
pip install hermes-agent
# or: curl -fsSL https://hermes-agent.sh/install | bash

# Clone and install Agentic OS
git clone <your-repo-url> ~/agentic-os
~/agentic-os/install.sh --bashrc

# Source or restart shell
source ~/.bashrc
```

## Layout

```
~/agentic-os/
├── install.sh                  ← One-command setup
├── config/
│   ├── opencode.jsonc          ← OpenCode + OhMyOpenCode + MCP + LSP
│   └── oh-my-openagent.json    ← Agent/category model routing
├── hermes/
│   └── SOUL.md                 ← Hermes identity (auto-discovered)
├── wiki/                       ← LLM Wiki (symlinked to ~/wiki/)
│   ├── schemas/schema.md       ← Wiki maintenance rules
│   ├── AGENTS.md               ← Agent context
│   ├── setup.sh                ← Wiki bootstrap
│   ├── raw/                    ← Your immutable sources
│   └── wiki/                   ← LLM-maintained pages
├── dotfiles/
│   ├── tmux.conf               ← tmux config
│   └── bashrc.sh               ← PATH + tmux auto-start
├── README.md
└── .gitignore
```

## Updating

```bash
cd ~/agentic-os
git pull
./install.sh          # updates configs, preserves ~/wiki/ if symlinked
```

## Portable

Clone this repo onto any machine, run `install.sh --bashrc`, and the full stack is wired:

- OpenCode configured with OhMyOpenCode plugins, Hermes MCP bridge, and LSP
- Hermes gets its SOUL.md identity and web/browser tools enabled
- LLM Wiki scaffolded at ~/wiki/ with full maintenance schema
- tmux configured with mouse support and scrollback
- bashrc gets PATH entries and tmux auto-start
