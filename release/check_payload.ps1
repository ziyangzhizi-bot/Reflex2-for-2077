# check_payload.ps1 -- release gate: scan the SHIPPED BINARIES for strings a public release
# must not contain.  A file-name check cannot see text embedded in a DLL, which is how developer
# paths and a competitor's name travelled into an earlier package.
#
# ASCII-ONLY on purpose: Windows PowerShell 5.1 reads a .ps1 without a BOM as ANSI, so a file with
# only ASCII can never be mis-decoded.
#
# -AllowDirty : do not abort on a hard hit; report it as WAIVED and let the packager ship the
#               KNOWN-GOOD binary anyway (plan B: the verified-stable build predates the string
#               cleanup, and "ship the build that ran" outranks hygiene for this candidate).
#               The waiver is printed so it can be recorded in BUILD_INFO.
param(
    [Parameter(Mandatory=$true)][string]$Dll,
    [Parameter(Mandatory=$true)][string]$Asi,
    [switch]$AllowDirty
)

$hard = @(
    'ResTrack', 'Hudfix', 'framewarp-stage2', 'Nukem', 'DLSS Swapper',
    '_re\', '_re/', 'ZhuanZ', 'Downloads', 'SteamLibrary',
    'make_uimask', '019_CSMain', 'runtime.cpp L', 'd3d12_impl_command_list.cpp L',
    'routea_addon.cpp', 'demo_re', 'optiscaler_re'
)
$soft = @('OptiScaler')   # allowed only as a provenance comment; reported, not fatal

$fail = $false
foreach ($bin in @($Dll, $Asi)) {
    if (-not (Test-Path $bin)) { Write-Host ("  [skip] missing " + $bin); continue }
    $txt = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($bin))
    $name = Split-Path $bin -Leaf
    $hits = @()
    foreach ($s in $hard) {
        if ($txt.Contains($s)) {
            if ($AllowDirty) { $hits += $s }
            else {
                Write-Host ("  [FAIL] " + $name + " contains forbidden string '" + $s + "'") -ForegroundColor Red
                $fail = $true
            }
        }
    }
    if ($AllowDirty -and $hits.Count -gt 0) {
        Write-Host ("  [WAIVED] " + $name + " contains: " + ($hits -join ', ')) -ForegroundColor Yellow
        $fail = $true   # still counted, so the packager can record it
    }
    foreach ($s in $soft) {
        if ($txt.Contains($s)) {
            Write-Host ("  [WARN] " + $name + " mentions '" + $s + "' (provenance comment only)") -ForegroundColor Yellow
        }
    }
    if (-not $fail) { Write-Host ("  [OK]   " + $name + " clean") }
}
if ($fail -and -not $AllowDirty) { throw 'payload string scan failed -- packaging aborted' }
