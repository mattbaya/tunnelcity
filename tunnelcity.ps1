# SSH Tunnel Script (PowerShell version for Windows 11)
# Routes HTTP/HTTPS traffic through remote SSH server

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "start-bg", "start-detach", "stop", "status", "restart", "test", "docs", "help")]
    [string]$Command = "help"
)

# Function to write colored output (must be defined before use)
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

# Function to show OS-specific quick start guide
function Show-QuickStartGuide {
    Write-Host
    Write-Status "✨ Next Steps - System Proxy Configuration"
    Write-Host

    Write-Host "🧪 Windows Quick Setup:" -ForegroundColor Cyan
    Write-Host "  1. Settings > Network & Internet > Proxy"
    Write-Host "  2. Enable 'Use a proxy server'"
    Write-Host "  3. Address: 127.0.0.1, Port: $LOCAL_PORT"
    Write-Host
    Write-Host "  Or use PowerShell:"
    Write-Host "  Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 1"
    Write-Host

    $viewDetailed = Read-Host "📚 View detailed setup guide? [y/N]"
    if ($viewDetailed -match '^[Yy]$') {
        if (Test-Path "README-Windows11.md") {
            Write-Status "Opening detailed Windows setup guide..."
            if (Get-Command less -ErrorAction SilentlyContinue) {
                & less "README-Windows11.md"
            } elseif (Get-Command more -ErrorAction SilentlyContinue) {
                & more "README-Windows11.md"
            } else {
                Get-Content "README-Windows11.md" | Select-Object -First 100
                Write-Host
                Write-Status "View full guide: Get-Content README-Windows11.md | more"
            }
        } else {
            Write-Status "For detailed setup: https://github.com/mattbaya/tunnelcity"
        }
    } else {
        Write-Status "📌 Tip: Run '$(Split-Path $MyInvocation.ScriptName -Leaf) docs' anytime for detailed guides"
        Write-Status "🌐 Online: https://github.com/mattbaya/tunnelcity"
    }
    Write-Host
}

# Function to show available documentation
function Show-Documentation {
    Write-Host
    Write-Status "TunnelCity Documentation"
    Write-Host
    Write-Host "📚 Available Documentation:" -ForegroundColor Yellow
    Write-Host

    if (Test-Path "README.md") {
        Write-Host "  • README.md - Main project documentation"
    }

    if (Test-Path "README-macOS.md") {
        Write-Host "  • README-macOS.md - macOS setup and system proxy configuration"
    }

    if (Test-Path "README-Windows11.md") {
        Write-Host "  • README-Windows11.md - Windows 11 setup and system proxy configuration"
    }

    if (Test-Path "README-Linux.md") {
        Write-Host "  • README-Linux.md - Linux setup and system proxy configuration"
    }

    if (Test-Path "TROUBLESHOOTING.md") {
        Write-Host "  • TROUBLESHOOTING.md - Common issues and solutions"
    }

    Write-Host
    Write-Host "💡 Quick Commands:" -ForegroundColor Yellow
    Write-Host "  • View file: Get-Content README-Windows11.md | more"
    Write-Host "  • Open in browser: start README.md"
    Write-Host "  • Online docs: https://github.com/mattbaya/tunnelcity"
    Write-Host

    $viewDocs = Read-Host "Would you like to view a specific documentation file? [y/N]"
    if ($viewDocs -match '^[Yy]$') {
        Write-Host
        Write-Host "Available files:"
        $mdFiles = Get-ChildItem -Filter "*.md" -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt $mdFiles.Count; $i++) {
            Write-Host "  $($i + 1)) $($mdFiles[$i].Name)"
        }
        Write-Host
        $docChoice = Read-Host "Enter the number or filename to view"

        # Handle numeric choice
        if ($docChoice -match '^[0-9]+$') {
            $index = [int]$docChoice - 1
            if ($index -ge 0 -and $index -lt $mdFiles.Count) {
                $docFile = $mdFiles[$index].Name
            } else {
                $docFile = $null
            }
        } else {
            $docFile = $docChoice
        }

        if ($docFile -and (Test-Path $docFile)) {
            if (Get-Command more -ErrorAction SilentlyContinue) {
                & more $docFile
            } else {
                Get-Content $docFile
            }
        } else {
            Write-Error "File not found: $docFile"
        }
    }
}

# Function to prompt for configuration
function Request-Configuration {
    Write-Status "No .env file found. Let's set up your SSH tunnel configuration."
    Write-Host

    $sshUser = Read-Host "SSH username"
    $sshHost = Read-Host "SSH server hostname/IP"
    $localPortInput = Read-Host "Local SOCKS port (suggested: 8080)"
    $sshKeyInput = Read-Host "SSH key file path [~/.ssh/id_ed25519]"

    # Set defaults
    $localPort = if ($localPortInput) { $localPortInput } else { "8080" }
    $sshKey = if ($sshKeyInput) { $sshKeyInput } else { "~/.ssh/id_ed25519" }

    # Expand ~ to user profile
    $sshKey = $sshKey -replace '^~', $env:USERPROFILE

    # Create .env file
    $envContent = "# SSH Tunnel Configuration`n"
    $envContent += "SSH_USER=$sshUser`n"
    $envContent += "SSH_HOST=$sshHost`n"
    $envContent += "LOCAL_PORT=$localPort`n"
    $envContent += "SSH_KEY=$sshKey`n"

    Set-Content -Path ".env" -Value $envContent -Encoding UTF8
    Write-Success "Configuration saved to .env file"
    Write-Host

    # Offer to start tunnel immediately
    Write-Status "🚀 Configuration complete! Ready to start your SSH tunnel."
    Write-Host
    $startTunnelNow = Read-Host "Would you like to start the tunnel now? [Y/n]"

    if ($startTunnelNow -match '^[Nn]$') {
        Write-Status "Configuration saved. Run '$(Split-Path $MyInvocation.ScriptName -Leaf) start-bg' when you're ready to connect."
        exit 0
    } else {
        # Set a flag to indicate we should start the tunnel after config loading
        $script:FirstRunStartTunnel = $true
    }
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

# Function to check for port conflicts
function Test-PortConflicts {
    Write-Status "Checking for port conflicts on port $LOCAL_PORT..."

    # Get processes using the port
    $processInfo = $null
    try {
        $processInfo = Get-NetTCPConnection -LocalPort $LOCAL_PORT -ErrorAction SilentlyContinue |
                      Select-Object -ExpandProperty OwningProcess -Unique
    }
    catch {
        # Fallback to netstat if Get-NetTCPConnection fails
        try {
            $netstatOutput = netstat -ano | Select-String ":$LOCAL_PORT "
            if ($netstatOutput) {
                $processInfo = $netstatOutput | ForEach-Object {
                    ($_ -split '\s+')[-1]
                } | Sort-Object -Unique
            }
        }
        catch {
            Write-Warning "Unable to check port conflicts (network commands not available)"
            return $true
        }
    }

    if ($processInfo -and $processInfo.Count -gt 0) {
        Write-Host
        Write-Warning "Port $LOCAL_PORT is already in use!"
        Write-Host
        Write-Host "Processes using port $LOCAL_PORT:"

        $conflictsFound = $false
        foreach ($pid in $processInfo) {
            if ($pid -and $pid -ne "0") {
                try {
                    $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
                    if ($process) {
                        $processUser = (Get-WmiObject -Class Win32_Process -Filter "ProcessId=$pid" -ErrorAction SilentlyContinue).GetOwner().User
                        if (-not $processUser) { $processUser = "Unknown" }

                        Write-Host "  PID: $pid | User: $processUser | Command: $($process.ProcessName) $($process.Path)"

                        # Check if it's an SSH process
                        if ($process.ProcessName -eq "ssh" -or $process.Path -like "*ssh*") {
                            Write-Host "    ⚠️  This appears to be an SSH process using the same port" -ForegroundColor Yellow
                            $conflictsFound = $true
                        }
                    }
                }
                catch {
                    Write-Host "  PID: $pid | Unable to get process details"
                }
            }
        }

        Write-Host
        $killProcesses = Read-Host "Would you like to kill these processes? [y/N]"

        if ($killProcesses -match '^[Yy]$') {
            $killedAny = $false
            foreach ($pid in $processInfo) {
                if ($pid -and $pid -ne "0") {
                    try {
                        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
                        if ($process) {
                            $processUser = (Get-WmiObject -Class Win32_Process -Filter "ProcessId=$pid" -ErrorAction SilentlyContinue).GetOwner().User
                            $currentUser = $env:USERNAME

                            # Check if we can kill the process (same user or running as admin)
                            $canKill = $false
                            if ($processUser -eq $currentUser -or ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                                $canKill = $true
                            }

                            if ($canKill) {
                                Write-Status "Attempting to kill process $pid (user: $processUser)..."

                                try {
                                    # Try graceful termination first
                                    $process.CloseMainWindow() | Out-Null
                                    Start-Sleep -Seconds 2

                                    # Check if still running
                                    $stillRunning = Get-Process -Id $pid -ErrorAction SilentlyContinue
                                    if ($stillRunning) {
                                        Write-Warning "Process $pid didn't stop gracefully, forcing..."
                                        Stop-Process -Id $pid -Force
                                    }

                                    # Verify it's stopped
                                    Start-Sleep -Seconds 1
                                    $finalCheck = Get-Process -Id $pid -ErrorAction SilentlyContinue
                                    if (-not $finalCheck) {
                                        Write-Success "Successfully killed process $pid"
                                        $killedAny = $true
                                    }
                                    else {
                                        Write-Error "Failed to kill process $pid"
                                    }
                                }
                                catch {
                                    Write-Error "Failed to kill process ${pid}: $($PSItem.Exception.Message)"
                                }
                            }
                            else {
                                Write-Error "Cannot kill process $pid (owned by $processUser, you are $currentUser)"
                                Write-Status "Try running PowerShell as Administrator"
                            }
                        }
                    }
                    catch {
                        Write-Error "Error processing PID ${pid}: $($PSItem.Exception.Message)"
                    }
                }
            }

            if ($killedAny) {
                Start-Sleep -Seconds 2
                Write-Status "Rechecking port availability..."

                # Recheck if port is still in use
                try {
                    $remainingProcesses = Get-NetTCPConnection -LocalPort $LOCAL_PORT -ErrorAction SilentlyContinue
                    if (-not $remainingProcesses) {
                        Write-Success "Port $LOCAL_PORT is now available!"
                        return $true
                    }
                    else {
                        Write-Warning "Some processes are still using port $LOCAL_PORT"
                        return $false
                    }
                }
                catch {
                    Write-Success "Port conflict resolution completed"
                    return $true
                }
            }
            else {
                Write-Error "No processes were successfully killed"
                return $false
            }
        }
        else {
            Write-Warning "Port conflict not resolved. Tunnel may fail to start."
            $continueAnyway = Read-Host "Continue anyway? [y/N]"
            if ($continueAnyway -notmatch '^[Yy]$') {
                Write-Status "Operation cancelled by user"
                exit 1
            }
            return $false
        }
    }
    else {
        Write-Success "Port $LOCAL_PORT is available"
        return $true
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

    # Check for port conflicts before starting
    $portAvailable = Test-PortConflicts

    Write-Status "Starting SSH tunnel to $SSH_USER@$SSH_HOST..."
    Write-Status "Local SOCKS proxy will be available on 127.0.0.1:$LOCAL_PORT"

    if ($BackgroundMode) {
        # Background mode - first test connection interactively to handle password prompts
        Write-Status "Testing SSH connection (may prompt for key passphrase)..."

        # Test connection first to handle any interactive prompts (like password/passphrase)
        Write-Host
        Write-Status "Testing SSH connection - please enter your passphrase if prompted:"

        $testArgs = @(
            "-i", $SSH_KEY,
            "-o", "ConnectTimeout=10",
            "-o", "UserKnownHostsFile=$($env:USERPROFILE)\.ssh\known_hosts",
            "-o", "StrictHostKeyChecking=yes",
            "$SSH_USER@$SSH_HOST",
            "exit"
        )

        try {
            $testResult = & ssh @testArgs
            $testExitCode = $LASTEXITCODE
            if ($testExitCode -ne 0) {
                Write-Host
                Write-Error "SSH connection test failed. Please check your credentials and try again."
                return $false
            }
        }
        catch {
            Write-Host
            Write-Error "SSH connection test failed: $($PSItem.Exception.Message)"
            return $false
        }

        Write-Status "SSH connection verified. Starting tunnel in background..."

        # Now start the actual tunnel in background mode
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
            Write-Error "Failed to start SSH tunnel: $($PSItem.Exception.Message)"
            return $false
        }
    }
    else {
        # Foreground mode
        Write-Status "Running in foreground mode. Press Ctrl+C to stop."
        Write-Status "Configure your applications to use SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"

        Write-Status "Starting SSH tunnel in interactive mode..."
        Write-Status "Configure your applications to use SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"
        Write-Host
        Write-Status "Press Ctrl+C to stop the tunnel"
        Write-Host

        try {
            # Run SSH in foreground to handle passphrase properly
            & ssh -D $LOCAL_PORT -C -N -i $SSH_KEY -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o LogLevel=ERROR -o UserKnownHostsFile="$env:USERPROFILE\.ssh\known_hosts" -o StrictHostKeyChecking=yes "$SSH_USER@$SSH_HOST"
        }
        catch {
            Write-Error "SSH tunnel failed: $($PSItem.Exception.Message)"
            return $false
        }
    }
    return $true
}

# Function to start tunnel in a detachable session (Windows Terminal/PowerShell)
function Start-TunnelDetachable {
    Write-Status "Starting detachable SSH tunnel..."

    # Windows doesn't have tmux/screen, but we can use Windows Terminal or start a new PowerShell window
    $sessionName = "tunnelcity-$SSH_HOST"

    Write-Status "Creating new PowerShell window for detachable session"
    Write-Status "Local SOCKS proxy will be available on 127.0.0.1:$LOCAL_PORT"
    Write-Host

    # Create SSH command
    $sshCmd = "ssh -D $LOCAL_PORT -C -N -i `"$SSH_KEY`" -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o LogLevel=ERROR -o UserKnownHostsFile=`"$($env:USERPROFILE)\.ssh\known_hosts`" -o StrictHostKeyChecking=yes `"$SSH_USER@$SSH_HOST`""

    Write-Status "Creating detachable session..."
    Write-Status "A new PowerShell window will open for the SSH tunnel"
    Write-Status "Close that window or press Ctrl+C in it to stop the tunnel"
    Write-Host

    try {
        # Try to use Windows Terminal if available, otherwise use regular PowerShell
        if (Get-Command wt -ErrorAction SilentlyContinue) {
            Write-Status "Using Windows Terminal..."
            Start-Process wt -ArgumentList "new-tab", "--title", "TunnelCity SSH Tunnel", "powershell", "-NoExit", "-Command", $sshCmd
        } else {
            Write-Status "Using new PowerShell window..."
            Start-Process powershell -ArgumentList "-NoExit", "-Command", $sshCmd
        }

        Write-Success "SSH tunnel started in new window"
        Write-Status "The tunnel is running in the separate window"
        return $true
    }
    catch {
        Write-Error "Failed to start detachable tunnel: $($PSItem.Exception.Message)"
        Write-Status "Falling back to background mode..."
        return Start-Tunnel -BackgroundMode $true
    }
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
                    Write-Error "Failed to stop process: $($PSItem.Exception.Message)"
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
                Where-Object { $PSItem.CommandLine -like "*-D $LOCAL_PORT*$SSH_USER@$SSH_HOST*" } |
                ForEach-Object {
                    Write-Status "Stopping SSH process (PID: $($PSItem.Id))"
                    Stop-Process -Id $PSItem.Id -Force
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
    Write-Host "Usage: .$scriptName {start|start-bg|start-detach|stop|status|restart|test|docs|help}"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  start        - Start tunnel in foreground (interactive mode)"
    Write-Host "  start-bg     - Start tunnel in background"
    Write-Host "  start-detach - Start tunnel in detachable window (Windows Terminal/PowerShell)"
    Write-Host "  stop         - Stop the tunnel"
    Write-Host "  status       - Show tunnel status"
    Write-Host "  restart      - Restart the tunnel in background"
    Write-Host "  test         - Test the tunnel connection"
    Write-Host "  docs         - Show available documentation"
    Write-Host "  help         - Show this help message"
    Write-Host ""
    Write-Host "Configuration:"
    Write-Host "  SSH User: $SSH_USER"
    Write-Host "  SSH Host: $SSH_HOST"
    Write-Host "  Local Port: $LOCAL_PORT"
    Write-Host "  SSH Key: $SSH_KEY"
    Write-Host ""
    Write-Host "To use the tunnel, configure your applications to use:"
    Write-Host "  SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"
    Write-Host ""
    Write-Host "Documentation:"
    Write-Host "  Online: https://github.com/mattbaya/tunnelcity"
    Write-Host "  Local:  .$scriptName docs"
    Write-Host ""
    Write-Host "Requirements:"
    Write-Host "  - OpenSSH Client (install via Windows Features or Git for Windows)"
    Write-Host "  - SSH key configured for your server"
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
        Write-Error "Tunnel test failed: $($PSItem.Exception.Message)"
        return $false
    }
}

# Load configuration from .env file or prompt user
$FirstRunStartTunnel = $false
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^(.+?)=(.*)$' -and $_ -notmatch '^\s*#') {
            Set-Variable -Name $matches[1] -Value $matches[2] -Scope Script
        }
    }
} else {
    Request-Configuration
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^(.+?)=(.*)$' -and $_ -notmatch '^\s*#') {
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

# Handle first-run tunnel start
if ($FirstRunStartTunnel -eq $true) {
    Write-Host
    Write-Status "Starting your tunnel in background mode..."
    Write-Host

    # Check for existing tunnels
    if (Test-TunnelStatus) {
        Write-Warning "A tunnel is already running. Use '$(Split-Path $MyInvocation.ScriptName -Leaf) status' to check details."
        exit 0
    }

    # Start the tunnel
    $result = Start-Tunnel -BackgroundMode $true
    if ($result) {
        Write-Host
        Write-Success "Tunnel started successfully!"
        Show-QuickStartGuide
        New-Item -Path ".tunnelcity_welcome_shown" -ItemType File -Force | Out-Null
    } else {
        Write-Error "Failed to start tunnel. Check the error messages above."
        exit 1
    }
    exit 0
}

# Main script logic
switch ($Command) {
    "start" {
        if (Test-TunnelStatus) {
            exit 1
        }
        Start-Tunnel -BackgroundMode $false
        # Offer documentation after initial setup
        if (-not (Test-Path ".tunnelcity_welcome_shown")) {
            Show-QuickStartGuide
            New-Item -Path ".tunnelcity_welcome_shown" -ItemType File -Force | Out-Null
        }
    }
    "start-bg" {
        if (Test-TunnelStatus) {
            exit 1
        }
        $result = Start-Tunnel -BackgroundMode $true
        # Offer documentation for first-time background users
        if (-not (Test-Path ".tunnelcity_welcome_shown") -and $result) {
            Write-Host
            Write-Success "Tunnel started in background!"
            Show-QuickStartGuide
            New-Item -Path ".tunnelcity_welcome_shown" -ItemType File -Force | Out-Null
        }
    }
    "start-detach" {
        if (Test-TunnelStatus) {
            exit 1
        }
        $result = Start-TunnelDetachable
        # Offer documentation after detachable setup
        if (-not (Test-Path ".tunnelcity_welcome_shown") -and $result) {
            Show-QuickStartGuide
            New-Item -Path ".tunnelcity_welcome_shown" -ItemType File -Force | Out-Null
        }
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
    "docs" {
        Show-Documentation
    }
    "help" {
        Show-Usage
    }
    default {
        Show-Usage
        exit 1
    }
}