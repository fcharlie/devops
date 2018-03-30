#!/usr/bin/env pwsh

$Devroot = Split-Path $PSScriptRoot
Import-Module -Name "$Devroot/modules/Download"
Import-Module -Name "$Devroot/modules/Process"
Import-Module -Name "$Devroot/modules/Utils"


Function TryUpgradePorts {
    param(
        [String]$Name,
        [String]$Root,
        [String]$Version
    )
    $cjson = Get-Content "$Devroot/ports/$Name/config.json" -ErrorAction SilentlyContinue|ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($cjson -eq $null) {
        Write-Host "Invalid port: $Name."
        return -1
    }
    if ($cjson.version -eq $Version) {
        return -1
    }
    Write-Host "try to upgrade $Name to $($cjson.version)"
    &"$Root/ports/$Name/$Name.ps1"
    if ($LASTEXITCODE -eq 0) {
        Write-Host -ForegroundColor  Green "upgrade: $Name success."
        return 0
    }
    else {
        Write-Host -ForegroundColor  Red "upgrade: $Name failed."
        return 1
    }
}

[int]$success = 0
[int]$total = 0
Get-ChildItem -Path "$Devroot/locks/*.lock.json" |ForEach-Object {

    $cj = Get-Content $_.FullName |ConvertFrom-Json
    $version = $cj.version
    $name = $_.BaseName.Split(".lock")[0]
    $ret = TryUpgradePorts -Name $name -Root $Devroot -Version $version
    if ($ret -eq 1) {
        $total++
    }
    elseif ($ret -eq 0) {
        $total++
        $success++
    }
}

Write-Host "devops: upgrade tools/libs, success $success/$total"