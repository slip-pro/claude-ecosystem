#!/bin/bash
# Claude Ecosystem Installer (Linux/Mac)
# Creates symlinks from ~/.claude/ to this repo.
# Run as: bash install.sh

set -e

ECOSYSTEM_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
DIRS=("agents" "rules" "commands" "hooks")

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

# Merge hooks and permissions into settings.json
echo ""
echo -e "\033[36mConfiguring settings.json...\033[0m"

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
        PERMS_SECTION=$(echo "$HOOKS_JSON" | jq '.permissions')

        # Merge permissions (additive) and hooks (additive, deduplicate by command)
        MERGED=$(echo "$EXISTING" | jq \
            --argjson hooks "$HOOKS_SECTION" \
            --argjson perms "$PERMS_SECTION" \
            '
            .permissions.allow = ((.permissions.allow // []) + ($perms.allow // []) | unique)
            | .hooks as $existing_hooks
            | .hooks = (
                reduce ($hooks | to_entries[]) as $event (
                  ($existing_hooks // {});
                  .[$event.key] = (
                    (.[$event.key] // []) as $existing |
                    $existing + [
                      $event.value[] | select(
                        .hooks[0].command as $cmd |
                        [$existing[] | .hooks[].command] | index($cmd) | not
                      )
                    ]
                  )
                )
              )
            ')
        echo "$MERGED" > "$SETTINGS_PATH"

        echo -e "  \033[32mPermissions configured\033[0m"
        echo -e "  \033[32mHooks configured\033[0m in $SETTINGS_PATH"
    else
        echo -e "  \033[31mERROR\033[0m jq is required for settings.json configuration."
        echo "        Install jq: sudo apt install jq (Debian/Ubuntu) or brew install jq (macOS)"
        echo "        Then re-run this script."
        exit 1
    fi
else
    echo -e "  \033[33mSKIP\033[0m hooks (settings-hooks.json not found)"
fi

# Build Board MCP server
echo ""
echo -e "\033[36mBuilding Board MCP server...\033[0m"

BOARD_SERVER_DIR="$ECOSYSTEM_DIR/mcp/board-server"
if [ -d "$BOARD_SERVER_DIR" ]; then
    pushd "$BOARD_SERVER_DIR" > /dev/null
    if [ ! -d "node_modules" ]; then
        echo "  Installing dependencies..."
        npm install --silent 2>/dev/null
    fi
    npm run build --silent 2>/dev/null
    if [ -f "dist/board-server.js" ]; then
        echo -e "  \033[32mBoard MCP server built\033[0m"
    else
        echo -e "  \033[33mWARN\033[0m build completed but dist/board-server.js not found"
    fi
    popd > /dev/null
else
    echo -e "  \033[33mSKIP\033[0m Board MCP server (directory not found)"
fi

echo ""
echo -e "\033[32mInstallation complete!\033[0m"
echo ""
echo -e "\033[36mVerify:\033[0m"
echo "  1. Open Claude Code in any project"
echo "  2. Check agents: @developer, @auditor, @tester, @documentor, @designer"
echo "  3. Check commands: /plan, /pbr, /sprint, /close, /task, /done, /audit, /techdebt"
echo "  4. Edit a .ts file with console.log - hook should warn"
echo ""
echo -e "\033[36mBoard setup:\033[0m"
echo "  1. Copy mcp/board-server/.mcp.template.json to project root as .mcp.json"
echo "  2. Set MCP_API_URL, MCP_API_KEY, MCP_BOARD_ID in .mcp.json"
echo "  3. Replace ECOSYSTEM_PATH with actual path to this repo"
