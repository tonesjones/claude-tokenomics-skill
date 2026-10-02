# Tokenomics: the cost model

Read this only when it's unclear whether delegating a task pays off.

## Prices (per million tokens, Claude API list prices as of 2026-09)

| Model | Input | Output | Cache read | Cache write (5 min / 1 h) |
|---|---:|---:|---:|---:|
| Opus 5.5 | $4.00 | $20.00 | $0.20 | $5.00 / $8.00 |
| Sonnet 5.5 | $2.00 | $10.00 | $0.20 | $2.50 / $4.00 |
| Haiku 4.5 | $1.00 | $5.00 | $0.10 | $1.25 / $2.00 |

Refresh from the official pricing page (https://claude.com/pricing) when models
change. On a subscription plan these translate into usage-limit consumption
rather than dollars, but the ratios still hold.

## Cache facts that drive routing

- **Caches are per model and per prefix.** A subagent never reuses the main
  session's cache. It pays to write its own system prompt, tool schemas,
  CLAUDE.md, and brief before doing any work. Count on a few thousand to ~10K
  tokens of fixed overhead per spawn.
- **Switching the main session's model cold-starts everything.** The whole
  conversation is re-written to cache at the new model's write price. Use
  subagents, never `/model`, to reach cheaper tiers mid-task.
- **Warm re-reads are cheap.** Opus reads its cached context at $0.20/MTok, the
  same as Sonnet. Re-reading what Opus already holds is not the expensive part.
- **But context is re-read every turn.** Anything that lands in the main
  context (file contents, tool output, subagent reports) is paid for again on
  every later turn. Bulky reading done inline costs once to read and then keeps
  costing.
- **The cache expires** after its TTL (5 minutes by default, refreshed on every
  read). A main session idle past the TTL pays the write price again on its
  next turn.
- **Minimum cacheable prefix** is 512 tokens on Opus 5.5 / Sonnet 5.5 and 4096
  on Haiku 4.5. Shorter prefixes silently don't cache.

## Break-even rule of thumb

Delegate when the task's **new input + output** is large compared to a
subagent's fixed overhead (cold prefix + brief + returned summary). Keep it
inline when the task is small or its inputs are already in the main context.

Inline Opus cost ≈ new input × $4–5 + output × $20 + (growth of the main context × $0.20 × remaining turns)

Subagent cost ≈ (overhead + new input) × tier input price + output × tier output price + brief written by Opus × $20 + Opus review

## Worked examples

**Bulk task: read ~40K tokens of files, write ~5K tokens.**
- Inline Opus: ~$0.20 to read + ~$0.10 to write ≈ **$0.30**. The 45K then stays
  in context: about another $0.01 per later turn, roughly $0.27 more over 30 turns.
- Sonnet `worker`: ~50K input incl. overhead ≈ $0.10–0.13, 5K output ≈ $0.05,
  brief and ~300-token report ≈ $0.01 ≈ **$0.17**, and the main context grows by
  only the report.
- Haiku `grunt`: ≈ **$0.08**, if the task is pattern-following and objectively checkable.

**Small task: a 20-line edit in a file already in context.**
- Inline Opus: ~300 output tokens ≈ **$0.006**.
- Any subagent: ≥ 5K cold overhead + re-reading the file + Opus writing the
  brief ≈ **$0.02+**. Inline wins.

**Escalation:** a Haiku attempt that fails and is redone by Sonnet costs both
runs plus Opus's review of the failure. Route down only when "done when" is objective.
