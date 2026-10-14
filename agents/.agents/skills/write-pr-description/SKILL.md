---
name: write-pr-description
description: Write or rewrite a concise pull request description in Yunus's house style. Use when asked to "write a PR description", "update the PR description", or draft the body for a `gh pr create`. Uses ASD-STE100 for clear prose, explains the change and why this implementation is the right choice, and defaults to editing the current branch's open PR.
---

# write-pr-description

Write a short PR body that explains the purpose and the implementation choice. Match the author's voice, but use the new structure in this skill instead of copying an old PR structure.

## Required writing skill

Before drafting, load and follow the `asd-ste100` skill at its default 80% level.

Apply its sentence rules and guard rails to all PR prose. Keep the conversational voice below. Clarity and factual accuracy are more important than stylistic flourishes.

## When invoked

1. **Resolve the target.**
   - If the user provided a PR number with the skill invocation, edit that PR's body.
   - Else, if the current branch has an open PR (`gh pr view --json number,url`), edit it.
   - Else, print the body to stdout so the caller can pipe it into `gh pr create --body-file -` or include it in a heredoc.

2. **Gather context** (run in parallel where possible):
   - Read `git log <base>..HEAD --oneline` for the commit history on this branch.
   - Read `git diff <base>...HEAD` in full. Base is typically `dev`.
   - Read relevant RFCs, package documentation, or nearby code when they explain an ownership boundary or implementation constraint.
   - If the branch name embeds a Linear ticket (for example, `hel-12805-...`), fetch it through any configured Linear integration, MCP server, CLI, or API. Pull the title, description, and acceptance criteria. If Linear is unavailable, continue with the branch and PR context.
   - If the user or commits mention a related PR, fetch it with `gh pr view <number>`. Use it for context and tone.
   - Identify the closest credible alternative only when the task, diff, documentation, or code provides evidence for it. Never invent an alternative to make the rationale sound stronger.

3. **Draft the body** with the structure and voice below.

4. **Apply it.**
   - Existing PR: write the body to a temporary file, then run `gh pr edit <num> --body-file <tmpfile>`. Do not use `--body "..."` because backticks and `$` make shell quoting unsafe.
   - New PR: print the body to stdout for the caller to consume.

## Structure

Use two short paragraphs without headings:

```text
Purpose of this PR is to <state the change and its outcome>.

<Explain why this implementation fits the system better than the relevant alternative.>

Resolves hel-XXXXX
```

The first sentence must start with `Purpose of this PR is to`. Do not use a different opener, including for a mini PR, bug fix, or follow-up.

The first paragraph describes the change and why it matters. The second paragraph explains the implementation choice. Name the relevant constraint, existing abstraction, contract, source of truth, or ownership boundary. Contrast the choice with the closest credible alternative when one exists. If there is no meaningful alternative, explain why the implementation fits the existing design. Do not fabricate a comparison.

Do not add `What does this PR do?`, `How did you verify the code works?`, `How to test this PR?`, or any replacement headings. Do not add a standalone verification or test section.

Add `Resolves hel-XXXXX` in lowercase as the final line when there is a ticket.

## Voice notes

**Tone.** First person, conversational, and mildly self-aware. Do not sound corporate. Asides and parentheticals are fine when they help. These emojis are allowed when they fit naturally: `:)`, `🥳`, `😃`. Light phrases such as `Scream if you think I should implement this differently :)`, `Not super critical since ...`, and `Side mark, I intentionally chose ...` are permitted. Do not force them.

**Content.** Prefer the why over a summary of the diff. Reviewers can read the diff.

- For a fix, name the symptom, cause, and fix when known. Keep quoted error messages unchanged.
- Include blast-radius numbers when known.
- Cross-link related PRs by number or Markdown link.
- Mention collaborators when relevant.
- Embed a provided screenshot or video with its GitHub user-attachment URL. Use `<add screenshot>` only when a visual is necessary but unavailable.
- Do not make vague claims such as "cleaner" or "more robust". Name the concrete benefit or constraint.

**Length.** Default to 2 to 5 short sentences across the two paragraphs. Aim for 100 words or fewer. Use more only when a reviewer needs a non-obvious root cause or tradeoff to assess the change. Keep each sentence within the `asd-ste100` limits.

Before posting, remove bloat:

- Remove any sentence that only repeats the title or a clear part of the diff.
- Remove file lists and rename lists unless they explain the design choice.
- Replace long clauses with short sentences.
- Keep one idea in each sentence.
- Keep one name for each concept.

Do not add a context, background, verification, or testing section. Link to a document or issue when the rationale needs more detail.

## Do not

- Never use em dashes (`—`, U+2014) or en dashes (`–`, U+2013). Use commas, parentheses, colons, or two short sentences.
- Do not use semicolons.
- Do not restate the diff line by line.
- Do not invent facts, constraints, alternatives, test results, or confidence.
- Do not change identifiers, commands, numbers, quoted errors, or scope limits.
- Do not add headings.

## Calibration: pull live exemplars

If the tone feels stale, fetch the last few PRs:

```sh
gh pr list --repo getmateo/hellomateo --author yun-jay --state all --limit 5 --json number,title,body
```

Use recent PRs only to calibrate tone. Do not copy their headings, testing sections, or older structure. The structure in this skill is authoritative.
