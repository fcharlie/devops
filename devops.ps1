#!/usr/bin/env pwsh
## devops.ps1 list
## devops.ps1 version
## devops.ps1 install golang
## devops.ps1

Function PrintUsage {
    Write-Host "Devops utilies 1.0
Usage: devops cmd args
       list        list installed tools/libs
       search      search ported tools/libs
       install     install tools or libs
       upgrade     upgrade tools/libs
       version     print devops version and exit
       config      config your secure repository
       help        print help message
"
}

# list
Function DevopsList {
    param(
        [String]$Devroot
    )
    if (!(Test-Path $Devroot)) {
        Write-Host "devops: no tools installed."
        return
    }
    Write-Host -ForegroundColor Green "devops tools, found installed tools:"
    Get-ChildItem -Path "$Devroot/locks/*.lock.json" | ForEach-Object {
        $cj = Get-Content $_.FullName | ConvertFrom-Json
        $version = $cj.version
        $name = $_.BaseName.Split(".lock")[0]
        Write-Host "$name`t$version`t$($cj.prefix)"
    }
}

# search
Function DevopsSearch {
    param(
        [String]$Devroot
    )
    Write-Host -ForegroundColor Green "devops tools, found ports:"
    Get-ChildItem -Path "$Devroot/ports" | ForEach-Object {
        $cj = Get-Content "$($_.FullName)/config.json" | ConvertFrom-Json
        $version = $cj.version
        Write-Host "$($_.BaseName)`t$version`t$($cj.description)"
    }
}

if ($args.Count -eq 0) {
    PrintUsage
    exit 0
}

$subcmd = $args[0]

switch ($subcmd) {
    "list" {
        DevopsList -Devroot $PSScriptRoot
    }
    "search" {
        DevopsSearch -Devroot $PSScriptRoot
    }
    "install" {
        if ($args.Count -lt 2) {
            Write-Host -ForegroundColor Red "devops install missing argument, example: devops install golang"
            exit 1
        }
        $portx = $args[1]
        $portfile = $PSScriptRoot + "/ports/$portx/$portx.ps1"
        if (!(Test-Path $portfile)) {
            Write-Host -ForegroundColor Red -NoNewline "$portx "
            Write-Host "has not been ported to devops,
You can add your favorite tools to devops!"
            exit 1
        }
        &$portfile
        exit $LASTEXITCODE
    }
    "upgrade" {
        &"$PSScriptRoot/tools/upgrade.ps1"
        exit $LASTEXITCODE
    }
    "version" {
        Write-Host "devops: 1.0"
    }
    "help" {
        PrintUsage
        exit 0
    }
    "--help" {
        PrintUsage
        exit 0
    }
    Default {
        Write-Host -ForegroundColor Red "unsupported command '$xcmd' your can run devops help -a"
        exit 1
    }
}