<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# One week of the checkout weather routine (fictional, excerpted from the cycle log)

<!-- FICTIONAL — example artifact. Routine fires every 10 min; cadence
     guard targets 60 min quiet / 20 min with an incident open. -->

```
Tue 13:10  full cycle · sunny · no gate fired · skip ("channel picture current")
Tue 13:40  cadence guard: quiet, target 60m, last full cycle 30m ago · early-exit
Tue 14:10  full cycle · decline rate 1.9× baseline and climbing (overcast
           per the ONCALL.md tier table) · POSTED · trigger:
           "now overcast (was sunny)" — worsening posts immediately (gate 6)
Tue 15:10  full cycle · INC-371 declared minutes earlier (card declines,
           IC: Dana Osei) · POSTED · trigger: "incident opened" · target
           gap now 20m while it stays open
Tue 15:30  full cycle · mood computed partly_cloudy · HELD (improvement
           needs a confirming cycle) · skip
Tue 15:50  full cycle · hold confirmed · POSTED · trigger:
           "now partly_cloudy (was overcast)"
Wed 03:20  full cycle · metrics fetch FAILED · data_gaps=["metrics"] ·
           mood held at partly_cloudy (a missing signal is not a green
           signal — rule 18) · skip
Wed 09:40  full cycle · backlog_discount_applied=true — decline-rate p90
           still elevated from Tuesday's spike draining through the
           trailing window, current-health signals all green · capped at
           partly_cloudy · gate 6 fired on the flag flip · POSTED ·
           trigger: "elevated numbers are backlog, not live"
Thu 16:40  POSTED · trigger: "INC-371 resolved (still partly_cloudy:
           checkout p95 backlog draining)"
Fri 09:00  POSTED · trigger: "4h check-in" — last post would mislead a
           fresh reader (dominant cause changed)
```

Six posts in a week with a live incident. Every skip is logged with its
reason, and every judgment (the hold, the data-gap floor, the backlog
discount) left a flag in the stored report — the Wed 09:40 post fires
off that flag.
