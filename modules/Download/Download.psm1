# PowerShell module

Function Test-Command {
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Enter Command Name")]
        [ValidateNotNullorEmpty()]
        [String]$ExeName
    )
    $myErr = @()
    Get-Command -CommandType Application $ExeName -ErrorAction SilentlyContinue -ErrorVariable +myErr
    if ($myErr.count -eq 0) {
        return $True
    }
    return $False
}


Function DownloadFile {
    param(
        [String]$Url,
        [String]$Destination,
        [Switch]$Force
    )
    if (Test-Path $Destination) {
        Write-Host "Found $Destination, use download cache"
        return $true
    }
    if (Test-Command "wget") {
        wget "--user-agent=$UA" $Url -O $Destination
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        Remove-Item -Force $Destination -ErrorAction SilentlyContinue | Out-Null ### When wget download failed, remove self
        return $false
    }
    try {
        $UA = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
        Invoke-WebRequest -Uri $Uri -OutFile $Destination -UserAgent $UA  -UseBasicParsing
    }
    catch {
        Write-Host -ForegroundColor Red "Download error: $_"
        return $false
    }
    return $true
}