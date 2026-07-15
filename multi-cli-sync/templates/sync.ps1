# sync.ps1 - 用零依赖方式同步个人 skill，并在允许时写入 repo mirror 目标

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigFile = Join-Path $ScriptDir "config.ps1"

if (-Not (Test-Path -Path $ConfigFile)) {
    Write-Host "❌ 错误：缺少配置文件 $ConfigFile" -ForegroundColor Red
    exit 1
}

. $ConfigFile

if (-not (Get-Variable -Name PersonalExcludeSkills -Scope Script -ErrorAction SilentlyContinue) -and
    -not (Get-Variable -Name PersonalExcludeSkills -ErrorAction SilentlyContinue)) {
    $PersonalExcludeSkills = @()
}

Write-Host "🔄 开始执行 multi-cli-sync..." -ForegroundColor Cyan

function Test-PersonalExcluded {
    param([string]$SkillName)
    if (-not $PersonalExcludeSkills) { return $false }
    return ($PersonalExcludeSkills -contains $SkillName)
}

function Remove-PersonalInstall {
    param(
        [string]$SkillName,
        [string]$Target
    )
    if ($PersonalTargetLayout -eq "flat-files") {
        $path = Join-Path $Target "$SkillName.md"
        if (Test-Path -Path $path) {
            Remove-Item -Force $path
            Write-Host "  🗑️ 已删除排除 skill $SkillName.md <- $Target" -ForegroundColor Yellow
        }
    } else {
        $path = Join-Path $Target $SkillName
        if (Test-Path -Path $path) {
            Remove-Item -Recurse -Force $path
            Write-Host "  🗑️ 已删除排除 skill $SkillName <- $Target" -ForegroundColor Yellow
        }
    }
}

function Remove-ExcludedPersonalSkills {
    if ($PersonalTargetDirs.Count -eq 0) { return }
    if (-not $PersonalExcludeSkills -or $PersonalExcludeSkills.Count -eq 0) { return }

    Write-Host "🧹 清理已排除的个人 skill 安装副本..." -ForegroundColor Cyan
    foreach ($skillName in $PersonalExcludeSkills) {
        if (-not $skillName) { continue }
        foreach ($target in $PersonalTargetDirs) {
            Remove-PersonalInstall -SkillName $skillName -Target $target
        }
    }
}

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
        Remove-ExcludedPersonalSkills
        return
    }

    if ($PersonalTargetDirs.Count -eq 0) {
        Write-Host "⚠️ 跳过个人 skill 同步：未配置目标目录。" -ForegroundColor Yellow
        return
    }

    Write-Host "📦 同步个人 skill..." -ForegroundColor Cyan
    Remove-ExcludedPersonalSkills

    if ($PersonalSourceLayout -eq "flat-files") {
        $files = Get-ChildItem -Path $PersonalSourceDir -Filter "*.md"
        foreach ($file in $files) {
            if (Test-PersonalExcluded -SkillName $file.BaseName) {
                Write-Host "  ⏭️ 跳过排除 skill $($file.BaseName)（源保留，不安装）" -ForegroundColor Yellow
                continue
            }
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
            if (Test-PersonalExcluded -SkillName $dir.Name) {
                Write-Host "  ⏭️ 跳过排除 skill $($dir.Name)（源保留，不安装）" -ForegroundColor Yellow
                continue
            }
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
            if ($spec.Required) {
                throw "required mirror 源路径不存在，无法同步 $label: $source"
            }
            Write-Host "  ⚠️ 跳过 optional mirror $label（源路径不存在: $source）" -ForegroundColor Yellow
            continue
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
