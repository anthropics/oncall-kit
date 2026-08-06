<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Triage reference: test failures (worked example)

> A worked reference file. The references in this directory show a growth
> gradient — this one and its siblings are the medium shape a few weeks
> in; `deploy-rollout.md` is what a quarter of accreted incidents looks
> like. Your `oncall-setup` Mine phase drafts real ones from your own
> incident history in this same structure. Everything below is fictional
> example content — replace it.

## Symptoms

- Tests failing across unrelated PRs (not just one branch)
- Tests that *should* run silently not running (coverage gap — the quiet one)
- A single test flaking at elevated rate
- CI green locally, red in the pipeline (or vice versa)

## First checks (in order — stop when the timeline explains the symptom)

1. **Scope it.** Metrics source: failure rate by pipeline over the last 6h
   vs. same window yesterday. One pipeline or all? One test or many?
   `(query: {{metrics}} → ci.test.failure_rate by pipeline)`
2. **Timeline.** When did the rate move? List everything that changed in the
   preceding 2h: deploys of CI-infrastructure services, config/flag changes,
   merges to the pipeline definitions, runner-image updates.
   `(sources: {{deploys}}, {{code}} — recent merges to ci/ paths)`
3. **Silent-skip check.** If the report is "tests not running": diff the set
   of tests executed on the last good build vs. the current one. A shrinking
   executed-set with a green pipeline is a skip/filter bug, not a test bug.
4. **Read one failure honestly.** Pull the full log of one representative
   failure from the log store, not just the summary line. Infra failures
   (OOM, timeout, image pull) masquerade as test failures constantly.

## Correlation table

Mined "if you see X and Y, it means Z" rows. Every row carries provenance;
rows marked unverified are hypotheses, not conclusions.

| If you see | And | It usually means | Then |
|---|---|---|---|
| Executed-test count dropped | a skip/filter config or flag changed in the window | the filter change is over-matching — tests silently skipped | propose reverting the filter change; verify executed-count recovers *(seen 3×: INC-101, INC-118, INC-131)* |
| Failures across all pipelines simultaneously | a runner-image or shared-dependency update in the window | environment regression, not test regression | propose pinning the previous image *(seen 2×: INC-107, INC-124)* |
| One test flaking >10% | its history shows flakes clustered on one runner class | resource contention on that runner class | route to runner-infra owner; suggest temporary skip with expiry *(seen 1×, unverified: INC-129)* |
| Green locally, red in CI | test reads wall-clock or network | hermeticity bug in the test | route to test owner via CODEOWNERS; not an infra incident *(seen 2×: INC-112, INC-127)* |

## Known causes

Check `lessons.md` for entries tagged `#test-failures` before theorizing —
the same three causes account for most repeats.

## Escalation

- Broad + blocking merges → this is a page-severity incident per `ONCALL.md`
- Single-test flake → business-hours ping to the owning team, not a page
- Expected resolution window for filter/config reverts: ~30 min. If the
  executed-count hasn't recovered by then, the hypothesis is wrong — go back
  to first checks with the skip-set ruled *in* rather than out.
