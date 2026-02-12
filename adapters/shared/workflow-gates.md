# Workflow & Quality Gates

## Mandatory Gates

Gates are steps that CANNOT be skipped under any circumstances.

```
GATE 1: PLANNING       — agreed with owner (goal/task + decomposition)
GATE 2: QUALITY        — lint + type-check + build + test pass (before acceptance)
GATE 3: ACCEPTANCE     — owner sees results + scenarios and EXPLICITLY confirms
GATE 4: PRE-COMMIT     — lint + type-check + build + test (before commit)
GATE 5: REFLECTION     — closure checklist passed, documentation updated
```

If a gate is not passed — you CANNOT move forward.

## Trigger Recognition

| User phrase | What it means | What to do |
|---|---|---|
| "закрываем", "коммить", "готово", "финализируем" | Closure sequence | DO NOT commit. Show results → scenarios → acceptance |
| "ОК", "принято", "всё ок" (after results) | Acceptance passed | Pre-commit → Commit → Reflection |
| "пуш", "push" | Push command | Push (commit must already exist) |

**RULE**: NEVER create a commit right after "закрываем".
Between "закрываем" and commit: results → scenarios → acceptance → pre-commit.

## Anti-patterns

### DON'T:
- Start a new task without finishing the current one
- Add features "along the way" without discussion
- Change architecture without asking
- Delete code/data without backup
- Commit right after "закрываем" — first results, acceptance, pre-commit
- Skip lint/type-check/build/test before commit
- Skip acceptance — even if owner is in a hurry
- Skip reflection — it's not a formality

### ALWAYS:
- Keep focus on ONE goal/task at a time
- Track progress in real time
- Run lint + type-check + build + test before every commit
- Show results + scenarios before closing
- Go through closure checklist (docs, reflection)
- Recognize triggers — "закрываем" != "commit immediately"

## Conflict Priorities

1. **Security** > everything else
2. **Success criteria** > nice-to-have
3. **Existing patterns** > new solutions
4. **Simplicity** > flexibility
5. **Working code** > perfect code
