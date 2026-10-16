# Reusable C: drive cleanup script for this machine.
# Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File cleanup-c-drive.ps1

$ErrorActionPreference = 'SilentlyContinue'
$before = (Get-PSDrive C).Free
Write-Host "=== BEFORE: $([math]::Round($before/1GB,2)) GB free on C: ===" -ForegroundColor Cyan

# Tier 1: Regenerable cache/temp paths (machine-specific, verified)
$tier1 = @(
    'C:\Users\Bappi\AppData\Local\Temp',
    'C:\Users\Bappi\.cache',
    'C:\Users\Bappi\AppData\Local\NVIDIA',
    'C:\Users\Bappi\AppData\Local\Google',
    'C:\Users\Bappi\AppData\Local\npm-cache',
    'C:\Users\Bappi\AppData\Local\BraveSoftware',
    'C:\Users\Bappi\AppData\Local\Microsoft',
    'C:\Users\Bappi\AppData\Local\GitHubDesktop',
    'C:\Users\Bappi\AppData\Local\uv',
    'C:\Users\Bappi\AppData\Local\Cypress',
    'C:\Users\Bappi\AppData\Local\ms-playwright',
    'C:\Users\Bappi\AppData\Local\OpenAI',
    'C:\Users\Bappi\AppData\Local\Cline',
    'C:\Users\Bappi\AppData\Local\Packages',
    'C:\Users\Bappi\AppData\Roaming\uv',
    'C:\Windows\Temp',
    'C:\Windows\SoftwareDistribution\Download',
    'C:\ProgramData\Package Cache'
)

# Tier 2: User data — ONLY add paths the user has explicitly approved.
# Example: $tier2 = @('C:\Users\Bappi\AppData\Roaming\.minecraft')
$tier2 = @()

$totalFreed = 0

function Clean-Path($path, $label) {
    if (Test-Path $path) {
        $sizeBefore = (Get-ChildItem $path -Recurse -Force -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum
        Write-Host "Cleaning: $path ($([math]::Round($sizeBefore/1GB,2)) GB)" -ForegroundColor Yellow
        # Remove files first, then directories (handles locked files gracefully)
        Get-ChildItem $path -Recurse -Force -File -EA SilentlyContinue | Remove-Item -Force -EA SilentlyContinue
        Get-ChildItem $path -Recurse -Force -Directory -EA SilentlyContinue | Sort-Object { $_.FullName.Length } -Descending | Remove-Item -Force -Recurse -EA SilentlyContinue
        Get-ChildItem $path -Force -File -EA SilentlyContinue | Remove-Item -Force -EA SilentlyContinue
        $sizeAfter = (Get-ChildItem $path -Recurse -Force -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum
        $freed = $sizeBefore - $sizeAfter
        if ($freed -gt 0) { $script:totalFreed += $freed }
        Write-Host "  Freed: $([math]::Round($freed/1GB,2)) GB" -ForegroundColor Green
    } else {
        Write-Host "Skip (not found): $path" -ForegroundColor Gray
    }
}

Write-Host "`n--- Tier 1: Regenerable ---" -ForegroundColor Cyan
foreach ($p in $tier1) { Clean-Path $p }

# npm cache: use npm's own cleaner (much faster than Remove-Item)
$npmCache = 'C:\Users\Bappi\AppData\Roaming\npm'
if (Test-Path $npmCache) {
    Write-Host "Cleaning npm cache via npm cache clean --force" -ForegroundColor Yellow
    npm cache clean --force 2>&1 | Out-Null
    Write-Host "  npm cache cleaned (locked files free on reboot)" -ForegroundColor Green
}

if ($tier2.Count -gt 0) {
    Write-Host "`n--- Tier 2: User-approved data ---" -ForegroundColor Magenta
    foreach ($p in $tier2) { Clean-Path $p "USER-APPROVED" }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total freed: $([math]::Round($totalFreed/1GB,2)) GB" -ForegroundColor White
$after = (Get-PSDrive C).Free
Write-Host "AFTER: $([math]::Round($after/1GB,2)) GB free on C: (was $([math]::Round($before/1GB,2)) GB)" -ForegroundColor Cyan
Write-Host "Note: Locked files skipped, will free on reboot." -ForegroundColor DarkGray
