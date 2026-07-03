# AGENTS.md

## What this repo is

Two things living side by side:

1. **`global/`** — personal backup/restore snapshot of my global OpenCode Desktop configuration (`~/.config/opencode/`). See README.md for the restore procedure.
2. **`.opencode/`, `opencode.json`, `tools/`** — the EU Civic Tech Hackathon (22–23 June 2026) project setup, kept for reference/reuse (custom agents: researcher, scribe, coder, reviewer, plan, build, explore; skills: code-philosophy, code-review, frontend-philosophy, plan-protocol, plan-review; vendored plugins: envsitter-guard, firecrawl, simple-memory, worktree, background-agents). This tree only activates when OpenCode is opened directly on this repo folder as a project — it has no effect on the global config.

Note: this repo previously also contained an unrelated PDF-downloading script (download_pdfs.py, Unpaywall/DOI-based) from an even earlier project. Not part of either current scope — disregard unless the file is still physically present and explicitly relevant.

## Project rules

- Ask clarifying questions before starting any non-trivial or ambiguous task.
- Propose alternative approaches with trade-offs before committing to one.
- Local git commits are fine to make freely.
- NEVER push to GitHub, open a pull request, or merge a pull request without explicit confirmation first.

## Sync discipline

`global/` is a manual snapshot of `~/.config/opencode/`, not a live symlink. After changing plugins, models, or config on the actual machine, copy the changed file(s) into `global/` here before committing — don't let this repo drift silently out of date.

## OpenCode environment (hackathon project scope)

- `opencode.json` loads instructions from `./tools/philosophy.md` (project principles) and defines MCPs (Playwright, Context7, Exa, gh_grep) plus restricted agents (researcher, scribe, coder, reviewer, plan, build, explore) with granular bash/file permissions.
- Plugin stack installed via `setup.ps1`: Oh My OpenCode, kdco/workspace bundle (worktree, notify, delegation, planning), Simple Memory, EnvSitter Guard, opencode-firecrawl, Playwright MCP, Composio MCP, Context7 (bundled).
- worktree plugin confirmed working — use it for parallel branch work.
- `.gitignore` protects `opencode.local.json` (personal config overrides) from being committed.

## Known non-blocking issues

- `/init` may show a one-time Playwright SyntaxError during repo scan (hackathon project scope). Safe to ignore.
