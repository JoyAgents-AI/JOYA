# Engineering Workflow — Principles

> Inspired by [Superpowers](https://github.com/obra/superpowers).
> This guide defines universal engineering principles for all JOYA agents.
> Instance-level rules may extend these with tool-specific details (e.g., specific task trackers, CI systems).

## 1. Design Before Code

Do not write implementation code until the design is understood and approved.

- Clarify requirements: purpose, constraints, success criteria.
- Propose 2–3 approaches with trade-offs; get reviewer/Principal confirmation.
- Document the chosen design before implementation begins.
- YAGNI — cut anything speculative.

## 2. Test-Driven Development (TDD)

No failing test → no implementation code.

- **RED**: Write a minimal failing test describing expected behavior.
- **GREEN**: Write the least code to make it pass.
- **REFACTOR**: Clean up while keeping all tests green.
- Tests written after implementation don't count. If it happens, delete the implementation and restart from RED.

Exceptions (require Principal approval): throwaway prototypes, generated config, pure cosmetic changes.

## 3. Systematic Debugging

No random fix attempts. Follow a structured process:

1. **Investigate**: Read errors carefully. Reproduce reliably. Check recent changes.
2. **Analyze**: Find working analogues in the codebase, compare differences.
3. **Hypothesize**: State the hypothesis explicitly, test with minimal changes — one variable at a time.
4. **Fix**: Write a failing test to reproduce the bug, then TDD the fix.

**Three-strike rule**: Three consecutive failed fix attempts → stop and reassess the architecture with Manager or Principal.

## 4. Verification Before Completion

No verification evidence → no "done" claim.

- "Tests pass" requires actual test output showing zero failures.
- "Build succeeds" requires build command exit code 0.
- "Bug fixed" requires the original symptom test passing.
- "Requirement complete" requires checklist items verified one by one.

Banned phrases without evidence: "should work", "done", "fixed", "looks good".

## 5. Trinity Rule

Every delivery must satisfy all three simultaneously:

| Dimension | Requirement |
|-----------|-------------|
| **Code** | Implementation + commit |
| **Docs** | Corresponding documentation updated |
| **Tests** | New/changed code has test coverage |

Missing any one → not considered complete.

## 6. Code Review

Before submitting:
- All new functions have tests; each test was seen failing (RED phase).
- All tests pass with clean output.
- Edge cases and error paths are covered.
- Code matches the approved design.

On receiving review feedback: verify technically before accepting or disputing; re-run full test suite after each change.
