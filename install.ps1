# Installs the full closed-loop system (2 skills + 2 agents) for Claude Code on Windows.
# Usage:  irm https://raw.githubusercontent.com/islambenmebarekdz-collab/closed-loop-strategic-agent/main/install.ps1 | iex
# English skill bodies instead of Arabic:
#         & ([scriptblock]::Create((irm <same URL>))) en
param([ValidateSet("ar", "en")][string]$Lang = "ar")

$ErrorActionPreference = "Stop"
$base = "https://raw.githubusercontent.com/islambenmebarekdz-collab/closed-loop-strategic-agent/main"
$claude = Join-Path $HOME ".claude"

$files = @(
    @{ Url = "$base/$Lang/SKILL.md";          Dest = "$claude\skills\closed-loop-strategic-agent\SKILL.md" },
    @{ Url = "$base/reviewer/$Lang/SKILL.md"; Dest = "$claude\skills\closed-loop-reviewer\SKILL.md" },
    @{ Url = "$base/agents/independent-reviewer.md"; Dest = "$claude\agents\independent-reviewer.md" },
    @{ Url = "$base/agents/behavior-tester.md";      Dest = "$claude\agents\behavior-tester.md" }
)

foreach ($f in $files) {
    New-Item -ItemType Directory -Force (Split-Path $f.Dest) | Out-Null
    Invoke-WebRequest -Uri $f.Url -OutFile $f.Dest -UseBasicParsing
    Write-Host "Installed: $($f.Dest)"
}

Write-Host ""
Write-Host "Done ($Lang version). Open a new Claude Code session and say:"
Write-Host '  "سنعمل وفق منظومة الحلقة المغلقة" / "we work per the closed-loop system"'
