# claude-tokenomics-skill

A Claude skill that turns a finished plan into routed work: it decides whether
delegating pays at all, breaks the plan into tasks, routes each to **Opus**,
**Sonnet**, or **Haiku** by complexity and token shape, bundles and delegates
them without breaking the main session's prompt cache, then has Opus review
every result against its acceptance criteria and logs the outcome.

Current version: see [`VERSION`](VERSION) · history in [`CHANGELOG.md`](CHANGELOG.md)

## Repo layout

```
skills/tokenomics/SKILL.md   # the skill (frontmatter: name, description)
skills/tokenomics/reference/economics.md  # prices, cache facts, break-even (loaded on demand)
agents/worker.md             # Sonnet subagent used by the skill (Claude Code only)
agents/grunt.md              # Haiku subagent used by the skill (Claude Code only)
scripts/package.sh           # builds dist/tokenomics-<version>.zip for upload
VERSION, CHANGELOG.md        # versioning
```

## Cost model (why it routes the way it does)

- **Delegation isn't free.** Every subagent starts with a cold cache and pays
  for its own system prompt, tools, and brief. Small plans, dependent chains,
  and edits to files already in context run inline in the main session.
- **Cheaper tiers save on output and new input**, not on re-reading: Opus reads
  its warm cache at about Sonnet's price. Bulky reading or writing is what's
  worth handing off, because it also keeps the main context small.
- **Never switch the main session's model mid-task.** Caches are per model, so
  `/model` re-writes the whole conversation. Cheaper models run only as subagents.
- **Bundle work.** Same-tier tasks with shared inputs go to one subagent call;
  briefs are pointers (paths, line ranges), and reports are ≤ 10 lines.

Numbers and worked examples: [`reference/economics.md`](skills/tokenomics/reference/economics.md).

---

## Enterprise account setup

### 1. Clone the repo

```bash
git clone https://github.com/tonesjones/claude-tokenomics-skill.git
cd claude-tokenomics-skill
git checkout v2.1.0   # optional: pin to a released version (tags start at v2.1.0)
```

### 2. Import the skill into your enterprise Claude account (claude.ai / desktop)

1. Build the upload zip (needs `zip`):
   ```bash
   ./scripts/package.sh        # -> dist/tokenomics-<version>.zip
   ```
   The zip contains a single `tokenomics/` folder with `SKILL.md` at its root,
   which is the shape Claude expects.
2. Signed in to your **enterprise** account, open **Settings → Capabilities**
   (labels can shift between releases; look for the *Skills* section).
3. Make sure **Code execution and file creation** is on — skills depend on it.
   If the toggle or the Skills section is missing or greyed out, your org
   owner/admin has to enable Skills (and code execution) for the organization
   in the admin settings first.
4. Under **Skills**, choose **Upload skill** and select the zip.

### 3. Activate it in your workspace

- Toggle **tokenomics** on in the Skills list.
- Test it: draft a plan in a chat, then say *"route the plan"*. You should get
  a routing table (ID / Task / Shape / Model / Package / Why / Done when / Touches / Depends on), or a one-line "Inline: …" decision for small plans.
- To share it with your team, ask an org admin to provision it org-wide from
  the admin Skills settings (if your plan supports that) instead of each person
  uploading it.

### 4. (Optional) Use it in Claude Code with your enterprise login

Claude Code reads skills and subagents from disk, and here the `worker`/`grunt`
subagents actually run on Sonnet/Haiku. Their frontmatter uses `effort`,
`tools`, `omitClaudeMd`, and `maxTurns` to keep each spawn's cold prefix small;
`omitClaudeMd` needs Claude Code v2.1.271 or later (older versions ignore it):

```bash
mkdir -p ~/.claude/skills ~/.claude/agents
ln -s "$PWD/skills/tokenomics" ~/.claude/skills/tokenomics
ln -s "$PWD/agents/worker.md"  ~/.claude/agents/worker.md
ln -s "$PWD/agents/grunt.md"   ~/.claude/agents/grunt.md
```

Symlinks mean a `git pull` updates Claude Code immediately. (Use `.claude/`
inside a project instead of `~/.claude/` to scope it to one repo.)

> In claude.ai chat there are no named subagents, so the delegation step runs
> in-session; the delegation gate, routing table, and Opus review still apply.

### Version reference

| Field | Where |
|---|---|
| Installed version | the zip name you uploaded, e.g. `tokenomics-2.1.0.zip` |
| Latest version | [`VERSION`](VERSION) on `main`, or the repo's Releases/Tags |
| What changed | [`CHANGELOG.md`](CHANGELOG.md) |

---

## Update process

### Pulling updates into the enterprise account

```bash
cd claude-tokenomics-skill
git pull origin main             # or: git fetch --tags && git checkout v2.1.0
cat VERSION                      # confirm the version
./scripts/package.sh             # -> dist/tokenomics-<version>.zip
```

Then in enterprise Claude: **Settings → Capabilities → Skills**, delete (or
replace) the old **tokenomics** entry and upload the new zip. Re-test with
*"route the plan"*. Claude Code installs via symlink need no extra step.

### Making and versioning a change

1. Edit `skills/tokenomics/SKILL.md` (and `agents/*.md` if needed).
2. Bump `VERSION` (SemVer — see the rules at the top of `CHANGELOG.md`) and add
   a `CHANGELOG.md` entry.
3. Commit and tag:
   ```bash
   git add -A
   git commit -m "tokenomics vX.Y.Z: <summary>"
   git tag -a vX.Y.Z -m "tokenomics vX.Y.Z"
   git push origin main --tags
   ```
4. Optional: create a GitHub Release from the tag and attach
   `dist/tokenomics-X.Y.Z.zip`, so the enterprise side can download the zip
   without cloning.

Keep personal and enterprise copies in sync by treating this repo as the single
source of truth: edit here, then re-upload to whichever account needs it.
