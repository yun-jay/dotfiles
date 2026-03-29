---
name: web-app-pr-review
description: Review a web-app frontend PR for common issues before requesting a human review. Checks translation patterns, component structure, type usage, confirm dialogs, and more.
---

# Web App PR Review

Comprehensive frontend review of your web-app PR. Run this when you think you're done and want to catch issues before the human reviewer sees them.

## Instructions

1. Get the current branch diff against main:
   ```
   gh pr diff || git diff main...HEAD
   ```

2. Identify all changed/added files in `apps/web-app/`. Read the **full content** of each modified file (not just the diff).

3. Run through every check below on every changed file. Report findings as a checklist.

4. Run `just quick-lint` and `just typecheck web-app` and report errors.

## Checks

### 1. Lingui Translation Pattern (HIGH priority)

The team has adopted a new translation pattern. All new code must use it.

**NEW pattern (correct):**
```tsx
import { Trans, useLingui } from '@lingui/react/macro';

function MyComponent() {
  const { t } = useLingui();

  return <Input placeholder={t`Enter name`} />;
}
```

**OLD pattern (incorrect — flag every occurrence in new/changed code):**
```tsx
import { t } from '@lingui/core/macro';
import { useLingui } from '@lingui/react';

function MyComponent() {
  const { i18n } = useLingui();

  return <Input placeholder={t(i18n)`Enter name`} />;
}
```

Key differences:
- Import `useLingui` from `@lingui/react/macro` (NOT `@lingui/react`)
- Import `Trans` from `@lingui/react/macro` (NOT `@lingui/core/macro`)
- Destructure `{ t }` from `useLingui()` (NOT `{ i18n }`)
- Use `t\`text\`` (NOT `t(i18n)\`text\``)

**Reference files using the correct pattern:**
- `apps/web-app/src/features/calendars/components/create-calendar-modal.tsx`
- `apps/web-app/src/features/calendars/components/calendars-table.tsx`

**How to check:**
- `rg "from '@lingui/core/macro'" <changed-files>` — should NOT appear in new code
- `rg "from '@lingui/react'" <changed-files>` — should be `@lingui/react/macro` instead (unless it's a non-macro import like `I18nProvider`)
- `rg "t\(i18n\)" <changed-files>` — should NOT appear in new code

### 2. One Component Per File (HIGH priority)

Every file should contain at most **one exported component**. If a file defines multiple components, they must be split into separate files.

**How to check:**
- Count the number of `function ComponentName(` or `const ComponentName =` patterns that look like React components (return JSX) per file
- Small internal helpers (< 15 lines, not exported) are OK to keep inline
- If a component file has grown beyond ~200 lines, flag it for splitting into 2-3 files

### 3. Extract Reusable Helper Functions (HIGH priority)

Look for functions, hooks, computed values, or utility logic that:
- Appears in 2+ files in the diff
- Is duplicated from existing code elsewhere in the same feature or shared directory
- Could be extracted to a shared `utils`, `hooks`, or `lib` file and reused

**How to check:**
- Compare function bodies across files in the diff
- `rg` for similar function names or logic in `apps/web-app/src/features/` and `apps/web-app/src/hooks/`
- Flag inline utility functions that aren't component-specific

### 4. Types Should Use Supabase Types When Possible (HIGH priority)

New type definitions should be checked against existing Supabase-generated types. If a type mirrors a database row, use the generated type instead of redefining it.

**Supabase types are imported from:**
```tsx
import { Tables, TablesInsert, Enums, Database } from '@hellomateo/supabase/types';

// Row type for a table
type Employee = Tables<'employee'>;

// Insert type for a table
type NewCampaign = TablesInsert<'campaign'>;

// Enum type
type Status = Enums<'campaign_status'>;
```

**How to check:**
- For every new `type` or `interface` in the diff, check if it maps to a database table or enum
- `rg "Tables<'" apps/web-app/src/` to see how existing code uses generated types
- If a new type has fields like `id`, `created_at`, `organisation_id` — it likely mirrors a DB table

### 5. Use Existing Confirm Dialogs for Destructive Actions (HIGH priority)

Destructive actions (delete, remove, disconnect, clear) must have confirmation dialogs. Use the existing components — do not build custom dialogs.

**Available components:**
- `<ConfirmRemovalDialog />` — for database deletions (handles Supabase mutation + table revalidation)
  - Location: `apps/web-app/src/components/confirm-removal-dialog/lingui-confirm-removal-dialog.tsx`
- `<ConfirmActionDialog />` — for generic confirmations (non-deletion actions)
  - Location: `apps/web-app/src/components/confirm-action-dialog/confirm-action-dialog.tsx`

**How to check:**
- Look for `delete`, `remove`, `clear`, `disconnect` handlers that directly mutate without showing a dialog
- Look for custom confirmation dialogs that could use the existing components instead
- `rg "ConfirmRemovalDialog|ConfirmActionDialog" apps/web-app/src/` to see existing usage

### 6. Avoid `as` Type Casting (HIGH priority)

Type casting with `as` is almost always a code smell. If you need to cast, the types are likely wrong upstream.

**How to check:**
- `rg " as " <changed-files>` — flag every `as` cast in new/changed code
- Common offenders: casting Supabase query results, casting form values, casting function parameters
- Fix by: using proper generics, narrowing with type guards, or fixing upstream types
- `useForm()` should infer types from `defaultValues`/`values` — do NOT use `useForm<ExplicitType>()`

### 7. No `any` Types (MEDIUM priority)

- Flag any usage of `any` type in new or changed code
- Suggest proper types, generics, or form context instead
- Check for implicit `any` through untyped function parameters
- Prefer `unknown` if the type is truly unknown, then narrow with type guards

### 8. React Query Patterns (MEDIUM priority)

- Flag try/catch around mutations — use `onSuccess`/`onError` callbacks instead
- Flag `useEffect` that resets form values — use `values`/`defaultValues` prop instead
- Flag custom mutation logic when existing hooks like `useUpsertMutation` exist
- Check that existing mutation hooks are used rather than reimplementing

### 9. Avoid `for` Loops with `await` (HIGH priority)

Sequential `await` calls inside `for` loops are a performance anti-pattern. Each iteration waits for the previous one to complete.

**How to check:**
- `rg "for.*\{" <changed-files>` and look for `await` inside the loop body
- `rg "forEach.*await|for.*of.*await" <changed-files>`

**Correct patterns:**
```tsx
// Use Promise.all for parallel execution
await Promise.all(items.map((item) => supabase.from('table').insert(item)));

// Or batch operations — send an array instead of looping
await supabase.from('table').insert(items);

// Or use an RPC that accepts an array
await supabase.rpc('bulk_create', { items });
```

**Flag:**
- `await` inside `for`, `for...of`, `forEach`, or `.map()` loops
- Multiple sequential Supabase calls that could be batched into one
- Suggest `Promise.all`, batch inserts/updates, or an RPC that accepts arrays

### 10. Avoid `useEffect` Anti-Patterns (HIGH priority)

`useEffect` is commonly misused. Flag these patterns:

**Flag:**
- Fetching data inside `useEffect` — use `useQuery`/`useSWR` instead
- Defining functions inside `useEffect` that could be defined outside
- Setting form values in `useEffect` — use `values`/`defaultValues` prop on `useForm` instead
- Transforming/mapping data in `useEffect` + `setState` — compute during render or use `useMemo`
- Any `useEffect` that could be replaced by a React Query hook or computed value

**How to check:**
- `rg "useEffect" <changed-files>` and inspect each usage
- If it calls `fetch`, `supabase`, or any async operation — it should be a query hook
- If it calls `setValue`/`reset` on a form — it should use `values` prop

### 11. Filter in Query, Not Frontend (HIGH priority)

Data filtering should happen at the query level (Supabase `.eq()`, `.filter()`, etc.), not by fetching all data and filtering client-side.

**How to check:**
- Look for `.filter()` or conditional logic applied to query results
- Look for `useMemo` that filters an array from a query
- Check if the filter condition could be added as a `.eq()` / `.neq()` / `.in()` to the Supabase query

**Flag:**
- Frontend `.filter()` on data that could be filtered in the query
- Fetching all rows then filtering by a known value (e.g., status, type, organisation_id)

### 12. Data Table Cell Props (MEDIUM priority)

- Check that data-table columns use proper cell prop helpers: `textCellProps`, `badgeCellProps`, etc.
- Flag columns with inline styling that should use standard props
- Check that columns needed for filtering are included in the column definitions

### 13. Remove Unnecessary Code (MEDIUM priority)

- Flag unnecessary `useMemo` wrapping (especially for static data, simple transforms, or values that rarely change)
- Flag unnecessary `useCallback` wrapping (especially for simple handlers that don't need memoization)
- Flag unnecessary function wrappers — if a function just calls another function with the same args, call it directly
- Flag `"use client"` directives that are no longer needed
- Flag deprecated providers (e.g., `SidebarProvider`)
- Flag unused imports or variables

**How to check:**
- `rg "useMemo" <changed-files>` — check if the memoization is justified (expensive computation, referential equality needed for deps)
- `rg "useCallback" <changed-files>` — check if the callback is passed to memoized children
- Look for wrapper functions like `const refresh = () => swrMutate()` — just use `swrMutate` directly

### 14. Organisation ID Filters (MEDIUM priority)

- Check that Supabase queries from frontend include `organisation_id` filter where appropriate
- Flag queries on multi-tenant tables that don't scope by organisation

### 15. Extend Existing Abstractions (MEDIUM priority)

- When adding new behavior to a shared component (data-table, form, dialog), check if a similar pattern already exists
- Search the shared component's props/API for related functionality
- Flag cases where extending the existing API would be cleaner than a one-off solution
- Check if an existing shared component (e.g., `command-select-popover`) could be reused instead of building inline

### 16. Correct Import Paths (MEDIUM priority)

- Verify import paths are correct (`@/components/...`, `@/lib/...`, `@/features/...`)
- Check for imports from old locations that have been moved
- Run typecheck to catch broken imports

### 17. UX Completeness (MEDIUM priority)

- For any new filter/toggle/switch: verify user can clear/reset it
- For loading states: use skeletons not spinners
- For buttons/links: label must match what happens on click
- For modals/dialogs: verify they can be closed/dismissed
- For lists: verify empty states are handled

### 18. Complex Frontend Logic — Use RPCs (LOW priority)

- Flag complex data operations (multiple loops, filters, sequential updates) that should be an RPC/backend call instead
- Flag functions with many sequential Supabase calls — if something fails midway, there's no rollback; an RPC runs in a transaction
- Frontend should be thin — heavy data manipulation belongs on the backend
- If a single "save" action requires 5+ Supabase calls, it should be an RPC

**How to check:**
- Count the number of `supabase.from(` or `supabase.rpc(` calls in a single function
- If > 3-4 calls in one function, flag it as a candidate for an RPC
- Look for functions named `save*`, `create*`, `update*` that orchestrate many mutations

### 19. Simplicity (LOW priority)

- Flag overly complex logic that could be simplified
- Look for unnecessary abstractions or convoluted algorithms
- If something requires reading twice to understand, it probably needs simplification

## Output Format

Present findings as a markdown checklist grouped by category:

```
## Web App PR Review Results

### 1. Lingui Translation Pattern
- [ ] `create-foo-modal.tsx:3` — uses `import { t } from '@lingui/core/macro'`, switch to `import { useLingui } from '@lingui/react/macro'`
- [ ] `create-foo-modal.tsx:45` — uses `t(i18n)\`...\``, switch to `t\`...\``

### 2. One Component Per File
- [ ] `foo-page.tsx` defines `FooPage`, `FooHeader`, and `FooSidebar` — extract `FooHeader` and `FooSidebar` into their own files

### 3. Extract Reusable Helper Functions
- [ ] `useIsInactive` in `droppable-edge.tsx` duplicates logic in `action-placeholder.tsx` — extract to shared hook

### 4. Types Should Use Supabase Types
- [ ] `types.ts:12` — `FooRow` type mirrors the `foo` table, use `Tables<'foo'>` instead

### 5. Use Existing Confirm Dialogs
- [ ] `foo-list.tsx:89` — `handleDelete` directly calls mutation without confirmation, use `<ConfirmRemovalDialog />`

### 6. Avoid `as` Type Casting
- [ ] `edit-context.tsx:127` — `as FooType` cast, fix upstream types instead

### 9. Avoid `for` Loops with `await`
- [ ] `save-config.ts:216` — `await` inside `for` loop, use `Promise.all` or batch insert

### 10. Avoid `useEffect` Anti-Patterns
- [ ] `notifications-tab.tsx:65` — fetching data inside `useEffect`, use a query hook instead

...
```

If no issues are found in a category, show `(none found)`.

At the end, include a summary count: `Found X issues (Y high, Z medium, W low)`.

## Important

- Only flag real issues, not nitpicks
- Read surrounding code for context before flagging — something might look duplicated in the diff but have subtle differences
- If unsure about something, mention it but mark it as "worth checking" rather than a definitive issue
- Do NOT make any changes — this is a read-only review
- Focus only on files in `apps/web-app/`

## Reference

See `.claude/caroline-review-patterns.md` for the full dataset of Caroline's review comments that informed these checks.
