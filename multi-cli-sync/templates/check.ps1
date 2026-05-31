# check.ps1 - 用零依赖方式检查本地 skill 源与外部 CLI 目录之间是否发生漂移

$ErrorActionPreference = "Continue"

$SourceDir = "my-skills"

# -----------------------------------------------------------------------------
# 配置区：在这里定义目标 CLI skill 目录
# -----------------------------------------------------------------------------
$TargetDirs = @(
    # TODO: 在这里填入目标目录
)

if (-Not (Test-Path -Path $SourceDir)) {
    Write-Host "⚠️ 跳过检查：源目录 '$SourceDir' 不存在。" -ForegroundColor Yellow
    exit 0
}

if ($TargetDirs.Count -eq 0) {
    Write-Host "⚠️ 警告：还没有配置目标目录。请先编辑 scripts\check.ps1。" -ForegroundColor Yellow
    exit 0
}

$hasDrift = $false
Write-Host "🔍 开始检查 skill 漂移..." -ForegroundColor Cyan

foreach ($target in $TargetDirs) {
    if (-Not (Test-Path -Path $target)) {
        Write-Host "⚠️ 目标目录 $target 不存在，跳过。" -ForegroundColor Yellow
        continue
    }

    $skillFiles = Get-ChildItem -Path $SourceDir -Filter "*.md"
    foreach ($file in $skillFiles) {
        $externalFile = Join-Path -Path $target -ChildPath $file.Name

        if (-Not (Test-Path -Path $externalFile)) {
            Write-Host "❌ [缺失] $($file.BaseName) 在 $target 中不存在！" -ForegroundColor Red
            $hasDrift = $true
            continue
        }

        $localHash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        $externalHash = (Get-FileHash -Path $externalFile -Algorithm SHA256).Hash

        if ($localHash -ne $externalHash) {
            Write-Host "🚨 [发现漂移] $($file.BaseName) 在 $target 中与本地源不一致！" -ForegroundColor Red
            $hasDrift = $true
        } else {
            Write-Host "  ✔️ [正常] $($file.BaseName) 在 $target 中已同步。" -ForegroundColor Green
        }
    }
}

if ($hasDrift) {
    Write-Host "`n❌ 检测到漂移：你可能改了外部目录里的 skill 却没同步回来，或者改了本地源却没运行 sync.ps1。" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ 所有 skill 都已同步。" -ForegroundColor Cyan
    exit 0
}
