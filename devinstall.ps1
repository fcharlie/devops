#!/usr/bin/env pwsh

$toolslockfile = $PSScriptRoot + [System.IO.Path]::DirectorySeparatorChar + "devinstall.lock.json"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
$InternalUA = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome

Function DownloadFile {
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

$toolslocked = Get-Content $toolslockfile| ConvertFrom-Json
$newlocked = @{}
$cmake_major = 3
$cmake_minor = 11
$cmake_patchver = 2
$cmake_version = "$cmake_major.$cmake_minor.$cmake_patchver"

if ($toolslocked.cmake -ne $cmake_version) {
    # Download cmake and install.
    $cmakeurl = "https://cmake.org/files/v$cmake_major.$cmake_minor/cmake-$cmake_major.$cmake_minor.$cmake_pathver-Linux-x86_64.sh"
    if (DownloadFile -Uri $cmakeurl -Path "/tmp/cmake.sh") {
        chmod +x "/tmp/cmake.sh"
        sudo "/tmp/cmake.sh" --prefix=/usr/local --skip-license
        $newlocked["cmake"] = $cmake_version
    }
}
if ($newlocked["cmake"] -eq $null) {
    $newlocked["cmake"] = $toolslocked.cmake
}

ConvertTo-Json $newlocked |Out-File -Force -FilePath $toolslockfile