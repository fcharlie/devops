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
$va = $version.Split(".")
#https://cmake.org/files/v3.11/cmake-3.11.0-Linux-x86_64.sh
$filename = "cmake-$version-Linux-x86_64.sh"
$cmakeurl = "$($mconfig.sources)/v$($va[0]).$($va[1])/$filename"

if ((DownloadFile -Url $cmakeurl -Destination "/tmp/$filename") -eq $false) {
    Write-Host -ForegroundColor Red "download $cmakeurl failed"
    exit 1
}
# cmake_profile.sh
chmod +x "/tmp/$filename"


if ($prefix -ne "/usr/local" -and $prefix -ne "/usr") {
    &"/tmp/$filename" "--prefix=$prefix" --skip-license
    "export PATH=`$PATH:$prefix/bin ;# DOT NOT EDIT: installed by cmake_profile.sh"|Out-File "/tmp/cmake_profile.sh"
    chmod +x "/tmp/cmake_profile.sh"
    sudo mv "/tmp/cmake_profile.sh" "/etc/profile.d" -f
}
else {
    sudo "/tmp/$filename" "--prefix=$prefix" --skip-license
}


$obj = @{}
$obj["version"] = $version
$obj["prefix"] = $prefix

ConvertTo-Json $obj |Out-File -Force -FilePath $toolslockfile