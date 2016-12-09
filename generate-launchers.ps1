# generate-launchers
param ([switch]$Whatif)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function Generate-SublimeLauncher
{
    param ($FileName, [switch]$Whatif)

    if ([string]::IsNullOrEmpty($FileName))
    {
        throw "Invalid argument: FileName"
    }
    
    Generate-LauncherForTargets -FileName $FileName -Whatif:$Whatif -Targets @("c:\Program Files\Sublime Text 3\subl.exe", "c:\Program Files (x86)\Sublime Text 2\sublime_text.exe")
}

function Generate-EverythingLauncher
{
    param ($FileName, [switch]$Whatif)

    if ([string]::IsNullOrEmpty($FileName))
    {
        throw "Invalid argument: FileName"
    }
    
    Generate-LauncherForTargets -FileName $FileName -Whatif:$Whatif -Targets @(Join-Path $env:USERPROFILE "bin\Everything-1.2.1.371.exe")
}

function Generate-LauncherForTargets
{
    param ($FileName, $Targets, [switch]$Whatif)

    if ([string]::IsNullOrEmpty($FileName))
    {
        throw "Invalid argument: FileName"
    }

    if (!($Targets -is [array]))
    {
        throw "Invalid argument: Targets"
    }

    $script = @"
@echo off

"@

    $index = 0
    foreach ($target in $Targets)
    {
        $index += 1
        $script += @"
if not exist "{0}" goto :next{1}
start "target" "{0}" %*
:next{1}

"@ -f $target, $index
    }

    if (!$Whatif)
    {
        $script | Out-File $FileName -Encoding ascii        
    }
    else
    {
        $script | Out-Host
    }
}

$bindir = Join-Path $env:USERPROFILE "bin"

if (!(Test-Path $bindir))
{
    throw "Cannot access $($bindir)"
}

Generate-SublimeLauncher -FileName (Join-Path $bindir "subl.cmd") -Whatif:$Whatif
Generate-EverythingLauncher -FileName (Join-Path $bindir "everything.cmd") -Whatif:$Whatif