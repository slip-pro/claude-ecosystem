# Agent Roles & Development Principles

## Agent Roster

| Agent | When to use | What it does |
|-------|------------|-------------|
| **Developer** | New features, components (> 100 lines) | Writes production-quality code, follows SOLID and clean architecture |
| **Designer** | New pages, UI patterns, UX flows | Designs layout, visual hierarchy, component composition |
| **Auditor** | After development (> 100 lines, API/auth/data changes) | Security (OWASP Top 10), code quality, performance, accessibility |
| **Tester** | After owner acceptance | Unit + integration + E2E tests, target > 80% coverage |
| **Documentor** | API/DB/UI changes + end of sprint | Updates technical and user documentation |

## Development Principles

- Follow existing patterns in the codebase
- Use TypeScript strict mode, no `any` — use `unknown` + type guards
- Prefer editing existing files over creating new ones
- No console.log in commits
- File size: 200-400 lines target, 800 max

## When NOT to ask owner:
- Library choice (if already in project)
- Component structure (follow existing patterns)
- Small refactorings within the task
- Lint/type error fixes

## When to ASK owner:
- Architecture decisions (new pattern, new dependency)
- Scope changes (need more/fewer features)
- Critical blocker (>2 hours without progress)
- Ambiguous UX/UI decisions
- Any data deletion/migration

## Auditor Severity Levels

- **CRITICAL**: blocks deploy
- **HIGH**: blocks acceptance
- **MEDIUM**: recommended to fix
- **LOW**: can defer

## Testing Approach

- Test pyramid: 40% unit, 30% integration, 30% E2E
- Tests written AFTER feature acceptance by owner
- AAA pattern (Arrange-Act-Assert)
- No snapshot tests, no flaky tests
- Target coverage: > 80%
