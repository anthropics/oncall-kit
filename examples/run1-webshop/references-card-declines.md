<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Triage reference: card declines (fictional example)

<!-- FICTIONAL — example artifact. Drafted by oncall-setup Phase 1 from 14
     incidents, 2026-04 → 2026-06. Amended once after replay (see repo
     README): processor-status check moved ahead of deploy correlation. -->

## Symptoms

- Decline rate above baseline on the "Payments SLO" dashboard
- Support reports of "card doesn't work" clustering in time
- Checkout conversion dip with flat traffic

## First checks (in order)

1. **Scope.** `metrics`: decline rate by processor, by card network, by
   region — one slice or all? *(one processor ≈ upstream; all ≈ us)*
2. **Upstream status first.** Check the processor's status feed BEFORE
   correlating with our deploys — two past incidents were coincidental with
   deploys and misattributed. *(added after replay ❌, 2026-06-02)*
3. **Timeline.** Onset vs. `deploys` (#releases) window and any risk-rule
   changes *(seen: risk-rule pushes don't post to #releases — check the
   rules changelog explicitly)*.
4. **Read declines honestly.** `logs`: sample 20 decline reasons — issuer
   declines vs. gateway errors vs. our own risk rejections are three
   different incidents.

## Correlation table

| If you see | And | It usually means | Then |
|---|---|---|---|
| One processor's declines spiked | its status feed shows degradation | upstream outage | propose failover per runbook; route @payments-core *(seen 5×: INC-311, 318, 322, 340, 347)* |
| Declines up only for one card network | issuer-decline codes dominate | issuer-side event, not ours | comms to support, no code action *(seen 3×: INC-315, 329, 351)* |
| Our risk rejections spiked | a risk-rule change in the window | rule over-matching | propose rule rollback; route @risk-eng *(seen 4×: INC-320, 331, 338, 344)* |
| Gateway 5xx mixed with declines | checkout deploy in window | our regression presenting as declines | treat as deploy-rollout class instead *(seen 2×: INC-325, 342)* |

## Known causes

`lessons.md` tag: `#card-declines` (14 entries).

## Escalation

- Sustained decline-rate breach per ONCALL.md → page severity
- Routing: upstream/gateway → @payments-core · risk rules → @risk-eng
  *(threads showed @risk-eng responding; CODEOWNERS disagreed — resolved in
  Interview, 2026-06-02)*
- Expected window: failover ~15 min; rule rollback ~10 min. Blown window →
  the classification is wrong; re-run first checks with the ruled-out
  branches back in.
