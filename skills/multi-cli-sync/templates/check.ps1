# check.ps1 - Zero-dependency PowerShell script to check for skill drift

$ErrorActionPreference = "Continue"

$SourceDir = "my-skills"

# -----------------------------------------------------------------------------
# Configuration: Define your target CLI skill directories here
# -----------------------------------------------------------------------------
$TargetDirs = @(
    # TODO: Add your target directories here
)

if (-Not (Test-Path -Path $SourceDir)) {
    Write-Host "⚠️ Skipping check: Source directory '$SourceDir' does not exist." -ForegroundColor Yellow
    exit 0
}

if ($TargetDirs.Count -eq 0) {
    Write-Host "⚠️ Warning: No target directories configured. Please edit scripts\check.ps1." -ForegroundColor Yellow
    exit 0
}

$hasDrift = $false
Write-Host "🔍 Checking for skill drift..." -ForegroundColor Cyan

foreach ($target in $TargetDirs) {
    if (-Not (Test-Path -Path $target)) {
        Write-Host "⚠️ Target directory $target does not exist. Skipping." -ForegroundColor Yellow
        continue
    }
    
    $skillFiles = Get-ChildItem -Path $SourceDir -Filter "*.md"
    foreach ($file in $skillFiles) {
        $externalFile = Join-Path -Path $target -ChildPath $file.Name
        
        if (-Not (Test-Path -Path $externalFile)) {
            Write-Host "❌ [MISSING] $($file.BaseName) is missing in $target!" -ForegroundColor Red
            $hasDrift = $true
            continue
        }
        
        # Compare file hashes to check for drift
        $localHash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        $externalHash = (Get-FileHash -Path $externalFile -Algorithm SHA256).Hash
        
        if ($localHash -ne $externalHash) {
            Write-Host "🚨 [DRIFT DETECTED] $($file.BaseName) in $target differs from local source!" -ForegroundColor Red
            $hasDrift = $true
        } else {
            Write-Host "  ✔️ [OK] $($file.BaseName) in $target is in sync." -ForegroundColor Green
        }
    }
}

if ($hasDrift) {
    Write-Host "`n❌ Drift detected! You modified a skill in the external directory but forgot to sync it back, OR you modified it locally and forgot to run sync.ps1." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All skills are perfectly synchronized." -ForegroundColor Cyan
    exit 0
}
