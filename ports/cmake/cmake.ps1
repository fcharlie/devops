#!/usr/bin/env pwsh

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
$Toolsdir = Split-Path -Path (Split-Path $PSScriptRoot)
Import-Module -Name "$Toolsdir/modules/Download"
Import-Module -Name "$Toolsdir/modules/Process"
Import-Module -Name "$Toolsdir/modules/Utils"

$toolslockfile = $Toolsdir + "/locks/cmake.lock.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json
$configfile = $PSScriptRoot + "/config.json"
$mconfig = Get-Content $configfile -ErrorAction SilentlyContinue| ConvertFrom-Json

if ($toolslocked.version -eq $mconfig.version) {
    Write-Host "cmake $($toolslocked.version) already install, if not install, please remove cmake.lock.json"
    exit 0
}

$version = $mconfig.version
#https://github.com/Kitware/CMake/releases/download/v3.13.0/cmake-3.13.0-Linux-x86_64.tar.gz
$filename = "cmake-$version-Linux-x86_64"
$cmakeurl = "$($mconfig.sources)/v$version/$filename.tar.gz"

if ((DownloadFile -Url $cmakeurl -Destination "/tmp/$filename.tar.gz") -eq $false) {
    Write-Host -ForegroundColor Red "download $cmakeurl failed"
    exit 1
}

$prefix = $mconfig.prefix
$destdir = "/tmp/$filename"
if ((ProcessExec -FilePath "tar" -Arguments "-xvf  $filename.tar.gz" -Dir "/tmp") -ne 0) {
    Write-Host -ForegroundColor Red "untar /tmp/$filename.tar.gz failed"
    exit 1
}

try {
    Write-Host -ForegroundColor Green "install to $prefix"
    if ((Test-Path $prefix)) {
        Remove-Item -Fo  -Recurse $prefix
    }
    Move-Item -Force -Path $destdir -Destination $prefix
}
catch {
    Write-Host -ForegroundColor Red "move item failed: $_"
    exit 1
}

$lnfiles = "cmake", "cmake-gui", "cpack", "ccmake", "ctest"

foreach ($f in $lnfiles) {
    $xpath = "/usr/local/bin/$f"
    if (Test-Path $xpath) {
        sudo rm $xpath
    }
    sudo ln -s "$prefix/bin/$f" $xpath
}

$obj = @{}
$obj["version"] = $version
$obj["prefix"] = $prefix

ConvertTo-Json $obj |Out-File -Force -FilePath $toolslockfile