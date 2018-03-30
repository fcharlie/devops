#!/usr/bin/env pwsh
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
$Toolsdir = Split-Path -Path (Split-Path $PSScriptRoot)
Import-Module -Name "$Toolsdir/modules/Download"
Import-Module -Name "$Toolsdir/modules/Process"
Import-Module -Name "$Toolsdir/modules/Utils"



$toolslockfile = $PSScriptRoot + [System.IO.Path]::DirectorySeparatorChar + "config.lock.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json

$configfile = $PSScriptRoot + [System.IO.Path]::DirectorySeparatorChar + "config.json"
$mconfig = Get-Content $configfile -ErrorAction SilentlyContinue| ConvertFrom-Json

if ($toolslocked.version -eq $mconfig.version) {
    Write-Host "golang $($toolslocked.version) already install"
    exit 0
}

$besturl = Test-BestSourcesURL -Urls $mconfig.sources
if ($besturl -eq $null) {
    Write-Host -ForegroundColor Red "Bad sources config, please set it."
    exit 1
}
$version = $mconfig.version
$prefix = $mconfig.prefix
$gofilename = "go${version}.linux-amd64";
$gourl = "$besturl/$gofilename.tar.gz"

if ((DownloadFile -Url $gourl -Destination "/tmp/$gofilename.tar.gz") -eq $false) {
    exit 1
}

if ((ProcessExec -FilePath "tar" -Arguments "-xvf  $gofilename.tar.gz" -Dir "/tmp") -ne 0) {
    exit 1
}

if (Test-Path -Path $prefix) {
    Write-Host "move old go to /tmp"
    sudo mv $prefix "/tmp/go.back" -f
}

Write-Host "install golang to $prefix"
sudo mv "/tmp/go" $prefix -f

if ($LASTEXITCODE -ne 0) {
    exit 1
}

"export PATH=`$PATH:$prefix/bin ;# DOT NOT EDIT: installed by golang_profile.sh`nexport PATH=`$PATH:$HOME/go/bin ;# DOT NOT EDIT: installed by golang_profile.sh"|Out-File "/tmp/golang_profile.sh"

Write-Host "add $prefix/bin to `$PATH"
sudo mv "/tmp/golang_profile.sh" "/etc/profile.d" -f

$obj = @{}
$obj["version"] = $version
$obj["prefix"] = $prefix

ConvertTo-Json $obj |Out-File -Force -FilePath $toolslockfile