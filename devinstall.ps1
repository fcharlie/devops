#!/usr/bin/env pwsh

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
Import-Module -Name "${PSScriptRoot}/modules/Download"
$toolslockfile = $PSScriptRoot + [System.IO.Path]::DirectorySeparatorChar + "devinstall.lock.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json
$newlocked = @{}

### CMAKE VERSION
$cmake_major = 3
$cmake_minor = 11
$cmake_patchver = 0
$cmake_version = "$cmake_major.$cmake_minor.$cmake_patchver"

### Other version here


# Install cmake

if ($toolslocked.cmake -ne $cmake_version) {
    # Download cmake and install.
    $cmakeurl = "https://cmake.org/files/v$cmake_major.$cmake_minor/cmake-$cmake_major.$cmake_minor.$cmake_patchver-Linux-x86_64.sh"
    if (DownloadFile -Url $cmakeurl -Destination "/tmp/cmake.sh") {
        chmod +x "/tmp/cmake.sh"
        sudo "/tmp/cmake.sh" --prefix=/usr/local --skip-license
        $newlocked["cmake"] = $cmake_version
    }
}
if ($newlocked["cmake"] -eq $null) {
    $newlocked["cmake"] = $toolslocked.cmake
}

# Install other...

ConvertTo-Json $newlocked |Out-File -Force -FilePath $toolslockfile