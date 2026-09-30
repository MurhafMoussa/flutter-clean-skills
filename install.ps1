[CmdletBinding()]
param (
    [ValidateSet("all", "opencode", "claude", "agents")]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"

$userHome = [System.Environment]::GetFolderPath('UserProfile')
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceSkillsDir = Join-Path $scriptDir "skills"

if (-not (Test-Path $sourceSkillsDir)) {
    Write-Error "Source skills directory not found at $sourceSkillsDir"
}

$destinations = @()

if ($Target -eq "all" -or $Target -eq "opencode") {
    $destinations += (Join-Path $userHome ".config\opencode\skills")
}
if ($Target -eq "all" -or $Target -eq "agents") {
    $destinations += (Join-Path $userHome ".agents\skills")
}
if ($Target -eq "all" -or $Target -eq "claude") {
    $destinations += (Join-Path $userHome ".claude\skills")
}

Write-Host "Installing Flutter Clean Skills..." -ForegroundColor Cyan

$skills = Get-ChildItem -Path $sourceSkillsDir -Directory

foreach ($dest in $destinations) {
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    }
    
    Write-Host "Target: $dest" -ForegroundColor Yellow
    foreach ($skill in $skills) {
        $destSkillDir = Join-Path $dest $skill.Name
        Copy-Item -Path $skill.FullName -Destination $destSkillDir -Recurse -Force
        Write-Host "  -> Installed $($skill.Name)" -ForegroundColor Green
    }
}

Write-Host "`nAll skills successfully installed!" -ForegroundColor Cyan
