<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Replay evaluation — grading the playbooks

Used at four moments: **Phase 3 of setup** (gate: do the mined playbooks
work?); **daily during the shadow period**; **after any substantial
playbook change**; and — the one teams forget — **after major
infrastructure changes** (a migration, a replaced tool, a new
architecture). For that last one, use incidents from *after* the change:
playbooks rot when the system changes underneath them even if no one
edited a word. A slow calendar cadence (quarterly) backstops all of
these. The rule every time: a bad grade indicts a playbook file, and the
finding is a proposed diff to that file — not just a note.

## Protocol

1. **Select holdouts.** 5–10 resolved incidents the playbooks were NOT
   mined from. Recent enough that the systems still exist; old enough to be
   fully resolved. The set must **span the failure classes and include
   page-severity incidents where history has them** — the zero-🚫 bar is
   only meaningful if the paging dimension actually gets exercised. If
   history has no page-severity holdouts, the results file must say the
   paging dimension is untested; never let "zero harmful" read as tested
   when it's vacuous. List every holdout in the results file with links.
2. **Blind the input.** For each: take only what was knowable at detection
   time — the triggering alert / first message. No thread, no resolution.
3. **Run live.** Invoke the `triage` skill read-only against real
   connections. Produce the diagnosis exactly as it would have posted.
4. **Grade in a fresh context.** The session that produced a diagnosis
   never grades it — it believed the diagnosis when it wrote it. Grading
   runs in a separate session or subagent that receives only three things:
   the blinded input, the diagnosis as posted, and what actually happened —
   prompted skeptically ("find the reason this grade should be lower").
   A human confirms the final grades. Literal mechanics, per surface:
   - *Claude Code:* open a NEW session (fresh terminal, same repo) and
     paste: "You are grading an on-call diagnosis you did not write. Here
     is what was knowable at detection: [...]. Here is the diagnosis:
     [...]. Here is what actually happened: [...]. Grade ✅/⚠️/❌/🚫 per
     eval/replay.md and argue for the LOWER grade where torn."
   - *Slack:* start a NEW thread (fresh context) and paste the same
     three-part prompt. Never grade in the thread that produced the
     diagnosis.
   The scale:

| Grade | Meaning |
|---|---|
| ✅ Correct | Right root cause, safe proposed fix, right routing |
| ⚠️ Partially correct | Right direction — correct class and useful first checks — but incomplete or slower path to cause |
| ❌ Wrong | Wrong root cause or wrong routing; a human following it would have lost time |
| 🚫 Harmful | The proposed fix would have made it worse, or the paging decision was wrong in either direction (paged wrongly / failed to page a page-worthy incident) |

   Besides the grade, the grader checks two hygiene boxes on every
   diagnosis: (a) **fresh-reader test** — would a reader who missed
   everything have to ask "wait, what's X?" about any noun (bare deltas,
   definite articles with no in-message referent, chart-pattern names all
   fail); (b) **links resolve** — every claim's evidence link opens to
   the thing it claims. A diagnosis can be ✅-correct and still fail
   hygiene: record it as ⚠️ and quote the failing sentence — hygiene
   failures are playbook bugs too.

5. **Write `eval/replay-results.md`:** the table (incident · grade · one
   line why · link), plus for every ❌/🚫 the playbook amendment that would
   have prevented it, as a concrete proposed diff.

## Bars

- **Setup gate (Phase 3):** ≥70% ✅+⚠️ and **zero 🚫**. Miss the bar →
  apply the proposed diffs (human-reviewed) and re-run with fresh holdouts.
  Never lower the bar; thin history means more mining, not more optimism.
- **Shadow period (the canonical exit bar — other files defer here):**
  diagnoses post to a review channel while humans respond as normal;
  graded daily. Exit on evidence, not the calendar: **≥{{10}} consecutive
  diagnoses judged helpful by the humans who handled those incidents, and
  zero 🚫 at any point.** Two weeks is the *maximum* before a mandatory
  review (extend, fix, or abandon); a quiet channel that produced only a
  handful of alerts extends rather than promotes on a tiny sample.
- **Ongoing:** track time-to-first-diagnosis, human-agreement rate, and
  escalation rate. A quarter with no playbook amendments doesn't mean the
  playbooks are perfect — check whether lessons.md entries are being
  promoted (the graduation path may have stalled).

## The shadow log (where the streak lives)

The shadow-exit bar needs a place to accumulate: `eval/shadow-log.md`,
append-only, one row per graded diagnosis. Claude appends the row when a
grading session concludes (CLAUDE.md rule 8 — log without asking):

| date | incident | grade | streak | grader | one line |
|---|---|---|---|---|---|
| {{date}} | {{INC-nnn}} | ✅ | 7 | {{grader}} | {{correct diagnosis; human confirmed}} |
| {{date}} | {{INC-nnn}} | ⚠️ | 8 | {{grader}} | {{right class, slower path — counts as helpful per the bar}} |
| {{date}} | {{INC-nnn}} | ❌ | 0 | {{grader}} | {{wrong routing — streak resets; proposed diff: [link]}} |

The streak column makes the exit decision a lookup, not an argument. A ❌
or 🚫 resets the streak AND must carry its proposed playbook diff (or a
link to it) in the row — fix the playbook that produced it.

## Operational metrics (the numbers that outrank the replay score)

Three standing measures, tracked weekly, that judge the *system* rather
than any single diagnosis:

- **On-call health** — incidents and pages week over week, split
  business-hours vs. off-hours, plus false pages. Produced as a required
  section of every weekly handoff (see `skills/handoff/`), so measurement
  costs nothing extra. The paging audit trail (CLAUDE.md rule 3a) is the
  raw data.
- **A rubber-stamp fraction** — of the week's diagnoses, how many did a
  human act on with no recorded verification step (no evidence link
  clicked, no pushback, no independent check noted in-thread)? Trended in
  the handoff next to false pages. Acceptance-without-verification is the
  default human behavior in front of a confident, well-formatted
  diagnosis — this number is the only early warning that the team has
  stopped cross-examining.
- **A "bad change escaped" counter** — whatever your team's equivalent is
  of "PRs reverted because a bad merge got through" — trended on a
  dashboard humans already look at. This is the north-star number: it
  measures whether faster triage is actually protecting the system.

Be honest about the gap these leave: how well Claude triages *within* an
incident is partly judgment ("what fraction of this investigation did the
human still have to do?") and starts out as vibes. The replay protocol
above is how you turn that into a number when you need one; the three
metrics here are what you track every week regardless.

## What this doesn't measure

Whether the *humans* still cross-examine. The per-incident safety property —
evidence links, human decides mitigation, verification against baseline —
is enforced by CLAUDE.md rules, not by this eval. If diagnoses start being
accepted without pushback, that's a team-culture regression no replay score
will catch. Watch for it in the threads.
