param(
	[switch]$TestDownload,
	[switch]$TestScripts,
	[switch]$WhatIf
	)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

Set-Variable actionDownload -option Constant -value "download"
Set-Variable actionInstall -option Constant -value "install"
Set-Variable actionUnzip -option Constant -value "unzip"
Set-Variable actionExecute -option Constant -value "execute"

Set-Variable parameterName -option Constant -value "{Name}"
Set-Variable parameterUrl -option Constant -value "{Url}"
Set-Variable parameterInstruction -option Constant -value "{Instruction}"
Set-Variable parameterMd5 -option Constant -value "{MD5}"
Set-Variable parameterSecurityProtocol -option Constant -value "{Protocol}"

function Get-OutputLocation
{	
	return [io.path]::Combine((Get-Location), "oneliners")
}

function New-OneLiner
{
	param (
		$Name,
		$Url="",
		$Instruction="",
		$Md5="",
		[System.Net.SecurityProtocolType]$SecurityProtocolType="Ssl3",
		[switch]$Unzip,
		[switch]$Download,
		[switch]$Install,
		[switch]$RunScript
	)
	
	$obj = New-Object PSObject
	$obj | add-member Noteproperty Name $Name
	$obj | add-member Noteproperty Url $Url
	$obj | add-member Noteproperty Md5 $Md5
	$obj | add-member Noteproperty SecurityProtocolType $SecurityProtocolType
	$obj | add-member Noteproperty Instruction $Instruction
	$obj | add-member Noteproperty CommandLine ""
	$obj | add-member Noteproperty FileName ([io.path]::Combine((Get-OutputLocation), "$($Name).oneliner.ps1"))

	if ($Download)
	{	
		$obj | add-member Noteproperty Action $actionDownload 
	}
	elseif ($Install)
	{
		$obj | add-member Noteproperty Action $actionInstall
	}
	elseif ($Unzip)
	{
		$obj | add-member Noteproperty Action $actionUnzip
	}
	elseif ($RunScript)
	{
		$obj | add-member Noteproperty Action $actionExecute
	}
	return $obj
}

function Get-OneLinerCommandLine()
{
	param(
		$Template,
		$Object
		)
	$Template = $Template -replace $parameterName, $Object.Name
	$Template = $Template -replace $parameterUrl, $Object.Url
	$Template = $Template -replace $parameterInstruction, $Object.Instruction
	$Template = $Template -replace $parameterMd5, $Object.Md5
	$Template = $Template -replace $parameterSecurityProtocol, $Object.SecurityProtocolType
	return $Template	
}

$oneliners = @(										   
	(New-OneLiner -Name "SourceTree" -Url "https://downloads.atlassian.com/software/sourcetree/windows/ga/SourceTreeSetup-1.10.23.1.exe" -Md5 "18C3A09F5C240CCB2E1B98B0F2B4E0D5" -Install -Instruction '& $outfile /exenoui /exelog:"$($outfile).log" /quiet /qn /norestart /log "$($outfile).msi.log"' -SecurityProtocolType "Tls12"),
	(New-OneLiner -Name "SysInternals" -Url "http://download.sysinternals.com/files/SysinternalsSuite.zip" -Unzip -Instruction '"$($env:USERPROFILE)\bin"'),
	(New-OneLiner -Name "Fiddler" -Url "https://www.telerik.com/docs/default-source/fiddler/fiddlersetup.exe" -Install -Instruction '& $outfile /S' -SecurityProtocolType "Tls12"),
	(New-OneLiner -Name "Git" -Url "https://github.com/git-for-windows/git/releases/download/v2.12.0.windows.1/Git-2.12.0-64-bit.exe" -Md5 "CED52E70E5DE861D89A94034C3A53307" -Install -Instruction '& $outfile /VERYSILENT /SUPPRESSMSGBOXES /LOG="$($outfile).log"' -SecurityProtocolType "Tls12"),
	(New-OneLiner -Name "SublimeText3" -Url "https://download.sublimetext.com/Sublime%20Text%20Build%203126%20x64%20Setup.exe" -Md5 "DACBFCEE81B78532831BF95BFD52DC91" -Install -Instruction '& $outfile /VERYSILENT /SUPPRESSMSGBOXES /LOG="$($outfile).log"' -SecurityProtocolType "Tls12"),
	(New-OneLiner -Name "WinDirStat" -Url "https://windirstat.info/wds_current_setup.exe" -Md5 "3abf1c149873e25d4e266225fbf37cbf" -Install -Instruction '& $outfile /S' -SecurityProtocolType "Tls12"),
	(New-OneLiner -Name "FirewallFileAndPrint" -RunScript -Instruction '& netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes'),
	(New-OneLiner -Name "FirewallRemoteDesktop" -RunScript -Instruction '& netsh advfirewall firewall set rule group="remote desktop" new enable=Yes'),
	(New-OneLiner -Name "AzurePowershell" -Url "http://aka.ms/webpi-azps" -Install -Instruction 'move-item $outfile "$($outfile).exe" -Force; & "$($outfile).exe"' -SecurityProtocolType "Tls12"), # didn't figure out options for unattended
	(New-OneLiner -Name "DisableESCForAdmins" -RunScript -Instruction '& REG.EXE ADD "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 00000000 /f'),
	(New-OneLiner -Name "DisableESCForUsers" -RunScript -Instruction '& REG.EXE ADD "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 00000000 /f'),
	(New-OneLiner -Name "Speccy" -Url "http://download.piriform.com/spsetup130.exe" -Md5 "0942AE8ABF027AC095EF3CE2B590448A" -Install -Instruction '& $outfile /S'),
	(New-OneLiner -Name "Launchy" -Url "http://www.launchy.net/downloads/win/Launchy2.5.exe" -Md5 "C67962F064924F3C7B95D69F88E745C0" -Install -Instruction '& $outfile'), # didn't figure out options for unattended
	(New-OneLiner -Name "7Zip" -Url "http://www.7-zip.org/a/7z1604-x64.exe" -Md5 "04584F3AED5B27FD0AC2751B36273D94" -Install -Instruction '& $outfile /S'),
	(New-OneLiner -Name "Everything" -Url "http://www.voidtools.com/Everything-1.2.1.371.zip" -Md5 "753BC116DCB23BE1119C284F86193F51" -Unzip -Instruction '"$($env:USERPROFILE)\bin"'),
	(New-OneLiner -Name "BeyondCompare" -Url "https://www.scootersoftware.com/BCompare-4.1.9.21719.exe" -Md5 "AB54A1BA5F538702ACD9DCC15FA4A1F0" -Install -Instruction '& $outfile /VERYSILENT /SUPPRESSMSGBOXES /LOG="$($outfile).log"' -SecurityProtocolType "Tls12"),
	$null
) | ?{$_}

function Generate-CommandLine
{
	param (
		$OneLiners,
		[switch]$DisableInstall)


	$downloadTemplate = '$ErrorActionPreference="Stop";[System.Net.ServicePointManager]::SecurityProtocol = "'+$parameterSecurityProtocol+'";$url="' + $parameterUrl + '";$outdir="$($env:USERPROFILE)\Downloads\' + $parameterName + '";$outfile=[System.IO.Path]::Combine($outdir,(Split-Path -Leaf ([uri]::UnescapeDataString($url))));mkdir $outdir -Force|Out-Null;if(!(Test-Path $outfile)){$(New-Object Net.WebClient).DownloadFile($url, $outfile)};Start-Sleep -Seconds 2;if(!(Test-Path $outfile)){throw "Download Failed: $($url)"};$md5="{MD5}";if ($md5 -and ($md5 -notlike (Get-FileHash $outfile -Algorithm MD5).Hash)) {throw "MD5 check failed!"};'
	$installTemplate = $downloadTemplate + ' ' + $parameterInstruction + ';'
	$unzipTemplate = $downloadTemplate + '$dest=' + $parameterInstruction +';if (!(Test-Path $dest -pathType container)){mkdir $dest -Force|Out-Null};(new-object -com shell.application).namespace($dest).CopyHere((new-object -com shell.application).namespace("$($outfile)").Items(),16);'
	$executeTemplate = $parameterInstruction + ';'

	$actionTemplates = @{
		$actionUnzip = $unzipTemplate;
		$actionDownload = $downloadTemplate;
		$actionInstall = $installTemplate;
		$actionExecute = $executeTemplate;
	}

	$oneliners | %{
		$obj = $_

		Write-Host "Creating oneliner for $($obj.Name)"

		if ($DisableInstall -and ($obj.Action -eq $actionInstall))
		{
			Write-Host "DisableInstall: changing $($obj.Name) to download only"
			$obj.Action = $actionDownload
		}

		$template = $actionTemplates[$obj.Action]
		
		if (! $template)
		{
			throw "Don't know how to process $($obj)"
		}

		$obj.CommandLine = Get-OneLinerCommandLine -Template $template -Object $obj
		Write-Host "> $($obj.CommandLine)"
	}	
}

function Wait-Jobs
{
	param([array]$jobs)

	if (! $jobs.Length)
	{
		Write-Error "No jobs!"
	}

	$jobs | %{ Write-Progress -Id $_.ActivityId -Activity $_.Name -Status $_.State }
	
	while ($jobs | where State -eq Running)
	{			
		$jobs | %{ Write-Progress -Id $_.ActivityId -Activity $_.Name -Status $_.State }
		Start-Sleep -Second 1
	}
	
	$jobs | %{ Write-Progress -Id $_.ActivityId -Activity $_.Name -Status $_.State -Completed }
}

function TestScripts
{
	param (
		[Parameter(Mandatory=$true)]
		[array]$OneLiners)

	$jobs = @()
	$index = 0	
	$OneLiners | %{
		$obj = $_
		$job = Start-Job -Name "Testing $($obj.FileName)" -ScriptBlock { param ($filename); & powershell.exe -File $filename } -ArgumentList $obj.FileName
		$job | add-member Noteproperty CustomFileName $obj.FileName
		$job | add-member Noteproperty ActivityId $index
		$job | add-member Noteproperty Md5 $obj.Md5
		$jobs += $job
		$index += 1
	}

	Wait-Jobs $jobs

	$numErrors = 0
	$jobs | %{
		$job = $_
		try
		{
			$job | Receive-Job | Out-Null
			Write-Host "Script Succeeded: $($job.CustomFileName)" -ForegroundColor Green
		}
		catch
		{
			$numErrors += 1
			Write-Host "Script failed $($job.CustomFileName): $($_.Exception.ToString())" -ForegroundColor Red
		}
	}

	$jobs | Remove-Job

	if ($numErrors) 
	{
		throw "TestScripts failed! $($numErrors) problematic oneliner(s) out of $($OneLiners.Length)"
	}
}

function TestDownload
{
	param (
		[Parameter(Mandatory=$true)]
		[array]$OneLiners)

	$tempdir = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
	mkdir $tempdir -Force | Out-Null
	$jobs = @()
	$index = 0
	foreach ($obj in $OneLiners)
	{
		$url = $obj.Url
		if (! $url)
		{
			continue
		}

		$md5 = $obj.Md5		
		$outfile = Join-Path $tempdir (Split-Path -Leaf ([uri]::UnescapeDataString($url)))
		$command = "[System.Net.ServicePointManager]::SecurityProtocol = '$($obj.SecurityProtocolType)'; (New-Object Net.WebClient).DownloadFile('$url', '$outfile');"
		$job = Start-Job -Name "Downloading [$($obj.SecurityProtocolType)] $url -> $outfile" -ScriptBlock { param ($url, $outfile, $securityProtocolType); [System.Net.ServicePointManager]::SecurityProtocol = $securityProtocolType; (New-Object Net.WebClient).DownloadFile($url, $outfile); } -ArgumentList $url, $outfile, $obj.SecurityProtocolType
		$job | add-member Noteproperty Url $url
		$job | add-member Noteproperty OutputFile $outfile
		$job | add-member Noteproperty ActivityId $index
		$job | add-member Noteproperty Md5 $md5
		$job | add-member Noteproperty CommandInfo $command
		$jobs += $job
		$index += 1
	}

	Wait-Jobs $jobs

	$numErrors = 0
	$jobs | %{
		$job = $_
		$url = $job.Url
		$outfile = $job.OutputFile
		if(Test-Path $outfile)
		{
			Write-Host "Download Succeeded: $($url)" -ForegroundColor Green
			
			$md5exp = $job.Md5
			if ($md5exp)
			{
				$md5act = (Get-FileHash $outfile -Algorithm MD5).Hash
				Write-Host ("Downloaded MD5 is : {0}" -f $md5act)
				Write-Host ("Expected MD5 is   : {0}" -f $md5exp)
				if ($md5exp -ne $md5act)
				{
					Write-Warning "Hash mismatch!"
					$numErrors += 1
				}
				else
				{
					Write-Host "MD5 check succeeded: $($url)" -ForegroundColor Green
				}
			}

		}
		else
		{
			Write-Host "Download Failed: $($url)" -ForegroundColor Red
			Write-Host "Command: $($job.CommandInfo)"
			$numErrors += 1
		}
	}

	$jobs | Remove-Job

	rmdir $tempdir -Force -Recurse -Confirm:$false	

	if ($numErrors) 
	{
		throw "TestDownload failed! $($numErrors) problematic oneliner(s) out of $($OneLiners.Length)"
	}

}

function Main
{
	param (
		[Parameter(Mandatory=$true)]
		[array]$OneLiners,
		[switch]$DisableInstall)

	$outputdir = Get-OutputLocation
	mkdir $outputdir -Force | out-null
	Generate-CommandLine -OneLiners $oneliners -DisableInstall:$DisableInstall

	$OneLiners | fl *
	if (! $WhatIf)
	{
		$OneLiners | %{
			$obj = $_
			Write-Host "Writing $($obj.FileName)"
			[System.IO.File]::WriteAllLines($obj.FileName, $obj.CommandLine)
		}
	}
}

if ($TestDownload)
{
	TestDownload -OneLiners $oneliners
}

Main -OneLiners $oneliners -DisableInstall:$TestScripts

if ($TestScripts)
{
	TestScripts -OneLiners $oneliners
}
