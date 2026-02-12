# Board MCP Server

MCP server для интеграции Claude Code с доской задач. Предоставляет инструменты для чтения и управления карточками на доске.

## Инструменты

| Tool | Описание | Режим |
|------|----------|-------|
| `get_board_tasks` | Состояние доски: колонки, карточки, приоритеты | REST / Prisma |
| `get_card_details` | Детали карточки: описание, чеклисты, комментарии | REST / Prisma |
| `move_card` | Переместить карточку в другую колонку | REST only |
| `add_comment` | Добавить комментарий к карточке | REST only |
| `update_card` | Обновить заголовок, описание, приоритет, дедлайн | REST only |
| `create_card` | Создать новую карточку | REST only |

## Режимы работы

### REST API (рекомендуется)
Подключается к внешнему API доски. Поддерживает чтение и запись.

```env
MCP_API_URL=https://app.example.com
MCP_API_KEY=sk_live_xxxxx
MCP_BOARD_ID=your-board-id
```

### Prisma (локальная БД)
Для проектов, где доска — часть приложения с Prisma ORM. Только чтение.

**Требования:**
- Проект должен иметь `@prisma/client` в своих зависимостях с уже сгенерированным клиентом (`prisma generate`)
- MCP-сервер подхватывает `@prisma/client` через dynamic import из проекта

```env
MCP_BOARD_ID=your-board-id
# Без MCP_API_URL — автоматически Prisma mode
```

## Подключение к проекту

### 1. Сборка (автоматически через installer)

Инсталлер экосистемы (`install.ps1` / `install.sh`) собирает сервер автоматически. Ручная сборка:

```bash
cd mcp/board-server
npm install
npm run build
```

### 2. Per-project `.mcp.json`

Скопировать `.mcp.template.json` в корень проекта как `.mcp.json`. Все credentials хранятся в `.mcp.json` проекта:

```json
{
  "mcpServers": {
    "board": {
      "command": "node",
      "args": ["/path/to/claude-ecosystem/mcp/board-server/dist/board-server.js"],
      "env": {
        "MCP_API_URL": "https://app.example.com",
        "MCP_API_KEY": "sk_live_xxxxx",
        "MCP_BOARD_ID": "your-board-id"
      }
    }
  }
}
```

Заменить:
- `ECOSYSTEM_PATH` — путь к ecosystem-репо
- `MCP_API_URL` — URL доски
- `MCP_API_KEY` — API-ключ
- `MCP_BOARD_ID` — ID доски проекта

**Важно:** `.mcp.json` содержит секреты — добавь в `.gitignore`.

### 3. Проверка

Открой Claude Code в проекте и проверь:
```
/task
```
Должен показать задачи с доски.

## API Contract

REST API должен поддерживать эндпоинты:

```
GET  /api/v1/boards/:boardId           — доска с колонками и карточками
GET  /api/v1/boards/cards/:cardId      — детали карточки
POST /api/v1/boards/cards/:cardId/move — переместить карточку
POST /api/v1/boards/cards/:cardId/comments — добавить комментарий
PATCH /api/v1/boards/cards/:cardId     — обновить карточку
POST /api/v1/boards/cards              — создать карточку
```

Авторизация: `Authorization: Bearer <API_KEY>`
