# sync.ps1 - 用零依赖方式同步个人 skill，并在允许时写入 repo mirror 目标

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigFile = Join-Path $ScriptDir "multi-cli-sync.config.ps1"

if (-Not (Test-Path -Path $ConfigFile)) {
    Write-Host "❌ 错误：缺少配置文件 $ConfigFile" -ForegroundColor Red
    exit 1
}

. $ConfigFile

Write-Host "🔄 开始执行 multi-cli-sync..." -ForegroundColor Cyan

function Copy-Pair {
    param(
        [string]$Source,
        [string]$Target
    )

    $parent = Split-Path -Parent $Target
    if ($parent -and -not (Test-Path -Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    if (Test-Path -Path $Source -PathType Container) {
        if (Test-Path -Path $Target) {
            Remove-Item -Recurse -Force $Target
        }
        Copy-Item -Recurse -Force $Source $Target
    } else {
        Copy-Item -Force $Source $Target
    }
}

function Sync-PersonalSkills {
    if (-Not (Test-Path -Path $PersonalSourceDir -PathType Container)) {
        Write-Host "⚠️ 跳过个人 skill 同步：源目录 '$PersonalSourceDir' 不存在。" -ForegroundColor Yellow
        return
    }

    if ($PersonalTargetDirs.Count -eq 0) {
        Write-Host "⚠️ 跳过个人 skill 同步：未配置目标目录。" -ForegroundColor Yellow
        return
    }

    Write-Host "📦 同步个人 skill..." -ForegroundColor Cyan

    if ($PersonalSourceLayout -eq "flat-files") {
        $files = Get-ChildItem -Path $PersonalSourceDir -Filter "*.md"
        foreach ($file in $files) {
            foreach ($target in $PersonalTargetDirs) {
                if (-Not (Test-Path -Path $target)) {
                    New-Item -ItemType Directory -Force -Path $target | Out-Null
                }
                if ($PersonalTargetLayout -eq "flat-files") {
                    Copy-Item -Force $file.FullName (Join-Path $target $file.Name)
                } elseif ($PersonalTargetLayout -eq "folder-skills") {
                    $skillDir = Join-Path $target $file.BaseName
                    if (-Not (Test-Path -Path $skillDir)) {
                        New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
                    }
                    Copy-Item -Force $file.FullName (Join-Path $skillDir "SKILL.md")
                } else {
                    throw "不支持的 PersonalTargetLayout=$PersonalTargetLayout"
                }
                Write-Host "  ✔️ 已同步 $($file.BaseName) -> $target" -ForegroundColor Green
            }
        }
    } elseif ($PersonalSourceLayout -eq "folder-skills") {
        if ($PersonalTargetLayout -ne "folder-skills") {
            throw "folder-skills 源只能同步到 folder-skills 目标"
        }
        $dirs = Get-ChildItem -Path $PersonalSourceDir -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") }
        foreach ($dir in $dirs) {
            foreach ($target in $PersonalTargetDirs) {
                if (-Not (Test-Path -Path $target)) {
                    New-Item -ItemType Directory -Force -Path $target | Out-Null
                }
                $dest = Join-Path $target $dir.Name
                if (Test-Path -Path $dest) {
                    Remove-Item -Recurse -Force $dest
                }
                Copy-Item -Recurse -Force $dir.FullName $dest
                Write-Host "  ✔️ 已同步 $($dir.Name) -> $target" -ForegroundColor Green
            }
        }
    } else {
        throw "不支持的 PersonalSourceLayout=$PersonalSourceLayout"
    }
}

function Sync-RepoMirrors {
    if ([int]$RepoMirrorWriteOk -ne 1) {
        Write-Host "🪞 跳过 repo mirror 写入：RepoMirrorWriteOk=$RepoMirrorWriteOk" -ForegroundColor Yellow
        return
    }

    if ($RepoMirrorSpecs.Count -eq 0) {
        Write-Host "⚠️ 跳过 repo mirror 写入：未配置 RepoMirrorSpecs。" -ForegroundColor Yellow
        return
    }

    Write-Host "🪞 同步 repo mirrors..." -ForegroundColor Cyan

    foreach ($spec in $RepoMirrorSpecs) {
        $label = $spec.Label
        $kind = $spec.Kind
        $source = $spec.Source
        $target = $spec.Target

        if (-Not (Test-Path -Path $source)) {
            throw "源路径不存在，无法同步 $label: $source"
        }

        if ($kind -eq "file-to-file" -or $kind -eq "dir-to-dir") {
            Copy-Pair $source $target
            Write-Host "  ✔️ 已同步 mirror $label" -ForegroundColor Green
        } else {
            throw "不支持的 Kind=$kind（$label）"
        }
    }
}

Sync-PersonalSkills
Sync-RepoMirrors

Write-Host "✅ multi-cli-sync 执行完成！" -ForegroundColor Cyan
