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
    winget show --id $id -e --source winget @Accept *> $null
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

Step 'winget source refresh (winget only; msstore prompts in CI)'
winget source update --name winget | Out-Null

Step 'DBeaver (Community edition)'
winget install --id DBeaver.DBeaver.Community -e --source winget @Accept --disable-interactivity
if ($LASTEXITCODE -in @(0, -1978335189)) {
    Write-Host '  DBeaver installed'
} else {
    Write-Host "  not available in this index (exit $LASTEXITCODE); install from dbeaver.io"
}

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
