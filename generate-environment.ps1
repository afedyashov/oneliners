param ([switch]$Whatif)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$bindir = Join-Path $env:USERPROFILE "bin"
if (!(Test-Path $bindir))
{
    throw "Cannot access $($bindir)"
}

# read-environment

[array]$paths = $env:PATH -split ";"

# modify-environment

if (!$paths.Contains($bindir))
{
    $paths += $bindir
}

# write-environment
$uniquePaths = $paths | select -uniq | ?{ ![string]::IsNullOrEmpty($_) -and (Test-Path $_) }

$pathValue = $uniquePaths -join ";" 
if (!$Whatif)
{
    [System.Environment]::SetEnvironmentVariable("PATH", $pathValue, "USER")
}
else
{
    $pathValue | Out-Host
}
