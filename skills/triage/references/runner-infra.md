<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Triage reference: runner-infra (worked example)

> Fictional example content in the kit's webshop-CI universe — your
> `oncall-setup` Mine phase drafts the real one from your own incident
> history in this structure: Symptoms · First checks · Correlation table
> (every row with provenance) · Known causes · Escalation. Delete this
> file if your on-call doesn't have this failure class.

## Symptoms

- Jobs queued but not starting; queue age climbing
- Jobs starting then dying mid-run (OOM, disk, network)
- One runner class unhealthy while others are fine
- Capacity errors from the cloud provider (instance type unavailable)

## First checks (in order — stop when the timeline explains the symptom)

1. **Scope by runner class.** All classes or one? One class points at its
   image, instance type, or pool config; all classes points at the
   scheduler or the provider.
   `(query: {{metrics}} → runner.queue_age by class, runner.available by class)`
2. **Provider stockout check.** Capacity errors from the provider mean
   the machine type is unavailable — builds are slow, not broken. This is
   an *overcast* fact to communicate, not a bug to fix.
   `(query: {{logs}} → provisioning errors, last 2h)`
3. **Timeline.** Runner-image updates, pool-size changes, scheduler
   deploys in the window.
   `(sources: {{deploys}}, {{code}} — runner-image and pool config paths)`
4. **Read one dead job honestly.** Full log, not the summary. OOM and
   disk-full masquerade as test failures and as "runner flakiness"
   equally well.

## Correlation table

| If you see | And | It usually means | Then |
|---|---|---|---|
| Queue age climbing, available count normal | scheduler deploy in the window | scheduler regression — capacity exists but isn't being assigned | propose rolling back the scheduler deploy *(seen 1×: INC-113)* |
| One class OOMing | its image updated in the window | the new image raised memory floor | propose pinning the previous image; route to image owner *(seen 2×: INC-108, INC-122)* |
| Provider capacity errors | one instance type only, others fine | stockout — provider is out of that machine type | communicate (overcast, not stormy); propose a fallback instance type if policy names one *(seen 2×: INC-111, INC-128)* |
| A capacity chart flatlines after every deploy | the metric emits one series per pod and a consumer reads the first series | the consumer is reading a dead pod's last minutes, not the live fleet | aggregate across series (max/sum) at the query, never index into the series list *(seen 1×: INC-149)* |
| Jobs dying at a consistent wall-clock time | a cron (cleanup, image GC) fires at that time | the cron is killing or starving live jobs | correlate the cron schedule; propose rescheduling it *(seen 1×, unverified: INC-125)* |

## Known causes

Check `lessons.md` for entries tagged `#runner-infra` before theorizing.

## Escalation

- All classes down or queue age blocking every merge → page-severity per
  `ONCALL.md`
- Provider stockout → business-hours ping + status communication; paging
  won't make machines exist
- Expected resolution window for an image pin: one pool-recycle (~20
  min). If jobs still die on the pinned image, the image wasn't the
  cause — back to first checks with the scheduler ruled in.
