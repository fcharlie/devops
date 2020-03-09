# PowerShell module

# On Windows, Start-Process -Wait will wait job process, obObject.WaitOne(_waithandle);
# Don't use it
Function ProcessExec {
    param(
        [string]$FilePath,
        [string]$Argv,
        [string]$WD
    )
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $FilePath
    if ([String]::IsNullOrEmpty($WD)) {
        $ProcessInfo.WorkingDirectory = $PWD
    }
    else {
        $ProcessInfo.WorkingDirectory = $WD
    }
    Write-Host "$FilePath $Argv [$($ProcessInfo.WorkingDirectory)]"
    #0x00000000 WindowStyle
    $ProcessInfo.Arguments = $Argv
    $ProcessInfo.UseShellExecute = $false ## use createprocess not shellexecute
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessInfo
    if ($Process.Start() -eq $false) {
        return -1
    }
    $Process.WaitForExit()
    return $Process.ExitCode
}


Function WinGet {
    param(
        [String]$URL,
        [String]$Destination
    )
    $wgetSet = Get-Command -CommandType Application wget -ErrorAction SilentlyContinue
    if ($null -ne $wgetSet) {
        $wgetExe = $wgetSet[0].Source
        $wgetArgv = "`"--user-agent=$UA`" `"$Url`" -O `"$Destination`""
        Write-Host "devdownload (wget-devi): $URL"
        $ex = ProcessExec -FilePath $wgetExe -Argv $wgetArgv -WD $PWD
        if ($ex -ne 0) {
            Remove-Item -Force $Destination -ErrorAction SilentlyContinue
            return $false
        }
        return $true
    }
    $curlSet = Get-Command -CommandType Application curl -ErrorAction SilentlyContinue
    if ($null -ne $curlSet) {
        $TlsArg = "--proto-redir =https"
        if (!$URL.StartsWith("https://")) {
            $TlsArg = ""
        }
        $curlExe = $curlSet[0].Source
        $curlargv = "-A `"$deviUA`" --progress-bar -fS --connect-timeout 15 --retry 3 -o `"$Destination`" -L $TlsArg $URL"
        Write-Host "devdownload (curl-devi): $URL"
        $ex = ProcessExec -FilePath $curlExe -Argv $curlargv -WD $PWD
        if ($ex -ne 0) {
            Remove-Item -Force $Destination -ErrorAction SilentlyContinue
            return $false
        }
        return $true
    }
    Write-Host "devdownload (pwsh wget): $URL ..."
    #$xuri = [uri]$Uri
    try {
        Remove-Item -Force $Destination -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $URL -OutFile $Destination -UserAgent $deviUA -UseBasicParsing
    }
    catch {
        Write-Host -ForegroundColor Red "download failed: $_"
        Remove-Item -Force $Destination -ErrorAction SilentlyContinue
        return $false
    }
    return $true
}

function TestTcpConnection {
    Param(
        [string]$ServerName,
        $Port = 80,
        $Count = 0,
        $WaitFor = 1000
    )
    try {
        $ResponseTime = [System.Double]::MaxValue
        $tcpclient = New-Object system.Net.Sockets.TcpClient
        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $tcpConnection = $tcpclient.BeginConnect($ServerName, $Port, $null, $null)
        $ConnectionSucceeded = $tcpConnection.AsyncWaitHandle.WaitOne(3000, $false)
        $stopwatch.Stop()
        $ResponseTime = $stopwatch.Elapsed.TotalMilliseconds
        if (!$ConnectionSucceeded) {
            $tcpclient.Close()
        }
        else {
            $tcpclient.EndConnect($tcpConnection) | Out-Null
            $tcpclient.Close()
        }
        return $ResponseTime
    }
    catch {
        return [System.Double]::MaxValue
    }
}

Function Test-UrlConnection {
    param(
        [String]$Url,
        [int]$Timeoutms = 3000
    )
    $xuri = [uri]$Url
    $resptime = TestTcpConnection -ServerName $xuri.Host -Port $xuri.Port
    $mt = [System.Convert]::ToInt32($resptime)
    if ($mt -gt $Timeoutms) {
        return $false
    }
    return $true
}


Function Test-BestSourcesURL {
    param(
        [String[]]$Urls
    )
    if ($Urls.Count -eq 0 -or $null -eq $Urls) {
        Write-Host -ForegroundColor Red "Test-BestWebConnection input urls empty"
        return $null
    }
    [System.Double]$pretime = [System.Double]::MaxValue
    [int]$index = 0
    for ($i = 0; $i -lt $Urls.Count; $i++) {
        $u = $Urls[$i]
        $xuri = [uri]$u
        $resptime = TestTcpConnection -ServerName $xuri.Host -Port $xuri.Port
        Write-Host "check url: $u response: $resptime ms"
        if ($pretime -gt $resptime) {
            $index = $i
            $pretime = $resptime
        }
    }
    return $Urls[$index]
}
