# SSH Tunnel Script for Windows 11

This PowerShell script creates an SSH tunnel with SOCKS5 proxy functionality on Windows 11.

## Prerequisites

1. **OpenSSH Client**: Install via Windows Features or Git for Windows
   - **Option 1 - Windows Features**:
     1. Open Settings > Apps > Optional features
     2. Click "Add an optional feature"
     3. Search for "OpenSSH Client" and install it
   - **Option 2 - Git for Windows**: Download from https://git-scm.com/download/win

2. **SSH Key Setup**: Ensure you have SSH key authentication configured for your remote server

## Installation

1. Save the `tunnelcity.ps1` script to your desired location
2. Open PowerShell as Administrator (first time only to set execution policy)
3. Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Usage

Open PowerShell and navigate to the script directory, then run:

```powershell
# Show help
.\tunnelcity.ps1 help

# Start tunnel in background
.\tunnelcity.ps1 start-bg

# Check tunnel status
.\tunnelcity.ps1 status

# Test tunnel connectivity
.\tunnelcity.ps1 test

# Stop tunnel
.\tunnelcity.ps1 stop

# Restart tunnel
.\tunnelcity.ps1 restart

# Start tunnel in foreground (interactive)
.\tunnelcity.ps1 start
```

## Configuration

The script uses these default settings (modify at the top of the script):
- **SSH User**: your_username
- **SSH Host**: your_server.com
- **Local Port**: 8080

## Using the SOCKS5 Proxy

Once the tunnel is running, configure your applications to use:
- **Proxy Type**: SOCKS5
- **Host**: 127.0.0.1
- **Port**: 8080

### Browser Configuration Examples

**Chrome**:
```
--proxy-server="socks5://127.0.0.1:8080"
```

**Firefox**:
1. Settings > Network Settings
2. Manual proxy configuration
3. SOCKS Host: 127.0.0.1, Port: 8080
4. Select "SOCKS v5"

## Troubleshooting

### "SSH is not available"
Install OpenSSH Client via Windows Features or Git for Windows.

### "Execution Policy" Error
Run PowerShell as Administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### SSH Connection Issues
- Verify SSH key authentication works: `ssh your_username@your_server.com`
- Check if the remote host is reachable
- Ensure port 8080 is not already in use locally

### Testing Without curl
The script works best with curl for testing. Install Git for Windows to get curl, or use Windows Subsystem for Linux (WSL).

## Differences from Bash Version

- Uses Windows temp directory for PID files
- PowerShell-native process management
- Windows-compatible colored output
- Execution policy considerations
- Optional curl dependency for testing