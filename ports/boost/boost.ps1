#!/usr/bin/env pwsh
# install boost to your location

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
$Toolsdir = Split-Path -Path (Split-Path $PSScriptRoot)
Import-Module -Name "$Toolsdir/modules/Download"
Import-Module -Name "$Toolsdir/modules/Process"
Import-Module -Name "$Toolsdir/modules/Utils"

$toolslockfile = $Toolsdir + "/locks/boost.lock.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue | ConvertFrom-Json
$configfile = $PSScriptRoot + "/config.json"
$mconfig = Get-Content $configfile -ErrorAction SilentlyContinue | ConvertFrom-Json

if ($toolslocked.version -eq $mconfig.version) {
    Write-Host "boost $($toolslocked.version) already install, if not install, please remove boost.lock.json"
    exit 0
}

$version = $mconfig.version
$va = $version.Split(".")
$prefix = $mconfig.prefix
$linked = $mconfig.linked
$filename = "boost_$($va[0])_$($va[1])_$($va[2])"
$boosturl = "$($mconfig.sources)/$version/source/$filename.tar.bz2"

if ((DownloadFile -Url $boosturl -Destination "/tmp/$filename.tar.bz2") -eq $false) {
    Write-Host -ForegroundColor Red "download git $boosturl failed"
    exit 1
}
$destdir = "/tmp/$filename"
if ((ProcessExec -FilePath "tar" -Arguments "-xvf  $filename.tar.bz2" -Dir "/tmp") -ne 0) {
    Write-Host -ForegroundColor Red "untar /tmp/$filename.tar.bz2 failed"
    exit 1
}
if ((ProcessExec -FilePath "$destdir/bootstrap.sh" -Dir $destdir) -ne 0) {
    Write-Host -ForegroundColor Red "bootstrap b2 failed"
    exit 1
}
$b2cmdline = "--prefix=`"$prefix`""
if ($linked -eq "static") {
    $b2cmdline += " cxxflags=`"-fPIC`" link=static"
}
$b2cmdline += " install"
if ((ProcessExec -FilePath "$destdir/b2" -Arguments $b2cmdline -Dir $destdir) -ne 0) {
    Write-Host -ForegroundColor Red "build boost failed"
    exit 1
}

$obj = @{ }
$obj["version"] = $version
$obj["prefix"] = $prefix

ConvertTo-Json $obj | Out-File -Force -FilePath $toolslockfile