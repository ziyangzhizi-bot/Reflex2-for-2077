# cleanup.ps1 -- 清理调试产物,释放磁盘(不动 mod 本身)
#
# 用法:
#   .\cleanup.ps1 -DryRun                 # 先看要删什么、能省多少
#   .\cleanup.ps1                         # 真删
#   .\cleanup.ps1 -KeepDumps              # 崩溃 dmp 也保留(每个 ~200 MB)
#   .\cleanup.ps1 -KeepBackups 3          # 保留最近 3 个旧版 DLL(默认 2)
#
# 删除内容:
#   routea_frame_*.raw        离线取帧转储(每个 ~14-30 MB)
#   routea_warp_uimask.raw    离线遮罩数据(3.6 MB)
#   fwcrash_*.dmp             崩溃完整内存转储(每个 ~200 MB;.txt 摘要保留)
#   routea_warp.addon64.prev_* 旧版 DLL(保留最近 N 个 + 已知可跑的 *_restorepoint)

[CmdletBinding()]
param(
    [string]$GameDir,
    [int]$KeepBackups = 2,
    [switch]$KeepDumps,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
if (-not $GameDir) {
    $GameDir = @(
        'E:\SteamLibrary\steamapps\common\Cyberpunk 2077\bin\x64',
        'D:\SteamLibrary\steamapps\common\Cyberpunk 2077\bin\x64'
    ) | Where-Object { Test-Path (Join-Path $_ 'Cyberpunk2077.exe') } | Select-Object -First 1
}
if (-not $GameDir) { Write-Host '找不到游戏目录,请用 -GameDir 指定。' -ForegroundColor Red; exit 2 }

Write-Host "清理目标: $GameDir"
$doomed = @()

$doomed += Get-ChildItem (Join-Path $GameDir 'routea_frame_*.raw')        -ErrorAction SilentlyContinue
$doomed += Get-ChildItem (Join-Path $GameDir 'routea_warp_uimask.raw')    -ErrorAction SilentlyContinue
if (-not $KeepDumps) { $doomed += Get-ChildItem (Join-Path $GameDir 'fwcrash_*.dmp') -ErrorAction SilentlyContinue }

$keep = @()
$keep += Get-ChildItem (Join-Path $GameDir 'routea_warp.addon64.prev_*_restorepoint') -ErrorAction SilentlyContinue
$keep += Get-ChildItem (Join-Path $GameDir 'routea_warp.addon64.prev_*') -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First $KeepBackups
$doomed += Get-ChildItem (Join-Path $GameDir 'routea_warp.addon64.prev_*') -ErrorAction SilentlyContinue |
           Where-Object { $keep.FullName -notcontains $_.FullName }

$doomed = $doomed | Sort-Object FullName -Unique
if ($doomed.Count -eq 0) { Write-Host '没有可清理的文件。' -ForegroundColor Green; exit 0 }

$total = ($doomed | Measure-Object Length -Sum).Sum
foreach ($f in $doomed) {
    $rel = $f.FullName.Substring($GameDir.Length).TrimStart('\')
    if ($DryRun) { Write-Host ("  [试运行] 删除 {0,-46} {1,10:N0} B" -f $rel, $f.Length) -ForegroundColor Cyan }
    else         { Remove-Item $f.FullName -Force; Write-Host ("  [删除]   {0,-46} {1,10:N0} B" -f $rel, $f.Length) }
}
Write-Host ''
Write-Host ("将释放 / 已释放: {0:N1} MB (共 {1} 个文件)" -f ($total / 1MB), $doomed.Count) -ForegroundColor Green
Write-Host ("保留的回退点: " + (($keep | ForEach-Object { $_.Name }) -join ', '))
if (-not $KeepDumps) { Write-Host '崩溃摘要 fwcrash_*.txt 已保留(只有 .dmp 被删);下次崩溃会重新生成。' }
