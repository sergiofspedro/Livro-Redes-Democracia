# AGENTS.md

## What this repo is

Personal backup/restore repo for my global OpenCode Desktop configuration — see README.md for the restore procedure. Not a project template, not shared with a team.

## Project rules

- Ask clarifying questions before starting any non-trivial or ambiguous task.
- Propose alternative approaches with trade-offs before committing to one.
- Local git commits are fine to make freely.
- NEVER push to GitHub, open a pull request, or merge a pull request without explicit confirmation first.

## Sync discipline

The `global/` folder is a manual snapshot of `~/.config/opencode/`, not a live symlink. After changing plugins, models, or config on the actual machine, copy the changed file(s) into `global/` here before committing — don't let this repo drift silently out of date.
