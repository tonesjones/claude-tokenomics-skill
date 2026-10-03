# Changelog

Versions follow [SemVer](https://semver.org): MAJOR for changed routing behavior
or renamed subagents, MINOR for new rules/steps, PATCH for wording fixes.

## 2.1.0 — 2026-10-03
Folds in rules from the account-side copy that branched off 1.0.0 separately.
- Tasks list **Touches** (files modified); packages run in parallel only when
  their Touches don't overlap. Routing table gains a Touches column.
- Approval gate: wait for the user on the routing table when a task is flagged
  or more than half the expected tokens go to subagents.
- Fallback to the general-purpose agent with a model override when `worker` /
  `grunt` aren't installed.
- Escalation cap: a task escalates at most once, then Opus does it.
- Log gains a `tokens in/out` column; transcripts noted as the usage source.
- Description also triggers on `/tokenomics`.

## 2.0.0 — 2026-10-02
- Routing is now cache- and token-aware (changed routing behavior → MAJOR).
- New step 0 delegation gate: small, sequential, or already-loaded work runs
  inline instead of paying subagent cold-start costs.
- Tasks carry a **Shape** (read-heavy / write-heavy / reasoning / touch-up);
  reasoning and touch-up stay on Opus.
- Same-tier tasks are bundled into packages (one cold start per package).
- Delegation rules: never switch the main session's model, pointer-only briefs,
  ≤ 10-line reports.
- Proportionate review: objective checks accept on pass; diffs read only for
  flagged tasks, Haiku spot-checks, and integration points.
- Log gains `shape` and `package` columns.
- New `reference/economics.md` with prices, cache facts, and break-even examples.
- `worker`: `effort: medium`, tools allowlist. `grunt`: tools allowlist,
  `omitClaudeMd`, `maxTurns: 25`. Both use a compact report contract.

## 1.0.0 — 2026-10-01
- Initial port from personal account: plan breakdown, Opus/Sonnet/Haiku routing,
  delegation to `worker`/`grunt` subagents, Opus review, routing log.
