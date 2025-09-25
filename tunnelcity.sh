#!/bin/bash

# SSH Tunnel Script
# Routes HTTP/HTTPS traffic through remote SSH server

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display documentation
show_documentation() {
    echo
    print_status "TunnelCity Documentation"
    echo
    echo "📚 Available Documentation:"
    echo

    if [[ -f "README.md" ]]; then
        echo "  • README.md - Main project documentation"
    fi

    if [[ -f "README-macOS.md" ]]; then
        echo "  • README-macOS.md - macOS setup and system proxy configuration"
    fi

    if [[ -f "README-Windows11.md" ]]; then
        echo "  • README-Windows11.md - Windows 11 setup and system proxy configuration"
    fi

    if [[ -f "README-Linux.md" ]]; then
        echo "  • README-Linux.md - Linux setup and system proxy configuration"
    fi

    if [[ -f "TROUBLESHOOTING.md" ]]; then
        echo "  • TROUBLESHOOTING.md - Common issues and solutions"
    fi

    echo
    echo "💡 Quick Commands:"
    echo "  • View file: cat README-macOS.md | less"
    echo "  • Open in browser: open README.md (macOS) | start README.md (Windows)"
    echo "  • Online docs: https://github.com/mattbaya/tunnelcity"
    echo

    read -p "Would you like to view a specific documentation file? [y/N]: " view_docs
    if [[ "$view_docs" =~ ^[Yy]$ ]]; then
        echo
        echo "Available files:"
        ls -1 *.md 2>/dev/null | nl
        echo
        read -p "Enter the number or filename to view: " doc_choice

        # Handle numeric choice
        if [[ "$doc_choice" =~ ^[0-9]+$ ]]; then
            doc_file=$(ls -1 *.md 2>/dev/null | sed -n "${doc_choice}p")
        else
            doc_file="$doc_choice"
        fi

        if [[ -f "$doc_file" ]]; then
            if command -v less >/dev/null 2>&1; then
                less "$doc_file"
            else
                cat "$doc_file"
            fi
        else
            print_error "File not found: $doc_file"
        fi
    fi
}

# Function to show OS-specific quick start guide
offer_quick_start_guide() {
    local os_type=$(uname)
    echo
    print_status "✨ Next Steps - System Proxy Configuration"
    echo

    case "$os_type" in
        "Darwin")
            echo "🍎 macOS Quick Setup:"
            echo "  1. System Preferences > Network > Advanced > Proxies"
            echo "  2. Check 'SOCKS Proxy' and enter: 127.0.0.1:$LOCAL_PORT"
            echo "  3. Click OK > Apply"
            echo
            echo "  Or use command line:"
            echo "  sudo networksetup -setsocksfirewallproxy \"Wi-Fi\" 127.0.0.1 $LOCAL_PORT"
            ;;
        "Linux")
            echo "🐧 Linux Quick Setup:"
            echo "  1. Set environment variables:"
            echo "     export ALL_PROXY=socks5://127.0.0.1:$LOCAL_PORT"
            echo "  2. Or configure desktop environment:"
            echo "     Settings > Network > Proxy > Manual"
            echo "  3. Set SOCKS Host: 127.0.0.1, Port: $LOCAL_PORT"
            ;;
        *)
            echo "🧪 Windows/Other Quick Setup:"
            echo "  1. Settings > Network & Internet > Proxy"
            echo "  2. Enable 'Use a proxy server'"
            echo "  3. Address: 127.0.0.1, Port: $LOCAL_PORT"
            ;;
    esac

    echo
    read -p "📚 View detailed setup guide? [y/N]: " view_detailed
    if [[ "$view_detailed" =~ ^[Yy]$ ]]; then
        case "$os_type" in
            "Darwin")
                if [[ -f "README-macOS.md" ]]; then
                    print_status "Opening detailed macOS setup guide..."
                    if command -v less >/dev/null 2>&1; then
                        less "README-macOS.md"
                    else
                        cat "README-macOS.md" | head -100
                        echo
                        print_status "View full guide: cat README-macOS.md | less"
                    fi
                else
                    print_status "For detailed setup: https://github.com/mattbaya/tunnelcity"
                fi
                ;;
            "Linux")
                if [[ -f "README-Linux.md" ]]; then
                    print_status "Opening detailed Linux setup guide..."
                    if command -v less >/dev/null 2>&1; then
                        less "README-Linux.md"
                    else
                        cat "README-Linux.md" | head -100
                        echo
                        print_status "View full guide: cat README-Linux.md | less"
                    fi
                else
                    print_status "For detailed setup: https://github.com/mattbaya/tunnelcity"
                fi
                ;;
            *)
                print_status "For detailed Windows setup: https://github.com/mattbaya/tunnelcity"
                print_status "Or run: $0 docs"
                ;;
        esac
    else
        print_status "📌 Tip: Run '$0 docs' anytime for detailed guides"
        print_status "🌐 Online: https://github.com/mattbaya/tunnelcity"
    fi
    echo
}

# Function to offer documentation after successful operations
offer_documentation() {
    echo
    print_status "🎉 TunnelCity is now configured and ready to use!"
    echo
    echo "📖 Would you like to view setup documentation for:"
    echo "  1) System-wide proxy configuration (recommended)"
    echo "  2) Application-specific proxy setup"
    echo "  3) Troubleshooting guide"
    echo "  4) Skip documentation"
    echo
    read -p "Select an option [1-4]: " doc_option

    case "$doc_option" in
        "1")
            case "$(uname)" in
                "Darwin")
                    if [[ -f "README-macOS.md" ]]; then
                        print_status "Opening macOS proxy configuration guide..."
                        if command -v less >/dev/null 2>&1; then
                            less "README-macOS.md"
                        else
                            cat "README-macOS.md"
                        fi
                    fi
                    ;;
                "Linux")
                    if [[ -f "README-Linux.md" ]]; then
                        print_status "Opening Linux proxy configuration guide..."
                        if command -v less >/dev/null 2>&1; then
                            less "README-Linux.md"
                        else
                            cat "README-Linux.md"
                        fi
                    fi
                    ;;
                *)
                    print_status "For Windows, see README-Windows11.md for system proxy setup"
                    ;;
            esac
            ;;
        "2")
            if [[ -f "README.md" ]]; then
                print_status "Opening main documentation..."
                if command -v less >/dev/null 2>&1; then
                    less "README.md"
                else
                    cat "README.md"
                fi
            fi
            ;;
        "3")
            if [[ -f "TROUBLESHOOTING.md" ]]; then
                print_status "Opening troubleshooting guide..."
                if command -v less >/dev/null 2>&1; then
                    less "TROUBLESHOOTING.md"
                else
                    cat "TROUBLESHOOTING.md"
                fi
            fi
            ;;
        "4"|"")
            print_status "Documentation skipped. Run '$0 docs' anytime to view guides."
            ;;
        *)
            print_warning "Invalid option. Run '$0 docs' to view documentation later."
            ;;
    esac
    echo
}

# Function to prompt for configuration
prompt_for_config() {
    print_status "No .env file found. Let's set up your SSH tunnel configuration."
    echo

    read -p "SSH username: " SSH_USER_INPUT
    read -p "SSH server hostname/IP: " SSH_HOST_INPUT
    read -p "Local SOCKS port (suggested: 8080): " LOCAL_PORT_INPUT
    read -p "SSH key file path [~/.ssh/id_ed25519]: " SSH_KEY_INPUT

    # Set defaults
    LOCAL_PORT_INPUT=${LOCAL_PORT_INPUT:-8080}
    SSH_KEY_INPUT=${SSH_KEY_INPUT:-~/.ssh/id_ed25519}

    # Expand tilde
    SSH_KEY_INPUT=${SSH_KEY_INPUT/#\~/$HOME}

    # Create .env file
    cat > .env << EOF
# SSH Tunnel Configuration
SSH_USER=$SSH_USER_INPUT
SSH_HOST=$SSH_HOST_INPUT
LOCAL_PORT=$LOCAL_PORT_INPUT
SSH_KEY=$SSH_KEY_INPUT
EOF

    print_success "Configuration saved to .env file"
    echo

    # Offer to start tunnel immediately
    print_status "🚀 Configuration complete! Ready to start your SSH tunnel."
    echo
    read -p "Would you like to start the tunnel now? [Y/n]: " start_tunnel_now

    if [[ "$start_tunnel_now" =~ ^[Nn]$ ]]; then
        print_status "Configuration saved. Run '$0 start-bg' when you're ready to connect."
        exit 0
    else
        # Set a flag to indicate we should start the tunnel after config loading
        FIRST_RUN_START_TUNNEL=true
    fi
}

# Load configuration from .env file or prompt user
FIRST_RUN_START_TUNNEL=false
if [[ -f ".env" ]]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    prompt_for_config
    export $(cat .env | grep -v '^#' | xargs)
fi

# Configuration with defaults
SSH_USER="${SSH_USER:-user}"
SSH_HOST="${SSH_HOST:-server.com}"
LOCAL_PORT="${LOCAL_PORT:-8080}"
SSH_KEY="${SSH_KEY:-~/.ssh/id_ed25519}"

# Expand SSH key path
SSH_KEY=${SSH_KEY/#\~/$HOME}
TUNNEL_PID_FILE="/tmp/ssh_tunnel_${SSH_HOST}.pid"


# Function to check for port conflicts
check_port_conflicts() {
    local port="$LOCAL_PORT"
    local conflicts_found=false
    local process_info

    print_status "Checking for port conflicts on port $port..."

    # Check if port is in use
    if command -v lsof >/dev/null 2>&1; then
        process_info=$(lsof -ti:"$port" 2>/dev/null)
    elif command -v netstat >/dev/null 2>&1; then
        # Fallback to netstat if lsof not available
        process_info=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1)
    else
        print_warning "Unable to check port conflicts (lsof/netstat not available)"
        return 0
    fi

    if [[ -n "$process_info" ]]; then
        echo
        print_warning "Port $port is already in use!"
        echo
        echo "Processes using port $port:"

        # Show detailed process information
        for pid in $process_info; do
            if ps -p "$pid" >/dev/null 2>&1; then
                local process_details=$(ps -p "$pid" -o pid,ppid,user,command --no-headers 2>/dev/null)
                local process_user=$(echo "$process_details" | awk '{print $3}')
                local process_cmd=$(echo "$process_details" | awk '{for(i=4;i<=NF;i++) printf "%s ", $i; print ""}')

                echo "  PID: $pid | User: $process_user | Command: $process_cmd"

                # Check if it's an SSH tunnel
                if echo "$process_cmd" | grep -q "ssh.*-D.*$port"; then
                    echo "    ⚠️  This appears to be another SSH tunnel using the same port"
                    conflicts_found=true
                fi
            fi
        done

        echo
        read -p "Would you like to kill these processes? [y/N]: " kill_processes

        if [[ "$kill_processes" =~ ^[Yy]$ ]]; then
            local killed_any=false
            for pid in $process_info; do
                if ps -p "$pid" >/dev/null 2>&1; then
                    local process_user=$(ps -p "$pid" -o user --no-headers 2>/dev/null | tr -d ' ')
                    local current_user=$(whoami)

                    if [[ "$process_user" == "$current_user" ]] || [[ "$current_user" == "root" ]]; then
                        print_status "Attempting to kill process $pid (user: $process_user)..."

                        # Try graceful termination first
                        if kill "$pid" 2>/dev/null; then
                            sleep 2
                            if ps -p "$pid" >/dev/null 2>&1; then
                                print_warning "Process $pid didn't stop gracefully, forcing..."
                                kill -9 "$pid" 2>/dev/null
                            fi

                            if ! ps -p "$pid" >/dev/null 2>&1; then
                                print_success "Successfully killed process $pid"
                                killed_any=true
                            else
                                print_error "Failed to kill process $pid"
                            fi
                        else
                            print_error "Failed to send signal to process $pid"
                        fi
                    else
                        print_error "Cannot kill process $pid (owned by $process_user, you are $current_user)"
                        print_status "Try running with sudo or contact the process owner"
                    fi
                fi
            done

            if [[ "$killed_any" == "true" ]]; then
                sleep 1
                print_status "Rechecking port availability..."

                # Recheck if port is still in use
                if command -v lsof >/dev/null 2>&1; then
                    remaining_processes=$(lsof -ti:"$port" 2>/dev/null)
                else
                    remaining_processes=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1)
                fi

                if [[ -z "$remaining_processes" ]]; then
                    print_success "Port $port is now available!"
                    return 0
                else
                    print_warning "Some processes are still using port $port"
                    return 1
                fi
            else
                print_error "No processes were successfully killed"
                return 1
            fi
        else
            print_warning "Port conflict not resolved. Tunnel may fail to start."
            read -p "Continue anyway? [y/N]: " continue_anyway
            if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
                print_status "Operation cancelled by user"
                exit 1
            fi
            return 1
        fi
    else
        print_success "Port $port is available"
        return 0
    fi
}

# Function to check if tunnel is already running
check_tunnel_status() {
    if [[ -f "$TUNNEL_PID_FILE" ]]; then
        local pid=$(cat "$TUNNEL_PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            print_warning "Tunnel is already running (PID: $pid)"
            return 0
        else
            print_warning "Stale PID file found, removing..."
            rm -f "$TUNNEL_PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Function to start the tunnel
start_tunnel() {
    local background_mode=$1
    
    # Check for port conflicts before starting
    check_port_conflicts

    print_status "Starting SSH tunnel to $SSH_USER@$SSH_HOST..."
    print_status "Local SOCKS proxy will be available on 127.0.0.1:$LOCAL_PORT"
    
    if [[ "$background_mode" == "true" ]]; then
        # Background mode - first test the connection interactively to handle password prompts
        print_status "Testing SSH connection (may prompt for key passphrase)..."

        # Test connection first to handle any interactive prompts (like password/passphrase)
        echo
        print_status "Testing SSH connection - please enter your passphrase if prompted:"
        if ! ssh -i "$SSH_KEY" \
            -o ConnectTimeout=10 \
            -o UserKnownHostsFile=~/.ssh/known_hosts \
            -o StrictHostKeyChecking=yes \
            "$SSH_USER@$SSH_HOST" \
            "exit"; then
            echo
            print_error "SSH connection test failed. Please check your credentials and try again."
            return 1
        fi

        print_status "SSH connection verified. Starting tunnel in background..."

        # Now start the actual tunnel in background mode
        ssh -D "$LOCAL_PORT" -C -N -f \
            -i "$SSH_KEY" \
            -o ServerAliveInterval=60 \
            -o ServerAliveCountMax=3 \
            -o ExitOnForwardFailure=yes \
            -o LogLevel=ERROR \
            -o UserKnownHostsFile=~/.ssh/known_hosts \
            -o StrictHostKeyChecking=yes \
            "$SSH_USER@$SSH_HOST"
        
        local ssh_exit_code=$?
        if [[ $ssh_exit_code -eq 0 ]]; then
            # Find the SSH process PID
            local ssh_pid=$(ps aux | grep "ssh -D $LOCAL_PORT" | grep -v grep | awk '{print $2}' | head -n1)
            if [[ -n "$ssh_pid" ]]; then
                echo "$ssh_pid" > "$TUNNEL_PID_FILE"
                print_success "Tunnel started in background (PID: $ssh_pid)"
                print_status "Configure your applications to use SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"
                print_status "Run '$0 stop' to stop the tunnel"
                print_status "Run '$0 status' to check tunnel status"
            else
                print_error "Failed to find SSH process PID"
                return 1
            fi
        else
            print_error "Failed to start SSH tunnel (exit code: $ssh_exit_code)"
            return 1
        fi
    else
        # Foreground mode
        print_status "Running in foreground mode. Press Ctrl+C to stop."
        print_status "Configure your applications to use SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"

        # Start SSH tunnel once, handling passphrase interactively
        print_status "Starting SSH tunnel in interactive mode..."
        print_status "Configure your applications to use SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"
        echo
        print_status "Press Ctrl+C to stop the tunnel"
        echo

        # Run SSH in foreground to handle passphrase properly
        # This will block until the user presses Ctrl+C or the connection fails
        ssh -D "$LOCAL_PORT" -C -N \
            -i "$SSH_KEY" \
            -o ServerAliveInterval=60 \
            -o ServerAliveCountMax=3 \
            -o ExitOnForwardFailure=yes \
            -o LogLevel=ERROR \
            -o UserKnownHostsFile=~/.ssh/known_hosts \
            -o StrictHostKeyChecking=yes \
            "$SSH_USER@$SSH_HOST"
    fi
}

# Function to stop the tunnel
stop_tunnel() {
    if [[ -f "$TUNNEL_PID_FILE" ]]; then
        local pid=$(cat "$TUNNEL_PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            print_status "Stopping SSH tunnel (PID: $pid)..."
            kill "$pid"
            sleep 2
            if ps -p "$pid" > /dev/null 2>&1; then
                print_warning "Process didn't stop gracefully, forcing..."
                kill -9 "$pid"
            fi
            rm -f "$TUNNEL_PID_FILE"
            print_success "Tunnel stopped"
        else
            print_warning "Process with PID $pid not found"
            rm -f "$TUNNEL_PID_FILE"
        fi
    else
        print_warning "No tunnel PID file found. Trying to find and kill SSH processes..."
        pkill -f "ssh -D $LOCAL_PORT.*$SSH_USER@$SSH_HOST"
        print_status "Attempted to kill matching SSH processes"
    fi
}

# Function to show tunnel status
show_status() {
    if check_tunnel_status; then
        local pid=$(cat "$TUNNEL_PID_FILE")
        print_success "Tunnel is running (PID: $pid)"
        print_status "SOCKS5 proxy available at: 127.0.0.1:$LOCAL_PORT"
        
        # Test connectivity
        print_status "Testing external IP..."
        local external_ip=$(curl -s --socks5 "127.0.0.1:$LOCAL_PORT" ifconfig.me 2>/dev/null || echo "Unable to determine")
        print_status "Your apparent external IP: $external_ip"
    else
        print_warning "Tunnel is not running"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 {start|start-bg|stop|status|restart|test|docs|help}"
    echo ""
    echo "Commands:"
    echo "  start     - Start tunnel in foreground (interactive mode)"
    echo "  start-bg  - Start tunnel in background"
    echo "  stop      - Stop the tunnel"
    echo "  status    - Show tunnel status"
    echo "  restart   - Restart the tunnel in background"
    echo "  test      - Test the tunnel connection"
    echo "  docs      - Show available documentation"
    echo "  help      - Show this help message"
    echo ""
    echo "Configuration:"
    echo "  SSH User: $SSH_USER"
    echo "  SSH Host: $SSH_HOST"
    echo "  Local Port: $LOCAL_PORT"
    echo "  SSH Key: $SSH_KEY"
    echo ""
    echo "To use the tunnel, configure your applications to use:"
    echo "  SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"
    echo ""
    echo "Documentation:"
    echo "  Online: https://github.com/mattbaya/tunnelcity"
    echo "  Local:  $0 docs"
}

# Function to test connection inline (for interactive mode)
test_connection_inline() {
    print_status "Testing tunnel connection..."
    local test_result=$(curl -s --socks5 "127.0.0.1:$LOCAL_PORT" --connect-timeout 10 ifconfig.me 2>/dev/null)
    if [[ -n "$test_result" ]]; then
        print_success "Tunnel working! External IP: $test_result"
    else
        print_error "Tunnel test failed"
    fi
}

# Function to test the tunnel
test_tunnel() {
    if ! check_tunnel_status; then
        print_error "Tunnel is not running. Start it first with '$0 start-bg'"
        return 1
    fi

    print_status "Testing tunnel connection..."

    # Test SOCKS proxy
    local test_result=$(curl -s --socks5 "127.0.0.1:$LOCAL_PORT" --connect-timeout 10 ifconfig.me 2>/dev/null)
    if [[ -n "$test_result" ]]; then
        print_success "Tunnel is working! Your external IP appears as: $test_result"

        # Compare with direct connection
        local direct_ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "Unable to determine")
        print_status "Direct connection IP: $direct_ip"

        if [[ "$test_result" != "$direct_ip" ]]; then
            print_success "IP addresses are different - tunnel is working correctly!"
        else
            print_warning "IP addresses are the same - tunnel might not be working"
        fi
    else
        print_error "Tunnel test failed - unable to connect through proxy"
        return 1
    fi
}

# Handle first-run tunnel start
if [[ "$FIRST_RUN_START_TUNNEL" == "true" ]]; then
    echo
    print_status "Starting your tunnel in background mode..."
    echo

    # Check for existing tunnels
    if check_tunnel_status; then
        print_warning "A tunnel is already running. Use '$0 status' to check details."
        exit 0
    fi

    # Start the tunnel
    if start_tunnel true; then
        echo
        print_success "Tunnel started successfully!"
        offer_quick_start_guide
        touch ".tunnelcity_welcome_shown"
    else
        print_error "Failed to start tunnel. Check the error messages above."
        exit 1
    fi
    exit 0
fi

# Main script logic
case "$1" in
    "start")
        if check_tunnel_status; then
            exit 1
        fi
        start_tunnel false
        # Offer documentation after initial setup
        if [[ ! -f ".tunnelcity_welcome_shown" ]]; then
            offer_quick_start_guide
            touch ".tunnelcity_welcome_shown"
        fi
        ;;
    "start-bg")
        if check_tunnel_status; then
            exit 1
        fi
        start_tunnel true
        # Offer documentation for first-time background users
        if [[ ! -f ".tunnelcity_welcome_shown" ]] && [[ $? -eq 0 ]]; then
            echo
            print_success "Tunnel started in background!"
            offer_quick_start_guide
            touch ".tunnelcity_welcome_shown"
        fi
        ;;
    "stop")
        stop_tunnel
        ;;
    "status")
        show_status
        ;;
    "restart")
        print_status "Restarting tunnel..."
        stop_tunnel
        sleep 2
        start_tunnel true
        ;;
    "test")
        test_tunnel
        ;;
    "docs")
        show_documentation
        ;;
    "help")
        show_usage
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
