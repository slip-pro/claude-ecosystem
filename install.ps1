# Claude Ecosystem Installer (Windows)
# Creates directory junctions from ~/.claude/ to this repo.
# Run as: powershell -ExecutionPolicy Bypass -File install.ps1

param(
    [string]$EcosystemDir = $PSScriptRoot
)

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$Dirs = @("agents", "rules", "skills", "hooks")

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

# Merge hooks into settings.json
Write-Host ""
Write-Host "Configuring hooks in settings.json..." -ForegroundColor Cyan

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

    # Merge hooks (replace hooks section)
    if ($hooksConfig.hooks) {
        $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue $hooksConfig.hooks -Force
    }

    # Write back
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8
    Write-Host "  Hooks configured in $settingsPath" -ForegroundColor Green
} else {
    Write-Host "  SKIP hooks (settings-hooks.json not found)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Verify:" -ForegroundColor Cyan
Write-Host "  1. Open Claude Code in any project"
Write-Host "  2. Check agents: @developer, @auditor, @tester, @documentor, @designer"
Write-Host "  3. Check skills: /sprint, /close, /audit, /techdebt"
Write-Host "  4. Edit a .ts file with console.log - hook should warn"
