# Daily Session Prompt — M0→M3 adaptive plan

Use this template for short daily OpenChamber sessions (≤ 60 min). The M0–M3 plan is an adaptive ladder — finish M0 cleanly before considering M1, etc.

---

## M0 — Orient (≤ 5 min)

- Read `notes/NIGHT-REPORT-<last>.md` (most recent noites report).
- Run `git log --oneline -10` in the active project.
- Check container/cron health if the project runs on the VPS.
- **Output**: 1 paragraph — current state, last done, next obvious step.

## M1 — Plan (≤ 10 min)

- Pick ONE concrete deliverable for this session. State it as: "End of session, <file> exists and <check> passes."
- If the deliverable touches the VPS: state the SSH session id, the host, and the rollback line.
- If the deliverable touches config: state the backup path (`<file>.bak-<YYYYMMDD>-<motivo>`).
- **Output**: 3 bullets — Deliverable, Rollback, Verify.

## M2 — Execute (≤ 35 min)

- Do the work. No scope creep. If a side-quest appears, write it to `notes/SIDE-QUESTS-<date>.md` and continue.
- Commit at logical breakpoints (atomic commits).
- If the work fails: STOP at first error, do not retry the same way twice. Read the error, identify the root cause, then try a genuinely different approach.

## M3 — Verify + Handoff (≤ 10 min)

- Run the verify step from M1. If it fails: rollback.
- **If the session closed a pendência item, update the doc first** (close + seed for next wave + header line). This is the same M3 hard rule as `noite.md` — see SKILL.md §"M3 hard rule". For ≤60 min daily sessions this usually means 1 close-commit, no seed.
- Write 1 paragraph in `notes/HANDOFF-<date>.md` — what was done, what's next, blockers.
- If a noites session is needed: produce a noites prompt using the `noite.md` template.

---

## Anti-patterns

- **Don't** re-read files already in context. If a file was read this session, the content is still in your context window.
- **Don't** chain more than 3 `windows-mcp_*` calls without a `Snapshot` or `WaitFor` in between.
- **Don't** paste large file contents into the chat — write to disk and reference the path.
- **Don't** invent success — if a step fails, report the failure with the exact error.
