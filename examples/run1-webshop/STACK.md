<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# STACK.md — capability → connection map (fictional example)

<!-- FICTIONAL — example artifact. Written at the Phase 0 gate. -->

Generated: 2026-06-02 · Channel: #checkout-oncall · Probed by: oncall-setup

| Capability | Bound to | Probe result | Notes |
|---|---|---|---|
| `metrics` | the Grafana connection | ✅ listed dashboards; read checkout.* series | key dashboards: "Checkout funnel", "Payments SLO" |
| `logs` | the CloudWatch Logs connection | ✅ ran a test query | groups: /svc/checkout, /svc/webhook-relay |
| `pager` | the Opsgenie connection | ⚠️ read last 5 incidents OK; listing services 403'd | read-only key lacks service scope — gap below |
| `code` | the GitHub connection | ✅ read CODEOWNERS, recent PRs | repos: shop/checkout, shop/webhook-relay |
| `alert-channels` | #payments-alerts, #checkout-oncall | ✅ member of both | #payments-alerts is automated-only |
| `deploys` | #releases channel | ✅ readable | release bot posts start/finish per service |
| `incidents` | threads in #checkout-oncall | ✅ can read + post to records | humans declare with a "🔴 INC:" thread |

## Gaps

- `pager` service listing 403s → routing tree uses Slack group handles, not
  pager escalation policies. Fix: scope the key, then regenerate this file.
- No synthetic-checkout probe connected → the sitrep reports real-traffic
  signals only; quiet-hours degradation may be detected late. Accepted for
  now (Interview, 2026-06-02).

## Access posture

All bindings are read-only except: none.
