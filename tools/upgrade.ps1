#!/usr/bin/env pwsh

$Devroot = Split-Path $PSScriptRoot
Import-Module -Name "$Devroot/modules/Download"
Import-Module -Name "$Devroot/modules/Process"
Import-Module -Name "$Devroot/modules/Utils"

[int]$successed = 0
[int]$total = 0
Function TryUpgradePorts {
    param(
        [String]$Name,
        [String]$Root,
        [String]$Version
    )
    $cjson = Get-Content "$Devroot/ports/$Name/config.json" -ErrorAction SilentlyContinue|ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($cjson -eq $null) {
        Write-Host "Invalid port: $Name."
        return 
    }
    if ($cjson.version -eq $Version) {
        return 
    }
    $total++
    &"$Root/ports/$Name/$Name.ps1"
    if ($LASTEXITCODE -eq 0) {
        $successed++
        Write-Host -ForegroundColor  Green "upgrade: $Name success."
    }
    else {
        Write-Host -ForegroundColor  Red "upgrade: $Name failed."
    }
}


Get-ChildItem -Path "$Devroot/locks/*.lock.json" |ForEach-Object {

    $cj = Get-Content $_.FullName |ConvertFrom-Json
    $version = $cj.version
    $name = $_.BaseName.Split(".lock")[0]
    TryUpgradePorts -Name $name -Root $Devroot -Version $version
}

Write-Host "devops: upgrade tools/libs, success $successed/$total"