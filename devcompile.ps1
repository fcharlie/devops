#!/usr/bin/env pwsh

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
$InternalUA = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
$toolslockfile = $PSScriptRoot + [System.IO.Path]::DirectorySeparatorChar + "devcompile.lock.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json
$newlocked = @{}

$git_version = "2.16.2"


# Download file from web
Function Get-WebFile {
    param(
        [String]$Uri,
        [String]$Path
    )
    Write-Host "Download URL: $Uri"
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $Path -UserAgent $InternalUA -UseBasicParsing
    }
    catch {
        Write-Host -ForegroundColor Red "Download error: $_"
        return $false
    }
    return $true
}

#$BaseLocation=Get-Location

## compile git
if ($toolslocked.git -ne $git_version) {
    # Download cmake and install.
    $giturl = "https://github.com/git/git/archive/v$git_version.tar.gz"
    if (Get-WebFile -Uri $giturl -Path "/tmp/git-$git_version.tar.gz") {
        $tarproc = Start-Process -FilePath "tar" -ArgumentList "-xvf /tmp/git-$git_version.tar.gz" -WorkingDirectory "/tmp" -NoNewWindow -Wait -PassThru
    }
}
if ($newlocked["git"] -eq $null) {
    $newlocked["git"] = $toolslocked.git
}