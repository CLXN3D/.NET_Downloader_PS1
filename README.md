
# .NET_Downloader_PS1

This PowerShell script automates the process of downloading and installing specific versions of the .NET runtime, SDK, and other related components. It supports downloading packages for multiple architectures (x86, x64, ARM64) and provides options for installation and cleanup.

## Table of Contents

- [Features](#features)
- [Command-Line Parameters](#command-line-parameters)
- [Examples of Usage](#examples-of-usage)
- [How It Works](#how-it-works)

---

## Features

- **Customizable Downloads**: Specify which types of .NET packages to download (e.g., Windows Desktop Runtime, ASP.NET Core Runtime, etc.).
- **Version Selection**: Choose specific .NET versions to include (e.g., 5.0, 6.0, 7.0, etc.).
- **Architecture Support**: Download packages for x86, x64, or ARM64 architectures.
- **Installation Options**: Automatically install downloaded packages or skip installation.
- **Download and Install Modes**:
  - Download all packages first, then install them (`DownloadAllThenInstall`).
  - Download and install one package at a time (`DownloadOneThenInstall`).
- **Cleanup**: Optionally delete downloaded packages after installation.

---

## Command-Line Parameters

The script accepts the following parameters:

| Parameter Name           | Description                                                                                     | Default Value |
|--------------------------|-------------------------------------------------------------------------------------------------|---------------|
| `windowsdesktop`         | Include the Windows Desktop Runtime.                                                            | `"true"`      |
| `aspnetcore_runtime`     | Include the ASP.NET Core Runtime.                                                               | `"false"`     |
| `dotnet_hosting`         | Include the .NET Hosting Bundle.                                                                | `"false"`     |
| `dotnet_runtime`         | Include the .NET Runtime.                                                                       | `"false"`     |
| `dotnet_sdk`             | Include the .NET SDK.                                                                           | `"false"`     |
| `x86`                    | Include x86 architecture.                                                                       | `"true"`      |
| `x64`                    | Include x64 architecture.                                                                       | `"true"`      |
| `arm64`                  | Include ARM64 architecture.                                                                     | `"false"`     |
| `DownloadTo`             | Specify the folder where files will be downloaded.                                              | `Downloads`   |
| `10_0`                   | Include specific .NET versions (e.g., `"true"` to include .NET 10.0).                           | `"true"`      |
| `AutoInstall`            | Automatically install packages after downloading.                                               | `"true"`      |
| `DownloadAllThenInstall` | Download all packages first, then install them.                                                 | `"true"`      |
| `DownloadOneThenInstall` | Download and install one package at a time.                                                     | `"false"`     |
| `DeleteAfterInstall`     | Delete packages after installation.                                                             | `"false"`     |

---

## Examples of Usage

### Example 1: Basic Usage
Download and install the latest Windows Desktop Runtime for .NET 10.0 and .NET 9.0 (x64 only).

```powershell
.\script.ps1 `
    -windowsdesktop "true" `
    -x86 "false" `
    -x64 "true" `
    -arm64 "false" `
    -10_0 "true" `
    -9_0 "true" `
    -AutoInstall "true" `
    -DownloadAllThenInstall "true"
```

### Example 2: Custom Download Folder
Download the .NET SDK for .NET 8.0 and .NET 7.0 into a custom folder.

```powershell
.\script.ps1 `
    -dotnet_sdk "true" `
    -x86 "true" `
    -x64 "true" `
    -arm64 "false" `
    -8_0 "true" `
    -7_0 "true" `
    -DownloadTo "C:\CustomFolder" `
    -AutoInstall "false"
```

### Example 3: Download One Package at a Time
Download and install one package at a time for .NET 6.0 and .NET 5.0, deleting the files after installation.

```powershell
.\script.ps1 `
    -dotnet_runtime "true" `
    -x86 "true" `
    -x64 "true" `
    -arm64 "false" `
    -6_0 "true" `
    -5_0 "true" `
    -AutoInstall "true" `
    -DownloadOneThenInstall "true" `
    -DeleteAfterInstall "true"
```

### Example 4: Skip Installation
Download the ASP.NET Core Runtime for .NET 7.0 without installing it.

```powershell
.\script.ps1 `
    -aspnetcore_runtime "true" `
    -x86 "true" `
    -x64 "true" `
    -arm64 "false" `
    -7_0 "true" `
    -AutoInstall "false"
```

---

## How It Works

1. **Metadata Fetching**:
   - The script fetches metadata from the `.NET release-metadata` URLs for the specified versions.
   - It parses the metadata to identify the latest stable releases for the selected package types and architectures.

2. **File Downloading**:
   - For each selected version and architecture, the script downloads the corresponding files to the specified folder (`DownloadTo`).
   - If a file already exists, it skips the download.

3. **Installation**:
   - If `AutoInstall` is set to `"true"`, the script installs the downloaded packages using the `/quiet /norestart` flags.
   - The installation mode depends on the values of `DownloadAllThenInstall` and `DownloadOneThenInstall`.

4. **Cleanup**:
   - If `DeleteAfterInstall` is set to `"true"`, the script deletes the downloaded files after installation.

---

## Notes

- Ensure you have administrator rights to perform installation on your system.
- The script hides download progress by default (`$ProgressPreference = 'SilentlyContinue'`) to improve performance.
- If both `DownloadAllThenInstall` and `DownloadOneThenInstall` are set to `"true"`, the script prioritizes `DownloadOneThenInstall` if `DeleteAfterInstall` is `"true"`. Otherwise, it uses `DownloadAllThenInstall`.

---
