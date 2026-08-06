<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# ONCALL.md — standing on-call policy

<!-- Copy to your repo root. Every {{...}} is filled during oncall-setup
     Phase 2 (Interview). Mined suggestions may appear as comments; a human
     sets every policy value. This file is policy: changes go by PR. -->

## What this covers

{{one paragraph: the system this on-call owns, in fresh-reader language, and
the channel it runs in}}

Incident severity levels, incident command, and stakeholder communications
remain your team's existing incident-management process — this kit plugs
into that process and does not replace it: {{link to your incident
process / severity definitions}}. Claude never runs an incident and never
communicates to stakeholders beyond this channel.

## Incident records

An incident exists when a human declares one: {{how, e.g. "start a thread
here beginning 🔴 INC:" / "tag the pager incident ci-infra" — must match
the `incidents` binding in STACK.md}}. Claude may propose that something
deserves an incident; it never declares one itself.

## Incident lifecycle

Four states. `active` and `stale` are the open pair — stale means "this
looks abandoned: fixed-but-never-closed, or genuinely dropped," a
nobody's-watching alarm, not a closure. `mitigated` (fix in, still
watching) and `resolved` (done) are the closed pair; keep them distinct.
An archived or deleted incident channel/thread means resolved regardless
of what its frozen text says — nobody works an incident in a place that
no longer exists. Claude never changes a state (rule 2); it applies these
rules when deciding what to *report*:

- **Stale takes three legs, never silence alone:** (1) the record/thread
  quiet ≥ {{24h}}; (2) nothing in the alert channels naming it in the last
  hour; (3) its specific symptom absent from current data — and leg 3
  only counts if the relevant run/window actually *completed* ("not
  failing yet" ≠ "passing"). If your checks can't see the incident's
  actual symptom, don't call it stale — a healthy proxy covers only the
  path it measures ("checkouts are flowing" proves the checkout path, not
  the whole payment provider). Every "looks stale" nudge carries its
  one-line evidence ("thread quiet 26h; merges flowing; no related
  alerts").
- **Promotions climb a ladder; demotions don't.** Suggesting a stale or
  closed incident is live again requires evidence **newer than the
  verdict it would overturn** — and your own earlier posts, or re-reading
  an unchanged status line, never count as activity (or your sweep keeps
  every zombie alive forever). Treating an incident as *quieter* may rest
  on older evidence: a wrong "quieter" is cheap to fix; a wrong
  resurrection is the failure mode this ladder exists to prevent.
- **No verdict is a verdict.** "Mitigated?" with a question mark,
  "duplicate of INC-…", an unparseable status line: none of these changes
  what you report. Absent evidence never moves state. And someone
  *asking* "any update?" is a question, not an update — don't let it
  reset the quiet clock.
- **Zombie sweep:** the morning sitrep lists every open incident with no
  update in {{24h}}, and the weekly handoff lists those quiet {{72h}} —
  "record still says active, thread silent since yesterday: close it or
  update it."

## Paging policy

Deterministic alerts page humans directly — always. Claude is never in
the detection path. These criteria serve two purposes: they are the
values Claude uses when **proposing** deterministic rules (starter rules
for new services, tuning proposals after incidents), and they define
page-severity for **Claude's own findings** during triage (a correlation
discovery, an unalerted symptom) — with every page/no-page decision
logged per CLAUDE.md rule 3a. Written in plain English on purpose —
judgment clauses like "not during a known deploy window" are allowed.

**New services** get conservative starter rules before launch — proposed
by Claude by analogy to the closest existing service, installed by a
human — never a monitoring routine. Coarse rules that cannot die
silently beat clever monitoring that can.

| Signal | Page when | Sustain | Exempt when |
|---|---|---|---|
| {{e.g. pipeline error rate}} | {{> N%}} | {{M min}} | {{known deploy window; see Deploy windows}} |
| {{…}} | {{…}} | {{…}} | {{…}} |

<!-- Worked example (the fictional webshop CI team) — replace every value:
| Signal | Page when | Sustain | Exempt when |
|---|---|---|---|
| pipeline error rate | >2% | 5 min | inside a posted deploy window (see Deploy windows) |
| merge-queue p90 wait | >45 min | 15 min | merge wave: >30 commits/hr AND latest trunk build finished green |
| executed-test count | drops >10% vs last good build | 1 build | never — a green pipeline running fewer tests is a coverage incident, not a quiet day |
| trunk blocked by the auto-revert system | any | 30 min | never |
Everything below these lines → lessons.md for the morning sitrep.
Note the merge-wave exemption: absence of failures only counts on a
FINISHED build — an unfinished green build proves nothing. -->

Anything observed that does **not** trip these criteria: log to `lessons.md`
for the morning sitrep instead (CLAUDE.md rule 3).

## Severity norms

- **Page** (any hour): {{definition}}
- **Business-hours ping**: {{definition}}
- **Morning log line**: everything else

## Deploy windows

How to check whether a deploy is in progress: {{the `deploys` capability
binding, a channel, a calendar — name it}}

## Routing tree

<!-- Drafted by Mine phase from CODEOWNERS × who-actually-responded;
     conflicts resolved in Interview. Group handles must be real. -->

| Failure class | Owner | Notes |
|---|---|---|
| {{test-failures}} | {{@group}} | {{…}} |
| {{merge-queue}} | {{@group}} | {{…}} |
| {{runner-infra}} | {{@group}} | {{…}} |
| Anything company-blocking | {{@escalation}} | escalate immediately |

Claude mentions an owner only when this tree names one for the diagnosed
class (CLAUDE.md rule 12).

**Escalation timeout:** a page-severity finding with no human
acknowledgment within {{N minutes}} escalates to {{next handle up the
ladder}}. An acknowledgment is an explicit affirmative from a person
("ack", "on it", or {{designated reaction}}) — bot posts, alert traffic,
and passive emoji don't count. One escalation only — never a loop.
**Terminal step** if the escalation also goes unacked: {{repeat-page via
the pager's escalation policy / post to #wider-channel / accepted
"unattended until morning" posture — the team chose deliberately}}.

The ladder has more states than "paged" and "resolved" — each gets a
`paging-log.md` line:

- **Ack-then-silence:** acked, then nothing for {{30 min}} while the page
  condition persists → one (and only one) in-thread nudge naming the
  still-firing signal. Never re-page an acked incident on your own.
- **Re-fire after ack:** the signal cleared and tripped again → a *new*
  paging decision with a new log entry; the old ack doesn't cover a new
  firing.
- **Page unconfirmed:** the page call returned success but the pager
  shows no incident within {{2 min}} → treat as page-failed and take the
  fallback path, noting both in the log.
- **Two page-severity findings at once:** two pages, two entries — unless
  correlation says one cause, in which case one page naming both symptoms
  (triage step 3b).

**Fallback alerting:** if a page-severity finding cannot page (no pager
bound, or the page call fails), Claude instead {{@-mentions @escalation
in this channel / posts to #always-watched-channel / holds for the
morning log}}. Chosen in the Interview; never improvised mid-incident.
Known limitation the team accepted: Slack @-mentions don't penetrate
Do-Not-Disturb — an @-mention fallback is business-hours-grade coverage.

**Out-of-band path (Slack itself down):** {{human-owned note: where the
team coordinates when Slack is unavailable — e.g., the pager's own
incident notes + a video-call bridge. Claude can't help here; this line
exists so the team decides this before an outage, not during one.}}

## Alert-rule proposals

Format: proposals are paste-ready {{monitor JSON / Terraform / PromQL /
UI steps}} for {{alerting tool}} — never prose.
Install mode: {{**human installs** (default — Claude drafts, a human
pastes; kit stays fully read-only) / **alert-editor extension** (opt-in:
Claude may CREATE new rules after per-rule approval in the channel;
additive only — never modify, delete, or silence an existing rule; every
write logged to lessons.md; credential noted in STACK.md)}}.

## Read-only guarantee

This agent never changes the state of any monitored system. Its only
outputs are: messages in the channel; entries in the repo's log files
(`lessons.md`, `paging-log.md`, `eval/shadow-log.md`); updates to the
bound weather report page (only if opted in above); proposed diffs as
PRs; and (where a pager is bound) pages. There is no allowlist
and nothing to configure in this section — it exists so every reader of
this policy knows the contract. All mitigation is performed by humans.

## Status on demand — and the optional weather report

Default: no standing status service. When someone asks for status, answer
from the open incident records plus these health signals: {{e.g.
merge-queue depth, deploy lag on critical branches, error rates}}.
Fresh-reader rules apply (CLAUDE.md rule 10).

Opt-in: the `weather` skill (routine 6 in `templates/routines.md`) — an
event-gated standing report. {{not opted in (default) / opted in on
{{date}}; report page: {{canvas link / repo file}}; cadence targets set
in Interview}}.

If opted in, the mood tier boundaries — set in Interview, read by the
weather skill, never invented by it (CLAUDE.md rule 15):

| Tier | {{base signal 1, e.g. deploy freshness}} | {{base signal 2, e.g. trunk health}} |
|---|---|---|
| sunny | {{< 1h}} | {{trunk green, nothing blocked}} |
| partly_cloudy | {{1–2h}} | {{latest trunk build failing < 30 min}} |
| overcast | {{2–4h}} | {{failing or blocked 30 min–2h}} |
| stormy | {{> 4h}} | {{blocked > 2h}} |

## Handoff and sitreps

Weekly handoff cadence: {{e.g. Mondays 8am ET}} · Posted to: {{channel}}
Morning sitrep: {{off (default) / weekdays {{8:30am TZ}}}} — reads
`paging-log.md`, `lessons.md`, and the open incident records; posts
nothing when there is genuinely nothing.
