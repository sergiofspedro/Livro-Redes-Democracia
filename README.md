# OpenCode Stack

Two things in this repo — pick the section that matches what you're trying to do.

## 1. Personal backup & restore (`global/`)

Mirror of my global OpenCode Desktop configuration (`~/.config/opencode/`). If this machine dies, this is what I use to get back to a working setup on a fresh install. Applies across every OpenCode project I open — not a per-repo config.

```
global/
├── opencode.jsonc          # plugin list: oh-my-openagent, cc-safety-net
├── oh-my-openagent.json    # subagent/category model mapping + browser automation config
└── plugins/
    ├── notify.ts           # kdco/notify — native OS task-completion notifications
    ├── notify/
    └── kdco-primitives/    # shared dependency for notify
```

### Restore on a new machine

1. Install [OpenCode Desktop](https://opencode.ai)
2. Install [Bun](https://bun.sh) — required by `ocx`: `powershell -c "irm bun.sh/install.ps1 | iex"`, then restart your terminal
3. Clone this repo and run the restore script:
   ```powershell
   gh repo clone sergiofspedro/Opencode-stack
   cd Opencode-stack
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\setup-global.ps1
   ```
4. Fully restart OpenCode Desktop after the script finishes — plugin config is only read at startup.

### What `setup-global.ps1` does

- Copies `global/opencode.jsonc` and `global/oh-my-openagent.json` into `~/.config/opencode/`
- Copies `global/plugins/*` into `~/.config/opencode/plugins/`
- Installs `ocx` globally and registers the `kdco` community registry
- Adopts `~/.config/opencode/profiles/default/` under OCX so the same config is portable/versioned going forward

### Keeping `global/` in sync

No automatic sync — when I change the global config on my machine (add a plugin, tweak a model), I manually copy the changed file(s) here and commit. Local commits are fine to make freely; **pushing always needs my explicit confirmation first.**

---

## 2. EU Civic Tech Hackathon project (`.opencode/`, `opencode.json`, `tools/`)

EU Civic Tech Hackathon project — 22–23 June 2026, under the European Democracy Shield initiative. Kept here for reference/reuse, not actively maintained. This is a project-scoped OpenCode setup — it only takes effect when OpenCode is opened directly on this repo folder, and has no effect on the global config above.

### Team Setup — OpenCode Environment

This project used [OpenCode Desktop](https://opencode.ai) as the shared AI coding agent, with a curated stack of plugins and MCPs.

### 1. Get your own OpenRouter API key
Each team member needs their own [OpenRouter](https://openrouter.ai) account and API key.

**Recommended model per work mode:**

| Mode | Model | Why |
|---|---|---|
| **Plan mode** | `moonshotai/kimi-k2.7-code` | Strong long-horizon planning, native multi-turn reasoning, good MCP tool-use depth |
| **Build mode** | `deepseek/deepseek-v4-flash` | Very low cost per call, fast |
| **Debug mode** | `deepseek/deepseek-v4-pro` | Stronger reasoning, large context window |

### 2. Clone this repo
```powershell
gh repo clone sergiofspedro/Opencode-stack
cd Opencode-stack
```

### 3. Run the setup script — choose your OS

- **`setup.ps1`** — Windows (PowerShell). Tested and verified end-to-end.
- **`setup.sh`** — macOS (Bash). ⚠️ Untested.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup.ps1
```

Installs the full shared project stack: Oh My OpenCode, kdco/workspace bundle (worktree, notify, delegation, planning agents), Simple Memory (git-committed shared team memory), EnvSitter Guard, opencode-firecrawl, Playwright MCP, Context7 + Exa + gh_grep.

### 4. Manual steps after the script

**Firecrawl:** `firecrawl login --browser` or set `FIRECRAWL_API_KEY`

**Composio:** create a free account at composio.dev, get an API key, set it as an env var (never paste in chat), then run `/connect` inside OpenCode.

### 5. Launch OpenCode and connect
Open the OpenCode Desktop app, **Open Folder** on this repo folder, then:
```
/connect     -> enter YOUR OWN OpenRouter API key
/models      -> select your model per the table above
/init        -> scans the repo, merges with shared AGENTS.md rules
```

**Known issue (safe to ignore):** `/init` may show a one-time Playwright `SyntaxError` during the repo scan.

### Shared vs personal config
- `opencode.json` (committed) — shared MCPs and agent permissions.
- `opencode.local.json` (gitignored) — personal overrides, never shared.

### Security reminder
Never commit or paste API keys anywhere. All keys go in environment variables or the app's own `/connect` prompts.
