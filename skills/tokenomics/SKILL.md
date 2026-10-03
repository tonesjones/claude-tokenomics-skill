---
name: tokenomics
description: After a plan is drafted, decide whether delegation pays, map each task to Opus, Sonnet, or Haiku by difficulty and token shape, bundle and delegate to the matching subagent without breaking the main session's prompt cache, then have Opus review results against acceptance criteria. Use at the end of any planning session or when asked to "route the plan" or run /tokenomics.
---

# Tokenomics

Turn a finished plan into routed, delegated work, then review it. Cheaper tiers
save money on **output tokens and new input** (file reads, tool output), not on
re-reading context: the main session re-reads its warm cache at about the same
price as Sonnet. Every subagent starts cold. If unsure whether delegation pays,
see `reference/economics.md`.

## 0. Delegation gate
Execute the plan inline in the main session (lower `/effort` if the work is
routine) and skip steps 2–5 when **any** of these is true:
- ≤ 3 tasks, or one dependent chain where each step needs the last one's reasoning.
- The files involved are already in context and the edits are small.
- The "done when" can't be checked objectively (a cheap tier risks paying twice).

State the decision in one line, e.g. *"Inline: 2 sequential edits, files already loaded."*

Inline still means using the right skill. If a dedicated skill covers the work
(`code-review` for a review, `security-review` for a security pass), invoke it
in the main session instead of doing the work freehand.

## 1. Break the plan into tasks
Each task must be independently executable and include:
- **ID**: T1, T2, …
- **Description**: one or two sentences
- **Inputs**: file paths, line ranges, or outputs of other tasks it needs
- **Touches**: files it will modify
- **Done when**: concrete, checkable acceptance criteria (tests pass, file exists, output matches spec)
- **Depends on**: task IDs, if any
- **Shape**: `read-heavy` (lots of new input), `write-heavy` (lots of output), `reasoning` (small I/O, hard), or `touch-up` (small change to already-loaded context)

If a task can't be given concrete acceptance criteria, it is still ambiguous and stays with Opus.

## 2. Route each task

| Model | Route here when the task… | Examples |
|---|---|---|
| **Opus** (main session) | needs judgment, design choices, ambiguity resolution, cross-cutting reasoning, or security-sensitive decisions; or is a `reasoning`/`touch-up` task | architecture, tricky debugging, API design, small fixes in loaded files |
| **Sonnet** (`worker`) | is well specified, needs real reasoning or non-trivial code, and is `read-heavy` or `write-heavy` | implementing a feature to spec, refactors, writing tests, moderate debugging |
| **Haiku** (`grunt`) | is mechanical, follows a clear pattern, and has an objective "done when" | renames, formatting, boilerplate, docstrings, extracting or summarizing, lookups |

Routing rules:
- When in doubt between two tiers, choose the cheaper one **only if** the "done when" is fully objective; otherwise choose the stronger one.
- Any task touching auth, crypto, data deletion, or migrations is routed to Sonnet at minimum and is always flagged for Opus review.
- Split a mixed task rather than routing the whole thing up a tier.
- Don't give Haiku open-ended exploration or long multi-turn loops: its context is smaller (200K) and a failed run costs a redo one tier up.

## 3. Bundle into packages
Group same-tier tasks that share inputs into **one** subagent call (P1, P2, …),
so the cold start is paid once. Run packages in parallel only when they are
independent (no dependency between them and no overlap in **Touches**) and
latency matters; each parallel spawn is another cold start.

## 4. Output the routing table
Present it before delegating:

| ID | Task | Shape | Model | Package | Why | Done when | Touches | Depends on |
|---|---|---|---|---|---|---|---|---|

Then add a one-line estimate of the share of expected **tokens** (not tasks) on each tier.

Stop and wait for the user to approve or adjust the table when any task is
flagged (auth, crypto, deletion, migrations) or more than half the expected
tokens go to subagents, unless the user already said to proceed without
confirmation. Otherwise continue straight to delegation.

## 5. Delegate (cache-safe)
- Never switch the main session's model (`/model`). That cold-starts the whole conversation cache. Cheaper tiers run only as subagents.
- Opus tasks run in the main session; Sonnet packages go to `worker`, Haiku packages to `grunt`. Respect dependencies.
- If `worker` or `grunt` isn't defined in this environment, use the general-purpose agent with a model override (`sonnet` / `haiku`) and put the agent's report contract (≤ 10 lines, no diffs or file contents) in the brief.
- Briefs carry **pointers, not pastes**: paths, line ranges, each task's description and "done when", constraints. Never paste file contents or the whole plan; Opus output is the most expensive token you can spend.
- Expect compact reports (the agents are told ≤ 10 lines). Everything returned is re-read on every later main-session turn.
- While a subagent runs, do Opus-tier tasks rather than idling past the cache TTL.

## 6. Review (Opus), proportionate
For each completed task:
- Objective "done when" (tests, lint, build, file exists): run the check yourself and accept on pass. Don't re-read the diff.
- Read the diff only for flagged tasks (auth, crypto, deletion, migrations), spot-checks of Haiku output, and integration points between tasks.
- Mark it **pass**, **fix** (small correction done by Opus), or **escalate** (redo one tier up, with the original brief plus the failure reason).
- A task escalates at most once. If it fails again, Opus does it in the main session.

## 7. Log
Append to `routing-log.md`, one line per task (inline runs get one line for the whole plan):
`date | task ID | shape | model | package | result (pass/fix/escalate/inline) | tokens in/out | notes`

Record token usage when the subagent result reports it (one figure per
package is fine); otherwise write `n/a`. The session transcripts under
`~/.claude/projects/` hold per-model usage for later cost analysis.

Escalations are the tuning signal: if a (tier, shape) pair keeps escalating, route it higher next time. If inline runs were consistently trivial, tighten the gate.
