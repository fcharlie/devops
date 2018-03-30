#!/usr/bin/env pwsh
## devops.ps1 list
## devops.ps1 version
## devops.ps1 install golang


Function DevopsList {
    param(
        [String]$Devroot
    )
    Write-Host -ForegroundColor Green "devops tools, found ports:"
    Get-ChildItem -Path "$Devroot/ports" |ForEach-Object {
        $cj = Get-Content "$($_.FullName)/config.json" |ConvertFrom-Json
        $version = $cj.version
        Write-Host "$($_.BaseName)`t$version`t$($cj.description)"
    }
}

DevopsList -Devroot $PSScriptRoot