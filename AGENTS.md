# AGENTS.md

## What this repo is

Personal backup/restore snapshot of my global OpenCode Desktop configuration (`~/.config/opencode/`) — one unified stack, restorable with a single `setup.ps1`. See README.md for the restore procedure and what's inside `global/`.

This repo originally started as a project template for the EU Civic Tech Hackathon (22–23 June 2026). That project-scoped setup (a separate `.opencode/` tree with its own agents/skills/permissions, only active when opening this repo folder directly) was merged into the global config on 2026-07-03 — the custom agents (researcher, scribe, coder, reviewer, plan, build), skills, and vendored plugins (envsitter-guard, firecrawl, simple-memory, worktree, background-agents) are now part of `global/` and apply everywhere, not just this repo. The old hackathon-only `explore` agent was dropped to avoid colliding with oh-my-openagent's own `explore` — still recoverable from git history if ever needed.

Note: this repo even earlier contained an unrelated PDF-downloading script (download_pdfs.py, Unpaywall/DOI-based). Not part of current scope.

## Project rules

- Ask clarifying questions before starting any non-trivial or ambiguous task.
- Propose alternative approaches with trade-offs before committing to one.
- Local git commits are fine to make freely.
- NEVER push to GitHub, open a pull request, or merge a pull request without explicit confirmation first.

## Sync discipline

`global/` is a manual snapshot of `~/.config/opencode/`, not a live symlink. After changing plugins, models, agents, or skills on the actual machine, copy the changed file(s) into `global/` here before committing — don't let this repo drift silently out of date.

## Known non-blocking issues

- Some vendored plugins (envsitter-guard, firecrawl, simple-memory) carry their own `package.json`/lockfiles from their upstream repos — dependencies are consolidated into the top-level `global/package.json` instead; the per-plugin lockfiles are inert and can be ignored.
