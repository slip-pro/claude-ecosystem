# Claude Ecosystem Installer (Windows)
# Creates directory junctions from ~/.claude/ to this repo.
# Run as: powershell -ExecutionPolicy Bypass -File install.ps1

param(
    [string]$EcosystemDir = $PSScriptRoot
)

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$Dirs = @("agents", "rules", "commands", "hooks")

Write-Host "Claude Ecosystem Installer" -ForegroundColor Cyan
Write-Host "Ecosystem repo: $EcosystemDir"
Write-Host "Claude config:  $ClaudeDir"
Write-Host ""

# Ensure .claude directory exists
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
    Write-Host "Created $ClaudeDir"
}

# Create junctions for each directory
foreach ($dir in $Dirs) {
    $source = Join-Path $EcosystemDir $dir
    $target = Join-Path $ClaudeDir $dir

    if (-not (Test-Path $source)) {
        Write-Host "  SKIP $dir (not found in ecosystem repo)" -ForegroundColor Yellow
        continue
    }

    # Check if target already exists
    if (Test-Path $target) {
        $item = Get-Item $target -Force

        # Check if it's already a junction to the right place
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            $existingTarget = (Get-Item $target).Target
            if ($existingTarget -eq $source) {
                Write-Host "  OK   $dir (junction already exists)" -ForegroundColor Green
                continue
            }
            # Junction to wrong place - remove and recreate
            Write-Host "  FIX  $dir (updating junction)" -ForegroundColor Yellow
            cmd /c "rmdir `"$target`"" 2>$null
        } else {
            # Regular directory - backup and replace
            $backup = "${target}_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-Host "  BACK $dir -> $(Split-Path $backup -Leaf)" -ForegroundColor Yellow
            Rename-Item -Path $target -NewName $backup
        }
    }

    # Create junction (no elevation required, unlike symlinks)
    cmd /c "mklink /J `"$target`" `"$source`""
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  LINK $dir -> $source" -ForegroundColor Green
    } else {
        Write-Host "  FAIL $dir (junction creation failed)" -ForegroundColor Red
    }
}

# Merge hooks and permissions into settings.json
Write-Host ""
Write-Host "Configuring settings.json..." -ForegroundColor Cyan

$settingsPath = Join-Path $ClaudeDir "settings.json"
$hooksTemplatePath = Join-Path $EcosystemDir "settings-hooks.json"
$hooksDir = (Join-Path $ClaudeDir "hooks") -replace '\\', '/'

if (Test-Path $hooksTemplatePath) {
    # Read template and replace {HOOKS_DIR}
    $hooksTemplate = Get-Content $hooksTemplatePath -Raw
    $hooksTemplate = $hooksTemplate -replace '\{HOOKS_DIR\}', $hooksDir
    $hooksConfig = $hooksTemplate | ConvertFrom-Json

    # Read or create settings.json
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    } else {
        $settings = [PSCustomObject]@{}
    }

    # Merge ecosystem permissions into settings.json (add missing, keep existing)
    if ($hooksConfig.permissions) {
        $existingPerms = $null
        if ($settings.PSObject.Properties['permissions']) {
            $existingPerms = $settings.permissions
        }

        if (-not $existingPerms) {
            $settings | Add-Member -NotePropertyName "permissions" -NotePropertyValue $hooksConfig.permissions -Force
        } else {
            # Merge allow lists: add ecosystem permissions that don't already exist
            $existingAllow = @()
            if ($existingPerms.PSObject.Properties['allow']) {
                $existingAllow = @($existingPerms.allow)
            }
            foreach ($perm in $hooksConfig.permissions.allow) {
                if ($existingAllow -notcontains $perm) {
                    $existingAllow += $perm
                }
            }
            $existingPerms | Add-Member -NotePropertyName "allow" -NotePropertyValue $existingAllow -Force
            $settings | Add-Member -NotePropertyName "permissions" -NotePropertyValue $existingPerms -Force
        }
        Write-Host "  Permissions configured" -ForegroundColor Green
    }

    # Merge ecosystem hooks into settings.json (preserves user-added hooks)
    if ($hooksConfig.hooks) {
        $existingHooks = $null
        if ($settings.PSObject.Properties['hooks']) {
            $existingHooks = $settings.hooks
        }

        if (-not $existingHooks) {
            # No existing hooks — just set ecosystem hooks
            $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue $hooksConfig.hooks -Force
        } else {
            # Merge: for each lifecycle event, append ecosystem entries that don't already exist
            foreach ($hookEvent in $hooksConfig.hooks.PSObject.Properties) {
                $eventName = $hookEvent.Name
                $ecosystemEntries = $hookEvent.Value

                if (-not $existingHooks.PSObject.Properties[$eventName]) {
                    # Event doesn't exist in current settings — add it
                    $existingHooks | Add-Member -NotePropertyName $eventName -NotePropertyValue $ecosystemEntries -Force
                } else {
                    # Event exists — merge hook entries by checking command strings
                    $existing = @($existingHooks.$eventName)
                    foreach ($ecosystemEntry in $ecosystemEntries) {
                        $ecosystemHooks = $ecosystemEntry.hooks
                        $entryAlreadyExists = $false
                        foreach ($hook in $ecosystemHooks) {
                            $hookCommand = $hook.command
                            # Check if this hook command already exists in any entry
                            foreach ($existingEntry in $existing) {
                                foreach ($existingHook in $existingEntry.hooks) {
                                    if ($existingHook.command -eq $hookCommand) {
                                        $entryAlreadyExists = $true
                                        break
                                    }
                                }
                                if ($entryAlreadyExists) { break }
                            }
                            if ($entryAlreadyExists) { break }
                        }
                        if (-not $entryAlreadyExists) {
                            $existing += $ecosystemEntry
                        }
                    }
                    $existingHooks.$eventName = $existing
                }
            }
            $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue $existingHooks -Force
        }
    }

    # Write back
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8
    Write-Host "  Hooks configured in $settingsPath" -ForegroundColor Green
} else {
    Write-Host "  SKIP hooks (settings-hooks.json not found)" -ForegroundColor Yellow
}

# Build Board MCP server
Write-Host ""
Write-Host "Building Board MCP server..." -ForegroundColor Cyan

$boardServerDir = Join-Path $EcosystemDir "mcp\board-server"
if (Test-Path $boardServerDir) {
    Push-Location $boardServerDir
    try {
        if (-not (Test-Path "node_modules")) {
            Write-Host "  Installing dependencies..."
            npm install --silent 2>&1 | Out-Null
        }
        npm run build --silent 2>&1 | Out-Null
        if (Test-Path "dist\board-server.js") {
            Write-Host "  Board MCP server built" -ForegroundColor Green
        } else {
            Write-Host "  WARN build completed but dist/board-server.js not found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  FAIL Board MCP server build failed: $_" -ForegroundColor Red
    }
    Pop-Location
} else {
    Write-Host "  SKIP Board MCP server (directory not found)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Verify:" -ForegroundColor Cyan
Write-Host "  1. Open Claude Code in any project"
Write-Host "  2. Check agents: @developer, @auditor, @tester, @documentor, @designer"
Write-Host "  3. Check commands: /plan, /pbr, /sprint, /close, /task, /done, /audit, /techdebt"
Write-Host "  4. Edit a .ts file with console.log - hook should warn"
Write-Host ""
Write-Host "Board setup:" -ForegroundColor Cyan
Write-Host "  1. Copy mcp/board-server/.mcp.template.json to project root as .mcp.json"
Write-Host "  2. Set MCP_API_URL, MCP_API_KEY, MCP_BOARD_ID in .mcp.json"
Write-Host "  3. Replace ECOSYSTEM_PATH with actual path to this repo"
