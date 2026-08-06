---
name: oncall-setup
description: >
  Bootstrap a Claude-assisted on-call for this channel/repo: discover the
  available connectors, mine incident history into draft triage playbooks,
  interview the human for policy, validate against held-out incidents, and
  install the scheduled routines. Use when the user wants to "set up on-call",
  "bootstrap the on-call kit", "onboard this channel", or has just installed
  the oncall-kit plugin. Five gated phases — never run more than one phase
  per turn, and never activate anything before Phase 4 sign-off.
---

<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# On-call setup (five gated phases)

You are bootstrapping the on-call kit for this team. The kit's `README.md`
defines the target state; `CLAUDE.md` defines your standing rules — read both
before acting. Rules 13–15 (gates, provenance, thresholds) govern everything
below.

Determine which phase you're in by what exists on disk:

| If | Phase |
|---|---|
| No `STACK.md` | 0 — Discover |
| `STACK.md` exists, no draft references | 1 — Mine |
| Drafts exist, `ONCALL.md` has unfilled `{{...}}` policy blanks | 2 — Interview |
| `ONCALL.md` complete, no `eval/replay-results.md` | 3 — Validate |
| Replay passed, routines not yet installed | 4 — Install |

**Open every phase with the same four-line briefing — it is the FIRST text
of the phase's first reply, before any tool call, every phase including
Phase 0:**

> **Phase N of 5 — {{name}}.** What happens: {{one sentence}}. Takes about:
> {{estimate — Discover ~10 min · Mine ~30–60 min of my work + ~20 min of
> your review · Interview ~15 min of questions · Validate ~30 min ·
> Install ~15 min of you pasting routines}}. What changes: {{the files
> written / nothing outside this repo / routines go live}}. At the end I'll
> stop and ask you to: {{what the gate will ask}}.

If this is the user's first phase this session, also show the one-line map
of all five phases so they know where they are. Then run the phase, deliver
its output, STOP at the gate.

## Phase 0 — Discover

Goal: bind capabilities to whatever is actually connected, without naming
vendors anywhere else in the kit.

0. **Determine the surface.** Are you running in the Slack channel (as the
   channel's Claude) or in a local Claude Code session in the repo? Note it
   in `STACK.md`. Phases 0–3 work from either; **Phase 4 requires the
   channel**. If you're local, tell the user now what Phase 4 will need so
   it isn't a surprise: `@Claude` invited to the on-call channel (and each
   alert channel to watch), and an Owner adding this repo to the channel's
   access bundle. Point them at `TAG-SETUP.md` — it separates what they can
   do themselves from what needs their Claude org Owner, and contains a
   paste-ready request message with the blanks to fill from this repo's
   context. Offer to fill those blanks for them now. Record "channel
   connectivity: unverified" as a Gap.

1. Enumerate every tool/connection available in this session (in a channel:
   also ask yourself "what can I access from this channel?" and list the MCP
   tools present).
2. For each, probe **read-only**: list one dashboard, run one trivial log
   query, list the last 5 pages/incidents, read the repo's CODEOWNERS. Record
   what worked, what 403'd, what doesn't exist.
3. Classify each connection into the kit's capability slots:
   - `metrics` — dashboards / time-series (error rates, latency, queue depth)
   - `logs` — searchable log store
   - `pager` — paging + incident history
   - `code` — repo host: PRs, diffs, CODEOWNERS, deploy history
   - `alert-channels` — Slack channels where alerts and incident chatter land
   - `incidents` — where incident records live: threads in the on-call
     channel (the zero-infrastructure default), per-incident channels if
     the team's incident tooling provisions them, pager incident objects,
     or tickets. Ask the human how an incident is *declared* today and bind
     to that — never invent a new incident process during setup.
   - `deploys` — deploy/release feed, if separate from `code`
4. Write `STACK.md` from `templates/STACK.md`: one line per capability →
   concrete connection, plus the probe result and any gaps ("no pager
   connected — paging phase of routines will be skipped").

**Gate:** post the capability map. Ask the human, explicitly and numbered:
(1) confirm or correct each binding; (2) name any alert channels you
couldn't discover; (3) how is an incident DECLARED on this team today —
thread convention, per-incident channel, pager object, ticket? (This
question is mandatory even if the `incidents` bullet was answered — a
guessed declaration convention poisons everything downstream.) Do not
proceed.

## Phase 1 — Mine

Goal: draft the triage playbooks from the team's own history instead of a
blank page.

0. **Agree the scope before reading anything.** The window question is also
   the consent question — ask it in one message that names exactly what
   you'll read:

   > I'll mine resolved incidents to draft your playbooks. That means
   > reading, over the window you pick: your pager's incident history, the
   > incident threads and alert traffic in {{the bound channels, named}},
   > and any postmortem docs you point me at. I extract investigation
   > steps and root causes — symptoms, queries, fixes. I won't quote
   > individuals or read channels beyond those named. How far back — 30,
   > 60, or 90 days? And is there anything to exclude (a channel, a
   > specific incident, a time range)?

   Honor exclusions absolutely, and if history retrieval comes up short of
   the agreed window (search depth, retention), say what you actually
   covered — never silently mine less than agreed.

1. **Collect.** Pull the resolved incidents from the agreed sources only. For each: the triggering alert,
   the thread, who responded, what they checked (queries, dashboards,
   commands visible in the thread), the stated root cause, the fix, time to
   resolution.
2. **Cluster into failure classes.** Aim for 3–7 classes that cover ≥80% of
   incidents; everything else goes in an `uncategorized` list, not a forced
   class. Name classes by symptom, not by root cause ("merge queue stalled",
   not "the Redis bug").
3. **Draft one reference file per class** using the structure in
   `skills/triage/references/test-failures.md` (the worked example):
   symptoms, first checks (the queries humans actually ran, generalized),
   a correlation table of "if you see X and Y, it means Z" mined from the
   resolutions, known-cause pointers into `lessons.md`, and escalation hints.
   **Every mined row carries provenance:** `(seen 3×: INC-nnn, INC-nnn,
   INC-nnn)` or `(seen 1×, unverified)`.
4. **Seed `lessons.md`** from `templates/lessons.md`: one entry per distinct
   resolved incident, in the entry formats defined there (incident /
   investigation / GOTCHA), newest first, and write its opening Status
   banner.
5. **Propose the routing tree** for `ONCALL.md`: cross CODEOWNERS (or module
   ownership) with who actually responded per class in the threads. Where
   they disagree, flag it — that's a question for Phase 2, not a guess.
   While you're in the data, check concentration: if one person handled
   most incidents across classes, flag it as a **bus-factor finding** for
   the Interview — framed as team resilience ("routing currently depends
   heavily on one responder; do you want the tree to distribute this?"),
   never as commentary on the person. Do not route around it yourself.

6. **Draft the alert-coverage report.** The mined incidents also grade the
   team's alerting. Look for three signatures and propose accordingly,
   every item with provenance:
   - **Coverage gaps** — incidents a *human* noticed with no alert firing:
     propose a new rule ("would have caught INC-311, INC-322").
   - **Late alerts** — alert fired long after observable onset: propose a
     tightened threshold/window, with the onset evidence.
   - **Noise** — rules that fired repeatedly with no incident: propose
     retirement or a raised threshold.
   Write the report to `alert-coverage.md` at the repo root (it lives
   there permanently — later post-incident proposals and decisions append
   to it, so declined proposals aren't re-proposed). Proposals are drafts
   for humans to review at the gate; none is installed in this phase.

**Gate:** the gate post MUST open with a verifiable header — these are
mechanical self-checks, not prose: (a) the mined incident-ID list's count,
which must equal the `lessons.md` entry count and must contain zero
holdout or excluded IDs (state all three checks and their results); (b) a
line reading exactly "Routing conflicts: none" or "Routing conflicts:
[list]" — resolving a conflict silently is forbidden, so this line makes
silence impossible; (c) one sample correlation row showing its provenance
tag; (d) a standalone checklist of EVERY routing-tree handle and every
correlation-row action target (who gets @-mentioned or paged, ever), each
on its own line for individual confirmation — these are the rows a
poisoned or mistaken mining pass would weaponize, so they get eyes one by
one, not skimmed inside 40 drafts. Then post a summary table (class → incident count → confidence) and
the draft files. Every draft is reviewable markdown; ask the human to correct,
delete, or confirm each class. Low-confidence rows stay marked even after
this gate — only repeated confirmation in production removes the annotation.

## Phase 2 — Interview

Goal: fill the policy blanks that cannot be mined. Ask **only** these, one
block at a time, offering mined suggestions where you have them:

1. **Paging criteria.** For each metric worth paging on: threshold, sustain
   window, and exemptions (deploy windows, known-noisy periods). Suggest
   values from alert history ("this metric's alerts self-resolved under 4%
   in 11 of 12 cases — suggest paging at sustained >4%/10min") but the human
   sets the number (rule 15).
2. **Severity norms.** What's a page vs. a business-hours ping vs. a morning
   log line.
3. **Escalation owners.** Resolve every routing-tree conflict flagged in
   Phase 1; get the real group handles (route to groups, not individuals).
   If Phase 1 flagged a bus-factor finding, raise it here as a resilience
   question and let the team decide whether the tree should distribute
   load differently than history did.
4. **Deploy windows.** How to tell a deploy is in progress (the `deploys`
   capability, a channel, a calendar).
5. **Escalation timeout and fallback alerting.** Two decisions, both the
   human's:
   - *Timeout:* when Claude posts a page-severity finding and @-mentions
     the routed owner, how long does it wait for acknowledgment before
     escalating — and to whom? An ack is an **explicit affirmative from a
     human** ("ack", "on it", or the team's designated reaction, from a
     person) — bot posts, alert traffic, and passive emoji do not count.
     Suggest a default ({{15 min}} → the escalation handle from block 3),
     but the human sets both the clock and the ladder. Also ask for the
     **terminal step**: if the escalation itself goes unacked, what
     happens — repeat-page via the pager's escalation policy, a wider
     channel post, or an explicitly accepted "unattended until morning"
     posture? The ladder must end somewhere deliberate. Without answers,
     Claude never re-pings on its own.
   - *Fallback:* when a page-severity finding can't page — no `pager`
     bound in STACK.md, or the page call fails — what happens instead?
     Offer the options and let them choose: @-mention the escalation
     group in the on-call channel; post to a designated always-watched
     channel; or hold for the morning log (only sane for teams with no
     off-hours expectations — say so). Be honest about the first two:
     **Slack @-mentions don't penetrate Do-Not-Disturb**, so an
     @-mention fallback is business-hours-grade coverage — tell the team
     this before they choose it. Record the choice in `ONCALL.md`;
     never invent a fallback mid-incident.

6. **Alert-rule proposals: format and install mode.** Two decisions:
   - *Format:* which alerting tool should proposals target, and in what
     paste-ready native form (monitor JSON, Terraform, PromQL, UI steps)?
     Prose proposals are not acceptable output — a proposal is something a
     human can install in under a minute.
   - *Install mode:* **default — Claude drafts, a human installs** (the
     paste is the permission; keeps the kit fully read-only). Or the
     **alert-editor extension**, opt-in only: a separate write credential
     to the alerting tool, additive-only — Claude may CREATE a new rule
     after explicit per-rule approval in the channel, may never modify,
     delete, or silence an existing rule, and logs every write to
     `lessons.md`. If they opt in, record it in `ONCALL.md` and
     `STACK.md`'s access posture. Present the trade honestly: the
     extension saves a paste; the default keeps "no write credentials to
     monitored systems" true without asterisks.

7. **Confirm the read-only guarantee.** Not a question — a statement to
   make once, so the team knows the contract: this agent never changes the
   state of any monitored system; its only outputs are messages, log
   entries, proposed PRs, and pages. There is no allowlist to configure.
   Teams that want automated mitigation are outside this kit's scope and
   should design that separately, on an accountable human identity.

8. **Lifecycle windows and standing reports.** Three decisions, all
   human-set numbers (rule 15):
   - *Staleness/zombie windows:* how long an open incident stays quiet
     before a "looks stale" nudge ({{24h}} suggested) and before the
     handoff's zombie list ({{72h}} suggested) — these gate what Claude
     *says*, never what it changes.
   - *Morning sitrep:* on or off, what time, and confirm the "post
     nothing when empty" behavior.
   - *Weather report:* opt in or skip — show the cost anchor from
     `templates/routines.md` and the cadence-guard design before they
     choose. Skipping is the default and completely fine (status stays
     on-demand). If they opt in, three things go into `ONCALL.md`: the
     cadence targets, the report-page binding, and the mood
     tier-boundary table (the two base signals and the human-set
     boundaries mapping each to sunny/partly_cloudy/overcast/stormy —
     the weather skill refuses to run without it).

Write the answers into `ONCALL.md` from `templates/ONCALL.md`, replacing
every `{{...}}`. Template fields no block covered (e.g. handoff cadence,
status-on-demand signals): fill with a sensible default, mark each
`(proposed)`, and list them explicitly at the gate for confirmation —
never leave blanks, never present a default as the user's decision.

**Gate:** post the completed `ONCALL.md` diff. The human signs off the
policy. Do not proceed.

## Phase 3 — Validate

Goal: prove the drafted playbooks against incidents they weren't built from.

1. Hold out 5–10 resolved incidents **not used** in Phase 1 (or the most
   recent ones if history is thin — say so). Span the failure classes and
   include page-severity incidents where they exist; if none exist, the
   results file states the paging dimension is untested.
2. For each: take only the triggering alert/first message, run the `triage`
   skill as if live (read-only), and produce the diagnosis you would have
   posted. For long-running holdouts, also produce the >30-min update —
   graded against triage step 6a's story-so-far spec, not just the
   diagnosis.
3. Grade **in a fresh context** (a separate session/subagent that didn't
   produce the diagnoses, prompted skeptically; human confirms), per
   `eval/replay.md`: ✅ correct / ⚠️ partially correct / ❌ wrong /
   🚫 harmful (would have misdirected mitigation or paged wrongly).
4. Write `eval/replay-results.md`: the table, per-incident links, and for
   every ❌/🚫 the playbook change that would have prevented it, as a
   proposed diff.

**Gate:** pass = ≥70% ✅+⚠️ **and zero 🚫**. Present the percentage as a
smoke test, not statistics — with 5–10 holdouts one grade swings ~14
points. The real content of this gate is the per-incident review of every
❌/🚫 and its proposed diff; the real quantitative gate is the shadow
period, where evidence actually accumulates. On pass, ask to
proceed. On fail, apply the proposed playbook diffs (with human review)
and re-run with fresh holdouts; a thin-history team that exhausts its
holdouts goes to shadow with the alert-watch routine in review-only mode
rather than re-testing on incidents the playbooks have now seen. Never
lower the bar.

## Phase 4 — Install

Goal: turn it on, narrowest first.

0. **Verify channel connectivity before anything else.** This phase only
   works from the Slack channel. The checklist, done by the human:
   `/invite @Claude` to the on-call channel and each alert channel to be
   watched; an Owner adds this repo to the channel's access bundle. Then
   the proof: **from the channel**, ask `@Claude what can you access from
   this channel?` and have it read `ONCALL.md` back. If it can't read the
   repo, stop — pasting routines against a repo the channel can't reach
   fails silently. Clear the "channel connectivity: unverified" gap in
   `STACK.md` once this passes.

1. Generate the routine messages from `templates/routines.md`, with real
   channel names, cadences, and `STACK.md` bindings filled in. Order:
   handoff (read-only) → morning sitrep (read-only, if chosen) → alert
   investigation (posts diagnoses) → weather (opt-in, event-gated, if
   chosen in Interview block 8). There is
   no detection routine to install — detection stays in the team's
   deterministic alerting; if a service is launching without alerts,
   propose starter rules per templates/routines.md instead.
2. Recommend the shadow period for the alert-watch routine (the handoff is
   a read-only weekly report and goes live immediately). Shadow exits on
   **evidence, not the calendar**: diagnoses post to a review
   channel/thread and are graded daily, and promotion to live follows the
   shadow-exit bar in `eval/replay.md` — the canonical source, which also
   covers the quiet-channel case (too few alerts means extend, not
   promote).
2a. **Create the routine registry.** After the pastes, create (or update) a
   channel canvas — or a pinned message where canvases aren't available —
   titled "Standing work in this channel": every routine's name, schedule,
   one-line purpose, live-or-shadow status, and last-changed date, plus
   one closing line ("to change when/where, edit the routine here; to
   change how/policy, PR {{repo}}"). Humans install routines; you keep
   this registry current whenever standing work changes, so what's
   running is legible at a glance to anyone who joins the channel.
3. The human pastes each routine into the channel (routines belong to the
   channel and its members — you don't install standing work for a team
   without them seeing exactly what it says).

**Gate (final):** confirm each routine the human installed by listing the
channel's standing work back. Remind them: to change *when/where*, edit the
routine in-channel; to change *how/policy*, PR the repo. Setup complete.
