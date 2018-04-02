#!/usr/bin/env pwsh
# nodejs url: $url/v$version/node-v$version-linux-x64.tar.xz
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
$Toolsdir = Split-Path -Path (Split-Path $PSScriptRoot)
Import-Module -Name "$Toolsdir/modules/Download"
Import-Module -Name "$Toolsdir/modules/Process"
Import-Module -Name "$Toolsdir/modules/Utils"

$toolslockfile = $Toolsdir + "/locks/nodejs.lock.json"
$configfile = $PSScriptRoot + "/config.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json
$mconfig = Get-Content $configfile -ErrorAction SilentlyContinue| ConvertFrom-Json

if ($toolslocked.version -eq $mconfig.version) {
    Write-Host "nodejs $($toolslocked.version) already install"
    exit 0
}

$besturl = Test-BestSourcesURL -Urls $mconfig.sources
if ($besturl -eq $null) {
    Write-Host -ForegroundColor Red "Bad sources config, please set it."
    exit 1
}
$version = $mconfig.version
$prefix = $mconfig.prefix
$nodejsfile = "node-v$version-linux-x64"
$nodejsurl = "$besturl/v$version/$nodejsfile.tar.xz"

if ((DownloadFile -Url $nodejsurl -Destination "/tmp/$nodejsfile.tar.gz") -eq $false) {
    Write-Host -ForegroundColor Red "download $nodejsurl failed"
    exit 1
}

if ((ProcessExec -FilePath "tar" -Arguments "-xvf  $nodejsfile.tar.gz" -Dir "/tmp") -ne 0) {
    Write-Host -ForegroundColor Red "untar /tmp/$nodejsfile.tar.gz failed"
    exit 1
}


if (Test-Path -Path $prefix) {
    sudo rm "/tmp/nodejs.back" -rf
    Write-Host -ForegroundColor Yellow "move old nodejs to /tmp"
    sudo mv $prefix "/tmp/nodejs.back" 
}

Write-Host -ForegroundColor Green "install nodejs to $prefix"
$requiredsudo = $prefix.StartsWith("/usr/")

if ($requiredsudo) {
    sudo mv "/tmp/$nodejsfile" $prefix 
}
else {
    mv "/tmp/$nodejsfile" $prefix 
}

if ($LASTEXITCODE -ne 0) {
    exit 1
}
if ($prefix -ne "/usr/local" -and $prefix -ne "/usr") {
    "export PATH=`$PATH:$prefix/bin ;# DOT NOT EDIT: installed by nodejs_profile.sh"|Out-File "/tmp/nodejs_profile.sh"
    Write-Host "add $prefix/bin to `$PATH"
    chmod +x "/tmp/nodejs_profile.sh"
    sudo mv "/tmp/nodejs_profile.sh" "/etc/profile.d" -f
}

$obj = @{}
$obj["version"] = $version
$obj["prefix"] = $prefix

ConvertTo-Json $obj |Out-File -Force -FilePath $toolslockfile