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

## M0 Pre-flight (path resolution) — added 2026-09-04

Before step 2, validate every path cited in the brief against the actual filesystem. One wrong path in a noites brief sends the orchestrator on a multi-minute M0 recon detour (real example: `ses_f96b45f0cffedj1m4dihINdUlH`, 348s wasted).

**Pre-flight checks (run BEFORE step 1, in this order):**

1. `pwd` — confirm current working directory is a project root.
2. `git rev-parse --show-toplevel` — confirm it points to a valid git root.
3. For every absolute path in the brief: `ls -la <path>` and `cd <path> && pwd`. If any path doesn't exist, fix the brief (do not just log it).
4. `docker ps --filter name=<project-keyword>` — confirm the project container is `Up`.
5. Tool-permission reminder: the orchestrator's `bash` is denied by AGENTS.md rule. Every shell action goes through `task(agent=...)`. `fdx-git`/`fdx-ls`/`fdx-grep` MUST pass `directory=<repo-root>` because the session CWD is often the **parent dir** of the git root, not the git root itself (openchamber container default).

**Path mapping (container ↔ host)** — document this in the brief so the orchestrator does not have to guess:

| Container path (use this in brief) | Host path (use this in compose/scripts) |
|---|---|
| `/home/openchamber/workspaces/<project>/` | `/home/pipeline/pipeline/docker/openchamber/workspaces/<project>/` |
| `/home/openchamber/workspaces/<project>/app/` | `/home/pipeline/pipeline/docker/openchamber/workspaces/<project>/app/` |
| `/home/openchamber/.config/opencode/` | `/home/pipeline/pipeline/docker/openchamber/data/opencode/config/` |
| `/home/openchamber/.local/share/opencode/opencode.db` | bind mount — never copy live, use `sqlite3.Connection.backup()` |

Rule: **always cite container paths in briefs, host paths in scripts/composes**. Mixing them is the #1 source of the 348s M0 detour.

## M3a — Auto-debrief (added 2026-09-04)

The last 10–15 minutes of the noites session generate an **auto-debrief**. This is a separate file from the NIGHT-REPORT — the report describes what was done, the debrief describes how the session **ran** (efficiency, errors, infra).

**Auto-debrief protocol:**

1. At M3 (after `git status` is clean), spawn ONE subagent: `task(agent="vps-operator", brief="...")`. The brief must include: the session id (`ses_...`), the target path for the debrief (`notes/NIGHT-SESSION-DEBRIEF-<SID>.md`), the size cap (≤3 KB), and a pointer to the schema below.
2. The subagent MUST:
   - Use `sqlite3.Connection.backup()` to snapshot the opencode DB (per AGENTS.md rule, never copy a live DB).
   - Extract from the snapshot: `messages` (filter by session id), `tool_calls`, `subagent_sessions`, `goal_mode` if present, and any `error` rows.
   - Compute: actual runtime, tool error breakdown (top 5), subagent timing table (with parallel/serial flags), cache hit ratio, cost.
   - Write the debrief using the schema below. **Do not include** PII, secrets, `av_agt_*` tokens, or the full message text — only counts, durations, and pattern summaries.
3. The orchestrator commits the debrief as `chore(docs): auto-debrief ses_<id>` and pushes with the NIGHT-REPORT.

**Auto-debrief schema (≤3 KB target, copy verbatim):**

```markdown
# NIGHT-SESSION-DEBRIEF: <SID>
**Runtime**: <X>h <Y>m (target <Z>h) — delta: ±<W>h
**Mode**: completed | early-exit | killed | crashed
**Model**: <primary> | **Cost**: $<X.XX> | **Cache hit**: <ratio>

## Tool health (top 5 errors)
| Tool | Count | Pattern | First / last seen |
|------|-------|---------|-------------------|
| <tool> | <n> | <pattern> | <ts> / <ts> |

## Subagent efficiency
| Subagent | Time | Wasted? | Note |
|----------|------|---------|------|
| <agent> | <s>s | yes/no | <note> |

## Parallelism
- <X> subagents fired in <Y>s (cluster) — yes/no
- <N>m serial where parallelism was possible — yes/no

## Auto-corrections made by orchestrator
- <correction 1>
- <correction 2>

## Owner blockers raised
- <blocker 1> (e.g. OPENALEX_KEY missing — Inbox item, not committed)

## Infra observations
- RAM peak: <X> GiB / <Y> GiB
- Peak gate hits: <N>
- MCP -32001: <N>
- Container restarts: <N>

## Owner decisions recommended
- [ ] <decision 1>
- [ ] <decision 2>
```

## M3b — Manual debrief review (next-day owner session)

The next-day session (typically 30–60 min, owned by the human) reviews the auto-debrief and decides which fixes to apply. This is the **manual half** of the debrief protocol.

**Protocol for the next-day session:**

1. Open the auto-debrief: `notes/NIGHT-SESSION-DEBRIEF-<SID>.md`. If the file is missing or <1 KB, the auto-debrief failed — re-run M3a manually.
2. For each item in `## Owner decisions recommended`: classify as `apply now` / `plan first` / `reject`. The owner uses the `question` tool for binary decisions.
3. For each item in `## Tool health` and `## Subagent efficiency` with `Wasted? yes`: classify as `fix in skill` / `fix in config` / `accept as-is`.
4. For each item in `## Infra observations` with abnormal values: classify as `log it` / `fix now` / `regression watch`.
5. Write `notes/DEBRIEF-ACTIONS-<YYYYMMDD>.md` (≤2 KB) with the decisions. Each action links to a follow-up commit or a `fix` task in the next noites prompt.
6. Commit + push the actions file as `chore(docs): debrief actions from ses_<id>`.

**Why the dual auto+manual split**: the auto-debrief is cheap (≤10 min) and always runs. The manual review is where context meets judgement — without it, even a perfect auto-debrief is just a log file nobody reads. The 4–10 session cohort is the sweet spot for this protocol: enough history to see patterns, still small enough that one review per noites session is sustainable.

**Anti-pattern**: do not skip the manual review just because the auto-debrief looks clean. The most expensive lessons are the ones that look "fine" in the data but reveal a process problem in conversation.

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

## M3 hard rule: pendências doc must end the cycle in a true state — added 2026-09-04

**Rule.** Every noites session MUST end the cycle by updating the pendências doc — even if the session ran over budget, ended early, or closed zero new tasks. The doc is the most important artifact the noites session produces, more than any commit. A stale doc poisons the next cycle.

**When.** This update is the FIRST step of M3, BEFORE writing the NIGHT-REPORT. (Closing the items in the report before the doc means the report cannot accurately cite the close-commit hash; the doc must come first.)

**3 sub-steps, all mandatory:**

1. **Close finished items** — any item finished during M2 moves from `❌ Falta executar` to `✅ Já implementado e merged (NÃO repetir)`, with a one-line citation of the closing commit hash. Commit as `chore(docs): close pendências X, Y from this cycle`.

2. **Seed pendências for the next wave** — append a section to the doc titled `## Pendências para a próxima wave (<NEXT_WAVE_NAME>)`. Content:
   - Items still open after this wave (cite why they didn't ship — BLOCKED, deferred, out of scope, owner-gated).
   - Items surfaced DURING this wave that are now candidates (e.g. "better-sqlite3 ABI mismatch discovered during WebKit smoke — needs `npm rebuild` + verification").
   - Each item: one-line "why this matters" + one-line "suggested next-step". This is what the next prompt-noite-builder call uses to seed the mission list.
   - Commit as `chore(docs): seed pendências for <NEXT_WAVE_NAME>`. If no items, commit `chore(docs): no new pendências for <NEXT_WAVE_NAME>` (empty state is still a state — it tells the next session "nothing to seed").

3. **Update the "Última reconciliação" line** in the doc header from `<previous date> (<previous wave>)` to `<today date> (<current wave>)`. Single line, no commit (rolled into the close commit).

**Why this is hard, not soft.** A noites session that ends with a stale PENDENCIAS doc forces the next session to do a 30-minute "archaeology" pass to figure out what is still real and what is fiction. The 2026-09-04 dashboard Wave B post-mortem (§H lesson 1) explicitly flagged this: "Briefings can be stale" — and the cure is a strict end-of-cycle doc update.

**Anti-pattern.** Writing the NIGHT-REPORT before the doc update. The report cites commits, but the doc's `✅ Já implementado` block is the place to bind commit hash → closed item. If the doc is updated after the report, the report can be wrong; if the doc is updated before, the report can cite the close-commit accurately. **Order: doc close → doc seed → doc header line → NIGHT-REPORT → push → auto-debrief.**

**Verification step (M3 verify).** Before pushing, run: `git log --oneline -3 -- <PENDENCIAS-doc-path>`. The last 3 commits should include the close-commit AND the seed-commit. If only 1 or 0 is present, the M3 hard rule was skipped — fix before push.
