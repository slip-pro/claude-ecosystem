# Coding Style

## TypeScript / JavaScript
- Strict mode enabled, no `any` — use `unknown` + type guards
- Interfaces: PascalCase, suffix `Props` for component props (e.g. `ButtonProps`)
- Components: PascalCase (.tsx), Utilities: camelCase (.ts), Constants: UPPER_SNAKE_CASE

## Import Order
1. Framework core (React, Vue, etc.)
2. Third-party libraries
3. Internal components
4. Internal utilities
5. Types

## Formatting
- 2 spaces indent
- Single quotes for JS/TS, double quotes for JSX attributes
- Semicolons required
- Max line length: 80 characters

## No console.log
- Remove all `console.log` before commit
- Use proper error boundaries for production error handling
- Debug statements are caught by hooks

## File Size
- Target: 200-400 lines per file
- Maximum: 800 lines
- If larger — decompose into smaller modules

## Stack-Specific Patterns
Read the project's CLAUDE.md and `.claude/rules/` for:
- CSS framework conventions (Tailwind, CSS Modules, styled-components)
- UI component patterns (functional components, composition)
- API layer patterns (REST, GraphQL, tRPC)
- ORM patterns (soft delete, FK validation, query optimization)
