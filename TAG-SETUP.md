<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Getting Claude Tag ready for this kit

Claude Tag is @Claude living in your Slack channels. It's new, so this
page spells out what *you* can do yourself, what only your **Claude org
Owner** can do, and what to send them.
Do this before setup Phase 4 (the kit's Phase 0 will remind you).

## What you need to know in one paragraph

Claude Tag is available on Claude Team and Enterprise plans. It starts
with **no access to anything** — an Owner
provisions it an identity with its own service-account credentials (an
"access bundle"), scoped to your workspace or specific channels. Channel
work bills to an org usage balance with a spend limit, not to your seat.
Full docs: [setup overview](https://claude.com/docs/claude-tag/admins/setup-overview) ·
[how it works](https://claude.com/docs/claude-tag/concepts/how-it-works) ·
[the identity model](https://claude.com/blog/agent-identity-access-model).

## What you can do yourself (no admin needed)

- `/invite @Claude` into your on-call channel and each alert channel you
  want watched (once the app is installed in the workspace).
- Check what it can reach: `@Claude what can you access from this channel?`
  — or click **Configure** in the footer of any Claude reply.
- Create, list, edit, and disable routines in the channel ("what routines
  are set up here?").
- Run this kit's Phases 0–3 from a local Claude Code session in the repo,
  before Tag is provisioned at all.

## What only an Owner can do

At [claude.ai/admin-settings/claude-tag](https://claude.ai/admin-settings/claude-tag)
(must be an **Owner** in the Claude org — an Admin can view but not
complete setup):

1. Pair the Slack workspace with the Claude organization.
2. Create Claude Tag's identity and access bundle.
3. Attach connections — for this kit, at minimum: your **metrics source**,
   **log store**, **code host** (with this repo included), and optionally
   your **pager**. Read-only credentials everywhere to start; see
   [add connections](https://claude.com/docs/claude-tag/admins/add-connections)
   for credential types per service.
4. Scope the bundle to your on-call channel (and workspace, if desired).
5. Fund the usage balance and
   [set a spend limit](https://claude.com/docs/claude-tag/admins/set-spend-limit)
   for the pilot.

## The message to send your admin

Paste this to whoever owns your Claude org, filling the blanks:

> Hi — our team is setting up a Claude-assisted on-call in
> **#{{on-call channel}}** using an open-source kit (repo:
> {{repo URL}}). Could you do the one-time Claude Tag provisioning for us?
>
> 1. At claude.ai/admin-settings/claude-tag (needs Owner role), pair our
>    Slack workspace if it isn't already.
> 2. Create/extend an access bundle scoped to **#{{on-call channel}}** with
>    **read-only** connections to: {{metrics tool}}, {{log tool}},
>    {{GitHub org/repo}}, and {{pager tool}} (read incidents only — no
>    paging permission yet).
> 3. Include our repo {{repo URL}} in the bundle so Claude can read its
>    playbooks.
> 4. Set a spend limit of {{amount}}. (No number yet? A few hundred
>    dollars is a common ceiling for a pilot month — the pilot itself
>    measures the real figure.)
>
> Nothing will act autonomously: the kit is propose-only, everything is
> read-only, and paging stays off until after a two-week shadow period
> (Claude only posts drafts to a review channel while humans run on-call
> as usual) that we review together. Setup guide: claude.com/docs/claude-tag/admins/setup-overview

## Verifying it worked

From the on-call channel:

1. `@Claude what can you access from this channel?` — the list should
   match what the admin attached.
2. `@Claude read ONCALL.md from {{repo}}` — if it can read the repo, the
   kit's Phase 4 gate passes and routines can be installed.

If either fails, the access bundle is missing that piece — send the admin
the specific gap, not the whole checklist again.

## Two gotchas worth knowing up front

- **DMs are different.** A DM with Claude runs on *your* claude.ai seat
  with your limits, not the channel's setup. Do on-call work in the
  channel, where the connections and audit trail live.
- **Access follows the channel, not the person.** What Claude can reach is
  decided by which channel you're in. If a probe fails in a thread, you're
  probably in a channel outside the bundle's scope. The same rule applies
  to the optional weather routine: the channel it posts to, and the
  Slack canvas holding its report page, must both be inside the bundle's
  scope.
