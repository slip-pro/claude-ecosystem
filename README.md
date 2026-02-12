# Claude Ecosystem

Centralized Claude Code configuration: agents, commands, rules, hooks, workflow templates.

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
| Commands | 8 | /plan, /pbr, /sprint, /audit, /close, /task, /done, /techdebt |
| Rules | 3 | coding-style, security, ecosystem-convention |
| Hooks | 4 | console.log checks, pre-compact save, ecosystem reminder |
| Workflow | 5 | DECISIONS (sprint), DECISIONS (board), GOALS, BACKLOG, NOTE |
| MCP | 1 | board-server (task board integration) |

## How It Works

```
Ecosystem repo  -->  ~/.claude/ (junctions/symlinks)  -->  All projects
                                    +
                          Project .claude/ (overrides)
```

**Priority:** project `.claude/` > user `~/.claude/` > plugin

## Workflow Modes

Экосистема поддерживает два режима работы — можно использовать оба одновременно.

### Sprint Mode (активная разработка)

Для проектов с целями, бэклогом и спринтами. Крупные фичи, планомерная разработка.

| Команда | Назначение |
|---------|-----------|
| `/plan` | Начальное планирование целей |
| `/pbr` | Груминг бэклога |
| `/sprint` | Открыть спринт |
| `/close` | Закрыть спринт |

**Файлы проекта:** DECISIONS.md (из sprint-шаблона), GOALS.md, BACKLOG.md

### Board Mode (поддержка, баги, задачи)

Для проектов с доской задач через MCP. Задачи берутся по одной с доски.

| Команда | Назначение |
|---------|-----------|
| `/task` | Открыть задачу с доски |
| `/done` | Закрыть задачу, обновить доску |

**Файлы проекта:** DECISIONS.md (из board-шаблона), MCP board server настроен

### Общие команды

| Команда | Назначение |
|---------|-----------|
| `/audit` | Аудит кода (GATE 2) |
| `/techdebt` | Поиск и логирование tech debt |

### Оба режима одновременно

Проект может использовать спринты для крупных фич и доску для багов/поддержки:
- Крупные фичи: `/sprint` → `/close`
- Баги, поддержка: `/task` → `/done`

## Adding to a New Project

### Sprint mode
1. Copy workflow templates:
   ```
   cp workflow/DECISIONS-TEMPLATE.md  your-project/DECISIONS.md
   cp workflow/GOALS-TEMPLATE.md      your-project/GOALS.md
   cp workflow/BACKLOG-TEMPLATE.md    your-project/BACKLOG.md
   cp workflow/NOTE-TEMPLATE.md       your-project/docs/notes/TEMPLATE.md
   ```
2. Create CLAUDE.md with project description and tech stack
3. (Optional) `.claude/rules/<project>-stack.md` for framework-specific patterns

### Board mode
1. Copy board DECISIONS template:
   ```
   cp workflow/DECISIONS-BOARD-TEMPLATE.md  your-project/DECISIONS.md
   ```
2. Set up MCP board server (see `mcp/board-server/README.md`)
3. Create CLAUDE.md with project description and tech stack

### Both modes
1. Copy both DECISIONS templates, merge relevant sections into your DECISIONS.md
2. Set up GOALS.md + BACKLOG.md for sprint mode
3. Set up MCP board server for board mode

## Board Mode Setup

1. Build the MCP server:
   ```bash
   cd mcp/board-server
   npm install
   npm run build
   ```

2. Add to project's `.claude/settings.local.json`:
   ```json
   {
     "mcpServers": {
       "board": {
         "command": "node",
         "args": ["/path/to/claude-ecosystem/mcp/board-server/dist/board-server.js"],
         "env": {
           "MCP_API_URL": "https://your-app.com",
           "MCP_API_KEY": "your-api-key",
           "MCP_BOARD_ID": "your-board-id"
         }
       }
     }
   }
   ```

3. See `mcp/board-server/README.md` for details.

## Multi-Tool Support

Помимо Claude Code, экосистема поддерживает генерацию конфигов для других AI-инструментов.

### Что портируется

| Контент | Claude Code | Cursor | Codex CLI | Antigravity |
|---------|:-----------:|:------:|:---------:|:-----------:|
| Coding rules | rules/ | .mdc | AGENTS.md | .md |
| Security rules | rules/ | .mdc | AGENTS.md | .md |
| Workflow gates | symlinks | .mdc | AGENTS.md | .md |
| Agent principles | agents/ | .mdc | AGENTS.md | .md |
| Commands (sprint, close...) | commands/ | -- | -- | workflows/ (без task/done) |
| Hooks | hooks/ | -- | -- | -- |
| MCP board server | settings.json | -- | -- | -- |

### Setup-скрипты

Каждый скрипт принимает путь к проекту и генерирует tool-specific конфиги из ecosystem source files.

**Cursor** — генерирует `.cursor/rules/*.mdc`:
```bash
# Windows
powershell -ExecutionPolicy Bypass -File setup-cursor.ps1 D:\CODING\my-project

# Linux / Mac
bash setup-cursor.sh ~/my-project
```

**OpenAI Codex CLI** — генерирует `AGENTS.md` в корне проекта:
```bash
# Windows
powershell -ExecutionPolicy Bypass -File setup-codex.ps1 D:\CODING\my-project

# Linux / Mac
bash setup-codex.sh ~/my-project
```

**Google Antigravity** — генерирует `.agent/rules/` и `.agent/workflows/`:
```bash
# Windows
powershell -ExecutionPolicy Bypass -File setup-antigravity.ps1 D:\CODING\my-project

# Linux / Mac
bash setup-antigravity.sh ~/my-project
```

Повторный запуск безопасно обновляет файлы. Пользовательские файлы в тех же директориях не затрагиваются.

> **Примечание:** Hooks и MCP board server — только для Claude Code. Для остальных инструментов портируются правила, workflow и принципы разработки.

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
