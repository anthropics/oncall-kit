<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# ONCALL.md — standing on-call policy (example: #checkout-oncall)

<!-- FICTIONAL — example artifact. Filled at the Interview gate
     2026-06-02; amended by PR since (weather opt-in 2026-07-06). -->

## What this covers

The checkout and payments path of the web shop: the checkout service, the
payment-processor integrations, and the webhook relay that fans out order
events. Runs in #checkout-oncall.

Incident severity levels, incident command, and stakeholder communications
remain the company incident process (see the incident-response handbook);
this kit plugs into it. Claude never runs an incident and never
communicates to stakeholders beyond this channel.

## Incident records

An incident exists when a human declares one: a thread in #checkout-oncall
beginning `🔴 INC:` (matches the `incidents` binding in STACK.md). Claude
may propose that something deserves an incident; it never declares one.

## Incident lifecycle

Four states per the kit's lifecycle rules (see `templates/ONCALL.md` for
the full text): `active`/`stale` open, `mitigated`/`resolved` closed.
Windows set in Interview: stale nudge after **24h** quiet (three-leg
evidence required); handoff zombie list at **72h**. Humans move all
states.

## Paging policy (set in Interview, 2026-06-02)

| Signal | Page when | Sustain | Exempt when |
|---|---|---|---|
| checkout error rate | > 2% | > 5 min | inside a posted deploy window (then: log + watch; page anyway at > 5% or > 15 min) |
| card decline rate | > 2× same-hour 7-day baseline | > 10 min | processor status feed already declares an incident → post to the existing thread instead of paging |
| webhook relay queue age | > 120 s | > 10 min | nightly import window 02:00–03:00 UTC |
| checkout p95 latency | > 1.8 s | > 10 min | — |

Below page tier → append to `lessons.md` for the morning log. Ambiguity
resolves per CLAUDE.md rule 3: toward paging on the page tier, toward the
log on the log tier.

## Severity norms

- **Page** (any hour): checkout down or degraded for real users now —
  any row above
- **Business-hours ping**: single-processor oddity with failover healthy;
  elevated-but-under-threshold trends
- **Morning log line**: everything else

## Deploy windows

The release bot posts start/finish per service in #releases (the
`deploys` binding). A window is open between a start and its finish, or
30 min after a start with no finish (assume stuck — that's its own
incident).

## Routing tree (conflicts resolved in Interview: who-actually-responds won)

| Failure class | Owner | Notes |
|---|---|---|
| card-declines | @risk-eng | CODEOWNERS said @payments-core; threads showed @risk-eng responding — resolved 2026-06-02 |
| webhook-lag | @payments-core | |
| checkout-latency | @payments-core | CDN-config causes route to @web-platform |
| Anything company-blocking | @eng-escalation | escalate immediately |

**Escalation timeout:** page-severity finding unacked for **15 min** →
escalate once to @eng-escalation. Ack = a reply or 👀 from a person in
the incident thread; bot posts don't count. One escalation only — never a
loop. **Terminal step** if the escalation also goes unacked: an
`[UNACKED]`-prefixed @here in #checkout-oncall with the
rabbit-holes-eliminated list attached.

Partial states (each gets a `paging-log.md` line): a pager-ack with no
thread activity for **30 min** while the condition persists gets one (and
only one) in-thread nudge naming the still-firing signal — never a
re-page; a signal that cleared and re-fired is a **new** paging decision;
a page call that "succeeded" with no pager incident visible within
**2 min** takes the fallback path.

**Fallback alerting** (no pager reachable): @-mention @eng-escalation in
#checkout-oncall. Accepted limitation: @-mentions don't penetrate DND —
this is business-hours-grade coverage, chosen knowingly.

**Out-of-band path (Slack down):** the pager's own incident notes + the
bridge line in the incident-response handbook. Decided 2026-06-02.

## Alert-rule proposals

Format: paste-ready Grafana alert-rule YAML. Install mode: **human
installs** (default — the kit stays fully read-only).

## Read-only guarantee

This agent never changes the state of any monitored system. Its only
outputs are: messages in the channel; entries in the repo's log files
(`lessons.md`, `paging-log.md`, `eval/shadow-log.md`); updates to the
"Checkout weather" canvas (opted in 2026-07-06); proposed diffs as PRs;
and pages. All mitigation is performed by humans.

## Status on demand — and the weather report

Status-on-demand from the open incident records plus: checkout error
rate, decline rate vs baseline, relay queue age, p95 latency.

Weather routine: **opted in 2026-07-06** (month two — see the run
README). Report page: the "Checkout weather" canvas in #checkout-oncall.
Cadence targets: 10 min with a page-severity incident open / 20 min with
any incident open / 60 min quiet.

Mood tier boundaries (set 2026-07-06; the weather skill reads these,
never invents them):

| Tier | checkout error rate | decline rate vs 7-day same-hour baseline |
|---|---|---|
| sunny | < 0.5% | < 1.3× |
| partly_cloudy | 0.5–1% | 1.3–1.8× |
| overcast | 1–2% | 1.8–2.5× |
| stormy | > 2% | > 2.5× |

## Handoff and sitreps

Weekly handoff: Mondays 9am ET → #checkout-oncall.
Morning sitrep: weekdays 8:30am ET; posts nothing when empty.
