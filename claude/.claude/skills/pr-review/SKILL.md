---
name: pr-review
description: Analyze unresolved PR review comments and create a plan to address them
argument-hint: [PR-number]
---

# PR Review Comments Skill

Analyze unresolved PR review comments and create a plan to address each one.

## Instructions

1. **Determine the PR**:
   - If argument `$0` is provided, use it as the PR number
   - Otherwise, check if current branch has a PR: `gh pr view --json number`
   - If no PR found, ask the user for the PR number

2. **Fetch the PR context and comments**:
   - Run: `task pr-context PR=<number> > pr-context.md`
   - Run: `task pr-comments PR=<number> > pr-comments.md`
   - Read both files (pr-context.md has title, description, and diff)

3. **Explore the codebase**:
   - Spin up at least one Explore agent (using Task tool with subagent_type=Explore) to understand:
     - The architecture and patterns used in the affected areas
     - Why the code was written this way
     - Project conventions and best practices
     - How the changes fit into the broader codebase
   - This exploration is REQUIRED - it enables you to make informed decisions and provide strong arguments

4. **Analyze each comment**:

   For each review comment, determine its type:
   - **Suggestion**: A proposed code improvement (often has "suggestion" code block)
   - **Change Request**: Something that needs to be modified
   - **Question**: Needs clarification or explanation
   - **Nitpick**: Minor style or preference issue
   - **Blocker**: Critical issue that must be addressed

4. **Create an action plan**:

   For each comment, you MUST decide: **Does this need to be fixed?**

   Write a structured response in this format:

   ```markdown
   # PR Review Action Plan

   ## Summary
   - Total comments: X
   - Will fix: X
   - Will not fix: X
   - Needs discussion: X

   ## Action Items

   ### Comment 1: [File:Line]
   **Type:** [Suggestion/Change Request/Question/Nitpick/Blocker]
   **Author:** @username
   **Comment:** [Brief summary of the comment]

   **Verdict:** [WILL FIX / WILL NOT FIX / NEEDS DISCUSSION]

   **Reasoning:** [Why this should or should not be fixed]

   **If WILL FIX - Proposed Solution:**
   ```[language]
   // Show the exact code change you would make
   ```

   **If WILL NOT FIX - Explanation for Reviewer:**
   [Draft a polite but well-argued response explaining why this doesn't need to change.
   Use evidence from codebase exploration: existing patterns, architectural decisions,
   or technical reasoning that supports keeping the current implementation.]

   **If NEEDS DISCUSSION:**
   [What clarification is needed before deciding]

   ---
   [Repeat for each comment]
   ```

5. **Create an action plan**:

6. **Present to user for approval**:
   - Show the action plan
   - Ask the user to review and approve before making changes
   - Wait for user confirmation on each item or group of items

## Decision Guidelines

When deciding whether to fix:

**WILL FIX when:**
- The comment identifies a genuine bug or issue
- The suggestion improves code quality, readability, or performance
- It aligns with project conventions or best practices
- It's a reasonable change request from the reviewer

**WILL NOT FIX when:**
- The current implementation is intentional and correct
- The suggestion would introduce unnecessary complexity
- It conflicts with project requirements or constraints
- It's purely stylistic and the current style is acceptable
- The codebase exploration reveals patterns/conventions that support the current approach

**When pushing back, use your codebase knowledge to provide strong arguments:**
- Reference existing patterns in the codebase that support the current approach
- Explain architectural decisions that justify the implementation
- Point to similar code elsewhere that follows the same pattern
- Provide technical reasoning based on how the code integrates with the system

**NEEDS DISCUSSION when:**
- The comment is ambiguous or unclear
- There are trade-offs that need team input
- You need more context about project conventions

## Notes

- Do NOT make changes automatically - always get user approval first
- For each "WILL FIX", provide concrete code showing the exact change
- For each "WILL NOT FIX", provide a well-reasoned, evidence-based explanation
- Don't be afraid to push back on comments when you have good arguments backed by codebase evidence
- Group related comments if they affect the same code area
- Prioritize blockers and change requests over suggestions
