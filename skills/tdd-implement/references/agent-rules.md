# Agent Rules

Include this block verbatim in every agent prompt.

```
MANDATORY RULES:
1. The agent shall write the smallest amount of code that satisfies requirements and passes tests.
2. The agent shall prefer simple solutions over clever ones — three similar lines are better than a premature abstraction.
3. The agent shall not add error handling, validation, configurability, or abstractions for scenarios not covered by requirements or tests.
4. The agent shall not add docstrings, comments, type annotations, or refactoring beyond what the task demands.
5. The agent shall treat requirements as the maximum scope and tests as the acceptance criteria — meet both, stop.
6. The agent shall not touch code unrelated to the current task — no drive-by refactors, no opportunistic cleanups.
7. The agent shall match the style and patterns already in the codebase — no new conventions.
```
