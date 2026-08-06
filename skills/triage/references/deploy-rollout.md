<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Triage reference: deploy-rollout (deep worked example)

> This file shows what a reference looks like **after a quarter of
> incidents** — yours starts thinner (the other references in this
> directory show the medium shape) and grows by PR as `lessons.md`
> entries graduate into it. Everything below is fictional example content
> in the kit's webshop-CI universe — replace it.
> The extracted-rules section at the bottom is the part of the
> *structure* worth reproducing verbatim — it's where a class's hard-won
> lessons end up once your own incidents pay for them.

## Symptoms

- A deploy is stuck: pipeline says "in progress" far past the usual window
- Post-deploy regression: error rate / latency moved right after a rollout
- Deploy-notification silence: the deploys feed went quiet but changes are
  clearly landing (or the reverse — deploys stopped and nobody was told)
- Config that "reverted itself": a manual fix vanished within hours
- A rollout ramp is misbehaving: canary looks fine but the full ramp
  doesn't, or the ramp stalled between steps

## First checks (in order — stop when the timeline explains the symptom)

1. **Timeline first.** From the `deploys` feed and `flags` change history:
   everything that changed in the 2h before onset — deploys, flag ramps,
   config template changes, infra rollouts. The symptom's onset minute is
   the most discriminating fact you will get all incident; pin it from
   metrics before reading any thread.
   `(sources: {{deploys}}, {{flags}}, {{metrics}})`
2. **Is the deploy pipeline itself healthy?** Distinguish "our change is
   bad" from "the deploy machinery is bad": check the deploy system's own
   error rate and queue, not just your service's.
   `(query: {{metrics}} → deploy.pipeline.state, deploy.queue.age)`
3. **What does the receiver see?** For any "A stopped talking to B"
   symptom (webhooks, notifications, callbacks): read B's access log for
   A's calls *before* theorizing about A. No entries at all is a different
   incident than entries with errors — and the single most common finding
   is a 403 whose identity surprised everyone (see the worked
   investigation below).
   `(query: {{logs}} → receiver access log, filtered to the sender's path)`
4. **Manual-fix-vanished check.** If a human's hand-applied mitigation
   disappeared: check whether deployment automation re-applied its
   template over the manual change. Automation undoing a manual mitigation
   is a recurring cause worth its own check, not a footnote — and it means
   the *durable* fix must land in the template, with the manual path used
   only to buy time.
   `(sources: {{deploys}} — template apply events around the vanish time)`
5. **Read one failure honestly.** Full log of one representative failed
   deploy from the log store, not the summary line. Deploy "failures" are
   frequently admission/policy rejections or quota errors masquerading as
   code problems.

## Correlation table

| If you see | And | It usually means | Then |
|---|---|---|---|
| Deploy "succeeded" but the downstream notification never fired | every prior "end-to-end" test injected downstream of the sender | you have never actually tested the sender — treat the pipeline as unverified from the front door | test from the true entry point before trusting any component *(seen 1×: INC-142; cost 3 false "verified" claims)* |
| Receiver returns 403 on a call that "has the right permissions" | the caller authenticates through a proxy or impersonation hop | the receiver sees the LAST hop's identity, not the originator's — ask "what principal actually arrives?", not "what did I configure?" | pull the receiver's auth log and read the actual identity; fix the grant for that principal, scoped to the one path it needs *(seen 1×: INC-142)* |
| A hand-applied config fix vanished within hours | deployment automation manages that config from a template | automation re-applied the template over the manual change | move the fix into the template; note the manual path buys time only until the next apply *(seen 2×: INC-137, INC-151)* |
| Evidence says something impossible ("the merged fix isn't in the file") | you read it through a cache, a contents API, or a search tool | suspect the measuring instrument before the system: caches serve stale reads; some search tools silently skip files they mis-detect as binary | pin reads to a commit SHA; re-run the search with detection quirks ruled out *(seen 2×: INC-142, INC-155)* |
| Deploy queue drains but a monitoring chart flatlines after every deploy | the metric emits one series per pod and a consumer reads the first series | the consumer is reading a dead pod's last minutes, not the live system | aggregate across series (max/sum) at the query, never index into the series list *(seen 1×: INC-149)* |
| Post-deploy regression, but the deploy diff looks unrelated | a flag ramp advanced in the same window | the flag, not the deploy — the two change feeds are read together or not at all | check `flags` history for the window before blaming the deploy *(seen 2×: INC-133, INC-146)* |
| Rollout stalled between canary and full | the ramp gate reads a metric that stopped emitting (not a metric that went red) | the gate fails closed on missing data — the ramp is waiting on a signal that will never arrive | fix the signal or have a human explicitly decide the step; never treat "no data" as "healthy" *(seen 1×, unverified: INC-158)* |
| Deploys stopped fleet-wide, deploy system healthy | an org-wide policy/admission change in the window | an enforcement layer is rejecting what it used to accept — enforcement fails closed | read the admission log for the named policy; route to the policy owner with the exact rejection line *(seen 1×: INC-144)* |
| "Retry the deploy" fixed it | nothing else changed | you have a race or a dependency blip, not a fix — it will be back | log it as unresolved in lessons.md with the retry noted; a retry that works is evidence, not resolution *(seen 3×: INC-135, INC-140, INC-153)* |
| The deploy that "caused" it happened after the metric moved | onset was pinned from a thread, not from data | human memory dated the onset wrong — re-pin from metrics | re-run the timeline from the metric's first bad minute *(seen 2×: INC-139, INC-146)* |

## A worked long investigation (journal style)

The incident that produced half the rows above — INC-142, "deploy-status
webhook went dark." Kept here because the *shape* of the investigation
recurs even when the specifics don't.

**Symptom.** The channel that announces deploys went silent on {{a
Tuesday}}; deploys themselves kept landing. Noticed by a human six days
in ("why is this feed so quiet?") — no alert existed for feed silence.

**Paper checks — everything that SHOULD make it work, each verified ✅:**

| check | result |
|---|---|
| webhook URL present in the deploy system's config template | ✅ |
| receiver endpoint up (uptime graph flat-green all week) | ✅ |
| receiver's auth config lists the deploy system's service account | ✅ |
| last template apply succeeded | ✅ |

Everything green on paper, zero deliveries observed. This table is the
signature move: when it's all-✅ and the thing still doesn't work, stop
re-checking config and go read what actually arrives.

**The first humbling finding.** "It worked in the end-to-end test" —
except every prior e2e test had injected a payload *downstream* of the
sender ("simulate what the webhook would send"), because triggering a
real deploy in a test was inconvenient. The sender had never been
exercised. Three separate "verified ✅" claims in the thread traced back
to tests that bypassed the one component that was broken.

**The evidence detour.** Mid-investigation, the code search said the
webhook-send call "wasn't in the file" on the deployed revision —
impossible, it was in the template history. The search tool had silently
skipped the file (mis-detected as binary); a SHA-pinned read showed the
call present all along. An hour lost to the instrument, not the system.

**Root cause.** The receiver's access log — the check that should have
been step 3, run on day one — showed the calls arriving all along and
being rejected 403. The deploy system authenticates through a forwarding
proxy, and the receiver sees the *proxy's* service identity, not the
deploy system's. The grant listed the originator; the principal that
actually arrived was never granted. Fixed with a grant for the proxy's
identity, deliberately scoped to the single webhook path — the narrow
scope is a security decision, not a convenience.

**Verification — through the same door.** Not a unit test of the grant: a
real deploy, triggered from the true entry point, observed end-to-end
into the channel. Then a starter alert on feed silence (>24h with deploys
landing), so the next regression is caught by a rule, not a bored human.

## Known causes

Check `lessons.md` for entries tagged `#deploy-rollout` before
theorizing.

## Proposing a flag ramp (resolution pattern — human executes)

When the proposed fix is "ramp {{flag}} back down," the proposal is a
**plan**, not an action: current %, target %, step size, hold time per
step, the one metric to watch at each hold, and the abort criterion
("checkout error rate not back under 2% within 10 min of the first step →
stop and page the owner"). Claude may read flag state and change history
via the `flags` binding — flag changes are timeline events exactly like
deploys — and never touches a flag itself (CLAUDE.md rule 1). After the
human executes each step, verification is the bounded three-check watch
(triage step 9) against the named metric.

## Escalation

- Deploys blocked fleet-wide, or a regression actively hurting users →
  page-severity per `ONCALL.md`
- One service's deploy stuck, workaround exists → business-hours ping to
  the service owner
- Expected resolution window for a grant/config fix: ~30 min from merge.
  For a template fix: one apply cycle. If blown, the hypothesis is wrong —
  return to first checks with the receiver's log ruled *in*.

## Rules this class taught us (the expensive ones)

- **An e2e test must enter the pipeline at the same door production
  traffic does.** If you can't trigger the real sender, write that down
  as a known coverage gap — not a green checkmark.
- **Ask "what principal actually arrives?", never "what did I
  configure?"** Identity through proxy chains is what the receiver's log
  says it is.
- **Verify the fix with the same tools that found the bug.** A different
  tool verifying is a different claim.
- **Suspect the instrument before the system** when evidence says
  something impossible.
- **Enforcement layers fail closed, enrichment layers fail open** — and
  fail-closed layers produce the most misleading errors in the chain, so
  name which dependency degraded.
- **Automation will re-apply its template over your manual fix.** Manual
  mitigation buys time; only the template version is real.
