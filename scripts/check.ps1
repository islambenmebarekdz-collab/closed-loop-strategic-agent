<#
.SYNOPSIS
    Quality gate for closed-loop-strategic-agent. Runs automatically before
    every push (see .githooks/pre-push).

.DESCRIPTION
    This repo is public and has no release stage: installs pull from `main`
    the moment it moves. So the only window to catch a defect is BEFORE the
    push -- a check that runs after it (CI) reports a break users already got.

        pwsh -File scripts\check.ps1            # before committing
        pwsh -File scripts\check.ps1 -Online    # after a push: is GitHub
                                                # serving what we have here?

    What it checks, and what it does NOT:
      1. Every file either installer downloads exists, for both languages,
         and both installers install the same set to the same places.
      2. install.ps1 parses the way Windows PowerShell 5.1 reads a SAVED file
         (ANSI unless BOM). Written after it was found broken for anyone who
         downloads it and runs it; `irm | iex` was unaffected. install.sh
         passes `bash -n`.
      3. Every skill and agent has valid frontmatter at byte 0 (a BOM there
         hides it), with name and description, and the name matches where the
         installer puts it.
      4. The Arabic and English copies of each skill have the same name and
         the same STRUCTURE (heading sequence, bullet, numbered-item, fence and
         table counts). AGENTS.md rule 1: a behaviour change lands in both in
         the same push. This is a tripwire for editing one language only; it
         CANNOT tell whether the two say the same thing. That still needs a
         side-by-side read, as AGENTS.md requires.
      Not checked: whether the installer actually runs on a clean machine
      (AGENTS.md asks for that by hand on Windows and Linux), and wording.

    ASCII-only: Windows PowerShell 5.1 reads .ps1 as ANSI without a BOM.
#>

[CmdletBinding()]
param(
    # Called from the pre-push hook: also refuse when tracked files have
    # uncommitted edits, because the checks read the working tree while the
    # push sends commits -- a pass would then vouch for something else.
    [switch]$PrePush,

    # Compare what raw.githubusercontent.com serves from main with this tree.
    [switch]$Online
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$results = @()
$failed = 0
function Add-Result([string]$Check, [bool]$Ok, [string]$Note = '') {
    $status = if ($Ok) { 'PASS' } else { 'FAIL' }
    $script:results += [PSCustomObject]@{ Check = $Check; Status = $status; Note = $Note }
    if (-not $Ok) { $script:failed++ }
}
function Read-Text([string]$Rel) {
    [System.IO.File]::ReadAllText((Join-Path $root $Rel), [System.Text.Encoding]::UTF8)
}

$ps1 = Read-Text 'install.ps1'
$sh  = Read-Text 'install.sh'

# --- 1) installer targets ----------------------------------------------------
function Get-Pairs([string]$Text, [string]$SrcPattern, [string]$DstPattern, [string]$LangVar) {
    $src = @([regex]::Matches($Text, $SrcPattern) | ForEach-Object { $_.Groups[1].Value.Replace($LangVar, '{L}') })
    $dst = @([regex]::Matches($Text, $DstPattern) | ForEach-Object { $_.Groups[1].Value.Replace('\', '/') })
    return @{ Src = $src; Dst = $dst }
}
$p = Get-Pairs $ps1 '\$base/([^"]+)"' 'Dest = "\$claude\\([^"]+)"' '$Lang'
$s = Get-Pairs $sh  '"\$BASE/([^"]+)"' '"\$CLAUDE/([^"]+)"' '$LANG_CHOICE'

Add-Result 'installers: same sources' (($p.Src -join '|') -eq ($s.Src -join '|')) ("ps1=" + $p.Src.Count + " sh=" + $s.Src.Count)
Add-Result 'installers: same destinations' (($p.Dst -join '|') -eq ($s.Dst -join '|')) ("ps1=" + $p.Dst.Count + " sh=" + $s.Dst.Count)

$missing = @()
foreach ($lang in 'ar', 'en') {
    foreach ($src in $p.Src) {
        $rel = $src.Replace('{L}', $lang)
        git cat-file -e ("HEAD:" + $rel) 2>$null
        if ($LASTEXITCODE -ne 0) { $missing += $rel }
    }
}
Add-Result 'installers: every source committed' ($missing.Count -eq 0) ($missing -join ', ')

$baseP = [regex]::Match($ps1, '\$base = "([^"]+)"').Groups[1].Value
$baseS = [regex]::Match($sh, 'BASE="([^"]+)"').Groups[1].Value
Add-Result 'installers: same base URL' ($baseP -and ($baseP -eq $baseS)) ''

# --- 2) installers parse -----------------------------------------------------
$bytes = [System.IO.File]::ReadAllBytes((Join-Path $root 'install.ps1'))
$nonAscii = @($bytes | Where-Object { $_ -gt 127 }).Count
Add-Result 'install.ps1: ASCII-only' ($nonAscii -eq 0) ("non-ASCII bytes: " + $nonAscii)

$errs = $null
[void][System.Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'install.ps1'), [ref]$null, [ref]$errs)
$note = (@($errs) | ForEach-Object { 'line ' + $_.Extent.StartLineNumber + ': ' + $_.Message }) -join '; '
Add-Result 'install.ps1: parses as a saved file' (@($errs).Count -eq 0) $note

# Git's own bash first: on Windows, `bash` on PATH is often the WSL launcher in
# WindowsApps, which mangles a Windows path ("No such file") and failed this
# check on a sound install.sh. Git for Windows keeps bash at <git>\..\..\bin.
$bash = $null
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    $gitBash = Join-Path (Split-Path (Split-Path $git.Source)) 'bin\bash.exe'
    if (Test-Path $gitBash) { $bash = $gitBash }
}
if (-not $bash) {
    $bash = Get-Command bash -All -ErrorAction SilentlyContinue |
        Where-Object { $_.Source -notlike '*\WindowsApps\*' } |
        Select-Object -First 1 -ExpandProperty Source
}
if ($bash) {
    $out = & $bash -n (Join-Path $root 'install.sh') 2>&1
    Add-Result 'install.sh: bash -n' ($LASTEXITCODE -eq 0) (($out | Out-String).Trim())
} else {
    Add-Result 'install.sh: bash -n' $false 'bash not found (the WSL launcher is skipped) -- not checked'
}

# --- 3) frontmatter ----------------------------------------------------------
function Get-Frontmatter([string]$Rel) {
    $b = [System.IO.File]::ReadAllBytes((Join-Path $root $Rel))
    $fm = @{ AtZero = ($b.Length -ge 3 -and $b[0] -eq 45 -and $b[1] -eq 45 -and $b[2] -eq 45) }
    $m = [regex]::Match((Read-Text $Rel), '(?s)\A---\r?\n(.*?)\r?\n---')
    if ($m.Success) {
        foreach ($line in ($m.Groups[1].Value -split '\r?\n')) {
            $kv = [regex]::Match($line, '^([A-Za-z_-]+):\s*(.*)$')
            if ($kv.Success) { $fm[$kv.Groups[1].Value] = $kv.Groups[2].Value.Trim() }
        }
    }
    return $fm
}

$expect = @{}   # file -> name the installer location implies
foreach ($i in 0..($p.Src.Count - 1)) {
    $dst = $p.Dst[$i]
    $name = if ($dst -match '^skills/([^/]+)/SKILL\.md$') { $Matches[1] }
            elseif ($dst -match '^agents/([^/]+)\.md$') { $Matches[1] } else { '' }
    foreach ($lang in 'ar', 'en') { $expect[$p.Src[$i].Replace('{L}', $lang)] = $name }
}

foreach ($rel in ($expect.Keys | Sort-Object)) {
    if (-not (Test-Path (Join-Path $root $rel))) { continue }   # reported above
    $fm = Get-Frontmatter $rel
    $problems = @()
    if (-not $fm.AtZero)       { $problems += 'no --- at byte 0 (BOM?)' }
    if (-not $fm['name'])      { $problems += 'no name' }
    if (-not $fm['description']) { $problems += 'no description' }
    if ($rel -like 'agents/*' -and -not $fm['tools']) { $problems += 'no tools' }
    if ($fm['name'] -and $expect[$rel] -and $fm['name'] -ne $expect[$rel]) {
        $problems += ("name '" + $fm['name'] + "' but installed as '" + $expect[$rel] + "'")
    }
    Add-Result ("frontmatter: " + $rel) ($problems.Count -eq 0) ($problems -join '; ')
}

# --- 4) ar/en parity ---------------------------------------------------------
function Get-Shape([string]$Rel) {
    $t = Read-Text $Rel
    $levels = ([regex]::Matches($t, '(?m)^(#+)\s') | ForEach-Object { $_.Groups[1].Value.Length }) -join ''
    return ('headings=' + $levels +
            ' bullets=' + [regex]::Matches($t, '(?m)^\s*[-*]\s').Count +
            ' numbered=' + [regex]::Matches($t, '(?m)^\s*\d+\.\s').Count +
            ' fences=' + [regex]::Matches($t, '(?m)^```').Count +
            ' tablerows=' + [regex]::Matches($t, '(?m)^\|').Count)
}
foreach ($src in ($p.Src | Where-Object { $_ -like '*{L}*' })) {
    $ar = $src.Replace('{L}', 'ar'); $en = $src.Replace('{L}', 'en')
    if (-not (Test-Path $ar) -or -not (Test-Path $en)) { continue }
    $sa = Get-Shape $ar; $se = Get-Shape $en
    Add-Result ("parity name: " + $src) ((Get-Frontmatter $ar)['name'] -eq (Get-Frontmatter $en)['name']) ''
    $n = if ($sa -eq $se) { '' } else { "ar: $sa | en: $se" }
    Add-Result ("parity shape: " + $src) ($sa -eq $se) $n
}

# --- pre-push: the tree must be what is being pushed -------------------------
if ($PrePush) {
    $dirty = @(git status --porcelain --untracked-files=no 2>$null)
    Add-Result 'pre-push: no uncommitted edits' ($dirty.Count -eq 0) (($dirty | Select-Object -First 5) -join '; ')
}

# --- online: what GitHub serves ----------------------------------------------
if ($Online) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $wc = New-Object System.Net.WebClient
    $files = @('install.ps1', 'install.sh')
    foreach ($lang in 'ar', 'en') { foreach ($src in $p.Src) { $files += $src.Replace('{L}', $lang) } }
    foreach ($rel in ($files | Select-Object -Unique)) {
        try {
            $remote = [System.Text.Encoding]::UTF8.GetString($wc.DownloadData($baseP + '/' + $rel)).Replace("`r`n", "`n")
            $local  = (Read-Text $rel).Replace("`r`n", "`n")
            Add-Result ("online: " + $rel) ($remote -eq $local) $(if ($remote -eq $local) { '' } else { 'GitHub main differs from this tree' })
        } catch {
            Add-Result ("online: " + $rel) $false $_.Exception.Message
        }
    }
}

Write-Host ''
$results | Format-Table -AutoSize -Wrap
if ($failed -gt 0) {
    Write-Host "$failed check(s) failed. main is the release here -- do not push." -ForegroundColor Red
    exit 1
}
Write-Host 'All checks passed.' -ForegroundColor Green
exit 0
