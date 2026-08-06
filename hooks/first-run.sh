#!/usr/bin/env bash
# Copyright 2026 Anthropic PBC
# SPDX-License-Identifier: Apache-2.0

# First-run greeting for the on-call kit (plugin install path).
# Emits context only when the working repo has no STACK.md — i.e. the kit
# is installed but Discover has never run. Read-only; never runs setup.

ROOT="$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --show-toplevel 2>/dev/null || echo "${CLAUDE_PROJECT_DIR:-.}")"
if [ ! -f "$ROOT/STACK.md" ] && [ ! -f "$ROOT/stack.md" ]; then
  cat <<'EOF'
The on-call kit plugin is installed but not yet configured (no STACK.md in
this repo). Greet the user per the kit CLAUDE.md "First run" section: a
three-sentence intro, then OFFER Phase 0 (Discover) — read-only capability
probe that writes STACK.md — explaining that everything else builds on it
and it surfaces missing connectors early. Do not run Phase 0 or probe any
connection without an explicit yes.
EOF
fi
exit 0
