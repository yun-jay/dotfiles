---
name: write-pr-description
description: Write or rewrite a pull request description in Yunus's house style. Use when asked to "write a PR description", "update the PR description", or to draft the body for a `gh pr create`. Defaults to editing the current branch's open PR; falls back to printing the body for a new PR.
---

# write-pr-description

Write a PR body that matches the voice and structure of the author's last ~20 PRs. Pull fresh exemplars when in doubt, style drifts.

## When invoked

1. **Resolve the target.**
   - If the user provided a PR number with the skill invocation, edit that PR's body.
   - Else, if the current branch has an open PR (`gh pr view --json number,url`), edit it.
   - Else, print the body to stdout so the caller can pipe it into `gh pr create --body-file -` (or include it in a heredoc).

2. **Gather context** (run in parallel where possible):
   - `git log <base>..HEAD --oneline`, commit history on this branch.
   - `git diff <base>...HEAD`, the actual changes. Read it, don't skim. Base is typically `dev`.
   - If the branch name embeds a Linear ticket (e.g. `hel-12805-…`), fetch it through any configured Linear integration, MCP server, CLI, or API. Pull the title, description, and any acceptance criteria. If Linear is unavailable, continue with the branch and PR context.
   - If a related/linked PR is mentioned in commits or by the user, fetch it with `gh pr view <number>` to mirror its tone and reference it correctly.

3. **Draft the body** following the template + style below.

4. **Apply it.**
   - Existing PR: `gh pr edit <num> --body-file <tmpfile>` (use a temp file, not `--body "..."`, avoids shell quoting hell with backticks and `$`).
   - New PR: print to stdout for the caller to consume.

## Template (use these exact headings)

```
## What does this PR do?
<prose, see voice notes below>

## How did you verify the code works?
- <terse bullet>

## How to test this PR?
- <terse bullet(s)>

Resolves hel-XXXXX
```

The headings are GitHub-PR-template defaults, don't rename, don't drop. The bottom `Resolves hel-XXXXX` (lowercase) is non-negotiable when there's a ticket.

## Voice notes

**First sentence pattern.** Pick one based on PR shape:
- **Standard PR**: `Purpose of this PR is to <verb> …`
- **Tiny PR**: `Mini PR <doing X>` (omits "Purpose of this PR is to", signals scope to reviewers).
- **Bug fix where root cause is the point**: dive straight in. `Fixes <symptom>. Cause was that <X>. Fix is <Y>.`
- **Follow-up**: `Symmetrizes / extends / completes <#prior-PR>'s handling of …`

**Tone.** First person, conversational, mildly self-aware. Not corporate. Asides and parentheticals are fine. Allowed emojis (sparingly, only when they fit naturally): `:)`, `🥳`, `😃`. Permitted lightness: `"Scream if you think I should implement this differently :)"`, `"Not super critical since …"`, `"Side mark, I intentionally chose …"`. Don't force it.

**What goes in "What does this PR do?".**
- The *why* > the *what*. Reviewers can read the diff.
- For fixes: name the symptom (often the verbatim error message in backticks), then cause, then fix. Include blast-radius numbers when known (`"218 failures across 9 nodes"`, `"17 production templates affected"`).
- Bulleted list when there are >2 distinct changes; prose for 1–2.
- Cross-link related PRs by number (`#8347`) or markdown (`[#7269](https://github.com/getmateo/hellomateo/pull/7269)`).
- @-mention collaborators when relevant (`as @SoerenGauch requested`).
- Embed screenshots/videos inline using GitHub user-attachments URLs, leave a placeholder like `<add screenshot>` if not provided.
- Reference the Linear ticket inline near the bottom of this section (`Fixes HEL-XXXXX`, uppercase here; the lowercase `Resolves hel-XXXXX` trailer is separate).

**What goes in "How did you verify".** Be terse. Almost always one of:
- `- manually`
- `- added tests`
- `- updated/added unit tests (<file>, <N> cases)` for bigger changes
- Combine when both: `- added tests` / `- captured live <X> webhooks through a tunnel, confirmed <Y>`

**What goes in "How to test".** Bullets. For backend / pure logic: `- run the tests`. For UI: imperative steps a reviewer can follow (`- create a booking in the iframe, cancel the booking, then try to click the button new booking`). Skip narration; just the steps.

**Length.** Default to short. The author keeps PR bodies tight; a long body is rare and only paid for by genuine complexity (root-cause narratives for non-obvious bugs, multi-area refactors that need a roadmap). When in doubt, cut.

- Mini PR: 2–4 sentences total.
- Standard fix/feat: 1–2 short paragraphs in "What does this PR do?". A "paragraph" is 2–4 sentences, not a wall.
- Complex/multi-area: cap "What does this PR do?" at ~150 words / ~12 bullet lines. If it wants to grow past that, you're probably explaining the diff instead of the why.

**Before posting, sweep for bloat:**
- Each bullet > 1 line of prose? Collapse or drop.
- Any sentence the reviewer could derive from the diff in 10 seconds? Cut.
- Listing every file or every rename? Cut.
- Multiple "additionally / furthermore / concretely / also" clauses? Probably padding.
- Repeating the title in expanded form? Cut.

If you find yourself writing a "context" or "background" section, stop. That's a doc, not a PR description. Link to the doc or to a related issue instead.

**Don't.**
- Never use em dashes (`—`, U+2014) or en dashes (`–`, U+2013). The author doesn't write them. Prefer commas, parentheses, colons, semicolons, or two short sentences. This rule is strict, sweep the draft for `—` before posting.
- Don't write "This PR ..." repeatedly. Vary openers.
- Don't restate the diff line-by-line.
- Don't add headings beyond the template.
- Don't pretend to have tested manually if you only wrote tests, or vice versa; defer to the actual evidence.

## Calibration: pull live exemplars

If anything in the voice notes feels stale or you're unsure of current conventions, fetch the last few PRs:

```
gh pr list --repo getmateo/hellomateo --author yun-jay --state all --limit 5 --json number,title,body
```

Match the most recent shape, not an old one.
