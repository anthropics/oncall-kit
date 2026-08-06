<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Example run: `#checkout-oncall` at a fictional web shop

A complete, fictional setup run — a payments/checkout on-call, deliberately
**not** CI, to show that the kit discovers *your* failure classes rather
than assuming CI's. Total human time across all five phases: about 2 hours.
Files in this directory are the artifacts those phases produced.

## The run, phase by phase

**Phase 0 — Discover** (~10 min). The channel had four connections. The
probe found the pager credential could read incidents but listing services
403'd — recorded as a gap rather than papered over. Output: `STACK.md`.

**Phase 1 — Mine** (~40 min, 60 days of history: 41 resolved incidents —
8 reserved untouched as Phase 3 holdouts, 33 mined).
Clustering proposed five classes; the human merged two ("card declines" and
"3DS failures" were one upstream pattern) and deleted one (a migration-era
class that can't recur). Final: `card-declines`, `webhook-lag`,
`checkout-latency`, plus 6 incidents left uncategorized — honestly. Output:
three drafted references (one included here), `lessons.md` seeded with 33
entries, and a routing tree with two flagged conflicts (CODEOWNERS said
`@payments-core`; threads showed `@risk-eng` actually responding to decline
spikes).

**Phase 2 — Interview** (~20 min). Paging thresholds set (the mined
suggestion for decline-rate was accepted; the latency one was tightened),
both routing conflicts resolved in favor of who-actually-responds, deploy
windows bound to the release channel, and the read-only guarantee
confirmed. Output: completed `ONCALL.md`
(included in this directory, as later amended).

**Phase 3 — Validate** (~30 min). 8 held-out incidents replayed:
5 ✅ · 2 ⚠️ · 1 ❌ · 0 🚫 = 87% pass. The ❌ (a decline spike misattributed
to a deploy that was coincidental) produced a proposed diff to
`card-declines.md`: "check the upstream processor's status feed *before*
correlating with deploys" — applied, gate passed. Output:
`replay-results.md`.

**Phase 4 — Install.** Routines pasted in order: handoff
(Mon 9am ET), alert-watch pointed at `#payments-alerts` in shadow mode
(posting to `#oncall-claude-review`) for two weeks. Paging routine held
back until after shadow. Status stayed on-demand — anyone asks in the
channel — per the kit's default (the weather routine came later; see
month two below).

## What the shadow period changed

Week 1: 11 alerts, 9 helpful diagnoses, 2 misses — both webhook-lag cases
where the reference lacked a check the humans always ran from muscle memory
(queue-consumer restarts). The playbook was amended by PR (the diff is what
you'd expect: one new row in the correlation table, provenance `seen 2×`).
Week 2: 8 alerts, 8 helpful. Shadow exited; the alert-watch routine was
repointed at the live threads. Paging stayed human for another month by
choice.

## Month two: what the shadow period couldn't teach

**The relapse.** INC-368 was flagged stale on the evidence "checkouts
flowing again, thread quiet a full day" — then re-fired hours later when
the processor's *webhook delivery* degraded while checkouts stayed
healthy.
Lesson (now in `lessons.md` and ONCALL.md's staleness rules): a healthy
proxy proves only the path it measures; if the incident's specific
symptom isn't something your checks would surface, hold off and say why.

**The first flag-ramp proposal.** For INC-372, Claude's diagnosis ended
with a ramp plan — new-checkout-flow flag 25% → 10% → 0%, 10-minute
holds, abort-and-restore if decline rate moved — which the on-call
executed by hand in four minutes. Claude wrote the plan; a human ran it.

**Weather opt-in.** With two incidents overlapping, "what's the state of
things" questions spiked, so the team opted into the weather routine
(2026-07-06) — the filled `ONCALL.md` in this directory records the
cadence targets, and `weather-week.md` shows a week of its cycle log:
six posts, dozens of silent cycles, every skip with a reason.

## The point

Nothing in this run required writing a playbook from scratch. The team's 41
incidents already contained the playbooks; the kit's job was extraction,
review, and gating.
