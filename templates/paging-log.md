<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# paging-log.md — {{YYYY-MM}}

<!-- Appended by Claude on EVERY page/no-page decision (CLAUDE.md rule 3a).
     Rotate monthly: move to paging-log/{{YYYY-MM}}.md, start fresh. This
     file is the tuning data for alert-gardening (post-incident rule
     proposals) and the source for the handoff's on-call-health and
     intake-health numbers. -->

Entry format:

```
## {{ts}} · {{signal}} · DECISION: {{page @handle / no-page → morning log}}
- Values: {{error rate 3.4%, sustained 7 min (threshold >2% / 5 min)}}
- Clause: {{which paging-table row tripped, or which exemption applied
  ("deploy window 10:00–10:20 — exempt")}}
- Ambiguity: {{none / "borderline — resolved toward paging per the
  tier-ambiguity rule, because …"}}
- Ladder: {{paged 02:14 → acked 02:19 by a human / no ack by {{02:29}} →
  escalated once to @{{group}} → terminal step taken: {{…}}. Partial
  states get their own lines: ack-then-silence nudge, re-fire-after-ack
  (new decision, new entry), page-unconfirmed → fallback path.}}
- Links: {{alert, thread, incident record}}
```

---

<!-- entries append below, newest first -->
