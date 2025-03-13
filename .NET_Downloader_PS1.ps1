# Define switches (parameters) at the start of the script
param (
    # Specify whether to include the Windows Desktop Runtime
    [string]$windowsdesktop = "true",
    # Specify whether to include the ASP.NET Core Runtime
    [string]$aspnetcore_runtime = "false",
    # Specify whether to include the .NET Hosting Bundle
    [string]$dotnet_hosting = "false",
    # Specify whether to include the .NET Runtime
    [string]$dotnet_runtime = "false",
    # Specify whether to include the .NET SDK
    [string]$dotnet_sdk = "false",
    # Specify whether to include x86 architecture
    [string]$x86 = "true",
    # Specify whether to include x64 architecture
    [string]$x64 = "true",
    # Specify whether to include ARM64 architecture
    [string]$arm64 = "false",
    # Specify the download folder path
    [string]$DownloadTo = "(New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path",
    # Specify whether to include .NET 11.0 when will it be available. To add more versions consider check variable '$versionsToProcess' 
    [string]$11_0 = "false",
    # Specify whether to include .NET 10.0
    [string]$10_0 = "true",
    # Specify whether to include .NET 9.0
    [string]$9_0 = "true",
    # Specify whether to include .NET 8.0
    [string]$8_0 = "false",
    # Specify whether to include .NET 7.0
    [string]$7_0 = "true",
    # Specify whether to include .NET 6.0
    [string]$6_0 = "true",
    # Specify whether to include .NET 5.0
    [string]$5_0 = "false",
    # Specify whether to automatically install packages after downloading
    [string]$AutoInstall = "true",
    # Specify whether to download all packages first, then install them
    [string]$DownloadAllThenInstall = "true",
    # Specify whether to download one package, install it, then proceed to the next
    [string]$DownloadOneThenInstall = "false",
    # Specify whether to delete packages after installation
    [string]$DeleteAfterInstall = "false"
)

# Hide downloading progress
$ProgressPreference = 'SilentlyContinue'

# Parse the download folder path
$downloadsFolder = Invoke-Expression $DownloadTo

# Function to download a file with retries
function Download-WithRetry {
    param (
        [string]$Url,
        [string]$Destination,
        [int]$MaxRetries = 3
    )
    $retryCount = 0
    while ($retryCount -lt $MaxRetries) {
        try {
            # Attempt to download the file
            Write-Host "  Downloading: $(Split-Path -Leaf $Url)" -ForegroundColor Cyan
            Invoke-WebRequest -Uri $Url -OutFile $Destination -TimeoutSec 30
            return $true
        } catch {
            # Retry if the download fails
            Write-Host "  Failed to download $(Split-Path -Leaf $Url). Retrying... ($($retryCount + 1)/$MaxRetries)" -ForegroundColor Yellow
            $retryCount++
        }
    }
    # Exit with an error message if all retries fail
    Write-Host "  Failed to download $(Split-Path -Leaf $Url) after $MaxRetries attempts." -ForegroundColor Red
    return $false
}

# Main script logic
Write-Host "Starting .NET package installation process..." -ForegroundColor Green

# Build the list of versions to process
$versionsToProcess = @()
if ($11_0 -eq "true") { $versionsToProcess += "11.0" }
if ($10_0 -eq "true") { $versionsToProcess += "10.0" }
if ($9_0 -eq "true") { $versionsToProcess += "9.0" }
if ($8_0 -eq "true") { $versionsToProcess += "8.0" }
if ($7_0 -eq "true") { $versionsToProcess += "7.0" }
if ($6_0 -eq "true") { $versionsToProcess += "6.0" }
if ($5_0 -eq "true") { $versionsToProcess += "5.0" }

# Validate and fetch metadata for each version
$allDownloads = @()
foreach ($version in $versionsToProcess) {
    $url = "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/$version/releases.json"
    Write-Host "  Fetching metadata from: $url" -ForegroundColor Cyan
    try {
        $metadata = Invoke-RestMethod -Uri $url -TimeoutSec 30

        # Extract releases and iterate through them
        foreach ($release in $metadata.releases) {
            # Check for windowsdesktop runtime
            if ($windowsdesktop -eq "true" -and $release."windowsdesktop" -and $release."windowsdesktop".files) {
                if ($release."windowsdesktop"."version-display" -notmatch "preview|rc") {
                    foreach ($file in $release."windowsdesktop".files) {
                        if (($file.rid -eq "win-x86" -and $x86 -eq "true") -or `
                            ($file.rid -eq "win-x64" -and $x64 -eq "true") -or `
                            ($file.rid -eq "win-arm64" -and $arm64 -eq "true")) {
                            if ($file.name.EndsWith(".exe")) {
                                $allDownloads += @{
                                    Type    = "windowsdesktop"
                                    Version = $release."windowsdesktop"."version"
                                    Url     = $file.url
                                    Rid     = $file.rid
                                    Name    = Split-Path -Leaf $file.url
                                }
                            }
                        }
                    }
                }
            }
        }
    } catch {
        Write-Host "  Releases.json for version '$version' does not exist. Skipping." -ForegroundColor Red
    }
}

# Filter for the latest version of each .NET release
$latestDownloads = @()
if ($allDownloads.Count -gt 0) {
    # Group by .NET version
    $groupedDownloads = $allDownloads | Group-Object { $_.Version.Split('.')[0..1] -join "." }

    foreach ($group in $groupedDownloads) {
        # Sort by version in descending order
        $sortedFiles = $group.Group | Sort-Object { [version]$_.Version } -Descending

        # Select the top two files (one for win-x64 and one for win-x86)
        $latestX64 = $sortedFiles | Where-Object { $_.Rid -eq "win-x64" } | Select-Object -First 1
        $latestX86 = $sortedFiles | Where-Object { $_.Rid -eq "win-x86" } | Select-Object -First 1

        if ($latestX64) { $latestDownloads += $latestX64 }
        if ($latestX86) { $latestDownloads += $latestX86 }
    }
}

# Debug output: Show parsed downloads
if ($latestDownloads.Count -eq 0) {
    Write-Host "  No download links found. Exiting script." -ForegroundColor Red
    exit
} else {
    Write-Host "  Parsed $($latestDownloads.Count) download links:" -ForegroundColor Green
    foreach ($download in $latestDownloads) {
        Write-Host "  $($download.Name) ($($download.Rid))" -ForegroundColor Cyan
    }
}

# Handle installation logic based on flags
if ($AutoInstall -eq "true") {
    if ($DownloadAllThenInstall -eq "true" -and $DownloadOneThenInstall -eq "true") {
        Write-Host "  Both 'DownloadAllThenInstall' and 'DownloadOneThenInstall' are set to 'true'. Choosing behavior based on 'DeleteAfterInstall'." -ForegroundColor Yellow
        if ($DeleteAfterInstall -eq "true") {
            $DownloadOneThenInstall = "true"
            $DownloadAllThenInstall = "false"
        } else {
            $DownloadAllThenInstall = "true"
            $DownloadOneThenInstall = "false"
        }
    }

    if ($DownloadAllThenInstall -eq "true") {
        # Download all packages first
        $downloadedFiles = @()
        foreach ($download in $latestDownloads) {
            $destination = Join-Path $downloadsFolder $download.Name
            if (-not (Test-Path $destination)) {
                if (Download-WithRetry -Url $download.Url -Destination $destination) {
                    $downloadedFiles += @{
                        Path = $destination
                    }
                }
            } else {
                Write-Host "  $($download.Name) already exists. Skipping download." -ForegroundColor Yellow
                $downloadedFiles += @{
                    Path = $destination
                }
            }
        }

        # Install all packages after downloading
        foreach ($file in $downloadedFiles) {
            if (Test-Path $file.Path) {
                Write-Host "  Installing $($file.Path)..." -ForegroundColor Cyan
                Start-Process -FilePath $file.Path -ArgumentList "/quiet /norestart" -Wait
            }
        }

        # Delete files if required
        if ($DeleteAfterInstall -eq "true") {
            foreach ($file in $downloadedFiles) {
                if (Test-Path $file.Path) {
                    Write-Host "  Deleting $($file.Path)" -ForegroundColor Yellow
                    Remove-Item -Path $file.Path -Force
                }
            }
        }
    } elseif ($DownloadOneThenInstall -eq "true") {
        # Download and install one package at a time
        foreach ($download in $latestDownloads) {
            $destination = Join-Path $downloadsFolder $download.Name
            if (-not (Test-Path $destination)) {
                if (Download-WithRetry -Url $download.Url -Destination $destination) {
                    Write-Host "  Installing $destination..." -ForegroundColor Cyan
                    Start-Process -FilePath $destination -ArgumentList "/quiet /norestart" -Wait

                    # Delete the file if required
                    if ($DeleteAfterInstall -eq "true") {
                        Write-Host "  Deleting $destination" -ForegroundColor Yellow
                        Remove-Item -Path $destination -Force
                    }
                }
            } else {
                Write-Host "  $destination already exists. Skipping download." -ForegroundColor Yellow
                Write-Host "  Installing $destination..." -ForegroundColor Cyan
                Start-Process -FilePath $destination -ArgumentList "/quiet /norestart" -Wait

                # Delete the file if required
                if ($DeleteAfterInstall -eq "true") {
                    Write-Host "  Deleting $destination" -ForegroundColor Yellow
                    Remove-Item -Path $destination -Force
                }
            }
        }
    }
} else {
    # Just download packages without installing
    foreach ($download in $latestDownloads) {
        $destination = Join-Path $downloadsFolder $download.Name
        if (-not (Test-Path $destination)) {
            if (Download-WithRetry -Url $download.Url -Destination $destination) {
                Write-Host "  Downloaded $($download.Name)" -ForegroundColor Green
            }
        } else {
            Write-Host "  $($download.Name) already exists. Skipping download." -ForegroundColor Yellow
        }
    }
}

Write-Host "Script completed successfully." -ForegroundColor Green
