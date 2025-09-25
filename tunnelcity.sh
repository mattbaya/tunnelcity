#!/bin/bash

# SSH Tunnel Script
# Routes HTTP/HTTPS traffic through remote SSH server

# Function to prompt for configuration
prompt_for_config() {
    print_status "No .env file found. Let's set up your SSH tunnel configuration."
    echo

    read -p "SSH username: " SSH_USER_INPUT
    read -p "SSH server hostname/IP: " SSH_HOST_INPUT
    read -p "Local SOCKS port [8080]: " LOCAL_PORT_INPUT
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
}

# Load configuration from .env file or prompt user
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
    
    print_status "Starting SSH tunnel to $SSH_USER@$SSH_HOST..."
    print_status "Local SOCKS proxy will be available on 127.0.0.1:$LOCAL_PORT"
    
    if [[ "$background_mode" == "true" ]]; then
        # Background mode
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
        # Interactive mode with menu
        while true; do
            print_status "Starting SSH tunnel in interactive mode..."
            print_status "Configure your applications to use SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"
            echo

            # Start SSH with error suppression for cleaner output
            ssh -D "$LOCAL_PORT" -C -N \
                -i "$SSH_KEY" \
                -o ServerAliveInterval=60 \
                -o ServerAliveCountMax=3 \
                -o ExitOnForwardFailure=yes \
                -o LogLevel=ERROR \
                -o UserKnownHostsFile=~/.ssh/known_hosts \
                -o StrictHostKeyChecking=yes \
                "$SSH_USER@$SSH_HOST" &

            local ssh_pid=$!

            # Wait a moment to see if SSH starts successfully
            sleep 2
            if ! ps -p "$ssh_pid" > /dev/null 2>&1; then
                print_error "SSH connection failed. Check your configuration."
                return 1
            fi

            print_success "SSH tunnel established (PID: $ssh_pid)"
            echo
            print_warning "Tunnel Menu:"
            echo "  [Enter] - Show this menu"
            echo "  r - Reconnect (useful after network changes)"
            echo "  t - Test tunnel connection"
            echo "  s - Show tunnel status"
            echo "  q - Quit and disconnect"
            echo

            # Wait for tunnel to disconnect or user input
            while ps -p "$ssh_pid" > /dev/null 2>&1; do
                read -t 1 -n 1 user_input
                if [[ $? -eq 0 ]]; then
                    case "$user_input" in
                        "r")
                            print_status "Reconnecting tunnel..."
                            kill "$ssh_pid" 2>/dev/null
                            wait "$ssh_pid" 2>/dev/null
                            break
                            ;;
                        "t")
                            echo
                            test_connection_inline
                            echo
                            ;;
                        "s")
                            echo
                            print_success "Tunnel is running (PID: $ssh_pid)"
                            print_status "SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"
                            echo
                            ;;
                        "q")
                            print_status "Disconnecting tunnel..."
                            kill "$ssh_pid" 2>/dev/null
                            wait "$ssh_pid" 2>/dev/null
                            print_success "Tunnel disconnected"
                            return 0
                            ;;
                        "")
                            echo
                            print_warning "Tunnel Menu:"
                            echo "  [Enter] - Show this menu"
                            echo "  r - Reconnect (useful after network changes)"
                            echo "  t - Test tunnel connection"
                            echo "  s - Show tunnel status"
                            echo "  q - Quit and disconnect"
                            echo
                            ;;
                    esac
                fi
            done

            # If we get here, SSH disconnected unexpectedly
            print_warning "SSH connection lost. Attempting to reconnect in 3 seconds..."
            print_status "Press 'q' and Enter to quit instead of reconnecting."

            read -t 3 -n 1 user_input
            if [[ "$user_input" == "q" ]]; then
                print_status "User requested quit"
                return 0
            fi
        done
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
    echo "Usage: $0 {start|start-bg|stop|status|restart|test}"
    echo ""
    echo "Commands:"
    echo "  start     - Start tunnel in foreground (interactive mode)"
    echo "  start-bg  - Start tunnel in background"
    echo "  stop      - Stop the tunnel"
    echo "  status    - Show tunnel status"
    echo "  restart   - Restart the tunnel in background"
    echo "  test      - Test the tunnel connection"
    echo ""
    echo "Configuration:"
    echo "  SSH User: $SSH_USER"
    echo "  SSH Host: $SSH_HOST"
    echo "  Local Port: $LOCAL_PORT"
    echo ""
    echo "To use the tunnel, configure your applications to use:"
    echo "  SOCKS5 proxy: 127.0.0.1:$LOCAL_PORT"
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

# Main script logic
case "$1" in
    "start")
        if check_tunnel_status; then
            exit 1
        fi
        start_tunnel false
        ;;
    "start-bg")
        if check_tunnel_status; then
            exit 1
        fi
        start_tunnel true
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
    *)
        show_usage
        exit 1
        ;;
esac
