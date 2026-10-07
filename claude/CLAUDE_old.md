## Core Principle: Reasoning-First

**Before writing, modifying, or refactoring any code, you MUST initiate a multi-step reasoning flow (Long-horizon loop). Direct code output is forbidden.**

### Applicability

The three-phase reasoning is **mandatory** for any code modification, regardless of size or complexity. This includes but is not limited to:

- New feature implementations, multi-file changes, architecture or design changes
- Performance optimizations, refactoring, security-related changes
- Single-line fixes, typo corrections, configuration changes, revert/rollback operations

Pure information queries, code reading/explanation, and spelling errors that do not change code behavior are exempt (no code is being modified).

### Phase 1: Self-Reflection

Before writing, deeply deconstruct the requirements, current codebase state, and historical context:

- **Requirement Alignment**: Restate the user's core intent in your own words to ensure no misunderstanding
- **Context Review**: Examine affected files, dependencies, global state, and existing architectural design
  - For any symbol (function, type, variable, file item, etc.) being added/modified/deleted, you must first use a search tool (`rg`/`grep`, etc.) to locate **all** references/calls/parameter-passing sites, listing file paths (with line numbers when necessary). Do not judge "probably unused" from impression alone.
  - Signature changes (parameter lists, return types, etc.) must confirm whether all call sites need corresponding updates, and the affected call sites must be listed in the analysis.
  - Before deleting a symbol, you must prove via search results that the reference count is 0 (including test code, scripts, and documentation examples), not subjective judgment.
  - Bad example (forbidden): "This function looks unused, just delete it." (unverified by search)
  - Good example (required): "Search found `parseConfig` called in 3 places: `src/loader.rs:42` (direct call), `tests/config_test.rs:18` (test case), `src/cli/mod.rs:7` (indirect via trait). After changing the signature, these 3 call sites were updated accordingly and tests were added."

- **Correction & Breakthrough**: Are there blind spots in prior implementations? Does the user's proposal have logical flaws or break established design patterns? Identify hidden pitfalls and propose correct solutions

### Phase 2: Side-effects Analysis

Evaluate the impact of the code change on the entire system, including but not limited to:

- **Performance**: Increased time/space complexity, memory leaks, I/O blocking, race conditions under high concurrency
- **Breaking Changes**: API contracts, database schemas, shared components, test case breakage
- **Edge Cases**: Null/undefined values, network failures, boundary values, concurrent requests, internationalization scenarios
- **Security & Maintainability**: Security vulnerabilities, increased technical debt, reduced readability

### Phase 3: Precision Implementation

Only proceed to code writing after the first two phases are complete and a clear conclusion has been reached:

- **Completeness**: Code must be complete; placeholder comments like `// TODO` or `// rest omitted...` are forbidden
- **Defensive Programming**: Include necessary error handling and boundary defenses
- **Testability**: Ensure code logic is clear and easy to unit test

### Output Format

Responses should follow the same three-phase structure: output the reflection and side-effects analysis first, then the code last. If the reasoning flow is skipped, briefly explain why.

## Modern & Standard-Library-First Principle

When generating code in any language, the following priority applies:

1. **Standard library first**: Prefer the standard library over third-party dependencies when the stdlib provides an adequate solution. Introducing a new dependency requires justification (the stdlib solution is missing, buggy, or prohibitively verbose).
2. **Modern idioms over legacy patterns**: Use the language's modern/recommended idioms (post-2020 era) rather than legacy patterns from earlier versions. This includes but is not limited to:
   - Function declarations (arrow functions, concise method syntax, etc.)
   - Collection operations (declarative/functional APIs over manual loops when readable)
   - HTTP / I/O operations (modern client APIs over deprecated ones)
   - Error handling (language-native patterns over hand-rolled workarounds)
   - Type system (newer type constructs over `any`/`Object`/`void*` escape hatches)
3. **Version awareness**: Target the language version specified in the project's toolchain/config file (e.g., `go.mod`, `pyproject.toml`, `.nvmrc`). Do not use features from versions newer than the project target, and do not use patterns already deprecated in the project's target version.
4. **Language-specific details**: See `@CLAUDE_<Lang>.md` for concrete before/after mappings per language.

## Mandatory Verification Rules

These rules apply unconditionally. No exceptions based on perceived simplicity or familiarity.

### Rule 1: Revert / Rollback Requires Read

Before executing any operation that involves **revert, rollback, undo, restore, or "change back to original"**, you MUST first Read the target file to confirm its current state. Never rely on memory or impression of what the file contained in a prior turn.

- Bad (forbidden): "I remember the original was X, let me write X." (unverified)
- Good (required): Read the file → confirm current state → then write the correct prior version.

### Rule 2: Post-Edit Verification

After every Edit or Write, immediately verify the result with a targeted Read or grep on the changed lines. Confirm that the final state matches what was intended before moving on.

### Rule 3: Root Cause Before Code Change

When debugging a behavior discrepancy (wrong state, unexpected output, silent failure), you MUST first capture real runtime data with a diagnostic command (e.g., check live output, query logs, inspect actual variable values) to isolate the root cause. Do not modify detection logic, regex patterns, or conditional branches until the actual data responsible for the misbehavior has been identified and shown.

- Bad (forbidden): "Maybe the regex is too broad, let me narrow it." → edit without data.
- Good (required): Capture the actual values being matched or compared → find the exact data causing the mismatch → then fix based on that evidence.

## Go Projects

See @CLAUDE_Go.md for Go-specific guidelines.
