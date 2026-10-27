<#
.SYNOPSIS
    Restores Windows dotfiles from this repo.

.DESCRIPTION
    Links each tracked config file into place so later edits (for example from the Windows Terminal
    settings UI) land in the repo and only need a commit. Any existing real file is renamed to
    <name>.bak-<timestamp> first.

    Symbolic links need Developer Mode (Settings > System > For developers) or an elevated prompt.
    Without either, files are copied instead and a warning is shown. Copies don't carry edits back
    to the repo, so run with -Pull after changing settings on Windows, then commit.

.PARAMETER Pull
    Copy the files in place back into the repo instead of installing them. Use this when the
    installed files are copies rather than links.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Pull
#>
[CmdletBinding()]
param(
    [switch] $Pull
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

# Repo path => target path
$links = [ordered]@{
    'git\.gitconfig'                 = Join-Path $env:USERPROFILE '.gitconfig'
    'windows-terminal\settings.json' = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
}

function Set-DotfileLink {
    <#
    .SYNOPSIS
        Replaces Target with a symbolic link to Source, backing up any real file first.
    #>
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Target
    )

    $dir = Split-Path $Target -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $existing = Get-Item $Target -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -eq 'SymbolicLink') {
            Remove-Item $Target -Force
        }
        else {
            $backup = '{0}.bak-{1}' -f $Target, (Get-Date -Format 'yyyyMMddHHmmss')
            Move-Item $Target $backup
            Write-Host "backed up $Target"
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
        Write-Host "linked $Target"
    }
    catch {
        Copy-Item $Source $Target
        Write-Warning "copied $Target (could not create a link: enable Developer Mode and re-run, or use -Pull after edits)"
    }
}

if ($Pull) {
    foreach ($entry in $links.GetEnumerator()) {
        $target = Get-Item $entry.Value -Force -ErrorAction SilentlyContinue
        if (-not $target) {
            Write-Warning "skipped $($entry.Value) (not found)"
        }
        elseif ($target.LinkType -eq 'SymbolicLink') {
            Write-Host "skipped $($entry.Value) (already a link to the repo)"
        }
        else {
            Copy-Item $entry.Value (Join-Path $repo $entry.Key) -Force
            Write-Host "pulled $($entry.Value)"
        }
    }
    Write-Host ''
    Write-Host 'Review with git diff, then commit and push.'
    return
}

foreach ($entry in $links.GetEnumerator()) {
    Set-DotfileLink -Source (Join-Path $repo $entry.Key) -Target $entry.Value
}

Write-Host ''
Write-Host 'Done. VS Code settings and extensions restore through VS Code Settings Sync (sign in from the Accounts menu).'
