# OpenCode Stack — Personal Backup & Restore

Personal mirror of my global OpenCode Desktop configuration. If this machine dies, this repo is what I use to get back to a working setup on a fresh install.

This is **not** a project template — it backs up the *global* config (`~/.config/opencode/`), which applies across every OpenCode project I open, not a per-repo `opencode.json`.

## What's in here

```
global/
├── opencode.jsonc          # plugin list: oh-my-openagent, cc-safety-net
├── oh-my-openagent.json    # subagent/category model mapping + browser automation config
└── plugins/
    ├── notify.ts           # kdco/notify — native OS task-completion notifications
    ├── notify/
    └── kdco-primitives/    # shared dependency for notify
```

## Restore on a new machine

1. Install [OpenCode Desktop](https://opencode.ai)
2. Install [Bun](https://bun.sh) — required by `ocx`: `powershell -c "irm bun.sh/install.ps1 | iex"`, then restart your terminal
3. Clone this repo and run the setup script:
   ```powershell
   gh repo clone sergiofspedro/Opencode-stack
   cd Opencode-stack
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\setup.ps1
   ```
4. Fully restart OpenCode Desktop after the script finishes — plugin config is only read at startup.

## What the script does

- Copies `global/opencode.jsonc` and `global/oh-my-openagent.json` into `~/.config/opencode/`
- Copies `global/plugins/*` into `~/.config/opencode/plugins/`
- Installs `ocx` globally and registers the `kdco` community registry
- Adopts `~/.config/opencode/profiles/default/` under OCX so the same config is portable/versioned going forward

## Keeping this repo in sync

There's no automatic sync — when I change the global config on my machine (add a plugin, tweak a model), I need to manually copy the changed file(s) here and commit. Local commits are fine to make freely; **pushing always needs my explicit confirmation first.**
