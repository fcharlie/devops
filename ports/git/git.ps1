#!/usr/bin/env pwsh
# install git to your location

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
$Toolsdir = Split-Path -Path (Split-Path $PSScriptRoot)
Import-Module -Name "$Toolsdir/modules/Base"

$toolslockfile = $Toolsdir + "/locks/git.lock.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue | ConvertFrom-Json
$configfile = $PSScriptRoot + "/config.json"
$mconfig = Get-Content $configfile -ErrorAction SilentlyContinue | ConvertFrom-Json

if ($toolslocked.version -eq $mconfig.version) {
    Write-Host "git $($toolslocked.version) already install, if not install, please remove git.lock.json"
    exit 0
}

$version = $mconfig.version
$prefix = $mconfig.prefix
#git-2.26.0.tar.xz
$gitfile = "git-$version.tar.xz"
$giturl = "$($mconfig.sources)/$gitfile"

if ((WinGet -Url $giturl -Destination "/tmp/$gitfile") -eq $false) {
    Write-Host -ForegroundColor Red "download git $giturl failed"
    exit 1
}
$gitsrcdir = "/tmp/git-$version"
if ((ProcessExec -FilePath "tar" -Argv "-xvf  $gitfile" -WD "/tmp") -ne 0) {
    Write-Host -ForegroundColor Red "untar /tmp/$gitfile failed"
    exit 1
}
if ((ProcessExec -FilePath "make" -Argv "configure" -WD $gitsrcdir) -ne 0) {
    Write-Host -ForegroundColor Red "make configure failed"
    exit 1
}
if ((ProcessExec -FilePath "/tmp/git-$version/configure" -Argv "--prefix=$($mconfig.prefix)" -WD $gitsrcdir) -ne 0) {
    Write-Host -ForegroundColor Red "make configure failed"
    exit 1
}
if ((ProcessExec -FilePath "make"  -WD $gitsrcdir) -ne 0) {
    Write-Host -ForegroundColor Red "make failed"
    exit 1
}

if ("/usr/local" -eq $prefix -or "/usr" -eq $prefix) {
    sudo make -C $gitsrcdir install
}
else {
    make -C $gitsrcdir install
    "export PATH=`$PATH:$prefix/bin ;# DOT NOT EDIT: installed by git_profile.sh" | Out-File "/tmp/git_profile.sh"
    sudo mv "/tmp/git_profile.sh" "/etc/profile.d" -f
}

if ($LASTEXITCODE -ne 0) {
    Write-Host -ForegroundColor Red "make install failed"
    exit 1
}

$obj = @{ }
$obj["version"] = $version
$obj["prefix"] = $prefix

ConvertTo-Json $obj | Out-File -Force -FilePath $toolslockfile