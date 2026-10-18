#Requires -Version 5.1
# install-windows.ps1 — winget toolchain. Run as your normal user.
param([switch]$SkipDocker)
$ErrorActionPreference = 'Stop'
$Accept = @('--accept-package-agreements', '--accept-source-agreements')

function Step($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Install-Pkg($id) {
    Write-Host "  $id"
    winget install --id $id -e @Accept --disable-interactivity
    # 0x8A15002B = "already installed"; that is success for an idempotent run
    if ($LASTEXITCODE -notin @(0, -1978335189)) {
        throw "winget install failed for $id (exit $LASTEXITCODE)"
    }
}

function Test-Pkg($id) {
    winget show --id $id -e @Accept *> $null
    return ($LASTEXITCODE -eq 0)
}

Step 'core packages'
foreach ($id in @(
        'Git.Git',
        'Python.Python.3.12',
        'Microsoft.OpenJDK.21',
        'OpenJS.NodeJS.LTS',
        'Microsoft.DotNet.SDK.10',
        'Microsoft.VisualStudioCode',
        'Bruno.Bruno'
    )) { Install-Pkg $id }

Step 'DBeaver (ID changes between index versions, so probe known IDs)'
$id = @('DBeaver.DBeaverCommunity', 'dbeaver.dbeaver', 'DBeaver.DBeaver') |
    Where-Object { Test-Pkg $_ } |
    Select-Object -First 1
if ($id) { Install-Pkg $id } else { Write-Host '  not found; install from dbeaver.io' }

if (-not $SkipDocker) {
    Step 'Docker Desktop (needs WSL2 + reboot on first use)'
    Install-Pkg 'Docker.DockerDesktop'
} else {
    Step 'Docker Desktop skipped (-SkipDocker)'
}

Step 'verify — PATH only updates in NEW terminals'
foreach ($c in 'git', 'py', 'java', 'javac', 'node', 'npm', 'dotnet', 'docker', 'code') {
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    if ($cmd) { Write-Host ("  {0,-8} {1}" -f $c, $cmd.Source) }
    else { Write-Host ("  {0,-8} MISSING (open a new terminal)" -f $c) }
}

Write-Host "`nNext: open a new terminal, then launch Docker Desktop once." -ForegroundColor Yellow
exit 0
