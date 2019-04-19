#!/usr/bin/env pwsh

$Devroot = Split-Path $PSScriptRoot
Import-Module -Name "$Devroot/modules/Download"
Import-Module -Name "$Devroot/modules/Process"
Import-Module -Name "$Devroot/modules/Utils"

[int]$success = 0
[int]$total = 0
Get-ChildItem -Path "$Devroot/locks/*.lock.json" | ForEach-Object {
    $lkv = Get-Content $_.FullName | ConvertFrom-Json
    $version = $lkv.version
    $name = $_.BaseName.Split(".lock")[0]
    $njson = Get-Content "$Devroot/ports/$Name/config.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($njson -eq $null -or $njson.version -eq $null) {
        Write-Host "Invalid port: $Name."
        return
    }
    if ($njson.version -eq $version) {
        #Write-Host "$name is already up to date"
        return
    }
    $total++
    &"$Devroot/ports/$name/$name.ps1"
    if ($LASTEXITCODE -eq 0) {
        Write-Host -ForegroundColor  Green "devops: upgrade $name success."
        $success++
    }
    else {
        Write-Host -ForegroundColor  Red "devops: upgrade $name failed."
    }
}

Write-Host "devops: upgrade tools/libs, success $success/$total"