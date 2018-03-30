#!/usr/bin/env pwsh
function TestTcpConnection {
    Param(
        [string]$ServerName,
        $Port = 80,
        $Timeout = 3000,
        $Count = 0,
        $WaitFor = 1000
    )

    $Error.Clear()
    $response = [pscustomobject]@{Timestamp = $(Get-Date); Timeout = $false; Success = $true; ResponseTimeInMilliseconds = $null}
    $response.Timeout = $false
    $response.Success = $true
    $tcpclient = New-Object system.Net.Sockets.TcpClient
    $stopwatch = New-Object System.Diagnostics.Stopwatch
    $stopwatch.Start()
    $tcpConnection = $tcpclient.BeginConnect($ServerName, $Port, $null, $null)
    $ConnectionSucceeded = $tcpConnection.AsyncWaitHandle.WaitOne($Timeout, $false)
    $stopwatch.Stop()
    $response.ResponseTimeInMilliseconds = $stopwatch.Elapsed.TotalMilliseconds
    if (!$ConnectionSucceeded) {
        $tcpclient.Close()
        $response.Timeout = $true
        $response.Success = $false
        $response.Timestamp = $(Get-Date)
    }
    else {
        $tcpclient.EndConnect($tcpConnection) | out-Null
        $tcpclient.Close()
        $response.Timestamp = $(Get-Date)
    }
    If ($Error) {
        Return
    }
    Return $response
}

TestTcpConnection -ServerName "bing.com" -Port 443

