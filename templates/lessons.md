<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# lessons.md — the living incident log

<!-- Seeded by oncall-setup Phase 1 from your incident history; appended by
     Claude after every incident without asking (CLAUDE.md rule 8); pruned
     by humans whenever. Newest first, below the status banner. -->

Status: {{one line, kept current — e.g. "quiet week; watching the
runner-image pin from INC-example; next: promote #merge-queue (3
recurrences)"}}

<!-- The banner is the resume point: anyone (or any session) picking this
     file up reads the first five lines and knows where things stand.
     Claude updates it whenever it appends an entry. -->

## Entry formats — three kinds

**Incident entry** (the default — a resolved incident or a died hypothesis):

```
## {{date}} · {{one-line title}} · #{{failure-class-tag}} · {{INC-nnn or thread link}}
- What happened: {{one fresh-reader sentence}}
- Root cause: {{mechanism, with evidence link}}
- Fix: {{what resolved it, who decided}}
- Gotcha / rule: {{the reusable lesson — the reason this file exists}}
```

**Investigation entry** (a long or inconclusive investigation worth its
trail — so no future session re-walks the same dead ends):

```
## {{date}} · Investigation: {{what}} · #{{tag}} · {{thread link}}
| step | result |
|---|---|
| {{check run}} | {{✅/❌ + link}} |
- Checked out on paper: {{everything that SHOULD make it work, each
  verified ✅ — the signature move before declaring a mystery}}
- Could not verify: {{what, why, and the exact one-line command the owner
  should run — hand the human a grep, not a mystery}}
- Rabbit holes eliminated: {{hypothesis → the evidence that killed it}}
- Confidence: {{~N%, and what the remaining % is, named}}
```

**GOTCHA one-liner** (a tool or environment surprise, not an incident):

```
- GOTCHA ({{date}}): {{the surprise, and the rule it implies — one line}}
```

## Graduation

When a tag accumulates **3 entries with the same mechanism**, or an entry
stops being a story and becomes a *procedure* (a checklist someone could
follow cold), promote it into that class's reference file by PR
(CLAUDE.md rule 9) and replace the entries with one pointer line. Record
the promotion itself as an entry — the reference file's provenance points
back here.

---

## 2026-06-30 · Example: retired skip rules resurrected by read-mode flag · #test-failures · INC-example
- What happened: tests that should run were silently skipped after a
  loader's read-mode flag flipped; executed-test count dropped with a green
  pipeline.
- Root cause: dual-read mode surfaced 44 stale rules from a secondary
  store (evidence: executed-set diff, flag-change timestamp).
- Fix: reverted the read-mode flag; executed-count recovered in ~20 min.
  Human-approved revert, teammate executed.
- Gotcha / rule: a *green* pipeline with a shrinking executed-test set is a
  coverage incident, not a quiet day. The sitrep now tracks executed-count.

## 2026-06-22 · Example investigation: deploy-status webhook went dark · #deploy-rollout · thread-link
| step | result |
|---|---|
| webhook config present in template | ✅ (link) |
| receiver endpoint healthy | ✅ (link) |
| receiver auth permits the sender | ✅ on paper (link) |
| a real delivery observed end-to-end | ❌ — none in 6 days |
- Checked out on paper: config, endpoint, permissions — everything that
  SHOULD make it work, each verified ✅.
- Could not verify: what identity actually arrives at the receiver — the
  owner should run: {{one-line log query on the receiver, drafted}}.
- Rabbit holes eliminated: "receiver was down" → uptime graph flat-green
  all week (link); "config reverted" → template history shows no change
  (link).
- Confidence: ~70% the sender's identity is rewritten in transit; the
  remaining 30% is a silent drop between the proxy hops, named in the
  escalation. (Resolved next day — see the worked investigation in
  `skills/triage/references/deploy-rollout.md`, which this entry
  graduated into.)

## 2026-06-14 · Example: theorized from config instead of checking metrics · #process · thread-link
- What happened: an hour spent on a plausible config theory the metrics
  didn't support.
- Root cause: config review before data review.
- Fix: n/a (process lesson).
- Gotcha / rule: query the data first, then theorize. Config tells you what
  *could* go wrong; metrics tell you what *did*. (Promoted to CLAUDE.md
  rule 5.)

- GOTCHA (2026-06-08, example): the team's code-search tool silently
  treats files containing multibyte UTF-8 as binary and returns no
  matches — an hour lost to phantom "reverted" code. When evidence says
  something impossible, suspect the measuring instrument first.
