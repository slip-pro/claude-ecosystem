# Research Confidence Levels

## При исследовании (Explore, WebSearch, Context7)

Каждый finding помечай уровнем уверенности:

- **HIGH** — проверено через Context7 или официальную документацию
- **MEDIUM** — несколько независимых источников согласны
- **LOW** — один источник, training data, или непроверенная информация

## Правила присвоения

| Источник | Confidence |
|----------|-----------|
| Context7 (resolve-library-id + query-docs) | HIGH |
| Официальная документация (WebFetch на docs сайте) | HIGH |
| Несколько WebSearch результатов согласны | MEDIUM |
| Один WebSearch результат | LOW |
| Знания из training data (без проверки) | LOW |
| Stack Overflow / GitHub issues | MEDIUM (если свежие) |

## Формат вывода

При предоставлении research findings:

```
### [Тема]
[Описание finding]
**Confidence: HIGH** — проверено через Context7, версия X.Y

### [Другая тема]
[Описание]
**Confidence: LOW** — из training data, рекомендуется проверить
```

## Важно

- Не выдавай LOW-confidence за факт — явно предупреди
- Для критических решений (выбор стека, архитектура) — требуй HIGH
- Для некритических решений — MEDIUM достаточно
- Training data — это гипотеза, не факт. Проверяй через инструменты
