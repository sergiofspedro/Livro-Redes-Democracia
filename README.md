# OpenCode Stack — Personal Backup & Restore

Mirror of my global OpenCode Desktop configuration (`~/.config/opencode/`). If this machine dies, this repo is what I use to get back to a working setup on a fresh install — one script, no hand-picking what to install.

Applies across every OpenCode project I open — not a per-repo config.

## What's in here

```
global/
├── opencode.jsonc            # plugins, custom agent permissions, instructions
├── oh-my-openagent.json      # subagent/category model mapping + browser automation config
├── package.json              # shared npm deps for the vendored plugins below
├── agents/                   # coder.md, researcher.md, reviewer.md, scribe.md
├── skills/                   # code-philosophy, code-review, frontend-philosophy, plan-protocol, plan-review
├── commands/                 # review.md
├── tools/                    # philosophy.md (referenced from opencode.jsonc instructions)
└── plugins/
    ├── notify.ts, notify/           # kdco/notify — native OS task-completion notifications
    ├── kdco-primitives/             # shared dependency for notify + worktree
    ├── worktree.ts, worktree/       # kdco/workspace — git worktree isolation
    ├── background-agents.ts         # kdco/workspace — parallel background task execution
    ├── workspace-plugin.ts          # kdco/workspace bundle entrypoint
    ├── envsitter-guard/             # blocks agents from reading/editing .env* files
    ├── firecrawl/                   # web scraping/crawling
    └── simple-memory/               # git-committed persistent memory
```

**Note on `explore`:** oh-my-openagent ships its own `explore` agent. An older project I worked from also defined a different `explore` agent with its own permissions — I deliberately did not bring that second one into the global config to avoid the two silently colliding. If I ever want it back, it's in this repo's git history (commit `d58faaa`).

## Restore on a new machine

1. Install [OpenCode Desktop](https://opencode.ai)
2. Install [Bun](https://bun.sh) — required by `ocx`: `powershell -c "irm bun.sh/install.ps1 | iex"`, then restart your terminal
3. Clone this repo and run the restore script:
   ```powershell
   gh repo clone sergiofspedro/Opencode-stack
   cd Opencode-stack
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\setup.ps1
   ```
4. Fully restart OpenCode Desktop after the script finishes — plugin config is only read at startup.

## What `setup.ps1` does

- Copies `global/opencode.jsonc`, `global/oh-my-openagent.json`, `global/package.json` into `~/.config/opencode/`
- Copies `global/agents/`, `global/skills/`, `global/commands/`, `global/tools/`, `global/plugins/` into their matching `~/.config/opencode/` subfolders
- Runs `npm install` in `~/.config/opencode/` for the vendored plugins' dependencies (envsitter, zod, node-notifier, etc.)
- Installs `ocx` globally and registers the `kdco` community registry
- Adopts `~/.config/opencode/profiles/default/` under OCX so the same config is portable/versioned going forward

## Manual steps after the script (only needed if actually using these plugins)

**Firecrawl:** `firecrawl login --browser` or set `FIRECRAWL_API_KEY` (firecrawl.dev)

## Keeping this repo in sync

No automatic sync — when I change the global config on my machine (add a plugin, tweak a model, edit an agent), I manually copy the changed file(s) into `global/` here and commit. Local commits are fine to make freely; **pushing always needs my explicit confirmation first.**
