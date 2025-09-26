# TunnelCity Setup Guide - Windows 11

This guide covers setting up and using TunnelCity SSH tunnels on Windows 11, including system-wide and application-specific proxy configuration.

## Prerequisites

### 1. Install OpenSSH Client

#### Option A: Windows Features (Recommended)
1. Press `Win + R`, type `appwiz.cpl`, press Enter
2. Click **Turn Windows features on or off**
3. Check **OpenSSH Client**
4. Click **OK** and restart if prompted

#### Option B: Settings App
1. **Settings** > **Apps** > **Optional features**
2. Click **Add an optional feature**
3. Search for **OpenSSH Client**
4. Install and restart if needed

#### Option C: PowerShell (Admin)
```powershell
# Install OpenSSH Client
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Verify installation
ssh -V
```

### 2. PowerShell Execution Policy
Run PowerShell as Administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. SSH Key Setup

#### Generate SSH Keys
```powershell
# Generate SSH key
ssh-keygen -t ed25519 -b 4096 -f "$env:USERPROFILE\.ssh\id_ed25519"

# Start SSH Agent service
Start-Service ssh-agent
Set-Service ssh-agent -StartupType Automatic

# Add key to agent
ssh-add "$env:USERPROFILE\.ssh\id_ed25519"
```

#### Copy Key to Remote Server
```powershell
# Method 1: Manual copy
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub" | clip
# Paste into remote server's ~/.ssh/authorized_keys

# Method 2: Using ssh-copy-id (if available via Git Bash)
ssh-copy-id -i "$env:USERPROFILE\.ssh\id_ed25519.pub" user@server.com

# Test connection
ssh user@server.com
```

## TunnelCity Configuration

1. Copy `.env.example` to `.env` and configure:
```powershell
Copy-Item .env.example .env
notepad .env  # or use your preferred editor
```

2. Update `.env` with your details:
```
SSH_USER=your_username
SSH_HOST=your_server.com
LOCAL_PORT=8080
```

## Using the SOCKS5 Proxy

Once your tunnel is running (`.\tunnelcity.ps1 start-bg`), configure applications to use:
- **Proxy Type**: SOCKS5
- **Host**: 127.0.0.1
- **Port**: 8080 (or your configured port)

### 🚀 Quick Setup - Most Reliable Methods

**1. System-wide Proxy (Recommended):**
```powershell
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "socks=127.0.0.1:8080"
```

**2. Firefox (Best SOCKS5 Support):**
Settings → General → Network Settings → Manual proxy → SOCKS Host: `127.0.0.1:8080` → SOCKS v5

**3. Chrome with PowerShell:**
```powershell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --proxy-server="socks5://127.0.0.1:8080"
```

### System-Wide Proxy Configuration (Recommended)

#### Method 1: Settings App (Recommended)
1. **Settings** > **Network & internet** > **Proxy**
2. Under **Manual proxy setup**, toggle **Use a proxy server** ON
3. **Address**: `127.0.0.1`
4. **Port**: `8080`
5. Check **Don't use the proxy server for local addresses**
6. Add to bypass list: `localhost;127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*`

**Important Notes**:
- Windows doesn't have native system-wide SOCKS5 support
- The above methods configure HTTP proxy settings that work with most applications
- For applications that don't respect system proxy settings, configure them individually
- Some applications may not respect system proxy settings

#### Method 2: PowerShell Commands (Recommended for Automation)
```powershell
# Enable system proxy (HTTP proxy - Windows doesn't support SOCKS5 system-wide natively)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "127.0.0.1:8080"

# Disable system proxy
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 0
```

#### Method 3: PowerShell with SOCKS5 Registry Setting (Limited Functionality)
```powershell
# This attempts to set SOCKS5 in registry (limited app support)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "socks=127.0.0.1:8080"

# Disable
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 0

# Check current proxy status
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" | Select-Object ProxyEnable, ProxyServer

# Refresh system proxy settings (notify running applications)
$signature = @'
[DllImport("wininet.dll", SetLastError = true, CharSet=CharSet.Auto)]
public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
'@
$wininet = Add-Type -MemberDefinition $signature -Name wininet -Namespace pinvoke -PassThru
$wininet::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0) | Out-Null
$wininet::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0) | Out-Null

Write-Host "Proxy settings refreshed"
```

#### Method 3: Command Line (netsh - Limited)
```cmd
# Windows doesn't have built-in SOCKS5 system proxy via netsh
# These commands are for HTTP proxies only
netsh winhttp set proxy proxy-server="127.0.0.1:8080" bypass-list="localhost"
netsh winhttp reset proxy
netsh winhttp show proxy
```

#### Method 4: PowerShell Proxy Management Functions
Add these to your PowerShell profile (`$PROFILE`):

```powershell
function Enable-SystemProxy {
    param(
        [string]$ProxyServer = "127.0.0.1:8080",
        [string[]]$BypassList = @("localhost", "127.*", "10.*", "172.16.*", "192.168.*")
    )

    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyServer -Value $ProxyServer

    if ($BypassList) {
        $bypassString = $BypassList -join ";"
        Set-ItemProperty -Path $regPath -Name ProxyOverride -Value $bypassString
    }

    # Refresh IE settings
    $signature = @'
[DllImport("wininet.dll", SetLastError = true, CharSet=CharSet.Auto)]
public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
'@
    $wininet = Add-Type -MemberDefinition $signature -Name wininet -Namespace pinvoke -PassThru
    $wininet::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0) | Out-Null
    $wininet::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0) | Out-Null

    Write-Host "✅ System proxy enabled: $ProxyServer" -ForegroundColor Green
}

function Disable-SystemProxy {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0

    # Refresh IE settings
    $signature = @'
[DllImport("wininet.dll", SetLastError = true, CharSet=CharSet.Auto)]
public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
'@
    $wininet = Add-Type -MemberDefinition $signature -Name wininet -Namespace pinvoke -PassThru
    $wininet::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0) | Out-Null
    $wininet::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0) | Out-Null

    Write-Host "❌ System proxy disabled" -ForegroundColor Red
}

function Get-SystemProxy {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    $proxySettings = Get-ItemProperty -Path $regPath

    [PSCustomObject]@{
        Enabled = [bool]$proxySettings.ProxyEnable
        Server = $proxySettings.ProxyServer
        Bypass = $proxySettings.ProxyOverride
    }
}

# Usage:
# Enable-SystemProxy
# Disable-SystemProxy
# Get-SystemProxy
```

### Application-Specific Configuration

#### Edge/Internet Explorer
Uses system proxy settings automatically.

#### Chrome/Chromium

**Method 1: PowerShell (Recommended)**
```powershell
# Close all Chrome instances first, then:
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --proxy-server="socks5://127.0.0.1:8080"

# Alternative syntax:
Start-Process chrome -ArgumentList "--proxy-server=socks5://127.0.0.1:8080"
```

**Method 2: Command Line**
```cmd
# Launch with SOCKS proxy
"C:\Program Files\Google\Chrome\Application\chrome.exe" --proxy-server="socks5://127.0.0.1:8080"

# Create a batch file for convenience
echo @"C:\Program Files\Google\Chrome\Application\chrome.exe" --proxy-server="socks5://127.0.0.1:8080" > chrome-proxy.bat
```

**Important**: Close all Chrome instances before running with proxy arguments.

#### Firefox (Recommended - Best SOCKS5 Support)
1. Open Firefox
2. **Settings** → **General** → **Network Settings** → **Settings** button
3. Select **"Manual proxy configuration"**
4. **SOCKS Host**: `127.0.0.1` **Port**: `8080`
5. Select **"SOCKS v5"** (important!)
6. Check **"Proxy DNS when using SOCKS v5"** (for better privacy)
7. Click **OK**

**Note**: Firefox has the best native SOCKS5 support of all browsers.

#### Command Line Tools

**curl** (if installed):
```cmd
curl --socks5 127.0.0.1:8080 https://ifconfig.me
```

**PowerShell Web Requests**:
```powershell
# PowerShell doesn't natively support SOCKS5
# Use Invoke-WebRequest with HTTP proxy or install curl
```


## Network Change Handling

### Task Scheduler for Auto-Start
Create a scheduled task to start tunnel automatically:

1. Open **Task Scheduler**
2. **Create Basic Task**
3. **Name**: TunnelCity Auto-Start
4. **Trigger**: At startup
5. **Action**: Start a program
6. **Program**: `powershell.exe`
7. **Arguments**: `-WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\path\to\tunnelcity.ps1" start-bg`

### PowerShell Profile for Aliases
Add to `$PROFILE` (create if doesn't exist):
```powershell
# Create convenient aliases
function Start-Tunnel { & "C:\path\to\tunnelcity.ps1" start-bg }
function Stop-Tunnel { & "C:\path\to\tunnelcity.ps1" stop }
function Test-Tunnel { & "C:\path\to\tunnelcity.ps1" test }
function Restart-Tunnel { & "C:\path\to\tunnelcity.ps1" restart }

Set-Alias tunnel Start-Tunnel
```

## Testing Your Setup

### Verify Tunnel is Working
```powershell
# If curl is available
curl --socks5 127.0.0.1:8080 https://ifconfig.me

# Using PowerShell (limited - HTTP proxy only)
$proxy = [System.Net.WebProxy]::new("127.0.0.1:8080")
$client = [System.Net.WebClient]::new()
$client.Proxy = $proxy
$client.DownloadString("https://ifconfig.me")
```

### Browser Testing
1. Configure browser to use SOCKS5 proxy
2. Visit https://whatismyipaddress.com
3. Compare with direct connection
4. Location should show your server's location

## Troubleshooting

### OpenSSH Not Found
```powershell
# Check if OpenSSH is installed
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

# Install if missing
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

### PowerShell Execution Policy
```powershell
# Check current policy
Get-ExecutionPolicy -List

# Set for current user only
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for single session
powershell.exe -ExecutionPolicy Bypass -File tunnelcity.ps1
```

### SSH Key Issues
```powershell
# Check SSH agent service
Get-Service ssh-agent

# Start if stopped
Start-Service ssh-agent

# List loaded keys
ssh-add -l

# Add key if needed
ssh-add "$env:USERPROFILE\.ssh\id_ed25519"
```

### Firewall Issues
```powershell
# Check Windows Defender Firewall
Get-NetFirewallProfile

# Allow SSH port (if needed)
New-NetFirewallRule -DisplayName "SSH Tunnel" -Direction Inbound -Port 8080 -Protocol TCP -Action Allow
```

### Port Already in Use
```powershell
# Check what's using port 8080
netstat -ano | findstr :8080

# Kill process by PID (replace XXXX with actual PID)
Stop-Process -Id XXXX -Force
```

## Security Considerations

### Windows Defender
Windows Defender may flag SSH tunneling tools. Add exclusions if needed:
1. **Windows Security** > **Virus & threat protection**
2. **Manage settings** under Virus & threat protection settings
3. **Add or remove exclusions**
4. Add your TunnelCity folder

### User Account Control (UAC)
- Run PowerShell as regular user (not Administrator) for security
- Only elevate privileges when necessary

### Network Profile
Ensure you're on the correct network profile:
```powershell
# Check network profile
Get-NetConnectionProfile

# Set to Private if needed (for home/work networks)
Set-NetConnectionProfile -NetworkCategory Private
```

## Useful External Resources

- **Windows SSH Setup**: https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse
- **PowerShell Execution Policy**: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies
- **Windows Proxy Configuration**: https://support.microsoft.com/en-us/windows/use-a-proxy-server-in-windows-02bd4c2a-5729-4b54-9ae0-b41b394b4de7
- **Task Scheduler Guide**: https://docs.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page
- **SSH Keys on Windows**: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#platform-windows