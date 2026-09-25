# install.ps1 -- Frame Warp (Route A) 一键安装 / 自检 / 卸载
#
# 用法(在本目录下):
#   .\install.ps1 -DryRun        # 只打印将要做什么,不动任何文件
#   .\install.ps1                # 安装到默认游戏目录
#   .\install.ps1 -GameDir 'D:\Steam\steamapps\common\Cyberpunk 2077\bin\x64'
#   .\install.ps1 -SelfCheck     # 只做换机自检,不安装
#   .\install.ps1 -Uninstall     # 卸载(从最近一次备份恢复)
#   .\install.ps1 -ForceDefaults # 覆盖已存在的开关文件(默认不覆盖)
#
# 安装内容:
#   bin\x64\routea_warp.addon64                插件本体
#   bin\x64\reshade-shaders\Shaders\*.fx       面板与开关(中文滑块)
#   bin\x64\plugins\routea_hook.asi            引擎侧钩子(相机/矩阵)
#   bin\x64\routea_warp_*.txt                  开关(默认值,已存在则不覆盖)
#
# 本脚本不改 ReShade 本体、不改游戏文件;所有被覆盖的文件先备份到 _fwbackup_<时间戳>\。

[CmdletBinding()]
param(
    [string]$GameDir,
    [ValidateSet('cn','en')][string]$Lang = 'cn',
    [switch]$DryRun,
    [switch]$Uninstall,
    [switch]$SelfCheck,
    [switch]$ForceDefaults
)

$ErrorActionPreference = 'Stop'
$Root    = Split-Path -Parent $MyInvocation.MyCommand.Path
$Payload = Join-Path $Root 'payload'
$Stamp   = Get-Date -Format 'yyyyMMdd_HHmmss'

function Say($m)  { Write-Host $m }
function Ok($m)   { Write-Host "  [OK]   $m"   -ForegroundColor Green }
function Warn($m) { Write-Host "  [警告] $m"   -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [缺失] $m"   -ForegroundColor Red }
function Step($m)   { if ($DryRun) { Write-Host "  [试运行] $m" -ForegroundColor Cyan } else { Write-Host "  [执行] $m" } }

function Find-GameDir {
    if ($GameDir) { return $GameDir }
    $cands = @(
        'E:\SteamLibrary\steamapps\common\Cyberpunk 2077\bin\x64',
        'D:\SteamLibrary\steamapps\common\Cyberpunk 2077\bin\x64',
        'C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077\bin\x64',
        'D:\Steam\steamapps\common\Cyberpunk 2077\bin\x64'
    )
    foreach ($c in $cands) { if (Test-Path (Join-Path $c 'Cyberpunk2077.exe')) { return $c } }
    # 退一步:问注册表里的 Steam 库
    foreach ($k in @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKCU:\SOFTWARE\Valve\Steam')) {
        try {
            $p = (Get-ItemProperty -Path $k -ErrorAction Stop).InstallPath
            if ($p) {
                $libs = Join-Path $p 'steamapps\libraryfolders.vdf'
                if (Test-Path $libs) {
                    foreach ($m in Select-String -Path $libs -Pattern '"path"\s+"([^"]+)"' -AllMatches) {
                        $d = Join-Path ($m.Matches[0].Groups[1].Value -replace '\\\\','\') 'steamapps\common\Cyberpunk 2077\bin\x64'
                        if (Test-Path (Join-Path $d 'Cyberpunk2077.exe')) { return $d }
                    }
                }
            }
        } catch { }
    }
    return $null
}

function Invoke-SelfCheck([string]$G) {
    Say ''
    Say '================ 换机自检 ================'
    Say "游戏目录: $G"
    $problems = @()

    if ($G -and (Test-Path (Join-Path $G 'Cyberpunk2077.exe'))) { Ok '找到 Cyberpunk2077.exe' }
    else { Bad '没找到 Cyberpunk2077.exe(--GameDir 指定 bin\x64 目录)'; $problems += 'gamedir' }

    if ($G -and (Test-Path (Join-Path $G 'nvngx_latewarp.dll'))) {
        Ok '找到 nvngx_latewarp.dll(NVIDIA latewarp 内核)'
        $v = (Get-Item (Join-Path $G 'nvngx_latewarp.dll')).VersionInfo.FileVersion
        if ($v) { Say "         内核版本: $v" }
    } else {
        Bad 'nvngx_latewarp.dll 不存在 —— 需要 NVIDIA 驱动自带该组件(40 系+较新驱动)'
        $problems += 'latewarp'
    }

    $reshade = @('dxgi.dll','ReShade64.dll','d3d12.dll') | ForEach-Object { Join-Path $G $_ } | Where-Object { Test-Path $_ }
    if ($reshade.Count -gt 0) { Ok ("找到 ReShade: " + ($reshade | ForEach-Object { Split-Path $_ -Leaf }) -join ', ') }
    else { Bad '没找到 ReShade(dxgi.dll / ReShade64.dll)—— 请先安装 ReShade(带 addon 支持的版本)'; $problems += 'reshade' }

    $shaders = Join-Path $G 'reshade-shaders\Shaders'
    if (Test-Path $shaders) { Ok "找到着色器目录: $shaders" } else { Bad "缺少 $shaders(面板与开关放这里)"; $problems += 'shaders' }

    if (Test-Path (Join-Path $G 'plugins')) { Ok '找到 plugins 目录' } else { Bad '缺少 plugins 目录(引擎侧钩子放这里)'; $problems += 'plugins' }

    $smi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if ($smi) {
        try {
            $q = & nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>$null
            if ($q) { Ok "GPU: $q" } else { Warn 'nvidia-smi 没有返回信息' }
        } catch { Warn 'nvidia-smi 调用失败' }
    } else { Warn '没有 nvidia-smi:无法确认 GPU/驱动(非 NVIDIA 卡上这个 mod 无法工作)' }

    $ex = Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue
    if ($ex -and -not $DryRun) { Bad '游戏正在运行 —— 请先退出游戏再安装(否则 DLL 被占用)'; exit 3 }
    if ($ex) { Warn "游戏正在运行(pid $($ex.Id))—— 安装前请先退出游戏,否则文件被占用" } else { Ok '游戏当前未运行' }

    Say ''
    if ($problems.Count -eq 0) {
        Say '结论: 环境满足要求,可以安装。' -ForegroundColor Green
        Say '注意: HDR/分辨率切换属于运行期行为,自检无法覆盖 —— 安装后用游戏内改分辨率验证一次。'
    } else {
        Say ("结论: 缺少: " + ($problems -join ', ')) -ForegroundColor Yellow
        Say '处理: 先补齐上面的缺项;即使缺 latewarp 内核,插件也会以加载但不动画面的方式运行(不会崩溃)。'
    }
    Say '========================================='
    return $problems
}

function Backup-IfExists([string]$Path, [string]$BackupRoot) {
    if (Test-Path $Path) {
        $rel = $Path.Substring($script:GD.Length).TrimStart('\')
        $dst = Join-Path $BackupRoot $rel
        $d   = Split-Path $dst -Parent
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $d | Out-Null
            Copy-Item $Path $dst -Force
        }
        Step "备份 $rel"
    }
}

function Copy-PayloadFile([string]$From, [string]$To, [string]$BackupRoot) {
    Backup-IfExists $To $BackupRoot
    $d = Split-Path $To -Parent
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
        Copy-Item $From $To -Force
    }
    Step "安装 $(Split-Path $To -Leaf)"
}

# ---------------------------------------------------------------- 主流程
$G = Find-GameDir
if (-not $G) { Say '找不到游戏目录,请用 -GameDir 指定(指向 bin\x64)。' -ForegroundColor Red; exit 2 }
if (-not (Test-Path (Join-Path $G 'Cyberpunk2077.exe'))) {
    Say "给定的目录里没有 Cyberpunk2077.exe: $G" -ForegroundColor Red; exit 2
}
$script:GD = $G

if ($SelfCheck) { Invoke-SelfCheck $G | Out-Null; exit 0 }

$BackupRoot = Join-Path $G ("_fwbackup_$Stamp")

if ($Uninstall) {
    Say ''
    Say '================ 卸载 ================'
    $latest = Get-ChildItem (Join-Path $G '_fwbackup_*') -Directory -ErrorAction SilentlyContinue |
              Sort-Object Name -Descending | Select-Object -First 1
    $targets = @(
        'routea_warp.addon64',
        'plugins\routea_hook.asi',
        'plugins\routea_hook_gametex.txt',
        'plugins\routea_hook_live.txt',
        'reshade-shaders\Shaders\routea_switch.fx',
        'reshade-shaders\Shaders\routea_ui_panel.fx'
    )
    foreach ($t in $targets) {
        $p = Join-Path $G $t
        if (Test-Path $p) { if (-not $DryRun) { Remove-Item $p -Force }; Step "删除 $t" }
    }
    Get-ChildItem (Join-Path $G 'routea_warp_*.txt') -ErrorAction SilentlyContinue | ForEach-Object {
        if (-not $DryRun) { Remove-Item $_.FullName -Force }
        Step "删除开关 $($_.Name)"
    }
    if ($latest) { Say "备份保留在: $($latest.FullName)(要恢复就把它里面的文件拷回去)" }
    Say '====================================='
    Say '提示: 想彻底关闭扭曲但保留插件,把 ReShade 面板里 Route A: 帧扭曲 的勾去掉即可(不写任何文件)。'
    exit 0
}

Say ''
Say '================ Frame Warp 安装 ================'
Say "来源: $Root"
Say "目标: $G"
Say "备份: $BackupRoot"
Say ''

Say '-- 自检 --'
$problems = Invoke-SelfCheck $G
Say ''

Say '-- 复制文件 --'
Copy-PayloadFile (Join-Path $Payload 'bin\routea_warp.addon64') (Join-Path $G 'routea_warp.addon64') $BackupRoot
Copy-PayloadFile (Join-Path $Payload 'shaders\routea_switch.fx')  (Join-Path $G 'reshade-shaders\Shaders\routea_switch.fx')  $BackupRoot
Copy-PayloadFile (Join-Path $Payload 'shaders\routea_ui_panel.fx') (Join-Path $G 'reshade-shaders\Shaders\routea_ui_panel.fx') $BackupRoot
Copy-PayloadFile (Join-Path $Payload 'plugins\routea_hook.asi')   (Join-Path $G 'plugins\routea_hook.asi')   $BackupRoot
Copy-PayloadFile (Join-Path $Payload 'plugins\routea_hook_gametex.txt') (Join-Path $G 'plugins\routea_hook_gametex.txt') $BackupRoot
Copy-PayloadFile (Join-Path $Payload 'plugins\routea_hook_live.txt')    (Join-Path $G 'plugins\routea_hook_live.txt')    $BackupRoot

Say ''
Say '-- 配置文件(用户版不需要任何配置文件;包里带了才复制) --'
$gateDir = Join-Path $Payload 'gates'
if (Test-Path $gateDir) {
    Get-ChildItem (Join-Path $gateDir '*') -File | ForEach-Object {
        $dst = Join-Path $G $_.Name
        if ((Test-Path $dst) -and (-not $ForceDefaults)) {
            Say "  [保留] $($_.Name)? 已存在(现值: 查看文件)"
        } else {
            if (-not $DryRun) { Copy-Item $_.FullName $dst -Force }
            Step "写开关 $($_.Name)? 默认值"
        }
    }
} else {
    Say '  [跳过] 包里没有配置文件 —— 正常:本版功能开箱即用,不需要任何 .txt'
}

Say ''
Say ''
Say '-- 面板语言 --'
$panelSrc = Join-Path $Payload ("shaders\lang\routea_ui_panel_" + $Lang.ToUpper() + ".fx")
if (Test-Path $panelSrc) {
    Backup-IfExists (Join-Path $G 'reshade-shaders\Shaders\routea_ui_panel.fx') $BackupRoot
    if (-not $DryRun) { Copy-Item $panelSrc (Join-Path $G 'reshade-shaders\Shaders\routea_ui_panel.fx') -Force }
    Step ("写入 " + $Lang.ToUpper() + " 版面板 routea_ui_panel.fx")
} else { Warn "缺少语言面板 $panelSrc -- 保持原面板不动" }

Say ''
Say '-- 修正 ReShade 预设(必须:预设值会覆盖 .fx 默认值) --'
$preset = Join-Path $G 'ReShadePreset.ini'
if (Test-Path $preset) {
    if (-not $DryRun) { Copy-Item $preset (Join-Path $BackupRoot 'ReShadePreset.ini') -Force -ErrorAction SilentlyContinue }
    $pt = [System.IO.File]::ReadAllText($preset)
    $need = ($pt -notmatch 'RouteAPath=1') -or ($pt -notmatch 'RouteAWarpOn=1')
    if ($need) {
        if ($pt -notmatch '\[routea_switch\.fx\]') { $pt += "`r`n[routea_switch.fx]`r`n" }
        $pt = [regex]::Replace($pt, 'RouteAPath=\d', 'RouteAPath=1')
        $pt = [regex]::Replace($pt, 'RouteAWarpOn=\d', 'RouteAWarpOn=1')
        if ($pt -notmatch 'RouteAPath=') { $pt = $pt.Replace('[routea_switch.fx]', "[routea_switch.fx]`r`nRouteAPath=1`r`nRouteAWarpOn=1") }
        if (-not $DryRun) { [System.IO.File]::WriteAllText($preset, $pt) }
        Step '预设已修正:RouteAPath=1 / RouteAWarpOn=1(否则画面不会扭)'
    } else { Say '  [OK] 预设里已经是 RouteAPath=1 / RouteAWarpOn=1' }
} else { Warn '游戏目录里没有 ReShadePreset.ini(没有预设就不用修)' }
Say '-- 校验 --'
if (-not $DryRun) {
    $want = (Get-FileHash (Join-Path $Payload 'bin\routea_warp.addon64') -Algorithm SHA256).Hash
    $got  = (Get-FileHash (Join-Path $G 'routea_warp.addon64') -Algorithm SHA256).Hash
    if ($want -eq $got) { Ok "插件哈希一致: $($got.Substring(0,16))" } else { Bad "插件哈希不一致! 期望 $want 实得 $got" }
    $hookWant = (Get-FileHash (Join-Path $Payload 'plugins\routea_hook.asi') -Algorithm SHA256).Hash
    $hookGot  = (Get-FileHash (Join-Path $G 'plugins\routea_hook.asi') -Algorithm SHA256).Hash
    if ($hookWant -eq $hookGot) { Ok "引擎钩子哈希一致: $($hookGot.Substring(0,16))" } else { Bad '引擎钩子哈希不一致!' }
} else { Say '  [试运行] 跳过哈希校验' }

Say ''
Say '-- 怎么用 --'
Say '  1. 启动游戏,按 ReShade 面板热键(默认 Home)打开面板。'
Say '  2. 在效果列表里勾上 routea_ui_panel.fx(中文滑块都在这里)。'
Say '  3. 想临时关掉扭曲:把同目录 routea_switch.fx 的 Route A: 帧扭曲 勾去掉。'
Say '  4. 日志: bin\x64\routea_warp.log(自动轮转);崩溃取证: bin\x64\fwcrash_*.txt'
Say ''
if ($problems.Count -gt 0) { Warn ("自检有缺项: " + ($problems -join ', ') + " —— 插件会以加载但不动画面的方式运行") }
Say '安装完成。回退:把备份目录里的文件拷回原位置即可。'
Say '================================================'
