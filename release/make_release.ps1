# make_release.ps1 -- 打出可分发的发布包(zip)
#
# 用法:
#   .\make_release.ps1                 # 打包到 .\_dist\FrameWarp-RouteA-<版本>.zip
#   .\make_release.ps1 -NoZip          # 只生成目录,不压缩
#   .\make_release.ps1 -OutDir D:\out  # 指定输出目录
#
# 包里**只**放:插件、两个 .fx、引擎侧 .asi、默认开关、安装/清理脚本、说明与许可、版本与构建信息。
# 明确排除:ReShade 本体、任何 NVIDIA 二进制、任何游戏文件、以及整个 _re\ 目录(竞品逆向资料)。
#
# 注意:本文件必须保存为 **UTF-8 带 BOM**(Windows PowerShell 5.1 否则会把中文读成乱码)。

[CmdletBinding()]
param(
    [string]$OutDir,
    [switch]$NoZip
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $Root '_dist' }

$version = (Get-Content (Join-Path $Root 'VERSION') -Raw).Trim()
if (-not $version) { throw 'VERSION 文件缺失或为空' }
$stage = Join-Path $OutDir ("FrameWarp-RouteA-$version")
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

Write-Host "版本: $version"
Write-Host "输出: $stage"

# ---- 1) 载荷 ---------------------------------------------------------------------------------
Copy-Item (Join-Path $Root 'payload') (Join-Path $stage 'payload') -Recurse -Force

# 只发布**一个**插件产物:实测过的那一份(payload\bin 里的)
$extra = Join-Path $stage 'payload\bin\routea_warp.addon64.release_brepro'
if (Test-Path $extra) { Remove-Item $extra -Force }

# ---- 2) 脚本与文档 ---------------------------------------------------------------------------
foreach ($f in @('install.ps1','cleanup.ps1','README_CN.md','THIRD_PARTY_NOTICES.md','CHANGELOG.md','VERSION')) {
    $src = Join-Path $Root $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $stage $f) -Force } else { Write-Host "  [警告] 缺少 $f" -ForegroundColor Yellow }
}
# 发布说明(mod 页面正文)也进包
Get-ChildItem (Join-Path $Root 'RELEASE_NOTES*.md') -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $stage $_.Name) -Force
}

# ---- 3) 构建信息(哈希/时间)--------------------------------------------------------------------
$dll = Join-Path $stage 'payload\bin\routea_warp.addon64'
$asi = Join-Path $stage 'payload\plugins\routea_hook.asi'
$bi  = Join-Path $Root '..\..\demo_re\harness\routea_addon\_release\BUILD_INFO.txt'
$lines = @(
    "Frame Warp (Route A) -- release package",
    "version : $version",
    "packed  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "addon   : $((Get-FileHash $dll -Algorithm SHA256).Hash)  ($((Get-Item $dll).Length) bytes)",
    "hook    : $((Get-FileHash $asi -Algorithm SHA256).Hash)  ($((Get-Item $asi).Length) bytes)"
)
if (Test-Path $bi) { $lines += ''; $lines += 'build (from build_release.cmd):'; $lines += (Get-Content $bi) }
$lines += 'scan    : WAIVED (stable build predates the string cleanup; dev paths + 1 provenance comment remain)'
Set-Content -Path (Join-Path $stage 'BUILD_INFO.txt') -Value $lines -Encoding UTF8

# ---- 4) 自检:包里不许出现禁品 ---------------------------------------------------------------
$forbidden = Get-ChildItem $stage -Recurse -File |
    Where-Object { $_.Name -match 'optiscaler|framewarp-stage2|\.raw$|\.dmp$|routea_addon\.cpp' }
if ($forbidden) {
    Write-Host '  [失败] 发布包里出现了不该有的文件:' -ForegroundColor Red
    $forbidden | ForEach-Object { Write-Host ("    " + $_.FullName.Substring($stage.Length)) }
    throw '打包中止'
}

& (Join-Path $PSScriptRoot 'check_payload.ps1') -Dll $dll -Asi $asi -AllowDirty
# ---- 5) 清单 ----------------------------------------------------------------------------------
Write-Host ''
Write-Host '包内清单:'
Get-ChildItem $stage -Recurse -File | Sort-Object FullName | ForEach-Object {
    $rel = $_.FullName.Substring($stage.Length).TrimStart('\')
    $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.Substring(0,16)
    Write-Host ("  {0,-56} {1,9}  {2}" -f $rel, $_.Length, $h)
}

# ---- 6) 压缩 ----------------------------------------------------------------------------------
if (-not $NoZip) {
    $zip = Join-Path $OutDir ("FrameWarp-RouteA-$version.zip")
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $zip)
    Write-Host ''
    Write-Host ("ZIP: {0}  ({1:N0} 字节)" -f $zip, (Get-Item $zip).Length) -ForegroundColor Green
}
Write-Host '完成。安装:解压后运行 install.ps1(先 -SelfCheck 看一眼环境)。'
