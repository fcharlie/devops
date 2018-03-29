#!/usr/bin/env pwsh

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
Import-Module -Name "${PSScriptRoot}\modules\WGet"
$toolslockfile = $PSScriptRoot + [System.IO.Path]::DirectorySeparatorChar + "devcompile.lock.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json
$newlocked = @{}

$git_version = "2.16.3"


Function ProcessExec {
    param(
        [string]$FilePath,
        [string]$Arguments,
        [string]$Dir
    )
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo 
    $ProcessInfo.FileName = $FilePath
    if ($Dir.Length -eq 0) {
        $ProcessInfo.WorkingDirectory = $PWD
    }
    else {
        $ProcessInfo.WorkingDirectory = $Dir
    }
    $ProcessInfo.Arguments = $Arguments
    $ProcessInfo.UseShellExecute = $false ## use createprocess not shellexecute
    $Process = New-Object System.Diagnostics.Process 
    $Process.StartInfo = $ProcessInfo 
    if ($Process.Start() -eq $false) {
        return -1
    }
    $Process.WaitForExit()
    return $Process.ExitCode
}
#$BaseLocation=Get-Location

# compile git
Function DevcompileGIT {
    param(
        [String]$Version
    )
    $giturl = "https://github.com/git/git/archive/v$git_version.tar.gz"
    if ((Get-WebFile -Url $giturl -Destination "/tmp/git-$git_version.tar.gz") -eq $false) {
        return $false
    }
    $gitsrcdir = "/tmp/git-$git_version"

    if ((ProcessExec -FilePath "tar" -Arguments "-xvf  git-$git_version.tar.gz" -Dir "/tmp") -ne 0) {
        return $false
    }
    if ((ProcessExec -FilePath "make" -Arguments "configure" -Dir $gitsrcdir) -ne 0) {
        return $false
    }
    if ((ProcessExec -FilePath "sh" -Arguments "-c `"./configure --prefix=/usr/local`"" -Dir $gitsrcdir) -ne 0) {
        return $false
    }
    if ((ProcessExec -FilePath "make"  -Dir $gitsrcdir) -ne 0) {
        return $false
    }
    if ((ProcessExec -FilePath "sudo" -Arguments "make install" -Dir $gitsrcdir) -ne 0) {
        return $false
    }
    return $true
}

if ($toolslocked.git -ne $git_version) {
    if (DevcompileGIT -Version $git_version) {
        $newlocked["git"] = $git_version
    }
}
else {
    Write-Host -ForegroundColor Green "git: $git_version already installed"
}

if ($newlocked["git"] -eq $null) {
    $newlocked["git"] = $toolslocked.git
}


ConvertTo-Json $newlocked |Out-File -Force -FilePath $toolslockfile