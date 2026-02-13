# Миграция проекта на централизованные ecosystem-инструкции

## Зачем

Ecosystem-репо (`~/.claude/`) содержит глобальные rules, agents, commands и hooks. Если проект дублирует их в своём `.claude/`, это:
- **Блокирует обновления** — проектный файл с тем же именем полностью перекрывает глобальный
- **Создаёт drift** — глобальный файл обновляется, а проектная копия нет
- **Засоряет проект** — лишние файлы без пользы

## Шаг 1: Аудит дублей

Запустить из корня проекта:

```bash
# Linux/Mac
for dir in rules agents commands; do
  if [ -d ".claude/$dir" ]; then
    echo "=== $dir ==="
    for f in .claude/$dir/*.md; do
      [ -f "$f" ] || continue
      name=$(basename "$f")
      global="$HOME/.claude/$dir/$name"
      if [ -f "$global" ]; then
        if diff -q "$f" "$global" > /dev/null 2>&1; then
          echo "  ДУБЛЬ (точный):     $name → УДАЛИТЬ"
        else
          echo "  ДУБЛЬ (изменённый): $name → РЕШИТЬ"
        fi
      else
        echo "  УНИКАЛЬНЫЙ:         $name → ОСТАВИТЬ"
      fi
    done
  fi
done
```

```powershell
# Windows
foreach ($dir in @("rules", "agents", "commands")) {
    $projectDir = ".claude\$dir"
    if (Test-Path $projectDir) {
        Write-Host "=== $dir ==="
        Get-ChildItem "$projectDir\*.md" | ForEach-Object {
            $global = Join-Path $env:USERPROFILE ".claude\$dir\$($_.Name)"
            if (Test-Path $global) {
                if ((Get-FileHash $_.FullName).Hash -eq (Get-FileHash $global).Hash) {
                    Write-Host "  ДУБЛЬ (точный):     $($_.Name) -> УДАЛИТЬ"
                } else {
                    Write-Host "  ДУБЛЬ (изменённый): $($_.Name) -> РЕШИТЬ"
                }
            } else {
                Write-Host "  УНИКАЛЬНЫЙ:         $($_.Name) -> ОСТАВИТЬ"
            }
        }
    }
}
```

## Шаг 2: Решения по изменённым дублям

Для каждого `ДУБЛЬ (изменённый)` задать вопрос:

> "Это улучшение полезно ВСЕМ проектам — или специфика ЭТОГО проекта?"

| Ответ | Действие |
|-------|----------|
| Полезно всем | Обновить глобальный файл в ecosystem-репо → удалить из проекта |
| Специфика проекта | Оставить, добавить комментарий `<!-- Override: отличие от глобального — ... -->` |

## Шаг 3: Удаление

1. Удалить файлы помеченные как `УДАЛИТЬ`
2. Удалить пустые директории (`rmdir .claude/rules` если пусто)
3. Обновить `CLAUDE.md` если он ссылался на удалённые файлы
4. Коммит: `refactor: remove duplicated ecosystem instructions`

## Шаг 4: Верификация

1. Открыть Claude Code в проекте
2. Спросить: "Какие у тебя правила по coding-style?" — должен ответить из глобальных
3. Проверить что проектные overrides (если есть) применяются поверх
4. Проверить что агенты и команды доступны: `@developer`, `/sprint`

## Что НЕ трогать

| Файл | Причина |
|------|---------|
| `CLAUDE.md` | Всегда проектно-специфичен |
| `.claude/settings.json` | Может содержать проектные deny-правила |
| `.mcp.json` | Всегда проектно-специфичен |

## Приоритеты мержа (напоминание)

```
project .claude/ > user ~/.claude/ > plugin
```

Проектный файл с тем же именем **полностью перекрывает** глобальный (не мержится).
