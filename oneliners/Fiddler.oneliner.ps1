$ErrorActionPreference="Stop";$url="https://www.telerik.com/docs/default-source/fiddler/fiddlersetup.exe";$outdir="$($env:USERPROFILE)\Downloads\Fiddler";$outfile=[System.IO.Path]::Combine($outdir,(Split-Path -Leaf ([uri]::UnescapeDataString($url))));mkdir $outdir -Force|Out-Null;if(!(Test-Path $outfile)){$(New-Object Net.WebClient).DownloadFile($url, $outfile)};if(!(Test-Path $outfile)){throw "Download Failed: $($url)"}; & $outfile /S;
