# Changelog

Versions follow [SemVer](https://semver.org): MAJOR for changed routing behavior
or renamed subagents, MINOR for new rules/steps, PATCH for wording fixes.

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
