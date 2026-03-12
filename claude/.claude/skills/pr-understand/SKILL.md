---
name: pr-understand
description: Understand what has been done in a Pull Request by analyzing the diff
argument-hint: [PR-number]
---

# PR Understanding Skill

Analyze a Pull Request to understand what changes have been made.

## Instructions

1. **Determine the PR**:
   - If argument `$0` is provided, use it as the PR number
   - Otherwise, check if current branch has a PR: `gh pr view --json number,title,body`
   - If no PR found, ask the user for the PR number

2. **Fetch the PR context**:
   - Run: `task pr-context PR=<number> > pr-context.md`
   - Read the pr-context.md file (contains PR title, description, and diff)

3. **Explore the codebase**:
   - Spin up at least one Explore agent (using Task tool with subagent_type=Explore) to understand:
     - The architecture and patterns used in the affected areas
     - How the changed files relate to the rest of the codebase
     - What components or features depend on the changed code
     - The broader context of why these changes matter
   - This exploration is REQUIRED - do not skip it

4. **Analyze and summarize**:

   Provide a structured summary:

   ### Overview
   2-3 sentences describing what this PR accomplishes.

   ### Files Changed
   List the main files/areas affected, grouped by feature or component.

   ### Key Changes
   - Describe significant changes
   - Note any new features, bug fixes, or refactoring
   - Highlight architectural decisions

   ### Technical Details
   Important implementation details worth noting.

   ### Potential Impact
   Based on codebase exploration:
   - Components/features that depend on changed code
   - Possible side effects or regressions to watch for
   - Areas that might need additional testing

   ### How This Affects the App
   Explain in practical terms what this PR changes from a user/system perspective.

5. **Keep the diff.diff file** for reference during the session.

## Notes

- Focus on understanding the "what" and "why"
- Flag any potential issues or concerns
- Be ready to answer follow-up questions
