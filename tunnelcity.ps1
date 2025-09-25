# SSH Tunnel Script (PowerShell version for Windows 11)
# Routes HTTP/HTTPS traffic through remote SSH server

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "start-bg", "stop", "status", "restart", "test", "help")]
    [string]$Command = "help"
)

# Function to prompt for configuration
function Request-Configuration {
    Write-Status "No .env file found. Let's set up your SSH tunnel configuration."
    Write-Host

    $sshUser = Read-Host "SSH username"
    $sshHost = Read-Host "SSH server hostname/IP"
    $localPortInput = Read-Host "Local SOCKS port [8080]"
    $sshKeyInput = Read-Host "SSH key file path [~/.ssh/id_ed25519]"

    # Set defaults
    $localPort = if ($localPortInput) { $localPortInput } else { "8080" }
    $sshKey = if ($sshKeyInput) { $sshKeyInput } else { "~/.ssh/id_ed25519" }

    # Expand ~ to user profile
    $sshKey = $sshKey -replace '^~', $env:USERPROFILE

    # Create .env file
    $envContent = @"
# SSH Tunnel Configuration
SSH_USER=$sshUser
SSH_HOST=$sshHost
LOCAL_PORT=$localPort
SSH_KEY=$sshKey
"@

    Set-Content -Path ".env" -Value $envContent -Encoding UTF8
    Write-Success "Configuration saved to .env file"
    Write-Host
}

# Load configuration from .env file or prompt user
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^([^#].*?)=(.*)$') {
            Set-Variable -Name $matches[1] -Value $matches[2] -Scope Script
        }
    }
} else {
    Request-Configuration
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^([^#].*?)=(.*)$') {
            Set-Variable -Name $matches[1] -Value $matches[2] -Scope Script
        }
    }
}

# Configuration with defaults
$SSH_USER = if ($SSH_USER) { $SSH_USER } else { "user" }
$SSH_HOST = if ($SSH_HOST) { $SSH_HOST } else { "server.com" }
$LOCAL_PORT = if ($LOCAL_PORT) { $LOCAL_PORT } else { "8080" }
$SSH_KEY = if ($SSH_KEY) { $SSH_KEY } else { "~/.ssh/id_ed25519" }

# Expand ~ to user profile in SSH key path
$SSH_KEY = $SSH_KEY -replace '^~', $env:USERPROFILE
$TUNNEL_PID_FILE = "$env:TEMP\ssh_tunnel_$SSH_HOST.pid"

# Function to write colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check if SSH command is available
function Test-SshAvailable {
    try {
        $null = Get-Command ssh -ErrorAction Stop
        return $true
    }
    catch {
        Write-Error "SSH is not available. Please install OpenSSH Client feature or Git for Windows."
        Write-Status "To install OpenSSH Client on Windows 11:"
        Write-Status "1. Open Settings > Apps > Optional features"
        Write-Status "2. Click 'Add an optional feature'"
        Write-Status "3. Search for 'OpenSSH Client' and install it"
        Write-Status "Or install Git for Windows which includes SSH"
        return $false
    }
}

# Function to check if tunnel is already running
function Test-TunnelStatus {
    if (Test-Path $TUNNEL_PID_FILE) {
        $pid = Get-Content $TUNNEL_PID_FILE -ErrorAction SilentlyContinue
        if ($pid -and (Get-Process -Id $pid -ErrorAction SilentlyContinue)) {
            Write-Warning "Tunnel is already running (PID: $pid)"
            return $true
        }
        else {
            Write-Warning "Stale PID file found, removing..."
            Remove-Item $TUNNEL_PID_FILE -Force -ErrorAction SilentlyContinue
            return $false
        }
    }
    return $false
}

# Function to start the tunnel
function Start-Tunnel {
    param([bool]$BackgroundMode)

    if (-not (Test-SshAvailable)) {
        return $false
    }

    Write-Status "Starting SSH tunnel to $SSH_USER@$SSH_HOST..."
    Write-Status "Local SOCKS proxy will be available on 127.0.0.1:$LOCAL_PORT"

    if ($BackgroundMode) {
        # Background mode - use Start-Process to run SSH in background
        $sshArgs = @(
            "-D", $LOCAL_PORT,
            "-C", "-N",
            "-i", $SSH_KEY,
            "-o", "ServerAliveInterval=60",
            "-o", "ServerAliveCountMax=3",
            "-o", "ExitOnForwardFailure=yes",
            "-o", "LogLevel=ERROR",
            "-o", "UserKnownHostsFile=$($env:USERPROFILE)\.ssh\known_hosts",
            "-o", "StrictHostKeyChecking=yes",
            "$SSH_USER@$SSH_HOST"
        )

        try {
            $process = Start-Process -FilePath "ssh" -ArgumentList $sshArgs -PassThru -WindowStyle Hidden
            Start-Sleep -Seconds 2

            if ($process -and -not $process.HasExited) {
                $process.Id | Out-File $TUNNEL_PID_FILE -Encoding ASCII
                Write-Success "Tunnel started in background (PID: $($process.Id))"
                Write-Status "Configure your applications to use SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"
                Write-Status "Run '$($MyInvocation.MyCommand.Name) stop' to stop the tunnel"
                Write-Status "Run '$($MyInvocation.MyCommand.Name) status' to check tunnel status"
                return $true
            }
            else {
                Write-Error "Failed to start SSH tunnel"
                return $false
            }
        }
        catch {
            Write-Error "Failed to start SSH tunnel: $($_.Exception.Message)"
            return $false
        }
    }
    else {
        # Foreground mode
        Write-Status "Running in foreground mode. Press Ctrl+C to stop."
        Write-Status "Configure your applications to use SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"

        try {
            & ssh -D $LOCAL_PORT -C -N -i $SSH_KEY -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o LogLevel=ERROR -o UserKnownHostsFile="$env:USERPROFILE\.ssh\known_hosts" -o StrictHostKeyChecking=yes "$SSH_USER@$SSH_HOST"
        }
        catch {
            Write-Error "SSH tunnel failed: $($_.Exception.Message)"
            return $false
        }
    }
    return $true
}

# Function to stop the tunnel
function Stop-Tunnel {
    if (Test-Path $TUNNEL_PID_FILE) {
        $pid = Get-Content $TUNNEL_PID_FILE -ErrorAction SilentlyContinue
        if ($pid) {
            $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
            if ($process) {
                Write-Status "Stopping SSH tunnel (PID: $pid)..."
                try {
                    Stop-Process -Id $pid -Force
                    Start-Sleep -Seconds 2
                    Write-Success "Tunnel stopped"
                }
                catch {
                    Write-Error "Failed to stop process: $($_.Exception.Message)"
                }
            }
            else {
                Write-Warning "Process with PID $pid not found"
            }
            Remove-Item $TUNNEL_PID_FILE -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        Write-Warning "No tunnel PID file found. Trying to find and kill SSH processes..."
        try {
            Get-Process -Name ssh -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandLine -like "*-D $LOCAL_PORT*$SSH_USER@$SSH_HOST*" } |
                ForEach-Object {
                    Write-Status "Stopping SSH process (PID: $($_.Id))"
                    Stop-Process -Id $_.Id -Force
                }
        }
        catch {
            Write-Status "Attempted to kill matching SSH processes"
        }
    }
}

# Function to show tunnel status
function Show-Status {
    if (Test-TunnelStatus) {
        $pid = Get-Content $TUNNEL_PID_FILE -ErrorAction SilentlyContinue
        Write-Success "Tunnel is running (PID: $pid)"
        Write-Status "SOCKS5 proxy available at: 127.0.0.1:$LOCAL_PORT"

        # Test connectivity
        Write-Status "Testing external IP..."
        try {
            # Use curl if available, otherwise use Invoke-WebRequest with proxy
            if (Get-Command curl -ErrorAction SilentlyContinue) {
                $externalIp = & curl -s --socks5 "127.0.0.1:$LOCAL_PORT" ifconfig.me 2>$null
            }
            else {
                # PowerShell alternative (more complex with SOCKS5)
                $externalIp = "Unable to determine (curl not available)"
            }
            Write-Status "Your apparent external IP: $externalIp"
        }
        catch {
            Write-Status "Your apparent external IP: Unable to determine"
        }
    }
    else {
        Write-Warning "Tunnel is not running"
    }
}

# Function to show usage
function Show-Usage {
    $scriptName = Split-Path $MyInvocation.ScriptName -Leaf
    Write-Host "Usage: .$scriptName {start|start-bg|stop|status|restart|test|help}"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  start     - Start tunnel in foreground (interactive mode)"
    Write-Host "  start-bg  - Start tunnel in background"
    Write-Host "  stop      - Stop the tunnel"
    Write-Host "  status    - Show tunnel status"
    Write-Host "  restart   - Restart the tunnel in background"
    Write-Host "  test      - Test the tunnel connection"
    Write-Host "  help      - Show this help message"
    Write-Host ""
    Write-Host "Configuration:"
    Write-Host "  SSH User: $SSH_USER"
    Write-Host "  SSH Host: $SSH_HOST"
    Write-Host "  Local Port: $LOCAL_PORT"
    Write-Host ""
    Write-Host "To use the tunnel, configure your applications to use:"
    Write-Host "  SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"
    Write-Host ""
    Write-Host "Requirements:"
    Write-Host "  - OpenSSH Client (install via Windows Features or Git for Windows)"
    Write-Host "  - SSH key configured for $SSH_USER@$SSH_HOST"
}

# Function to test the tunnel
function Test-Tunnel {
    if (-not (Test-TunnelStatus)) {
        Write-Error "Tunnel is not running. Start it first with '$(Split-Path $MyInvocation.ScriptName -Leaf) start-bg'"
        return $false
    }

    Write-Status "Testing tunnel connection..."

    try {
        # Test SOCKS proxy
        if (Get-Command curl -ErrorAction SilentlyContinue) {
            $testResult = & curl -s --socks5 "127.0.0.1:$LOCAL_PORT" --connect-timeout 10 ifconfig.me 2>$null
            if ($testResult) {
                Write-Success "Tunnel is working! Your external IP appears as: $testResult"

                # Compare with direct connection
                $directIp = & curl -s --connect-timeout 5 ifconfig.me 2>$null
                if (-not $directIp) { $directIp = "Unable to determine" }
                Write-Status "Direct connection IP: $directIp"

                if ($testResult -ne $directIp) {
                    Write-Success "IP addresses are different - tunnel is working correctly!"
                }
                else {
                    Write-Warning "IP addresses are the same - tunnel might not be working"
                }
                return $true
            }
            else {
                Write-Error "Tunnel test failed - unable to connect through proxy"
                return $false
            }
        }
        else {
            Write-Warning "curl not available - cannot test tunnel connectivity"
            Write-Status "Install curl or Git for Windows to enable tunnel testing"
            return $false
        }
    }
    catch {
        Write-Error "Tunnel test failed: $($_.Exception.Message)"
        return $false
    }
}

# Main script logic
switch ($Command) {
    "start" {
        if (Test-TunnelStatus) {
            exit 1
        }
        Start-Tunnel -BackgroundMode $false
    }
    "start-bg" {
        if (Test-TunnelStatus) {
            exit 1
        }
        Start-Tunnel -BackgroundMode $true
    }
    "stop" {
        Stop-Tunnel
    }
    "status" {
        Show-Status
    }
    "restart" {
        Write-Status "Restarting tunnel..."
        Stop-Tunnel
        Start-Sleep -Seconds 2
        Start-Tunnel -BackgroundMode $true
    }
    "test" {
        Test-Tunnel
    }
    default {
        Show-Usage
        exit 1
    }
}