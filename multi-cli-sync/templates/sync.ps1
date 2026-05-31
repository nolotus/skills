# sync.ps1 - 用零依赖方式把本地 skill 分发到多个 CLI 平台

$ErrorActionPreference = "Stop"

$SourceDir = "my-skills"

# -----------------------------------------------------------------------------
# 配置区：在这里定义目标 CLI skill 目录
# -----------------------------------------------------------------------------
$TargetDirs = @(
    # TODO: 在这里填入目标目录
)

Write-Host "🔄 开始执行多 CLI skill 同步..." -ForegroundColor Cyan

if (-Not (Test-Path -Path $SourceDir)) {
    Write-Host "❌ 错误：源目录 '$SourceDir' 不存在。" -ForegroundColor Red
    Write-Host "请先创建它，并把你的 markdown skill 放进去。"
    exit 1
}

if ($TargetDirs.Count -eq 0) {
    Write-Host "⚠️ 警告：还没有配置目标目录。请先编辑 scripts\sync.ps1。" -ForegroundColor Yellow
    exit 0
}

foreach ($target in $TargetDirs) {
    Write-Host "➡️ 正在同步到 $target..."
    if (-Not (Test-Path -Path $target)) {
        New-Item -ItemType Directory -Force -Path $target | Out-Null
    }

    $skillFiles = Get-ChildItem -Path $SourceDir -Filter "*.md"
    foreach ($file in $skillFiles) {
        $destination = Join-Path -Path $target -ChildPath $file.Name
        Copy-Item -Path $file.FullName -Destination $destination -Force
        Write-Host "  ✔️ 已同步 $($file.BaseName)" -ForegroundColor Green
    }
}

Write-Host "✅ 同步完成！" -ForegroundColor Cyan
