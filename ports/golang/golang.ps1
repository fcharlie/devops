#!/usr/bin/env pwsh

$Toolsdir = Split-Path $PSScriptRoot
Import-Module -Name "$Toolsdir\modules\Download"
Import-Module -Name "$Toolsdir\modules\Process"

$toolslockfile = $PSScriptRoot + [System.IO.Path]::DirectorySeparatorChar + "config.lock.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json

$configfile = $PSScriptRoot + [System.IO.Path]::DirectorySeparatorChar + "config.json"
$mconfig = Get-Content $configfile -ErrorAction SilentlyContinue| ConvertFrom-Json

if ($toolslocked.golang -eq $mconfig.version) {
    exit 0
}