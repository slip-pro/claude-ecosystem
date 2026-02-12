# Cursor Rules Generator
# Generates .cursor/rules/*.mdc from ecosystem source files.
# Run as: powershell -File setup-cursor.ps1 D:\CODING\my-project

param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath
)

$EcosystemDir = $PSScriptRoot

# Source files mapped to output .mdc files
# Format: @{ output = source; description }
$Rules = @(
  @{
    Source = "rules\coding-style.md"
    Output = "coding-style.mdc"
    Desc   = "Coding style conventions: TypeScript, " +
             "formatting, imports, file size limits"
  },
  @{
    Source = "rules\security.md"
    Output = "security.mdc"
    Desc   = "Security rules: input validation, XSS, " +
             "SQL injection, secrets, auth, CSRF"
  },
  @{
    Source = "adapters\shared\workflow-gates.md"
    Output = "workflow-gates.mdc"
    Desc   = "Workflow quality gates, trigger " +
             "recognition, anti-patterns"
  },
  @{
    Source = "adapters\shared\agents-guide.md"
    Output = "agents-guide.mdc"
    Desc   = "Agent roles, development principles, " +
             "testing approach"
  }
)

Write-Host "Cursor Rules Generator" -ForegroundColor Cyan
Write-Host "Ecosystem: $EcosystemDir"
Write-Host "Project:   $ProjectPath"
Write-Host ""

# Validate project path
if (-not (Test-Path $ProjectPath)) {
  Write-Host "ERROR: Project path not found: $ProjectPath" `
    -ForegroundColor Red
  exit 1
}

# Ensure .cursor/rules/ directory exists
$RulesDir = Join-Path $ProjectPath ".cursor\rules"
if (-not (Test-Path $RulesDir)) {
  New-Item -ItemType Directory -Path $RulesDir `
    | Out-Null
  Write-Host "  Created $RulesDir" `
    -ForegroundColor Green
}

# Generate .mdc files
foreach ($rule in $Rules) {
  $sourcePath = Join-Path $EcosystemDir $rule.Source
  $outputPath = Join-Path $RulesDir $rule.Output

  if (-not (Test-Path $sourcePath)) {
    Write-Host "  SKIP $($rule.Output) " `
      "(source not found: $($rule.Source))" `
      -ForegroundColor Yellow
    continue
  }

  $content = Get-Content $sourcePath -Raw -Encoding utf8

  # Build .mdc with YAML frontmatter
  $mdc = @"
---
description: "$($rule.Desc)"
alwaysApply: true
---
$content
"@

  # Write UTF-8 without BOM (compatible with both
  # PowerShell 5.x and 7.x)
  $utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText(
    $outputPath, $mdc, $utf8NoBom
  )
  Write-Host "  OK   $($rule.Output)" `
    -ForegroundColor Green
}

Write-Host ""
Write-Host "Done! Generated rules in:" `
  -ForegroundColor Green
Write-Host "  $RulesDir"
Write-Host ""
Write-Host "Files:" -ForegroundColor Cyan
foreach ($rule in $Rules) {
  $outputPath = Join-Path $RulesDir $rule.Output
  if (Test-Path $outputPath) {
    Write-Host "  $($rule.Output)"
  }
}
