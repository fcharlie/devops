#!/usr/bin/env pwsh
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


Function Test-BestSourcesURL {
    param(
        [String[]]$Urls
    )
    [System.String]$besturl = $null;
    [System.Double]$pretime = [System.Double]::MaxValue
    [int]$index = 0
    for ($i = 0; $i -lt $Urls.Count; $i++) {
        $u = $Urls[$i]
        $xuri = [uri]$u
        $resptime = TestTcpConnection -ServerName $xuri.Host -Port $xuri.Port
        Write-Host "$u response time: $resptime ms"
        if ($pretime -gt $resptime) {
            $index = $i
            $pretime = $resptime
        }
    }
    return $Urls[$index]
}

$urls = "https://storage.googleapis.com/golang", "https://studygolang.com/dl/golang"
$burl = Test-BestSourcesURL -Urls $urls

if ($burl -ne $null) {
    Write-Host -ForegroundColor Green "Best URL: $burl"
}