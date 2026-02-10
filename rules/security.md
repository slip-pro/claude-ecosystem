# Security Rules

## Input Validation
- Validate ALL user inputs with schema validation (Zod, Joi, etc.)
- API inputs: always validate with schema before processing
- Never trust client-side data — validate on server

## XSS Prevention
- Sanitize user-provided HTML before rendering (DOMPurify or equivalent)
- Never use raw HTML injection (`dangerouslySetInnerHTML`, `v-html`) without sanitization
- Use framework's built-in escaping mechanisms

## SQL Injection
- Always use ORM parameterized queries or prepared statements
- Never interpolate user input into raw SQL strings
- Raw queries only with parameterized templates

## Secrets
- No hardcoded secrets, tokens, or passwords in code
- Use environment variables (`.env`)
- `.env` files must be in `.gitignore`

## Authentication
- Protected routes: verify session via auth framework
- API routes: verify auth in middleware layer
- Rate limiting on auth endpoints

## CSRF
- Use framework's CSRF protection
- Do not bypass CSRF checks
