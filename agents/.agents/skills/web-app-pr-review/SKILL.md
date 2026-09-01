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

**Static translations outside components must use `msg` message descriptors:**
```tsx
import { msg } from '@lingui/core/macro';
import type { MessageDescriptor } from '@lingui/core';

// Correct — defined outside component, resolved inside
const LABELS: Record<string, MessageDescriptor> = {
  day: msg`Day`,
  week: msg`Week`,
};

function MyComponent() {
  const { t } = useLingui();
  return <span>{t(LABELS.day)}</span>;
}
```

**Incorrect — calling `t` outside a component:**
```tsx
// Wrong — t`` can only be called inside a component with useLingui()
const LABELS = {
  day: t`Day`,  // ❌ t is not available here
};
```

**Reference files using the correct pattern:**
- `apps/web-app/src/features/calendars/components/create-calendar-modal.tsx`
- `apps/web-app/src/features/calendars/components/calendars-table.tsx`

**How to check:**
- `rg "from '@lingui/core/macro'" <changed-files>` — should only import `msg`, NOT `t` (use `t` from `useLingui()` instead)
- `rg "from '@lingui/react'" <changed-files>` — should be `@lingui/react/macro` instead (unless it's a non-macro import like `I18nProvider`)
- `rg "t\(i18n\)" <changed-files>` — should NOT appear in new code
- Look for `t\`...\`` or `t(i18n)\`...\`` used in module-level constants (outside components) — these must use `msg\`...\`` instead and be resolved with `t(descriptor)` inside the component

**`<Trans>` vs `` t`...` `` inside JSX bodies (HIGH priority sub-check):**

Reserve `` t`...` `` for *string contexts* — places that must accept a plain string: `placeholder`, `aria-label`, `title`, `toast.success(...)`, `t({ message, context })`, dialog `description`/`labels` props, or values inside a `Record<…, string>`.

For *rendered JSX text content*, always use `<Trans>`. The `<Trans>` macro produces extraction-friendly output, supports nested JSX (links, bolding), and reads more naturally than a curly-brace interpolation.

**Bad — `` t`...` `` rendering text:**
```tsx
<h3>{t`Assigned ${assigned.length}/${total}`}</h3>
<Button onClick={handleReset}>{t`Reset`}</Button>
<p>{t`Available ${count}`}</p>
```

**Good — `<Trans>` with interpolation:**
```tsx
<h3><Trans>Assigned {assigned.length}/{total}</Trans></h3>
<Button onClick={handleReset}><Trans>Reset</Trans></Button>
<p><Trans>Available {count}</Trans></p>
```

**How to check:**
- `rg "\{t\`" <changed-files>` — flag every match where the result lands directly as JSX text (i.e. wrapped in `{…}` between tags, not assigned to a `placeholder`/`aria-label`/`title`/etc. attribute or used as a function argument)
- If you remove the only `` t`...` `` usage from a component, also drop `t` from the `useLingui()` destructure to avoid an unused-variable error

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

- Flag unnecessary function wrappers — if a function just calls another function with the same args, call it directly
- Flag `"use client"` directives that are no longer needed
- Flag deprecated providers (e.g., `SidebarProvider`)
- Flag unused imports or variables

**How to check:**
- Look for wrapper functions like `const refresh = () => swrMutate()` — just use `swrMutate` directly

(For `useMemo` / `useCallback` see check #20. For inline arrow-function handlers see check #21.)

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

### 20. React Performance Hooks (HIGH priority)

Do not wrap values in `useMemo` or functions in `useCallback` unless the computation is genuinely expensive (e.g., filtering/sorting large lists, complex transformations) **and** the result is passed to a dependency that benefits from referential stability (e.g., a `React.memo`-wrapped child, a dependency array of another hook, or a context value). For primitive values, simple derivations, inline event handlers passed to native DOM elements, and functions that are only called locally within the component, use plain variables and arrow functions instead.

**Bad — memoizing a cheap derivation:**
```tsx
const fullName = useMemo(() => `${firstName} ${lastName}`, [firstName, lastName]);
```
**Good:**
```tsx
const fullName = `${firstName} ${lastName}`;
```

**Bad — `useCallback` on a handler passed to a native DOM element:**
```tsx
const handleClick = useCallback(() => {
  setCount(count + 1);
}, [count]);
return <button onClick={handleClick}>Increment</button>;
```
**Good:**
```tsx
return <button onClick={() => setCount(count + 1)}>Increment</button>;
```

**Bad — memoizing a primitive or trivially derived boolean:**
```tsx
const isDisabled = useMemo(() => items.length === 0, [items]);
```
**Good:**
```tsx
const isDisabled = items.length === 0;
```

**Bad — `useCallback` for a function only used locally, not passed to children:**
```tsx
const parseInput = useCallback((raw: string) => {
  return raw.trim().toLowerCase();
}, []);
// only called inside the same component
const result = parseInput(inputValue);
```
**Good:**
```tsx
function parseInput(raw: string) {
  return raw.trim().toLowerCase();
}
const result = parseInput(inputValue);
```

**Bad — memoizing a static or near-static list:**
```tsx
const tabs = useMemo(
  () => [
    { id: "overview", label: "Overview" },
    { id: "settings", label: "Settings" },
    { id: "billing", label: "Billing" },
  ],
  [],
);
```
**Good:**
```tsx
const tabs = [
  { id: "overview", label: "Overview" },
  { id: "settings", label: "Settings" },
  { id: "billing", label: "Billing" },
];
```
Or, if referential stability is truly needed, hoist it outside the component:
```tsx
const TABS = [
  { id: "overview", label: "Overview" },
  { id: "settings", label: "Settings" },
  { id: "billing", label: "Billing" },
] as const;
function MyComponent() {
  // use TABS directly
}
```
There is zero computation to save with a static literal and an empty dep array. If referential stability matters (e.g., it's passed to a memoized child), hoist the constant outside the component instead. `useMemo` with `[]` is never the right tool for static data.

**When `useMemo` / `useCallback` IS appropriate (do not flag):**
- Filtering or sorting a large array before passing it to a memoized child component.
- A callback passed as a prop to a `React.memo`-wrapped component where referential stability prevents expensive re-renders.
- A value used in a `useEffect` / `useMemo` dependency array where a new reference would cause unwanted re-execution.
- Creating an object or array that serves as a context provider value.

**How to check:**
- `rg "useMemo|useCallback" <changed-files>` and inspect each call site.
- For each occurrence, ask: (1) Is the computation genuinely expensive? (2) Is the memoized value consumed by a `React.memo` child, a hook dep array, or a context value? If the answer to both is no, flag it.

**Reasoning:** `useMemo` and `useCallback` add cognitive overhead, increase closure scope, and make components harder to read. They are only net-positive when the memoized value is expensive to compute or when referential identity matters to a downstream consumer. For cheap expressions and native DOM event handlers, the cost of the hook (dependency array tracking, closure allocation) exceeds the cost of the computation itself.

### 21. Inline Component Function Handlers (MEDIUM priority)

When an event handler prop receives an inline arrow function that simply calls another function with no extra arguments, pass the function reference directly instead.

**Bad — unnecessary inline wrapper:**
```tsx
<Button
  variant="outline"
  onClick={() => {
    onSave();
  }}
  disabled={isMutating}
>
  <Trans>Save</Trans>
</Button>
```

**Good — pass the reference directly:**
```tsx
<Button
  variant="outline"
  onClick={onSave}
  disabled={isMutating}
>
  <Trans>Save</Trans>
</Button>
```

This obviously doesn't apply when you need to pass a custom argument to the handler (e.g., `onClick={() => onSelect(item.id)}`), or when you need to ignore the event argument that would otherwise be forwarded (e.g., a handler typed to take no arguments being passed to `onClick` is fine, but if the handler's signature would conflict with the event arg, keep the wrapper).

**How to check:**
- Look for `onClick={() => fn()}`, `onChange={() => fn()}`, `onSubmit={() => fn()}`, etc. where the arrow body is just a single call to a named function with no extra args.
- Replace with `onClick={fn}` unless the wrapper is needed to drop arguments or pass custom ones.

### 22. Use `@unpic/react` `Image` Instead of Raw `<img>` (MEDIUM priority)

The web-app uses `@unpic/react`'s `Image` component for all bitmap and SVG assets. Raw `<img>` elements should not be introduced in new code.

**Bad — raw `<img>`:**
```tsx
<img
  src="/illustrations/foo.svg"
  alt=""
  width={120}
  height={36}
  className="h-full w-full object-cover"
/>
```

**Good — `@unpic/react` `Image`:**
```tsx
import { Image } from '@unpic/react';

<Image
  src="/illustrations/foo.svg"
  alt=""
  width={120}
  height={36}
  layout="fixed"
  className="h-full w-full object-cover"
/>
```

Notes:
- Always pass `width` and `height` explicitly (required for layout to work without CLS).
- Pick a `layout` (`"fixed"`, `"constrained"`, or `"fullWidth"`) — most static assets in this app use `"fixed"`.
- Decorative images should keep `alt=""`.

**How to check:**
- `rg '<img ' <changed-files>` and flag each occurrence in `apps/web-app/`.
- Confirm the import comes from `@unpic/react` and not React DOM.

**Reasoning:** `@unpic/react` produces width/height-aware markup so layouts don't shift while images load, automatically handles `srcset` for raster assets, and gives us one consistent image primitive across the app. Mixing raw `<img>` defeats those guarantees and trips `eslint-plugin-next(no-img-element)`.

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

### 22. Use `@unpic/react` `Image` Instead of `<img>`
- [ ] `buffer-graphic.tsx:23` — raw `<img>` element, replace with `Image` from `@unpic/react`

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
