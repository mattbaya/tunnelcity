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
# Enable system proxy
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "127.0.0.1:8080"

# Disable system proxy
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 0
```

For advanced PowerShell proxy management functions and additional configuration options, see the [PowerShell documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies).

### Application-Specific Configuration

#### Edge/Internet Explorer
Uses system proxy settings automatically.

#### Browsers

**Firefox (Recommended - Best SOCKS5 Support)**
1. Open Firefox
2. **Settings** → **General** → **Network Settings** → **Settings** button
3. Select **"Manual proxy configuration"**
4. **SOCKS Host**: `127.0.0.1` **Port**: `8080`
5. Select **"SOCKS v5"** (important!)
6. Check **"Proxy DNS when using SOCKS v5"** (for better privacy)
7. Click **OK**

**Chrome/Chromium**
```powershell
# Close all Chrome instances first, then:
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --proxy-server="socks5://127.0.0.1:8080"

# Create a batch file for convenience:
echo @"C:\Program Files\Google\Chrome\Application\chrome.exe" --proxy-server="socks5://127.0.0.1:8080" > chrome-proxy.bat
```

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