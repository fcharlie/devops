#!/usr/bin/env pwsh

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Force use TLS 1.2
Import-Module -Name "${PSScriptRoot}/modules/Download"
Import-Module -Name "${PSScriptRoot}/modules/Process"

$toolslockfile = $PSScriptRoot + "/locks/devcompile.lock.json"
$configfile = $PSScriptRoot + "/config.json"
$toolslocked = Get-Content $toolslockfile -ErrorAction SilentlyContinue| ConvertFrom-Json
$mconfig = Get-Content $configfile -ErrorAction SilentlyContinue| ConvertFrom-Json
$newlocked = @{}

$git_version = "2.16.3"
$boost_major = 1
$boost_minor = 66
$boost_patchver = 0
$boost_version = "$boost_major.$boost_minor.$boost_patchver"
$boost_name = "boost_$boost_major`_$boost_minor`_$boost_patchver"

#$BaseLocation=Get-Location

# compile git
Function DevcompileGIT {
    param(
        [String]$Version
    )
    $giturl = "https://github.com/git/git/archive/v$git_version.tar.gz"
    if ((DownloadFile -Url $giturl -Destination "/tmp/git-$git_version.tar.gz") -eq $false) {
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

Function DevcompileBoost {
    param(
        [String]$Version,
        [String]$Name,
        [String]$Devhome,
        [String]$Prefix,
        [ValidateSet("static", "shared")]
        [String]$Linked # only shared or static
    )
    $destdir = $Devhome + [System.IO.Path]::DirectorySeparatorChar + $Name
    $boostfile = $destdir + ".tar.gz"
    $boosturl = "https://dl.bintray.com/boostorg/release/$Version/source/$Name.tar.gz"
    if ((DownloadFile -Url $boosturl -Destination $boostfile) -eq $false) {
        return $false
    }
    if ((ProcessExec -FilePath "tar" -Arguments "-xvf  $Name.tar.gz" -Dir $Devhome) -ne 0) {
        return $false
    }
    if ((ProcessExec -FilePath "$destdir/bootstrap.sh" -Dir $destdir) -ne 0) {
        return $false
    }
    $b2cmdline = "--prefix=`"$Prefix`""
    if ($Linked -eq "static") {
        $b2cmdline += " cxxflags=`"-fPIC`" link=static"
    }
    $b2cmdline += " install"
    if ((ProcessExec -FilePath "$destdir/b2" -Arguments $b2cmdline -Dir $destdir) -ne 0) {
        return $false
    }
    return $true
}

### Try to compile git
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

### Try to compile boost
if ($toolslocked.boost -ne $boost_version) {
    $boost_prefix = "/opt/boost"
    $devhome = "/tmp"
    $boost_linked = "static"
    if ($mconfig.boost.prefix -ne $null) {
        $boost_prefix = $mconfig.boost.prefix
    }
    if ($mconfig.boost.devhome -ne $null) {
        $devhome = $mconfig.boost.devhome
    }
    if ($mconfig.boost.linked -ne $null) {
        $boost_linked = $mconfig.boost.linked
    }
    if (!(Test-Path $devhome)) {
        New-Item -ItemType Directory -Force $devhome -ErrorAction Stop
    }
    $devhome = (Get-Item -Path $devhome -ErrorAction SilentlyContinue ).FullName
    $ret = DevcompileBoost -Version $boost_version -Name $boost_name -Prefix $boost_prefix -Devhome $devhome -Linked $boost_linked
    if ($ret) {
        $newlocked["boost"] = $boost_version
    }

}
else {
    Write-Host -ForegroundColor Green "boost: $boost_version already installed"
}

if ($newlocked["boost"] -eq $null) {
    $newlocked["boost"] = $toolslocked.boost
}



ConvertTo-Json $newlocked |Out-File -Force -FilePath $toolslockfile