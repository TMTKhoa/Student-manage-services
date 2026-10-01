@echo off
setlocal
REM ============================================================
REM  KhoaVeyonService.bat  -  for Veyon clients (keep in C:\cmd)
REM
REM  -install      one-time setup per PC (needs admin password once)
REM  -uninstall    remove services, rules and app blocks
REM  -killapp      force close all open apps
REM  -blockall     block all internet (LAN stays on)
REM  -allowpage    block internet EXCEPT sites listed in AllowPage.xlsx
REM  -allowall     allow all internet again
REM  -blockapp     block apps/folders listed in BlockAppList.xlsx
REM  -unblockapp   unblock those apps again
REM  -keepapp      close all apps EXCEPT those listed in KeepAppList.xlsx
REM  -lockdown     disable Task Manager and Settings for the logged-in user
REM  -unlock       enable Task Manager and Settings again
REM  -mute         mute the speakers
REM  -unmute       unmute the speakers
REM ============================================================

REM ===== SETTINGS =====
REM Folder that holds AllowPage.xlsx and BlockAppList.xlsx (keep the last backslash)
set "LISTDIR=C:\cmd\"
REM ====================

set "SELF=%~f0"
set "ACT=%~1"
set "MODE="

if /i "%ACT%"=="-killapp"    goto KILLAPP
if /i "%ACT%"=="-install"    goto INSTALL
if /i "%ACT%"=="-uninstall"  goto UNINSTALL
if /i "%ACT%"=="-blockall"   set "MODE=blockall"
if /i "%ACT%"=="-allowpage"  set "MODE=allowpage"
if /i "%ACT%"=="-allowall"   set "MODE=allowall"
if /i "%ACT%"=="-blockapp"   set "MODE=blockapp"
if /i "%ACT%"=="-unblockapp" set "MODE=unblockapp"
if /i "%ACT%"=="-keepapp"    set "MODE=keepapp"
if /i "%ACT%"=="-lockdown"   set "MODE=lockdown"
if /i "%ACT%"=="-unlock"     set "MODE=unlock"
if /i "%ACT%"=="-unlockdown" set "MODE=unlock"
if /i "%ACT%"=="-mute"       set "MODE=mute"
if /i "%ACT%"=="-unmute"     set "MODE=unmute"
if not defined MODE goto HELP

REM These run in the kid's own session, so they need no admin rights and no service
for %%U in (keepapp lockdown unlock mute unmute) do if /i "%MODE%"=="%%U" goto RUNPS

REM Already admin / SYSTEM (for example when started by the service)? Do the work now.
fltmc >nul 2>&1
if errorlevel 1 goto VIAUSER

:RUNPS
set "KV_MODE=%MODE%"
set "KV_DIR=%~dp0"
set "KV_LIST=%LISTDIR%"
set "KV_SELF=%SELF%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:KV_SELF); iex $t.Substring($t.IndexOf('#PS1'+'START'))"
exit /b 0

:VIAUSER
REM Normal (kid) account: ask the SYSTEM service to do the work
sc start KhoaVeyonService_%MODE% >nul 2>&1
if %errorlevel%==1060 echo Service not installed. Run KhoaVeyonService.bat -install as admin.
exit /b 0

:KILLAPP
taskkill /F /FI "USERNAME eq %USERNAME%" /FI "WINDOWTITLE ne N/A" /FI "IMAGENAME ne explorer.exe" /FI "IMAGENAME ne cmd.exe" /FI "IMAGENAME ne conhost.exe" /FI "IMAGENAME ne powershell.exe" /FI "IMAGENAME ne veyon-server.exe" /FI "IMAGENAME ne veyon-worker.exe" /FI "IMAGENAME ne veyon-service.exe" /FI "IMAGENAME ne veyon-master.exe" /FI "IMAGENAME ne ApplicationFrameHost.exe" /FI "IMAGENAME ne ShellExperienceHost.exe" /FI "IMAGENAME ne StartMenuExperienceHost.exe" /FI "IMAGENAME ne SearchHost.exe" /FI "IMAGENAME ne TextInputHost.exe" /FI "IMAGENAME ne SystemSettings.exe" /FI "IMAGENAME ne sihost.exe" /FI "IMAGENAME ne ctfmon.exe" /FI "IMAGENAME ne dwm.exe" >nul 2>&1
exit /b 0

:INSTALL
fltmc >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process '%SELF%' -ArgumentList '-install' -Verb RunAs"
  exit /b
)
for %%M in (blockall allowpage allowall blockapp unblockapp) do (
  sc stop KhoaVeyonService_%%M >nul 2>&1
  sc delete KhoaVeyonService_%%M >nul 2>&1
  sc create KhoaVeyonService_%%M binPath= "cmd.exe /c %SELF% -%%M" start= demand >nul
  sc sdset KhoaVeyonService_%%M "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;LCRPRC;;;IU)" >nul
)
REM Normal users may read and run files in this folder but not edit them
icacls "%~dp0." /inheritance:r /grant:r "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F" "Users:(OI)(CI)RX" >nul
echo.
echo Install done. Services KhoaVeyonService_* created.
echo Log file: %~dp0KhoaVeyonService.log
pause
exit /b 0

:UNINSTALL
fltmc >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process '%SELF%' -ArgumentList '-uninstall' -Verb RunAs"
  exit /b
)
call "%SELF%" -allowall
call "%SELF%" -unblockapp
for %%M in (blockall allowpage allowall blockapp unblockapp) do (
  sc stop KhoaVeyonService_%%M >nul 2>&1
  sc delete KhoaVeyonService_%%M >nul 2>&1
)
echo.
echo Uninstall done.
pause
exit /b 0

:HELP
echo Usage: KhoaVeyonService.bat [-install ^| -uninstall ^| -killapp ^| -blockall ^| -allowpage ^| -allowall ^| -blockapp ^| -unblockapp ^| -keepapp ^| -lockdown ^| -unlock ^| -mute ^| -unmute]
exit /b 0

#PS1START
$ErrorActionPreference = 'Continue'
$mode = $env:KV_MODE
$dir  = $env:KV_DIR
$list = $env:KV_LIST
$log  = Join-Path $dir 'KhoaVeyonService.log'
if (@('keepapp','lockdown','unlock','mute','unmute') -contains $mode) { $log = Join-Path $env:TEMP 'KhoaVeyonService.log' }
$sid  = '*S-1-5-32-545'

function Log($m) {
    try { Add-Content -Path $log -Value ("{0}  [{1}]  {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $mode, $m) } catch {}
}

# ---------- read column A of the first sheet of an .xlsx (Excel not needed) ----------
function Read-ColumnA($file) {
    $out = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $file)) { Log "File not found: $file"; return @() }
    Add-Type -AssemblyName System.IO.Compression
    $fs  = [IO.File]::Open($file, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    $zip = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Read)
    try {
        $shared = @()
        $e = $zip.GetEntry('xl/sharedStrings.xml')
        if ($e) {
            $r = New-Object IO.StreamReader($e.Open())
            $x = New-Object Xml.XmlDocument
            $x.LoadXml($r.ReadToEnd()); $r.Close()
            foreach ($si in $x.SelectNodes('//*[local-name()="si"]')) {
                $shared += (($si.SelectNodes('.//*[local-name()="t"]') | ForEach-Object { $_.InnerText }) -join '')
            }
        }
        $e = $zip.GetEntry('xl/worksheets/sheet1.xml')
        if (-not $e) {
            $e = $zip.Entries | Where-Object { $_.FullName -like 'xl/worksheets/sheet*.xml' } | Sort-Object FullName | Select-Object -First 1
        }
        if (-not $e) { Log "No worksheet found in $file"; return @() }
        $r = New-Object IO.StreamReader($e.Open())
        $x = New-Object Xml.XmlDocument
        $x.LoadXml($r.ReadToEnd()); $r.Close()
        foreach ($c in $x.SelectNodes('//*[local-name()="c"]')) {
            if ($c.GetAttribute('r') -notmatch '^A\d+$') { continue }
            $t = $c.GetAttribute('t'); $val = $null
            if ($t -eq 's') {
                $v = $c.SelectSingleNode('*[local-name()="v"]')
                if ($v) { $val = $shared[[int]$v.InnerText] }
            } elseif ($t -eq 'inlineStr') {
                $val = ($c.SelectNodes('.//*[local-name()="t"]') | ForEach-Object { $_.InnerText }) -join ''
            } else {
                $v = $c.SelectSingleNode('*[local-name()="v"]')
                if ($v) { $val = $v.InnerText }
            }
            if ($val) { $out.Add($val.Trim()) }
        }
    } finally { $zip.Dispose(); $fs.Dispose() }
    return $out.ToArray()
}

# ---------- IP helpers ----------
function ToLong($ip) {
    $b = [Net.IPAddress]::Parse($ip).GetAddressBytes()
    return ([long]$b[0] * 16777216) + ([long]$b[1] * 65536) + ([long]$b[2] * 256) + [long]$b[3]
}
function ToIp([long]$n) {
    return '{0}.{1}.{2}.{3}' -f (($n -shr 24) -band 255), (($n -shr 16) -band 255), (($n -shr 8) -band 255), ($n -band 255)
}

# ---------- firewall ----------
function Remove-Rules {
    Get-NetFirewallRule -DisplayName 'KhoaVeyonBlock*' -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
}

function Apply-Block($extra) {
    Remove-Rules
    $allow = New-Object System.Collections.Generic.List[object]
    $lan = @(
        @('10.0.0.0','10.255.255.255'),
        @('127.0.0.0','127.255.255.255'),
        @('169.254.0.0','169.254.255.255'),
        @('172.16.0.0','172.31.255.255'),
        @('192.168.0.0','192.168.255.255'),
        @('224.0.0.0','239.255.255.255'),
        @('255.255.255.255','255.255.255.255')
    )
    foreach ($p in $lan) { $allow.Add(@((ToLong $p[0]), (ToLong $p[1]))) }
    foreach ($ip in $extra) { $n = ToLong $ip; $allow.Add(@($n, $n)) }

    # block everything that is NOT inside an allowed range
    $sorted = @($allow | Sort-Object { $_[0] })
    $ranges = New-Object System.Collections.Generic.List[string]
    $next = [long]0
    foreach ($a in $sorted) {
        if ($a[0] -gt $next) { $ranges.Add((ToIp $next) + '-' + (ToIp ($a[0] - 1))) }
        if (($a[1] + 1) -gt $next) { $next = $a[1] + 1 }
    }
    if ($next -le 4294967295) { $ranges.Add((ToIp $next) + '-' + (ToIp 4294967295)) }

    New-NetFirewallRule -DisplayName 'KhoaVeyonBlock'  -Direction Outbound -Action Block -Profile Any -RemoteAddress $ranges.ToArray() | Out-Null
    New-NetFirewallRule -DisplayName 'KhoaVeyonBlock6' -Direction Outbound -Action Block -Profile Any -RemoteAddress '2000::/3' | Out-Null
}

# ---------- modes ----------
switch ($mode) {

    'blockall' {
        Apply-Block @()
        Log 'Internet BLOCKED (LAN allowed)'
    }

    'allowall' {
        Remove-Rules
        Log 'Internet ALLOWED'
    }

    'allowpage' {
        Remove-Rules   # so DNS works while we look the sites up
        $items = @(Read-ColumnA (Join-Path $list 'AllowPage.xlsx'))
        $names = @()
        foreach ($i in $items) {
            $d = ($i.ToLower() -replace '^[a-z]+://', '') -replace '[/?#:].*$', ''
            if ($d -match '^\d{1,3}(\.\d{1,3}){3}$' -or $d -match '^[a-z0-9-]+(\.[a-z0-9-]+)+$') { $names += $d }
        }
        $names = @($names | Select-Object -Unique)

        $ips = New-Object System.Collections.Generic.HashSet[string]
        foreach ($d in $names) {
            if ($d -match '^\d{1,3}(\.\d{1,3}){3}$') { [void]$ips.Add($d); continue }
            $try = @($d)
            if ($d -notlike 'www.*') { $try += "www.$d" }
            foreach ($h in $try) {
                $res = Resolve-DnsName $h -Type A -DnsOnly -ErrorAction SilentlyContinue | Where-Object { $_.Type -eq 'A' }
                foreach ($r in $res) { [void]$ips.Add($r.IPAddress) }
            }
        }
        # keep the DNS servers reachable, otherwise names cannot be resolved
        Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            ForEach-Object { $_.ServerAddresses } | Where-Object { $_ } | ForEach-Object { [void]$ips.Add($_) }

        Apply-Block @($ips)
        Log ("Internet BLOCKED except {0} sites ({1} IPs): {2}" -f $names.Count, $ips.Count, ($names -join ', '))
    }

    'blockapp' {
        $blockedFile = Join-Path $dir 'blocked.txt'
        $done = @()
        if (Test-Path -LiteralPath $blockedFile) { $done = @(Get-Content -LiteralPath $blockedFile) }
        $skip = @($env:windir, (Join-Path $env:ProgramFiles 'Veyon'), $dir.TrimEnd('\'))
        $items = @(Read-ColumnA (Join-Path $list 'BlockAppList.xlsx')) | Where-Object { $_ -match '^[A-Za-z]:\\' -or $_ -match '^\\\\' }

        foreach ($raw in $items) {
            $p = [Environment]::ExpandEnvironmentVariables($raw).Trim('"')
            $targets = @()
            if ($p -match '[\*\?]') {
                $targets = @(Get-ChildItem -Path $p -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
            } elseif (Test-Path -LiteralPath $p) {
                $targets = @($p)
            } else {
                Log "Not found: $p"
            }
            foreach ($t in $targets) {
                $bad = ($t.Length -le 3)
                foreach ($s in $skip) { if ($t -like "$s*") { $bad = $true } }
                if ($bad) { Log "SKIPPED (protected): $t"; continue }

                if (Test-Path -LiteralPath $t -PathType Container) {
                    icacls $t /deny "${sid}:(OI)(CI)(X)" | Out-Null
                    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like "$t\*" } | Stop-Process -Force -ErrorAction SilentlyContinue
                } else {
                    icacls $t /deny "${sid}:(X)" | Out-Null
                    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -eq $t } | Stop-Process -Force -ErrorAction SilentlyContinue
                }
                if ($done -notcontains $t) { $done += $t }
                Log "Blocked: $t"
            }
        }
        if ($done.Count -gt 0) { Set-Content -LiteralPath $blockedFile -Value $done }
    }

    'unblockapp' {
        $blockedFile = Join-Path $dir 'blocked.txt'
        if (Test-Path -LiteralPath $blockedFile) {
            foreach ($t in @(Get-Content -LiteralPath $blockedFile)) {
                if ($t -and (Test-Path -LiteralPath $t)) {
                    icacls $t /remove:d $sid | Out-Null
                    Log "Unblocked: $t"
                }
            }
            Remove-Item -LiteralPath $blockedFile -Force -ErrorAction SilentlyContinue
        } else {
            Log 'Nothing to unblock'
        }
    }

    # ---------- the modes below run as the logged-in user (no admin needed) ----------

    'keepapp' {
        $keepNames = @(); $keepPaths = @()
        foreach ($k in @(Read-ColumnA (Join-Path $list 'KeepAppList.xlsx'))) {
            $k = [Environment]::ExpandEnvironmentVariables($k).Trim('"')
            if ($k -match '\\') { $keepPaths += $k.TrimEnd('\') }
            elseif ($k) { $keepNames += ($k -replace '\.exe$', '').ToLower() }
        }
        $protect = @('explorer','cmd','conhost','powershell','pwsh','veyon-server','veyon-worker','veyon-service','veyon-master',
                     'applicationframehost','shellexperiencehost','startmenuexperiencehost','searchhost','textinputhost',
                     'systemsettings','sihost','ctfmon','dwm')
        $session = (Get-Process -Id $PID).SessionId
        foreach ($p in @(Get-Process -ErrorAction SilentlyContinue)) {
            if ($p.SessionId -ne $session -or $p.MainWindowHandle -eq 0) { continue }
            $n = $p.ProcessName.ToLower()
            if ($protect -contains $n -or $keepNames -contains $n) { continue }
            $path = $null
            try { $path = $p.Path } catch {}
            if ($path) {
                $kept = $false
                foreach ($kp in $keepPaths) { if ($path -like "$kp*") { $kept = $true } }
                if ($kept) { continue }
            }
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
            Log "Closed: $n"
        }
        Log ("Kept names: {0}; kept paths: {1}" -f ($keepNames -join ', '), ($keepPaths -join ', '))
    }

    'lockdown' {
        $sys = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
        $exp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
        foreach ($k in @($sys, $exp)) { if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null } }
        New-ItemProperty -Path $sys -Name DisableTaskMgr  -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $exp -Name NoControlPanel  -Value 1 -PropertyType DWord -Force | Out-Null
        Stop-Process -Name Taskmgr, SystemSettings -Force -ErrorAction SilentlyContinue
        Log 'Lockdown ON (Task Manager and Settings disabled)'
    }

    'unlock' {
        Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'   -Name DisableTaskMgr -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name NoControlPanel -ErrorAction SilentlyContinue
        Log 'Lockdown OFF (Task Manager and Settings enabled)'
    }

    { $_ -eq 'mute' -or $_ -eq 'unmute' } {
        $src = @"
using System;
using System.Runtime.InteropServices;

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar(float fLevel, Guid pguidEventContext);
    int j();
    int GetMasterVolumeLevelScalar(out float pfLevel);
    int k(); int l(); int m(); int n();
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, ref Guid pguidEventContext);
    int GetMute(out bool pbMute);
}

[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
    int Activate(ref Guid id, int clsCtx, IntPtr activationParams, out IAudioEndpointVolume aev);
}

[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
    int f();
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}

[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
class MMDeviceEnumeratorComObject { }

public class KvAudio {
    static IAudioEndpointVolume Vol() {
        var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev = null;
        Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(0, 1, out dev));
        IAudioEndpointVolume epv = null;
        var epvid = typeof(IAudioEndpointVolume).GUID;
        Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, 23, IntPtr.Zero, out epv));
        return epv;
    }
    public static void SetMute(bool m) { Guid ctx = Guid.Empty; Marshal.ThrowExceptionForHR(Vol().SetMute(m, ref ctx)); }
}
"@
        try {
            Add-Type -TypeDefinition $src
            [KvAudio]::SetMute(($mode -eq 'mute'))
            Log ("Speakers " + $(if ($mode -eq 'mute') { 'MUTED' } else { 'UNMUTED' }))
        } catch {
            Log "Mute failed: $_"
        }
    }
}