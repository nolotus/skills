# sync.ps1 - Zero-dependency PowerShell script to distribute local skills to multiple CLI platforms

$ErrorActionPreference = "Stop"

# Default source directory for your personal skills
$SourceDir = "my-skills"

# -----------------------------------------------------------------------------
# Configuration: Define your target CLI skill directories here
# -----------------------------------------------------------------------------
# Example paths:
# $CodexSkillsDir = "$env:USERPROFILE\.codex\skills"
# $ClaudeSkillsDir = "$env:USERPROFILE\.claude\skills"
$TargetDirs = @(
    # TODO: Add your target directories here
    # $CodexSkillsDir
    # $ClaudeSkillsDir
)

Write-Host "🔄 Starting multi-CLI skill synchronization..." -ForegroundColor Cyan

if (-Not (Test-Path -Path $SourceDir)) {
    Write-Host "❌ Error: Source directory '$SourceDir' does not exist." -ForegroundColor Red
    Write-Host "Please create it and add your markdown skills there first."
    exit 1
}

if ($TargetDirs.Count -eq 0) {
    Write-Host "⚠️ Warning: No target directories configured. Please edit scripts\sync.ps1 to add your CLI paths." -ForegroundColor Yellow
    exit 0
}

# Sync each skill to all target directories
foreach ($target in $TargetDirs) {
    Write-Host "➡️ Syncing to $target..."
    if (-Not (Test-Path -Path $target)) {
        New-Item -ItemType Directory -Force -Path $target | Out-Null
    }
    
    $skillFiles = Get-ChildItem -Path $SourceDir -Filter "*.md"
    foreach ($file in $skillFiles) {
        # Flat file copy example:
        $destination = Join-Path -Path $target -ChildPath $file.Name
        Copy-Item -Path $file.FullName -Destination $destination -Force
        
        Write-Host "  ✔️ Synced $($file.BaseName)" -ForegroundColor Green
    }
}

Write-Host "✅ Synchronization complete!" -ForegroundColor Cyan
