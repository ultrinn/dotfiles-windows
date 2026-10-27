<#
.SYNOPSIS
    Restores Windows dotfiles from this repo.

.DESCRIPTION
    Links each tracked config file into place so later edits (for example from the Windows Terminal
    settings UI) land in the repo and only need a commit. Any existing real file is renamed to
    <name>.bak-<timestamp> first.

    Symbolic links need Developer Mode (Settings > System > For developers) or an elevated prompt.
    Without either, files are copied instead and a warning is shown; re-run after enabling
    Developer Mode to switch to links.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1
#>
[CmdletBinding()]
param()

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
        Write-Warning "copied $Target (could not create a link: enable Developer Mode and re-run)"
    }
}

foreach ($entry in $links.GetEnumerator()) {
    Set-DotfileLink -Source (Join-Path $repo $entry.Key) -Target $entry.Value
}

Write-Host ''
Write-Host 'Done. VS Code settings and extensions restore through VS Code Settings Sync (sign in from the Accounts menu).'
