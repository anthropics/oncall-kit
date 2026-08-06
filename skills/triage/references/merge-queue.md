<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Triage reference: merge-queue (worked example)

> Fictional example content in the kit's webshop-CI universe — your
> `oncall-setup` Mine phase drafts the real one from your own incident
> history in this structure: Symptoms · First checks · Correlation table
> (every row with provenance) · Known causes · Escalation. Delete this
> file if your on-call doesn't have this failure class.

## Symptoms

- PRs stuck in the queue; queue depth growing
- Queue moving but slowly (wait time elevated, throughput normal-ish)
- Queue empty but merges still not landing on the target branch
- One PR cycling: repeatedly evicted and re-queued

## First checks (in order — stop when the timeline explains the symptom)

1. **Depth vs. throughput.** Depth growing with normal throughput is an
   arrival wave; depth growing with falling throughput is a real stall.
   `(query: {{metrics}} → mq.depth, mq.merges_per_hour, last 6h vs yesterday)`
2. **Is the head stuck?** The queue processes in order — one unmergeable
   head PR looks like a systemic stall. Check the head PR's own status
   and how long it's held position.
3. **Timeline.** What changed in the window: pipeline-definition merges,
   CI-infra deploys, flag ramps, runner capacity events.
   `(sources: {{deploys}}, {{flags}}, {{code}})`
4. **Merge wave check.** High commits/hr with the latest trunk build
   finished green is a wave, not an incident — say so and stop. If that
   build is still running, you don't know yet: absence of failures on an
   unfinished build proves nothing.

## Correlation table

| If you see | And | It usually means | Then |
|---|---|---|---|
| Depth growing, throughput near zero | head PR failing the same required check repeatedly | stuck head — one PR masquerading as a systemic stall | propose evicting the head PR (human acts); depth should drain at the usual rate *(seen 3×: INC-104, INC-116, INC-126)* |
| Wait time elevated across the board | runner queue age also elevated | capacity, not the queue — route to runner-infra | load `runner-infra.md`; don't tune the queue *(seen 2×: INC-109, INC-121)* |
| Queue drains but target branch doesn't advance | the post-merge pipeline (not the queue) is failing | the queue did its job; the stall is downstream | investigate the target branch's pipeline as its own incident *(seen 1×: INC-130)* |
| One PR evicted repeatedly | its base is racing a high-merge-rate window | rebase churn — the PR keeps going stale mid-flight | suggest the author merge during a quieter window; not an infra incident *(seen 1×, unverified: INC-119)* |

## Known causes

Check `lessons.md` for entries tagged `#merge-queue` before theorizing.

## Escalation

- Queue fully stalled and depth climbing → page-severity per `ONCALL.md`
- Elevated wait during a visible merge wave → morning log, no page
- Expected resolution window after evicting a stuck head: one queue cycle
  (~15 min). If depth doesn't start draining, the head wasn't the cause —
  back to first checks with capacity ruled in.
