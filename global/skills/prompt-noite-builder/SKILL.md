---
name: prompt-noite-builder
description: Generate noites prompts from a verified state snapshot. Use when the user asks to build a noites prompt, draft a nightly OpenChamber session brief, or assemble context for a noites OpenChamber session. Triggers include "build noites prompt", "noites session", "noites brief", "night prompt", "noite".
---

# prompt-noite-builder

Skill that generates **noites prompts** for OpenChamber sessions. Inputs: a current state snapshot (project + VPS status) and the requested mission scope. Output: a noites prompt ready to feed the openchamber dispatcher.

## When to use

- The user asks to "build a noites prompt" or "draft a noites brief" for an upcoming noites session.
- The orchestrator is about to launch a noites background session and needs the briefing.
- The user is closing a day and wants a structured prompt to drive the next noites cycle.

## When **not** to use

- Daily session briefs (use the `daily.md` template).
- Ad-hoc one-off prompts that have no noites structure (use `custom.md`).
- Tasks that do not require a noites state snapshot (write the prompt directly).

## Inputs

1. **State snapshot** — current project + VPS status (recent git log, container health, cron, etc.).
2. **Mission scope** — what the noites session should accomplish (theme, must-do, must-not).
3. **Keep/discard markers** — explicit list of items to KEEP and items to DISCARD from the prompt if it overflows the size limit.

## Outputs

- A single Markdown file (the noites prompt) with structured sections: identity, snapshot, mission, instructions, KEEP/DISCARD markers.
- File written under `notes/prompts/noite-<YYYYMMDD>.md` or the path the user specifies.

## Workflow

1. **Read** the state snapshot. If `notes/STATE-SNAPSHOT-<date>.md` exists, prefer it. Otherwise assemble one from the last NIGHT-REPORT and current `git log` / container status.
2. **Read** the KEEP/DISCARD marker list from the user. If absent, infer: KEEP = all `MUST DO` items, DISCARD = all `NICE TO HAVE` items past the size cap.
3. **Pick** the right template:
   - `noite.md` — default noites prompt (rich snapshot + KEEP/DISCARD + structured mission).
   - `daily.md` — smaller daily session brief (M0–M3 plan).
   - `custom.md` — for non-standard cases (e.g. one-shot rescue, infisical migration).
4. **Render** the prompt. Split into KEEP/DISCARD halves if it exceeds the OpenChamber size limit (~16k tokens).
5. **Write** the prompt file. **Do not paste it into the chat** — the user will read it from disk.
6. **Report** the path and a 1-line summary of what was generated.

## How the templates split when too large

The noites prompt is split using `<!-- KEEP: -->` and `<!-- DISCARD: -->` markers. The orchestrator loads the KEEP half first; if it fits, the DISCARD half is appended; if even KEEP overflows, the prompt is rejected and the user must shorten the mission scope.

## Templates

- `templates/noite.md` — full noites prompt template.
- `templates/daily.md` — daily session template (M0–M3).
- `templates/custom.md` — custom prompt template (non-standard cases).

## See also

- `openchamber-scheduler` (skill) — schedules noites sessions.
- `notes/NIGHT-REPORT-*.md` — past noites reports.
- `opencode.jsonc` (default_agent, schedule) — the noites session config.
