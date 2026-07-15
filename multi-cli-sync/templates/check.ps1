# check.ps1 - 用零依赖方式检查个人 skill 安装状态与 repo mirror gate

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigFile = Join-Path $ScriptDir "config.ps1"

if (-Not (Test-Path -Path $ConfigFile)) {
    Write-Host "❌ 错误：缺少配置文件 $ConfigFile" -ForegroundColor Red
    exit 1
}

. $ConfigFile

$HasRequiredDrift = $false
$HasOptionalDrift = $false

Write-Host "🔍 开始检查 multi-cli-sync 状态..." -ForegroundColor Cyan

function Report-Result {
    param(
        [string]$Status,
        [string]$Label,
        [string]$Detail,
        [int]$Required
    )

    if ($Status -eq "ok") {
        Write-Host "  ✔️ [正常] $Label" -ForegroundColor Green
        return
    }

    if ($Required -eq 1) {
        $script:HasRequiredDrift = $true
        Write-Host "❌ [$Label] $Detail" -ForegroundColor Red
    } else {
        $script:HasOptionalDrift = $true
        Write-Host "⚠️ [$Label] $Detail" -ForegroundColor Yellow
    }
}

function Get-PathDigest {
    param([string]$Path)

    if (Test-Path -Path $Path -PathType Leaf) {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    }

    if (Test-Path -Path $Path -PathType Container) {
        $items = Get-ChildItem -Path $Path -Recurse -File | Sort-Object FullName
        return ($items | ForEach-Object {
            $relative = $_.FullName.Substring($Path.Length).TrimStart('\\','/')
            $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
            "$relative|$hash"
        }) -join "`n"
    }

    return $null
}

function Compare-Pair {
    param(
        [string]$Label,
        [string]$Source,
        [string]$Target,
        [int]$Required
    )

    if (-Not (Test-Path -Path $Source)) {
        Report-Result "fail" $Label "源路径不存在：$Source" $Required
        return
    }

    if (-Not (Test-Path -Path $Target)) {
        Report-Result "fail" $Label "目标路径不存在：$Target" $Required
        return
    }

    $sourceIsDir = Test-Path -Path $Source -PathType Container
    $targetIsDir = Test-Path -Path $Target -PathType Container
    if ($sourceIsDir -ne $targetIsDir) {
        Report-Result "fail" $Label "源与目标类型不一致：$Source -> $Target" $Required
        return
    }

    $sourceDigest = Get-PathDigest $Source
    $targetDigest = Get-PathDigest $Target

    if ($sourceDigest -eq $targetDigest) {
        Report-Result "ok" $Label "" $Required
    } else {
        Report-Result "fail" $Label "内容不一致：$Source -> $Target" $Required
    }
}

function Test-PersonalExcluded {
    param([string]$SkillName)
    if (-not (Get-Variable -Name PersonalExcludeSkills -ErrorAction SilentlyContinue)) { return $false }
    if (-not $PersonalExcludeSkills) { return $false }
    return ($PersonalExcludeSkills -contains $SkillName)
}

function Check-ExcludedPersonalSkills {
    if ($PersonalTargetDirs.Count -eq 0) { return }
    if (-not (Get-Variable -Name PersonalExcludeSkills -ErrorAction SilentlyContinue)) { return }
    if (-not $PersonalExcludeSkills -or $PersonalExcludeSkills.Count -eq 0) { return }

    Write-Host "🧹 检查已排除 skill 是否仍被安装..." -ForegroundColor Cyan
    foreach ($skillName in $PersonalExcludeSkills) {
        if (-not $skillName) { continue }
        foreach ($target in $PersonalTargetDirs) {
            $path = if ($PersonalTargetLayout -eq "flat-files") {
                Join-Path $target "$skillName.md"
            } else {
                Join-Path $target $skillName
            }
            if (Test-Path -Path $path) {
                Report-Result "fail" "personal-excluded:$skillName:$target" "排除 skill 仍安装在 $path；请删掉或运行 sync 清理" 1
            } else {
                Report-Result "ok" "personal-excluded:$skillName:$target" "" 1
            }
        }
    }
}

function Check-PersonalSync {
    if (-Not (Test-Path -Path $PersonalSourceDir -PathType Container)) {
        Write-Host "⚠️ 跳过个人 skill 检查：源目录 '$PersonalSourceDir' 不存在。" -ForegroundColor Yellow
        Check-ExcludedPersonalSkills
        return
    }

    if ($PersonalTargetDirs.Count -eq 0) {
        Write-Host "⚠️ 跳过个人 skill 检查：未配置目标目录。" -ForegroundColor Yellow
        return
    }

    Write-Host "📦 检查个人 skill 安装状态..." -ForegroundColor Cyan
    Check-ExcludedPersonalSkills

    if ($PersonalSourceLayout -eq "flat-files") {
        $files = Get-ChildItem -Path $PersonalSourceDir -Filter "*.md"
        foreach ($file in $files) {
            $skillName = $file.BaseName
            if (Test-PersonalExcluded -SkillName $skillName) { continue }
            foreach ($target in $PersonalTargetDirs) {
                if ($PersonalTargetLayout -eq "flat-files") {
                    Compare-Pair "personal:$skillName:$target" $file.FullName (Join-Path $target $file.Name) 1
                } elseif ($PersonalTargetLayout -eq "folder-skills") {
                    Compare-Pair "personal:$skillName:$target" $file.FullName (Join-Path (Join-Path $target $skillName) "SKILL.md") 1
                } else {
                    Report-Result "fail" "personal:$skillName:$target" "不支持的 PersonalTargetLayout=$PersonalTargetLayout" 1
                }
            }
        }
    } elseif ($PersonalSourceLayout -eq "folder-skills") {
        if ($PersonalTargetLayout -ne "folder-skills") {
            Report-Result "fail" "personal-layout" "folder-skills 源只能同步到 folder-skills 目标" 1
            return
        }
        $dirs = Get-ChildItem -Path $PersonalSourceDir -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") }
        foreach ($dir in $dirs) {
            if (Test-PersonalExcluded -SkillName $dir.Name) { continue }
            foreach ($target in $PersonalTargetDirs) {
                Compare-Pair "personal:$($dir.Name):$target" $dir.FullName (Join-Path $target $dir.Name) 1
            }
        }
    } else {
        Report-Result "fail" "personal-layout" "不支持的 PersonalSourceLayout=$PersonalSourceLayout" 1
    }
}

function Check-RepoMirrors {
    if ($RepoMirrorSpecs.Count -eq 0) {
        Write-Host "⚠️ 跳过 repo mirror 检查：未配置 RepoMirrorSpecs。" -ForegroundColor Yellow
        return
    }

    Write-Host "🪞 检查 repo mirror gate..." -ForegroundColor Cyan

    foreach ($spec in $RepoMirrorSpecs) {
        $label = $spec.Label
        $kind = $spec.Kind
        $source = $spec.Source
        $target = $spec.Target
        $required = [int]$spec.Required

        if ($kind -eq "file-to-file" -or $kind -eq "dir-to-dir") {
            Compare-Pair $label $source $target $required
        } else {
            Report-Result "fail" $label "不支持的 Kind=$kind" $required
        }
    }
}

Check-PersonalSync
Check-RepoMirrors

if ($HasRequiredDrift) {
    Write-Host "`n❌ 存在 required drift。" -ForegroundColor Red
    exit 1
}

if ($HasOptionalDrift) {
    Write-Host "`n⚠️ required 项已通过，但存在 optional drift。" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n✅ 所有 required 项都已通过。" -ForegroundColor Cyan
exit 0
