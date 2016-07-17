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

Set-Variable parameterName -option Constant -value "{Name}"
Set-Variable parameterUrl -option Constant -value "{Url}"
Set-Variable parameterInstruction -option Constant -value "{Instruction}"
Set-Variable parameterMd5 -option Constant -value "{MD5}"

function Get-OutputLocation
{	
	return [io.path]::Combine((Get-Location), "oneliners")
}

function New-OneLiner
{
	param (
		$Name,
		$Url,
		$Instruction="",
		$Md5="",
		[switch]$Unzip,
		[switch]$Download,
		[switch]$Install
	)
	
	$obj = New-Object PSObject
	$obj | add-member Noteproperty Name $Name
	$obj | add-member Noteproperty Url $Url
	$obj | add-member Noteproperty Md5 $Md5
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
	return $Template	
}

$oneliners = @(
	(New-OneLiner -Name "SourceTree" -Url "https://downloads.atlassian.com/software/sourcetree/windows/SourceTreeSetup_1.8.3.exe" -Install -Instruction '& $outfile /exenoui /exelog:"$($outfile).log" /quiet /qn /norestart /log "$($outfile).msi.log"'),
	(New-OneLiner -Name "SysInternals" -Url "http://download.sysinternals.com/files/SysinternalsSuite.zip" -Unzip -Instruction '"$($env:USERPROFILE)\bin"'),
	(New-OneLiner -Name "Fiddler" -Url "https://www.telerik.com/docs/default-source/fiddler/fiddlersetup.exe" -Install -Instruction '& $outfile /S'),
	(New-OneLiner -Name "Git" -Url "https://github.com/git-for-windows/git/releases/download/v2.9.2.windows.1/Git-2.9.2-64-bit.exe" -Install -Instruction '& $outfile /VERYSILENT /SUPPRESSMSGBOXES /LOG="$($outfile).log"'),
	(New-OneLiner -Name "SublimeText3" -Url "https://download.sublimetext.com/Sublime%20Text%20Build%203114%20x64%20Setup.exe" -Install -Instruction '& $outfile /VERYSILENT /SUPPRESSMSGBOXES /LOG="$($outfile).log"'),
	(New-OneLiner -Name "WinDirStat" -Url "https://windirstat.info/wds_current_setup.exe" -Md5 "3abf1c149873e25d4e266225fbf37cbf" -Install -Instruction '& $outfile /S'),
	$null
) | ?{$_}

function Generate-CommandLine
{
	param (
		$OneLiners,
		[switch]$DisableInstall)


	$downloadTemplate = '$ErrorActionPreference="Stop";$url="' + $parameterUrl + '";$outdir="$($env:USERPROFILE)\Downloads\' + $parameterName + '";$outfile=[System.IO.Path]::Combine($outdir,(Split-Path -Leaf ([uri]::UnescapeDataString($url))));mkdir $outdir -Force|Out-Null;if(!(Test-Path $outfile)){$(New-Object Net.WebClient).DownloadFile($url, $outfile)};if(!(Test-Path $outfile)){throw "Download Failed: $($url)"};$md5="{MD5}";if ($md5 -and ($md5 -notlike (Get-FileHash $outfile -Algorithm MD5).Hash)) {throw "MD5 check failed!"};'
	$installTemplate = $downloadTemplate + ' ' + $parameterInstruction + ';'
	$unzipTemplate = $downloadTemplate + '$dest=' + $parameterInstruction +';if (!(Test-Path $dest -pathType container)){mkdir $dest -Force|Out-Null};(new-object -com shell.application).namespace($dest).CopyHere((new-object -com shell.application).namespace("$($outfile)").Items(),16);'

	$actionTemplates = @{
		$actionUnzip = $unzipTemplate;
		$actionDownload = $downloadTemplate;
		$actionInstall = $installTemplate
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
	$OneLiners | %{
		$obj = $_
		$url = $obj.Url
		$outfile = Join-Path $tempdir (Split-Path -Leaf ([uri]::UnescapeDataString($url)))
		$job = Start-Job -Name "Downloading $url -> $outfile" -ScriptBlock { param ($url, $outfile); (New-Object Net.WebClient).DownloadFile($url, $outfile) } -ArgumentList $url, $outfile
		$job | add-member Noteproperty Url $url
		$job | add-member Noteproperty OutputFile $outfile
		$job | add-member Noteproperty ActivityId $index
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
		}
		else
		{
			Write-Host "Download Failed: $($url)" -ForegroundColor Red
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
