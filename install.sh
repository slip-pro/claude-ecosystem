#!/bin/bash
# Claude Ecosystem Installer (Linux/Mac)
# Creates symlinks from ~/.claude/ to this repo.
# Run as: bash install.sh

set -e

ECOSYSTEM_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
DIRS=("agents" "rules" "commands" "skills" "hooks")

echo -e "\033[36mClaude Ecosystem Installer\033[0m"
echo "Ecosystem repo: $ECOSYSTEM_DIR"
echo "Claude config:  $CLAUDE_DIR"
echo ""

# Ensure .claude directory exists
mkdir -p "$CLAUDE_DIR"

# Create symlinks for each directory
for dir in "${DIRS[@]}"; do
    source="$ECOSYSTEM_DIR/$dir"
    target="$CLAUDE_DIR/$dir"

    if [ ! -d "$source" ]; then
        echo -e "  \033[33mSKIP\033[0m $dir (not found in ecosystem repo)"
        continue
    fi

    # Check if target already exists
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            existing=$(readlink -f "$target" 2>/dev/null || readlink "$target")
            if [ "$existing" = "$source" ]; then
                echo -e "  \033[32mOK\033[0m   $dir (symlink already exists)"
                continue
            fi
            # Symlink to wrong place - remove and recreate
            echo -e "  \033[33mFIX\033[0m  $dir (updating symlink)"
            rm "$target"
        else
            # Regular directory - backup and replace
            backup="${target}_backup_$(date +%Y%m%d_%H%M%S)"
            echo -e "  \033[33mBACK\033[0m $dir -> $(basename $backup)"
            mv "$target" "$backup"
        fi
    fi

    # Create symlink
    ln -s "$source" "$target"
    echo -e "  \033[32mLINK\033[0m $dir -> $source"
done

# Merge hooks into settings.json
echo ""
echo -e "\033[36mConfiguring hooks in settings.json...\033[0m"

SETTINGS_PATH="$CLAUDE_DIR/settings.json"
HOOKS_TEMPLATE="$ECOSYSTEM_DIR/settings-hooks.json"
HOOKS_DIR="$CLAUDE_DIR/hooks"

if [ -f "$HOOKS_TEMPLATE" ]; then
    # Read template and replace {HOOKS_DIR}
    HOOKS_JSON=$(sed "s|{HOOKS_DIR}|$HOOKS_DIR|g" "$HOOKS_TEMPLATE")

    if command -v jq &> /dev/null; then
        # Use jq for proper JSON merging
        if [ -f "$SETTINGS_PATH" ]; then
            EXISTING=$(cat "$SETTINGS_PATH")
        else
            EXISTING='{}'
        fi

        HOOKS_SECTION=$(echo "$HOOKS_JSON" | jq '.hooks')
        echo "$EXISTING" | jq --argjson hooks "$HOOKS_SECTION" '. + {hooks: $hooks}' > "$SETTINGS_PATH"
        echo -e "  \033[32mHooks configured\033[0m in $SETTINGS_PATH"
    else
        echo -e "  \033[33mWARN\033[0m jq not found. Please manually merge hooks from settings-hooks.json"
        echo "       Install jq: brew install jq (Mac) or apt install jq (Linux)"
    fi
else
    echo -e "  \033[33mSKIP\033[0m hooks (settings-hooks.json not found)"
fi

echo ""
echo -e "\033[32mInstallation complete!\033[0m"
echo ""
echo -e "\033[36mVerify:\033[0m"
echo "  1. Open Claude Code in any project"
echo "  2. Check agents: @developer, @auditor, @tester, @documentor, @designer"
echo "  3. Check skills: /sprint, /close, /audit, /techdebt"
echo "  4. Edit a .ts file with console.log - hook should warn"
