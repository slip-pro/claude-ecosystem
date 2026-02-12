# Antigravity Rules & Workflows Generator
# Generates .agent/rules/ and .agent/workflows/ from
# ecosystem source files.
# Run as: powershell -File setup-antigravity.ps1 D:\path

param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath
)

$EcosystemDir = $PSScriptRoot

# --- Source mappings ---

$Rules = @(
  @{
    Source = "rules\coding-style.md"
    Output = "coding-style.md"
  },
  @{
    Source = "rules\security.md"
    Output = "security.md"
  },
  @{
    Source = "adapters\shared\workflow-gates.md"
    Output = "workflow-gates.md"
  },
  @{
    Source = "adapters\shared\agents-guide.md"
    Output = "agents-guide.md"
  }
)

# NOTE: task.md and done.md excluded — they require MCP board
# server which is only available in Claude Code.
$Workflows = @(
  @{
    Source = "commands\sprint.md"
    Output = "sprint.md"
  },
  @{
    Source = "commands\close.md"
    Output = "close.md"
  },
  @{
    Source = "commands\audit.md"
    Output = "audit.md"
  },
  @{
    Source = "commands\techdebt.md"
    Output = "techdebt.md"
  },
  @{
    Source = "commands\plan.md"
    Output = "plan.md"
  },
  @{
    Source = "commands\pbr.md"
    Output = "pbr.md"
  }
)

# --- Helper: strip YAML frontmatter ---

function Remove-Frontmatter {
  param([string]$Content)

  if (-not $Content.StartsWith("---")) {
    return $Content
  }

  # Find the closing --- (second occurrence)
  $lines = $Content -split "`n"
  $endIndex = -1

  for ($i = 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].TrimEnd() -eq "---") {
      $endIndex = $i
      break
    }
  }

  if ($endIndex -eq -1) {
    return $Content
  }

  # Return everything after the closing ---
  $remaining = $lines[($endIndex + 1)..($lines.Count - 1)]
  $result = ($remaining -join "`n").TrimStart("`r`n")
  return $result
}

# --- Main ---

Write-Host "Antigravity Rules & Workflows Generator" `
  -ForegroundColor Cyan
Write-Host "Ecosystem: $EcosystemDir"
Write-Host "Project:   $ProjectPath"
Write-Host ""

# Validate project path
if (-not (Test-Path $ProjectPath)) {
  Write-Host "ERROR: Project path not found: " `
    -ForegroundColor Red -NoNewline
  Write-Host $ProjectPath
  exit 1
}

# Ensure output directories exist
$RulesDir = Join-Path $ProjectPath ".agent\rules"
$WorkflowsDir = Join-Path $ProjectPath ".agent\workflows"

foreach ($dir in @($RulesDir, $WorkflowsDir)) {
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir `
      | Out-Null
    Write-Host "  Created $dir" `
      -ForegroundColor Green
  }
}

# --- Generate rules (direct copy) ---

Write-Host ""
Write-Host "Rules:" -ForegroundColor Cyan

foreach ($rule in $Rules) {
  $sourcePath = Join-Path $EcosystemDir $rule.Source
  $outputPath = Join-Path $RulesDir $rule.Output

  if (-not (Test-Path $sourcePath)) {
    Write-Host "  SKIP $($rule.Output) " `
      "(source not found)" `
      -ForegroundColor Yellow
    continue
  }

  $content = Get-Content $sourcePath -Raw `
    -Encoding utf8
  Set-Content -Path $outputPath -Value $content `
    -Encoding utf8 -NoNewline

  Write-Host "  OK   $($rule.Output)" `
    -ForegroundColor Green
}

# --- Generate workflows (strip frontmatter) ---

Write-Host ""
Write-Host "Workflows:" -ForegroundColor Cyan

foreach ($wf in $Workflows) {
  $sourcePath = Join-Path $EcosystemDir $wf.Source
  $outputPath = Join-Path $WorkflowsDir $wf.Output

  if (-not (Test-Path $sourcePath)) {
    Write-Host "  SKIP $($wf.Output) " `
      "(source not found)" `
      -ForegroundColor Yellow
    continue
  }

  $content = Get-Content $sourcePath -Raw `
    -Encoding utf8
  $cleaned = Remove-Frontmatter -Content $content
  Set-Content -Path $outputPath -Value $cleaned `
    -Encoding utf8 -NoNewline

  Write-Host "  OK   $($wf.Output)" `
    -ForegroundColor Green
}

# --- Summary ---

Write-Host ""
Write-Host "Done! Generated files in:" `
  -ForegroundColor Green
Write-Host "  $RulesDir"
Write-Host "  $WorkflowsDir"
Write-Host ""
Write-Host "Structure:" -ForegroundColor Cyan
Write-Host "  .agent/"
Write-Host "  +-- rules/"

foreach ($rule in $Rules) {
  $outputPath = Join-Path $RulesDir $rule.Output
  if (Test-Path $outputPath) {
    Write-Host "  |   +-- $($rule.Output)"
  }
}

Write-Host "  +-- workflows/"

foreach ($wf in $Workflows) {
  $outputPath = Join-Path $WorkflowsDir $wf.Output
  if (Test-Path $outputPath) {
    Write-Host "  |   +-- $($wf.Output)"
  }
}
