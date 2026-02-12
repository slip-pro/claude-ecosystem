#!/bin/bash
# Cursor Rules Generator
# Generates .cursor/rules/*.mdc from ecosystem source files.
# Run as: bash setup-cursor.sh /path/to/my-project

set -e

ECOSYSTEM_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_PATH="$1"

# --- Color helpers ---
cyan() { echo -e "\033[36m$1\033[0m"; }
green() { echo -e "  \033[32m$1\033[0m $2"; }
yellow() { echo -e "  \033[33m$1\033[0m $2"; }
red() { echo -e "  \033[31m$1\033[0m $2"; }

# --- Validate args ---
if [ -z "$PROJECT_PATH" ]; then
  red "ERROR" "Usage: bash setup-cursor.sh <project-path>"
  exit 1
fi

cyan "Cursor Rules Generator"
echo "Ecosystem: $ECOSYSTEM_DIR"
echo "Project:   $PROJECT_PATH"
echo ""

if [ ! -d "$PROJECT_PATH" ]; then
  red "ERROR" "Project path not found: $PROJECT_PATH"
  exit 1
fi

# --- Ensure .cursor/rules/ exists ---
RULES_DIR="$PROJECT_PATH/.cursor/rules"
mkdir -p "$RULES_DIR"

# --- Rule definitions ---
# Each rule: "source|output|description"
RULES=(
  "rules/coding-style.md|coding-style.mdc|\
Coding style conventions: TypeScript, \
formatting, imports, file size limits"
  "rules/security.md|security.mdc|\
Security rules: input validation, XSS, \
SQL injection, secrets, auth, CSRF"
  "adapters/shared/workflow-gates.md|workflow-gates.mdc|\
Workflow quality gates, trigger \
recognition, anti-patterns"
  "adapters/shared/agents-guide.md|agents-guide.mdc|\
Agent roles, development principles, \
testing approach"
)

# --- Generate .mdc files ---
GENERATED=()

for entry in "${RULES[@]}"; do
  IFS='|' read -r source output desc <<< "$entry"

  source_path="$ECOSYSTEM_DIR/$source"
  output_path="$RULES_DIR/$output"

  if [ ! -f "$source_path" ]; then
    yellow "SKIP" "$output (source not found: $source)"
    continue
  fi

  content=$(cat "$source_path")

  # Write .mdc with YAML frontmatter
  cat > "$output_path" <<EOF
---
description: "$desc"
alwaysApply: true
---
$content
EOF

  green "OK  " "$output"
  GENERATED+=("$output")
done

echo ""
echo -e "\033[32mDone! Generated rules in:\033[0m"
echo "  $RULES_DIR"
echo ""
cyan "Files:"
for file in "${GENERATED[@]}"; do
  echo "  $file"
done
