<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# routines.md — the paste-ready standing work

<!-- Filled in by oncall-setup Phase 4 with your channel names, cadences,
     and STACK.md bindings. A HUMAN pastes each into the channel — the kit
     never installs standing work the channel didn't see. Order matters:
     read-only routines first; paging last, after the shadow period. -->

Routines are thin on purpose: they decide *when and where*; the skills and
ONCALL.md decide *how*. If you're tempted to put a threshold or a format
into a routine, stop — that's policy, PR it into the repo instead.

Include a timezone in every schedule ("9am {{TZ}}"), or it defaults to UTC.

## What this costs (read once)

Standing work is where agent token spend lives; this kit is built to keep
it low. The handoff is weekly. The alert-watch routine is event-driven —
it costs nothing when nothing fires, and storms are batched into one
triage. There are **no fast-polling items**. Verification after
a fix is three bounded checks, not a polling loop. The one thing YOU
control that dominates cost: which channels the watch routine covers
(don't watch high-volume channels whose alerts are rarely actionable —
fix those alerts first).

There is deliberately no *polling* status service. The optional weather
routine below is a deterministic cadence guard in front of an
event-gated compose step: the
schedule fires often, but most firings are a two-read early-exit that
posts nothing and costs a few hundred tokens. The channel only hears
about *events*; the report page absorbs everything else.

Rough token anchors so you can budget (model- and stack-dependent —
treat as order-of-magnitude, and **measure during your pilot**, which is
what the spend limit is for): a single triage ≈ 30–100k tokens
(page-severity with parallel fan-out can be several ×); the weekly
handoff ≈ 50–150k; a quiet week ≈ one handoff; weather ≈ 2–5k per full
cycle and ~0.3k per early-exit — a quiet day is a handful of full cycles.
Convert at your model's current pricing.

## How detection is wired (read before pasting)

Your existing deterministic alerting stays the source of truth: PagerDuty
(or equivalent) fires alerts into your alert channels, and page-worthy
alerts page humans directly, exactly as before. **Claude is never in the
detection path** — its standing role is to watch the alert channels and
triage what fires (routine 2). Its role in detection itself is
propose-and-tune only: starter rules for new services (below), coverage
gaps and tuning from the post-incident loop — always installed by humans
into the real alerting tool, where they cannot die silently.

## 1 · Weekly handoff (read-only)

```
@Claude every {{Monday at 8am {{TZ}}}}, run the handoff skill from the repo
for the past week and post the result here.
```

## 2 · Watch alert channels → triage (posts diagnoses)

<!-- During the shadow period, change "post ... in its thread" to
     "post ... in {{#review-channel}}" and grade daily per eval/replay.md. -->

```
@Claude watch {{#alerts-channel-1}} and {{#alerts-channel-2}}. When a new
alert lands, run the triage skill from the repo and post the diagnosis in
its thread — correlate across channels first, per the skill. If several
alerts land together or relate to an open incident, triage them as one
batch per the skill: one diagnosis naming every alert it accounts for,
never one post per alert. Propose fixes only — never execute anything.
```

## 3 · New service? Starter alerts, not a bridge

There is no standing routine for new services — detection is always
deterministic. Before (or at) launch, ask in the channel:

```
@Claude {{service}} launches soon and has no alerts. Propose conservative
starter rules — borrow thresholds from our closest existing service's
mined values plus standard defaults — paste-ready for {{alerting tool}},
for a human to install before launch.
```

A human installs them; the post-incident loop (triage's "would a rule
have caught this earlier?" + the alert-coverage report) tunes them from
the first real incident onward.

## 4 · Routine registry (Claude curates; paste once)

```
@Claude maintain the "Standing work in this channel" canvas (or pinned
note): whenever a routine here is created, edited, promoted from shadow,
or disabled, update the registry — each routine's name, schedule, one-line
purpose, live/shadow status, and last-changed date. End it with: "to
change when/where, edit the routine here; to change how/policy, PR
{{repo}}."
```

## 5 · Morning sitrep (weekdays, read-only)

```
@Claude every weekday at {{8:30am {{TZ}}}}: read paging-log.md and the
lessons.md entries since the last sitrep, plus the open incident records,
and post at most 6 lines: each open incident (state + one-line story a
fresh reader can land on), yesterday's log-tier observations worth a
human eye, and any zombie (open, silent >{{24h}} — per ONCALL.md's
lifecycle rules, with the three-leg evidence line). If there is genuinely
nothing — no open incidents, no log-tier entries — post nothing at all.
```

## 6 · Weather report (opt-in — read the cost paragraph first)

```
@Claude every {{10 min}}, run the weather skill from the repo. Its Phase 0
is the cadence guard — target gap {{10 min}} when a page-severity incident
is open, {{60 min}} when quiet — so most firings exit in two reads. Post
to this channel only when one of the skill's gates fires; update the
{{report canvas / repo file}} every full cycle regardless.
```

The schedule interval is the *tightest* cadence you ever want; the guard
inside the skill decides whether a firing does anything. Never set the
schedule slower than the fastest target gap, or a page-severity incident
can't get its tight cadence.

## Managing these

In the channel: "what routines are set up here?" · describe an edit ·
"disable the {{Friday rollup}}". Anyone in the channel can do all
three — that's by design. The registry canvas is the at-a-glance version
of the same answer; the weekly handoff's drift check verifies it still
matches what's actually installed. For current status, anyone can simply
ask in the channel ("@Claude what's the state of things — safe to
merge?") — on-demand answers need no standing routine.
