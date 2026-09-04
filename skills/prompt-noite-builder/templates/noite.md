# Noite Prompt — full noites session

Use this template for the **noites OpenChamber session** — the long, unsupervised background run that closes a day. Inputs: a verified state snapshot, a mission scope, and a KEEP/DISCARD list. Output: a single Markdown file the orchestrator can feed to `openchamber session.create`.

---

## Sections

1. **Identity** — who is running, what project, what model, what schedule.
2. **State snapshot** — the verified "as of" picture (git log, containers, cron, last noites report).
3. **Mission** — the concrete deliverables for tonight.
4. **Constraints** — hard rules (do not touch X, do not delete Y, etc.).
5. **Steps** — M0→M3 plan, scoped to the noites cycle.
6. **KEEP / DISCARD markers** — split points if the prompt overflows the size limit.
7. **Handoff** — where to write the result, what to commit, what to push.

---

## 1. Identity

- **Project**: <project slug>
- **Model**: <provider/model — prefer `minimax/minimax-m3-free` on local>
- **Schedule**: <cron or one-shot date>
- **Workspace**: <absolute path>
- **Last noites report**: `notes/NIGHT-REPORT-<last>.md`
- **Pendências doc**: <path or "none">

## 2. State snapshot

<verified state, max 30 lines, prefer bulleted>

- Git: branch `<branch>`, last commit `<sha>` — `<msg>`
- Containers: `<container>` = `<status>`, `<port>` mapped
- Cron: `<cron line>` last ran `<time>`
- Open todos: `<count>` open issues, `<top 3 titles>`
- Pendências (after reconciliation): `<closed by this run> closed, <open> open`

## 3. Mission

End of noites, **ALL** of the following are true:

- [ ] <deliverable 1 — verifiable, atomic>
- [ ] <deliverable 2 — verifiable, atomic>
- [ ] <deliverable 3 — verifiable, atomic>

**Optional** (do only if M0–M2 done with margin):

- [ ] <nice-to-have 1>
- [ ] <nice-to-have 2>

## 4. Constraints

- **Do not** touch `<file/container/cron>` without owner approval.
- **Do not** delete anything without a backup at `<backup path>`.
- **Do not** push to `<remote/branch>` without `git pull --rebase` first.
- **Do not** paste secrets, tokens, or `av_agt_*` keys into the chat.
- **If peak gate is active** (01:00–04:00 or 06:00–10:00 UTC): use a `*-peak` model and write "CONFIRMO QUE CONTINUA" in the body.

## 5. Steps (M0→M3)

### M0 — Orient (≤ 15 min)

- Read `notes/NIGHT-REPORT-<last>.md`.
- **Reconcile the pendências doc** (if one was declared in §1). For each `❌ Falta executar` item: run `git log --all --oneline | grep -i "<kw>"`, `ls -la <expected file>`, and the relevant `docker ps` / `curl` / `grep` checks. Move done items to `✅ Já implementado e merged (NÃO repetir)` with one citation. Commit the doc as `chore(docs): reconcile pendências — close items N, M, ...`. Do NOT start the mission without doing this.
- Run `git log --oneline -20` and `git status` in the workspace.
- Check container health: `docker ps` on the VPS (if relevant).
- Read the KEEP/DISCARD markers below; load the KEEP half first.

### M1 — Plan (≤ 20 min)

- For each mission deliverable, state: file path, verify step, rollback step.
- If the work touches the VPS: state the SSH session id, the host, and the rollback line.
- If the work touches opencode.jsonc / chains.json: state the backup path (`<file>.bak-<YYYYMMDD>-<motivo>`).

### M2 — Execute (rest of noites)

- Do the work in atomic commits. One commit = one logical change.
- After each commit: run the verify step from M1.
- If a step fails: STOP, read the error, identify root cause, retry with a genuinely different approach (never twice the same way).
- If the KEEP half is exhausted and the DISCARD half is still needed: load it, but do not start new threads — only finish in-flight work.

### M3 — Verify + Handoff (≤ 30 min before handoff time)

- Run ALL verify steps from M1 and M3.
- Run `git status` — must be clean (or only the expected untracked).
- **Re-reconcile the pendências doc**: any item you finished during M2 should be moved to the closed section with the commit hash. Commit as `chore(docs): close pendências X, Y from this cycle`.
- Write `notes/NIGHT-REPORT-<YYYYMMDD>.md`:
  - State (what is true now)
  - What was done (one bullet per deliverable, with commit hash)
  - What is next (one bullet per unfinished item, with the noites prompt path for the next cycle)
  - Lessons (one bullet per non-obvious gotcha, with severity)
  - **Pendências delta** (one line: `N closed this run, M remain open — see <doc path>`)

### M3a — Auto-debrief (≤ 10 min, last step before push)

- Spawn `task(agent="vps-operator", brief="Generate NIGHT-SESSION-DEBRIEF-<SID>.md (≤3 KB) per prompt-noite-builder schema. Use sqlite3.Connection.backup() for the opencode DB. <SID>=<current session id>")`.
- The subagent extracts: runtime, tool error breakdown, subagent timing, parallelism gaps, auto-corrections, owner blockers, infra observations. Returns a 1-line summary.
- Commit the debrief as `chore(docs): auto-debrief ses_<id>`.

### M3b — Manual debrief review (next-day owner session, OUT OF SCOPE for noites)

The next-day owner session reads `notes/NIGHT-SESSION-DEBRIEF-<SID>.md` and writes `notes/DEBRIEF-ACTIONS-<YYYYMMDD>.md` per the skill's M3b protocol. The noites session does NOT do M3b.

- Commit + push the NIGHT-REPORT and the auto-debrief.
- If the next noites cycle needs a prompt: produce it now using this same template.

## 6. KEEP / DISCARD markers

```
<!-- KEEP: everything above this line is mandatory -->
---
<!-- DISCARD: everything below this line is optional, loaded only if size budget allows -->
```

If the prompt exceeds the OpenChamber size limit (~16k tokens):

- The orchestrator loads everything UP TO `<!-- KEEP: -->` first.
- If KEEP fits, the DISCARD half is appended.
- If even KEEP overflows: REJECT the prompt, the user must shorten the mission scope.

## 7. Handoff

- **NIGHT-REPORT**: `notes/NIGHT-REPORT-<YYYYMMDD>.md` (mandatory).
- **Next noites prompt**: `notes/prompts/noite-<YYYYMMDD+1>.md` (if next cycle needed).
- **Open issues updated**: yes/no.
- **Push status**: commit `<sha>` pushed to `<remote>/<branch>` — yes/no.

---

## Anti-patterns (do not do)

- **Do not** re-read files already in context — they are in your window.
- **Do not** chain more than 3 `windows-mcp_*` or `vps-mcp_*` calls without a state check.
- **Do not** invent success — if a step fails, report the exact error.
- **Do not** start a noites prompt without a verified state snapshot.
- **Do not** use the `bash` tool on the orchestrator (denied); use `pc-exec` (PowerShell) or the `vps-bash-executor` skill for remote.

---

## Quick state snapshot (example, replace per session)

- `/home/pipeline/pipeline/docker/openchamber/data/opencode/config/opencode.jsonc` (openchamber config, **NUNCA editar sem backup**)
- `/home/pipeline/pipeline/docker/openchamber/data/opencode/agents/infisical-broker.py` (broker)
- `/home/pipeline/opencode-fallback-proxy/` (router)

### Paths críticos no openchamber container

- `/home/openchamber/.config/opencode/opencode.jsonc` (config global)
- `/home/openchamber/.local/share/opencode/opencode.db` (sessões, **NUNCA copiar vivo**)
- `/home/openchamber/.open-mem/memory.db` (memória avariada, ver regra 3)

---

## Tailscale serve map (referência, ver regra 8)

| URL | Host port | Container port | Serviço |
|---|---|---|---|
| `https://pipeline-vps-new.tailbbccd8.ts.net/` | 443 | 127.0.0.1:8082 | open-webui |
| `https://pipeline-vps-new.tailbbccd8.ts.net:8443/` | 8443 | 127.0.0.1:3010 | openchamber |
| `https://pipeline-vps-new.tailbbccd8.ts.net:8444/` | 8444 | 127.0.0.1:3000 | dashboard |

---

## Notas operacionais

- **app_user schema**: id, email, company_id, status, role, created_at, activation_token_hash, activation_expires_at, password_hash. User 10 = giofsp1@gmail.com (active, owner, company 10, created 2026-09-01T21:37:25.326Z).
- **DB live**: 49 tabelas, 10 users, 16 funding, schema_migrations #042 (gating_event_revert).
- **Rollback image**: `dashboard-b2b:pre-rebuild-20260901` JÁ CRIADA.
- **DB backup**: `/home/pipeline/pipeline/backups/dashboard-b2b/app-2026-09-01-pre-rebuild.db` (590KB) JÁ FEITO.
- **NIGHT-REPORT anterior**: `app/NIGHT-REPORT-20260903-2.md` (9475B) — sessão dia 2026-09-01.
- **Tailscale nodes**: pipeline-vps-new (100.95.67.86 active), pipeline-vps (100.87.152.63 MORTO), desktop-06s7p6v (100.106.88.63 Windows active), moto-g75-5g (offline).