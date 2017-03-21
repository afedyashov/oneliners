$ErrorActionPreference="Stop";[System.Net.ServicePointManager]::SecurityProtocol = "Ssl3";$url="http://download.piriform.com/spsetup130.exe";$outdir="$($env:USERPROFILE)\Downloads\Speccy";$outfile=[System.IO.Path]::Combine($outdir,(Split-Path -Leaf ([uri]::UnescapeDataString($url))));mkdir $outdir -Force|Out-Null;if(!(Test-Path $outfile)){$(New-Object Net.WebClient).DownloadFile($url, $outfile)};Start-Sleep -Seconds 2;if(!(Test-Path $outfile)){throw "Download Failed: $($url)"};$md5="0942AE8ABF027AC095EF3CE2B590448A";if ($md5 -and ($md5 -notlike (Get-FileHash $outfile -Algorithm MD5).Hash)) {throw "MD5 check failed!"};
