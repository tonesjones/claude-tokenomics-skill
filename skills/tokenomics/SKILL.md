---
name: tokenomics
description: After a plan is drafted, map each task to Opus, Sonnet, or Haiku, delegate execution to the matching subagent, then have Opus review results against acceptance criteria. Use at the end of any planning session or when asked to "route the plan".
---

# Tokenomics

Turn a finished plan into routed, delegated work, then review it.

## 1. Break the plan into tasks
Each task must be independently executable and include:
- **ID**: T1, T2, …
- **Description**: one or two sentences
- **Inputs**: files, context, or outputs of other tasks it needs
- **Done when**: concrete, checkable acceptance criteria (tests pass, file exists, output matches spec)
- **Depends on**: task IDs, if any

If a task can't be given concrete acceptance criteria, it is still ambiguous and stays with Opus.

## 2. Route each task

| Model | Route here when the task… | Examples |
|---|---|---|
| **Opus** | needs judgment, design choices, ambiguity resolution, cross-cutting reasoning, or security-sensitive decisions | architecture, tricky debugging, API design, final review |
| **Sonnet** | is well specified but needs real reasoning or non-trivial code | implementing a feature to spec, refactors, writing tests, moderate debugging |
| **Haiku** | is mechanical, repetitive, or high-volume with a clear pattern | renames, formatting, boilerplate, extracting or summarizing, simple lookups, docstrings |

Routing rules:
- When in doubt between two tiers, choose the cheaper one **only if** the "done when" is fully objective; otherwise choose the stronger one.
- Any task touching auth, crypto, data deletion, or migrations is routed to Sonnet at minimum and is always flagged for Opus review.
- Split a mixed task rather than routing the whole thing up a tier.

## 3. Output the routing table
Present it before delegating:

| ID | Task | Model | Why | Done when | Depends on |
|---|---|---|---|---|---|

Then add a one-line estimate of the share of tasks on each tier.

## 4. Delegate
- Opus tasks: do them in the main session.
- Sonnet tasks: delegate to the `worker` subagent.
- Haiku tasks: delegate to the `grunt` subagent.
- Respect dependencies, and run independent tasks in parallel where possible.
- Pass each subagent the task's description, inputs, and "done when". Do not pass it the whole plan.

## 5. Review (Opus)
For each completed task:
- Check the result against its "done when". Run tests or inspect output; do not take the subagent's word for it.
- Mark it **pass**, **fix** (small correction done by Opus), or **escalate** (redo at a higher tier).
- Re-check integration points between tasks.

## 6. Log
Append to `routing-log.md`, one line per task:
`date | task ID | model | result (pass/fix/escalate) | notes`

Escalations are the signal for tuning this rubric: if a task type keeps escalating from a tier, route it higher next time.
