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
4. **Pendências doc** (recommended) — a project-specific `*-PENDENCIAS.md` (e.g. `PRD-TECH-DESIGN-PENDENCIAS.md`) listing tracked implementation gaps. If present, MUST be reconciled before drafting the mission list.

## Outputs

- A single Markdown file (the noites prompt) with structured sections: identity, snapshot, mission, instructions, KEEP/DISCARD markers.
- File written under `notes/prompts/noite-<YYYYMMDD>.md` or the path the user specifies.
- (When a `*-PENDENCIAS.md` is present) An updated copy of the doc with closed items moved from `❌ Falta executar` to `✅ Já implementado e merged (NÃO repetir)` before the prompt is written.

## Workflow

1. **Reconcile pendências doc** (if present). For each project root, look for a `*-PENDENCIAS.md` (or any file matching `*PENDENCIAS*`/`*TODO*`/`*BACKLOG*` in the project root). For each item listed there: verify on the machine + git log + last NIGHT-REPORT whether it is now done. Move done items from `❌ Falta executar` to `✅ Já implementado e merged (NÃO repetir)`, cite the evidence (commit sha, container status, or report reference). Commit the updated doc with a one-liner (`chore(docs): reconcile pendências — close items 1, 2, 5`). **Do not skip this step** — it is the single most common source of duplicated work in noites sessions.
2. **Read** the state snapshot. If `notes/STATE-SNAPSHOT-<date>.md` exists, prefer it. Otherwise assemble one from the last NIGHT-REPORT and current `git log` / container status.
3. **Read** the KEEP/DISCARD marker list from the user. If absent, infer: KEEP = all `MUST DO` items, DISCARD = all `NICE TO HAVE` items past the size cap. Derive the mission list from the **remaining open items** of the reconciled pendências doc, not from the original list.
4. **Pick** the right template:
   - `noite.md` — default noites prompt (rich snapshot + KEEP/DISCARD + structured mission).
   - `daily.md` — smaller daily session brief (M0–M3 plan).
   - `custom.md` — for non-standard cases (e.g. one-shot rescue, infisical migration).
5. **Render** the prompt. Split into KEEP/DISCARD halves if it exceeds the OpenChamber size limit (~16k tokens).
6. **Write** the prompt file. **Do not paste it into the chat** — the user will read it from disk.
7. **Report** the path, a 1-line summary of what was generated, and a 1-line summary of which pendências items were closed during reconciliation.

## Pendências reconciliation protocol (step 1)

The protocol is the same regardless of which file holds the list. For each `❌ Falta executar` item, verify in this order:

1. **git log search** — `git log --all --oneline | grep -i "<keyword from item>"` and `git --no-pager log --oneline -50 | grep -i "<keyword>"`.
2. **file existence** — does the file/feature the item claims is missing actually exist now? (`ls -la`, `grep -rn <symbol>`).
3. **container/runtime** — if the item is about deployment, is the container healthy? (`docker ps`, `curl /api/health`).
4. **last NIGHT-REPORT** — does the most recent report declare the item done?

If 2+ of these confirm "done", move the item to `✅ Já implementado e merged (NÃO repetir)` with a citation (`commit 74f7a0a`, `container dashboard-b2b Up 11h`, `NR-9 §B2`). Cite one piece of evidence, not all four.

If only 1 confirms: leave the item open, note the partial evidence in parentheses.

If 0 confirm: leave the item open, no note.

**Edge case**: if the project has no `*-PENDENCIAS.md` file at all, skip step 1 and note in the report that no pendências doc was found. Suggest the user create one for the next cycle.

**Edge case**: if the doc is older than 60 days, recommend (do not require) creating a new doc rather than patching the old one.

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
- `*-PENDENCIAS.md` (project root) — the project's tracked implementation gaps; always reconcile in step 1.

## Why this protocol exists

The noites session has limited time and a fixed token budget. Re-checking pendências before drafting the mission list eliminates the most expensive failure mode: **duplicated work**. A pendências doc that is not reconciled quickly becomes fiction: items stay listed as "Falta executar" long after they were merged, which leads the next noites session to spend an evening re-implementing what was already merged weeks ago. The reconciliation step is cheap (≤ 10 minutes of `git log` + a few `ls`/`grep`/`docker ps` calls) and prevents a multi-hour wrong-night.

**Cost of skipping reconciliation**: typically 30–60% of the noites session is wasted on items already done. The 2026-09-03 dashboard Wave A debrief lists this as a top-3 lesson from the previous cycle.
