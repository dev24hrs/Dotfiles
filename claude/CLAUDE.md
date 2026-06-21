## Core Principle: Reasoning-First

**Before writing, modifying, or refactoring any code, you MUST initiate a multi-step reasoning flow (Long-horizon loop). Direct code output is forbidden.**

### Applicability

The three-phase reasoning is **mandatory** for:

- New feature implementations, multi-file changes, architecture or design changes
- Performance optimizations, refactoring, security-related changes

It may be skipped for: pure information queries, code reading/explanation, typo/single-line fixes, answering project configuration questions.

### Phase 1: Self-Reflection

Before writing, deeply deconstruct the requirements, current codebase state, and historical context:

-   **Requirement Alignment**: Restate the user's core intent in your own words to ensure no misunderstanding
-   **Context Review**: Examine affected files, dependencies, global state, and existing architectural design
-   **Correction & Breakthrough**: Are there blind spots in prior implementations? Does the user's proposal have logical flaws or break established design patterns? Identify hidden pitfalls and propose correct solutions

### Phase 2: Side-effects Analysis

Evaluate the impact of the code change on the entire system, including but not limited to:

-   **Performance**: Increased time/space complexity, memory leaks, I/O blocking, race conditions under high concurrency
-   **Breaking Changes**: API contracts, database schemas, shared components, test case breakage
-   **Edge Cases**: Null/undefined values, network failures, boundary values, concurrent requests, internationalization scenarios
-   **Security & Maintainability**: Security vulnerabilities, increased technical debt, reduced readability

### Phase 3: Precision Implementation

Only proceed to code writing after the first two phases are complete and a clear conclusion has been reached:

-   **Completeness**: Code must be complete; placeholder comments like `// TODO` or `// rest omitted...` are forbidden
-   **Defensive Programming**: Include necessary error handling and boundary defenses
-   **Testability**: Ensure code logic is clear and easy to unit test

### Output Format

Responses should follow the same three-phase structure: output the reflection and side-effects analysis first, then the code last. If the reasoning flow is skipped, briefly explain why.

## Go Projects

See @CLAUDE_Go.md for Go-specific guidelines.
