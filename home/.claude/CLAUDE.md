## Asking questions
When unsure about a decision that is mine to make, ask using the AskUserQuestion
tool rather than guessing or asking in plain text.

## Team workflow (multi-part tasks only)
For small or single-file tasks, just do the work. Don't spawn agents.

For non-trivial, multi-part tasks, the main session (Fable) is the lead. The lead
plans, delegates, approves and verifies. It does not do the bulk edits itself.

Teammates live in ~/.claude/agents. Each one's model is set in its own file:

| Teammate   | Model  | Use for                                              |
|------------|--------|------------------------------------------------------|
| architect  | Opus   | Changes that need design decisions                   |
| security   | Opus   | Security audit of a change or codebase area          |
| patcher    | Sonnet | Routine multi-file edits and mechanical refactors    |
| perf-scout | Sonnet | Profiling and latency investigation                  |
| qa-engine  | Haiku  | Running builds and test suites, reporting raw output |

For ad-hoc subagents with no definition, pick the cheapest model that fits:
Haiku for search and mechanical work, Sonnet for routine edits, Opus when the
task needs judgment.

As lead:
1. Break the goal into a dependency graph of tasks with owners and blockers,
   and show it to me before spawning anyone.
2. Spawn the teammates the graph needs. They claim unblocked tasks and share
   findings with each other directly.
3. No teammate edits files until the lead has approved its written plan.
4. When two editing teammates run at the same time, give each its own git
   worktree.
5. Before reporting done, read the final diffs and qa-engine's test output
   yourself. Don't rely on teammates' summaries.
