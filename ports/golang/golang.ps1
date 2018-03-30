#!/usr/bin/env pwsh
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
$Toolsdir = Split-Path $PSScriptRoot
Import-Module -Name "$Toolsdir/modules/Download"
Import-Module -Name "$Toolsdir/modules/Process"
Import-Module -Name "$Toolsdir/modules/Utils"



$toolslockfile = $PSScriptRoot + [System.IO.Path]::DirectorySeparatorChar + "config.lock.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json

$configfile = $PSScriptRoot + [System.IO.Path]::DirectorySeparatorChar + "config.json"
$mconfig = Get-Content $configfile -ErrorAction SilentlyContinue| ConvertFrom-Json

if ($toolslocked.golang -eq $mconfig.version) {
    exit 0
}