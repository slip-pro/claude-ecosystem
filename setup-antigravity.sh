#!/bin/bash
# Antigravity Rules & Workflows Generator
# Generates .agent/rules/ and .agent/workflows/ from
# ecosystem source files.
# Run as: bash setup-antigravity.sh /path/to/project

set -e

# --- Colors ---
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

# --- Args ---

PROJECT_PATH="$1"
ECOSYSTEM_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$PROJECT_PATH" ]; then
  echo -e "${RED}ERROR: Project path required.${RESET}"
  echo "Usage: bash setup-antigravity.sh /path/to/project"
  exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
  echo -e "${RED}ERROR: Project path not found:" \
    "${RESET}$PROJECT_PATH"
  exit 1
fi

# --- Source mappings ---

RULE_SOURCES=(
  "rules/coding-style.md"
  "rules/security.md"
  "adapters/shared/workflow-gates.md"
  "adapters/shared/agents-guide.md"
)

RULE_OUTPUTS=(
  "coding-style.md"
  "security.md"
  "workflow-gates.md"
  "agents-guide.md"
)

# NOTE: task.md and done.md excluded — they require MCP board
# server which is only available in Claude Code.
WF_SOURCES=(
  "commands/sprint.md"
  "commands/close.md"
  "commands/audit.md"
  "commands/techdebt.md"
  "commands/plan.md"
  "commands/pbr.md"
)

WF_OUTPUTS=(
  "sprint.md"
  "close.md"
  "audit.md"
  "techdebt.md"
  "plan.md"
  "pbr.md"
)

# --- Helper: strip YAML frontmatter ---

strip_frontmatter() {
  local content="$1"
  local first_line
  first_line=$(echo "$content" | head -n 1)

  if [ "$first_line" != "---" ]; then
    echo "$content"
    return
  fi

  # Find closing --- and output everything after it
  echo "$content" | awk '
    BEGIN { count = 0; found = 0 }
    /^---$/ {
      count++
      if (count == 2) { found = 1; next }
    }
    found { print }
  ' | sed '/./,$!d'
}

# --- Main ---

echo -e "${CYAN}Antigravity Rules & Workflows Generator${RESET}"
echo "Ecosystem: $ECOSYSTEM_DIR"
echo "Project:   $PROJECT_PATH"
echo ""

RULES_DIR="$PROJECT_PATH/.agent/rules"
WORKFLOWS_DIR="$PROJECT_PATH/.agent/workflows"

# Ensure output directories exist
for dir in "$RULES_DIR" "$WORKFLOWS_DIR"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    echo -e "  ${GREEN}Created${RESET} $dir"
  fi
done

# --- Generate rules (direct copy) ---

echo ""
echo -e "${CYAN}Rules:${RESET}"

for i in "${!RULE_SOURCES[@]}"; do
  src="$ECOSYSTEM_DIR/${RULE_SOURCES[$i]}"
  out="$RULES_DIR/${RULE_OUTPUTS[$i]}"

  if [ ! -f "$src" ]; then
    echo -e "  ${YELLOW}SKIP${RESET}" \
      "${RULE_OUTPUTS[$i]} (source not found)"
    continue
  fi

  cp "$src" "$out"
  echo -e "  ${GREEN}OK${RESET}   ${RULE_OUTPUTS[$i]}"
done

# --- Generate workflows (strip frontmatter) ---

echo ""
echo -e "${CYAN}Workflows:${RESET}"

for i in "${!WF_SOURCES[@]}"; do
  src="$ECOSYSTEM_DIR/${WF_SOURCES[$i]}"
  out="$WORKFLOWS_DIR/${WF_OUTPUTS[$i]}"

  if [ ! -f "$src" ]; then
    echo -e "  ${YELLOW}SKIP${RESET}" \
      "${WF_OUTPUTS[$i]} (source not found)"
    continue
  fi

  content=$(cat "$src")
  cleaned=$(strip_frontmatter "$content")
  echo "$cleaned" > "$out"
  echo -e "  ${GREEN}OK${RESET}   ${WF_OUTPUTS[$i]}"
done

# --- Summary ---

echo ""
echo -e "${GREEN}Done! Generated files in:${RESET}"
echo "  $RULES_DIR"
echo "  $WORKFLOWS_DIR"
echo ""
echo -e "${CYAN}Structure:${RESET}"
echo "  .agent/"
echo "  +-- rules/"

for out in "${RULE_OUTPUTS[@]}"; do
  if [ -f "$RULES_DIR/$out" ]; then
    echo "  |   +-- $out"
  fi
done

echo "  +-- workflows/"

for out in "${WF_OUTPUTS[@]}"; do
  if [ -f "$WORKFLOWS_DIR/$out" ]; then
    echo "  |   +-- $out"
  fi
done
