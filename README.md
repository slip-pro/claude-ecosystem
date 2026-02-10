# Claude Ecosystem

Centralized Claude Code configuration: agents, skills, rules, hooks, workflow templates.

## Installation

### Windows
```powershell
git clone <repo-url> D:\CODING\claude-ecosystem
cd D:\CODING\claude-ecosystem
powershell -ExecutionPolicy Bypass -File install.ps1
```

### Linux / Mac
```bash
git clone <repo-url> ~/claude-ecosystem
cd ~/claude-ecosystem
bash install.sh
```

## What's Included

| Type | Count | Description |
|------|-------|-------------|
| Agents | 5 | developer, auditor, tester, documentor, designer |
| Skills | 4 | /sprint, /close, /audit, /techdebt |
| Rules | 3 | coding-style, security, ecosystem-convention |
| Hooks | 4 | console.log checks, pre-compact save, ecosystem reminder |
| Workflow | 4 | DECISIONS, GOALS, BACKLOG, NOTE templates |

## How It Works

```
Ecosystem repo  -->  ~/.claude/ (junctions/symlinks)  -->  All projects
                                    +
                          Project .claude/ (overrides)
```

**Priority:** project `.claude/` > user `~/.claude/` > plugin

## Adding to a New Project

1. Copy workflow templates to your project:
   ```
   cp workflow/DECISIONS-TEMPLATE.md  your-project/docs/project-management/DECISIONS.md
   cp workflow/GOALS-TEMPLATE.md      your-project/docs/project-management/GOALS.md
   cp workflow/BACKLOG-TEMPLATE.md    your-project/docs/project-management/BACKLOG.md
   cp workflow/NOTE-TEMPLATE.md       your-project/docs/notes/TEMPLATE.md
   ```
2. Create CLAUDE.md with project description and tech stack
3. (Optional) Create `.claude/rules/<project>-stack.md` with framework-specific patterns
4. (Optional) Create `.claude/agents/` for project-specific agent overrides

## Updating

Edit files in this repo. Changes are immediately visible through junctions/symlinks.

```bash
cd ~/claude-ecosystem  # or D:\CODING\claude-ecosystem
git add . && git commit -m "update" && git push
```

On other machines: `git pull`

## Sync Check

```powershell
powershell -File sync-check.ps1
```

Checks for: uncommitted changes, broken junctions, shadow files in projects.
