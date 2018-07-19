#!/usr/bin/env pwsh
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
$Toolsdir = Split-Path -Path (Split-Path $PSScriptRoot)
Import-Module -Name "$Toolsdir/modules/Download"
Import-Module -Name "$Toolsdir/modules/Process"
Import-Module -Name "$Toolsdir/modules/Utils"

$toolslockfile = $Toolsdir + "/locks/golang.lock.json"
$configfile = $PSScriptRoot + "/config.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json
$mconfig = Get-Content $configfile -ErrorAction SilentlyContinue| ConvertFrom-Json

if ($toolslocked.version -eq $mconfig.version) {
    Write-Host "golang $($toolslocked.version) already install"
    exit 0
}

$besturl = Test-BestSourcesURL -Urls $mconfig.sources
if ($null -eq $besturl) {
    Write-Host -ForegroundColor Red "Bad sources config, please set it."
    exit 1
}
$version = $mconfig.version
$prefix = $mconfig.prefix
$gofilename = "go${version}.linux-amd64";
$gourl = "$besturl/$gofilename.tar.gz"

if ((DownloadFile -Url $gourl -Destination "/tmp/$gofilename.tar.gz") -eq $false) {
    Write-Host -ForegroundColor Red "download $gourl failed"
    exit 1
}

if ((ProcessExec -FilePath "tar" -Arguments "-xvf  $gofilename.tar.gz" -Dir "/tmp") -ne 0) {
    Write-Host -ForegroundColor Red "untar /tmp/$gofilename.tar.gz failed"
    exit 1
}

if (Test-Path -Path $prefix) {
    sudo rm "/tmp/go.back" -rf
    Write-Host -ForegroundColor Yellow "move old go to /tmp"
    sudo mv $prefix "/tmp/go.back"
}

Write-Host -ForegroundColor Green "install golang to $prefix"

$requiredsudo = $prefix.StartsWith("/usr/")

if ($requiredsudo) {
    sudo mv "/tmp/go" $prefix
}
else {
    mv "/tmp/go" $prefix
}

if ($LASTEXITCODE -ne 0) {
    exit 1
}


if ($prefix -ne "/usr/local" -and $prefix -ne "/usr") {
    "export PATH=`$PATH:$prefix/bin ;# DOT NOT EDIT: installed by golang_profile.sh
export PATH=`$PATH:$HOME/go/bin ;# DOT NOT EDIT: installed by golang_profile.sh"|Out-File "/tmp/golang_profile.sh"
}
else {
    "export PATH=`$PATH:$HOME/go/bin ;# DOT NOT EDIT: installed by golang_profile.sh"|Out-File "/tmp/golang_profile.sh"
}
chmod +x "/tmp/golang_profile.sh"
Write-Host "add $prefix/bin to `$PATH"
sudo mv "/tmp/golang_profile.sh" "/etc/profile.d" -f

$obj = @{}
$obj["version"] = $version
$obj["prefix"] = $prefix

ConvertTo-Json $obj |Out-File -Force -FilePath $toolslockfile