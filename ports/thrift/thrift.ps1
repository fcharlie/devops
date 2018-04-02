#!/usr/bin/env pwsh
# nodejs url: $url/v$version/node-v$version-linux-x64.tar.xz
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
$Toolsdir = Split-Path -Path (Split-Path $PSScriptRoot)
Import-Module -Name "$Toolsdir/modules/Download"
Import-Module -Name "$Toolsdir/modules/Process"
Import-Module -Name "$Toolsdir/modules/Utils"

# http://www-eu.apache.org/dist/thrift/0.11.0/thrift-0.11.0.tar.gz
# http://mirror.bit.edu.cn/apache/thrift/0.11.0/thrift-0.11.0.tar.gz

$toolslockfile = $Toolsdir + "/locks/thrift.lock.json"
$configfile = $PSScriptRoot + "/config.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json
$mconfig = Get-Content $configfile -ErrorAction SilentlyContinue| ConvertFrom-Json

if ($toolslocked.version -eq $mconfig.version) {
    Write-Host "thrift $($toolslocked.version) already install"
    exit 0
}

$besturl = Test-BestSourcesURL -Urls $mconfig.sources
if ($besturl -eq $null) {
    Write-Host -ForegroundColor Red "Bad sources config, please set it."
    exit 1
}
$version = $mconfig.version
$prefix = $mconfig.prefix
$thriftfile = "thrift-$version"
$thrifturl = "$besturl/$version/$thriftfile.tar.gz"

if ((DownloadFile -Url $thrifturl -Destination "/tmp/$thriftfile.tar.gz") -eq $false) {
    Write-Host -ForegroundColor Red "download $thrifturl failed"
    exit 1
}

if ((ProcessExec -FilePath "tar" -Arguments "-xvf  $thriftfile.tar.gz" -Dir "/tmp") -ne 0) {
    Write-Host -ForegroundColor Red "untar /tmp/$thriftfile.tar.gz failed"
    exit 1
}
$dir = Get-Location 
Set-Location "/tmp/$thriftfile"
mkdir "out"
Set-Location "out"
cmake "-DCMAKE_BUILD_TYPE=Release" "-DCMAKE_INSTALL_PREFIX=$prefix" ..
if ($LASTEXITCODE -ne 0) {
    Set-Location $dir
    exit 1
}
make
if ($LASTEXITCODE -ne 0) {
    Set-Location $dir
    exit 1
}

if ($prefix.StartsWith("/usr")) {
    sudo make install
}
else {
    make install
}

Set-Location $dir

$obj = @{}
$obj["version"] = $version
$obj["prefix"] = $prefix

ConvertTo-Json $obj |Out-File -Force -FilePath $toolslockfile

