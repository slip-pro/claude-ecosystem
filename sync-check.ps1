# Claude Ecosystem Sync Check (Windows)
# Checks for:
# 1. Uncommitted changes in ecosystem repo
# 2. Project-level files that shadow global configs
# Run as: powershell -ExecutionPolicy Bypass -File sync-check.ps1

param(
    [string]$EcosystemDir = $PSScriptRoot,
    [string[]]$ProjectDirs = @()
)

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$Dirs = @("agents", "rules", "commands", "hooks")

Write-Host "Claude Ecosystem Sync Check" -ForegroundColor Cyan
Write-Host ""

# 1. Check for uncommitted changes in ecosystem repo
Write-Host "1. Ecosystem repo status:" -ForegroundColor Yellow

Push-Location $EcosystemDir
$gitStatus = git status --porcelain 2>$null
if ($gitStatus) {
    Write-Host "  WARN: Uncommitted changes detected!" -ForegroundColor Red
    $gitStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    Write-Host "  Run: cd $EcosystemDir && git add . && git commit && git push" -ForegroundColor Yellow
} else {
    Write-Host "  OK: No uncommitted changes" -ForegroundColor Green
}

# Check if local is behind remote
$defaultBranch = git symbolic-ref refs/remotes/origin/HEAD 2>$null
if ($defaultBranch) { $defaultBranch = Split-Path $defaultBranch -Leaf }
else { $defaultBranch = "master" }
$behind = git rev-list "HEAD..origin/$defaultBranch" --count 2>$null
$ahead = git rev-list "origin/${defaultBranch}..HEAD" --count 2>$null
if ($behind -gt 0) {
    Write-Host "  WARN: Local is $behind commits behind remote" -ForegroundColor Yellow
}
if ($ahead -gt 0) {
    Write-Host "  INFO: Local is $ahead commits ahead of remote (push needed)" -ForegroundColor Yellow
}
Pop-Location

# 2. Check junctions integrity
Write-Host ""
Write-Host "2. Junction integrity:" -ForegroundColor Yellow

foreach ($dir in $Dirs) {
    $target = Join-Path $ClaudeDir $dir
    $source = Join-Path $EcosystemDir $dir

    if (-not (Test-Path $target)) {
        Write-Host "  MISS $dir (not found in ~/.claude/)" -ForegroundColor Red
        continue
    }

    $item = Get-Item $target -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "  OK   $dir (junction)" -ForegroundColor Green
    } else {
        Write-Host "  WARN $dir is a regular directory, not a junction!" -ForegroundColor Red
    }
}

# 3. Check for shadow files in projects
Write-Host ""
Write-Host "3. Shadow file detection:" -ForegroundColor Yellow

# Auto-detect project directories if not specified
if ($ProjectDirs.Count -eq 0) {
    $codingDir = "D:\CODING"
    if (Test-Path $codingDir) {
        $ProjectDirs = Get-ChildItem -Path $codingDir -Directory |
            Where-Object { Test-Path (Join-Path $_.FullName ".claude") } |
            Select-Object -ExpandProperty FullName
    }
}

if ($ProjectDirs.Count -eq 0) {
    Write-Host "  No projects found to check" -ForegroundColor Gray
} else {
    # Get list of global config files
    $globalFiles = @{}
    foreach ($dir in $Dirs) {
        $source = Join-Path $EcosystemDir $dir
        if (Test-Path $source) {
            Get-ChildItem -Path $source -Recurse -File | ForEach-Object {
                $relPath = $_.FullName.Substring($source.Length + 1)
                $globalFiles["$dir/$relPath"] = $true
            }
        }
    }

    foreach ($project in $ProjectDirs) {
        $projectName = Split-Path $project -Leaf
        $projectClaude = Join-Path $project ".claude"
        $shadows = @()

        foreach ($dir in $Dirs) {
            $projectDir = Join-Path $projectClaude $dir
            if (Test-Path $projectDir) {
                Get-ChildItem -Path $projectDir -Recurse -File | ForEach-Object {
                    $relPath = $_.FullName.Substring($projectDir.Length + 1)
                    $key = "$dir/$relPath"
                    if ($globalFiles.ContainsKey($key)) {
                        $shadows += "    $key (project overrides global)"
                    }
                }
            }
        }

        if ($shadows.Count -gt 0) {
            Write-Host "  $projectName:" -ForegroundColor Yellow
            $shadows | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
        } else {
            Write-Host "  $projectName: OK (no shadows)" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
