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
            $tcpclient.EndConnect($tcpConnection) | out-Null
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
    if ($Urls.Count -eq 0) {
        Write-Host -ForegroundColor Red "Test-BestWebConnection input urls empty"
    }
    [System.String]$besturl = $null;
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
