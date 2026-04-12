# Response Language

- Always respond to the user in Japanese, regardless of the input language.
- Internal thinking may be in any language.

# Sub-agents and Task Delegation

- If sub-agents are usable and independent contexts are enabled for tasks (such as refactoring, reviewing, wide-ranging exploration, searching on the web or in documents), or if you want to execute tasks in parallel, utilize sub-agents to delegate processing.

# Clarifying Requirements

- If user requests or requirements are unclear, repeatedly use `user_input` to delve deeper and clarify ambiguities.

# Git Commit Policy

- Stick to one feature per commit. Do not group multiple changes into a single commit.
-Commit messages should follow the Conventional Commits and gitmoji format.

# Design Principles

- There is no need to implement with minimal changes; prioritize conciseness and correctness of design.
- Adhere to the YAGNI principle, KISS principle, and DRY principle.
- Do not implement auxiliary functions or alternative paths for backward compatibility unless explicitly requested by the user.

# Package Manager

- If the project's package manager is known, use it directly (e.g., `pnpm`, `pnpm dlx`).
- If unknown, use `@antfu/ni` commands:
  - `ni` (install), `nr` (run), `nlx` (exec), `nu` (upgrade), `nun` (uninstall)
- Do not use `pnpm create` / `npm create`; set up the project manually.
