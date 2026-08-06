<!-- Copyright 2026 Anthropic PBC -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Postmortem: INC-2005 silent coverage loss (FICTIONAL)

Green pipelines while 9% of tests silently stopped running for 3 days.
Detection was a developer noticing. Action items: track executed-test
count (done, 06-01); consider alerting on count drop (open).
