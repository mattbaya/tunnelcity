# TunnelCity Setup Guide - macOS

This guide covers setting up and using TunnelCity SSH tunnels on macOS, including system-wide and application-specific proxy configuration.

## Prerequisites

### 1. SSH Client (Pre-installed)
macOS comes with SSH pre-installed. Verify by running:
```bash
ssh -V
```

### 2. SSH Key Setup
Generate and configure SSH keys for passwordless authentication:

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -b 4096 -f ~/.ssh/id_ed25519

# Copy public key to remote server
ssh-copy-id -i ~/.ssh/id_ed25519.pub your_username@your_server.com

# Test connection
ssh your_username@your_server.com
```

## TunnelCity Configuration

1. Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
nano .env  # or use your preferred editor
```

2. Update `.env` with your details:
```bash
SSH_USER=your_username
SSH_HOST=your_server.com
LOCAL_PORT=8080
```

3. Make the script executable:
```bash
chmod +x tunnelcity.sh
```

## Using the SOCKS5 Proxy

Once your tunnel is running (`./tunnelcity.sh start-bg`), configure applications to use:
- **Proxy Type**: SOCKS5
- **Host**: 127.0.0.1
- **Port**: 8080 (or your configured port)

### System-Wide Proxy Configuration

#### Method 1: System Preferences GUI
1. Open **System Preferences** > **Network**
2. Select your active network connection (Wi-Fi or Ethernet)
3. Click **Advanced..** > **Proxies** tab
4. Check **SOCKS Proxy**
5. Enter:
   - **SOCKS Proxy Server**: `127.0.0.1:8080`
   - **Bypass proxy settings**: Add local addresses like `*.local, 169.254/16`
6. Click **OK** > **Apply**

#### Method 2: Command Line (networksetup)
```bash
# Enable SOCKS proxy on Wi-Fi
sudo networksetup -setsocksfirewallproxy Wi-Fi 127.0.0.1 8080

# Enable SOCKS proxy on Ethernet
sudo networksetup -setsocksfirewallproxy Ethernet 127.0.0.1 8080

# Disable SOCKS proxy
sudo networksetup -setsocksfirewallproxystate Wi-Fi off
```

### Application-Specific Configuration

#### Safari
Uses system proxy settings automatically when configured above.

#### Chrome/Chromium
```bash
# Launch with SOCKS proxy
/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome \\
  --proxy-server="socks5://127.0.0.1:8080"

# Create an alias for convenience
echo 'alias chrome-proxy="/Applications/Google\\\\ Chrome.app/Contents/MacOS/Google\\\\ Chrome --proxy-server=socks5://127.0.0.1:8080"' >> ~/.zshrc
source ~/.zshrc
```

#### Firefox
1. **Firefox** > **Preferences** > **Network Settings**
2. Select **Manual proxy configuration**
3. **SOCKS Host**: `127.0.0.1`, **Port**: `8080`
4. Select **SOCKS v5**
5. Check **Proxy DNS when using SOCKS v5**
6. Click **OK**

#### Terminal Applications

**curl**:
```bash
curl --socks5 127.0.0.1:8080 https://ifconfig.me
```

**wget**:
```bash
# Add to ~/.wgetrc
echo "use_proxy=yes" >> ~/.wgetrc
echo "socks_proxy=127.0.0.1:8080" >> ~/.wgetrc
```

**git** (for GitHub/GitLab over SSH):
```bash
# Add to ~/.ssh/config
echo "Host github.com" >> ~/.ssh/config
echo "  ProxyCommand nc -X 5 -x 127.0.0.1:8080 %h %p" >> ~/.ssh/config
```

### Third-Party Proxy Tools

#### Proxyman (GUI Proxy Manager)
- Download: https://proxyman.io/
- Easy switching between proxy configurations
- Visual traffic inspection

#### ProxyChains (Command Line)
```bash
# Install via Homebrew
brew install proxychains-ng

# Configure /usr/local/etc/proxychains.conf
echo "socks5 127.0.0.1 8080" >> /usr/local/etc/proxychains.conf

# Use with any command
proxychains4 curl https://ifconfig.me
```

## Network Change Handling

### Automatic Reconnection
For laptops that change networks frequently, consider:

1. **Create a LaunchAgent** for automatic startup:
```bash
mkdir -p ~/Library/LaunchAgents

cat > ~/Library/LaunchAgents/com.user.tunnelcity.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.tunnelcity</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/tunnelcity.sh</string>
        <string>start-bg</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>NetworkState</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# Load the agent
launchctl load ~/Library/LaunchAgents/com.user.tunnelcity.plist
```

2. **Network Location Automation**:
   - System Preferences > Network > Location
   - Create different locations for Home/Work/etc.
   - Use scripts to auto-switch proxy settings per location

### Manual Network Change Recovery
When changing networks, you may need to:
```bash
# Stop and restart tunnel
./tunnelcity.sh restart

# Or use the new interactive menu (updated script)
./tunnelcity.sh start  # Will show reconnection menu
```

## Testing Your Setup

### Verify Tunnel is Working
```bash
# Check your IP through the tunnel
curl --socks5 127.0.0.1:8080 https://ifconfig.me

# Compare with direct IP
curl https://ifconfig.me

# Test DNS resolution through tunnel
curl --socks5 127.0.0.1:8080 https://whatismyipaddress.com
```

### Browser Testing
1. Visit https://whatismyipaddress.com with and without proxy
2. IP addresses should be different
3. Location should show your server's location

## Troubleshooting

### SSH Connection Issues
```bash
# Test direct SSH connection
ssh -v your_username@your_server.com

# Check SSH agent
ssh-add -l

# Add key if needed
ssh-add ~/.ssh/id_ed25519
```

### Proxy Not Working
```bash
# Check if tunnel is running
./tunnelcity.sh status

# Test SOCKS proxy directly
nc -z 127.0.0.1 8080

# Check what's listening on port 8080
lsof -i :8080
```

### DNS Issues
If websites load slowly or fail:
1. Clear DNS cache: `sudo dscacheutil -flushcache`
2. Try different DNS servers in Network preferences
3. Use `dig @8.8.8.8 example.com` to test DNS resolution

## Security Considerations

### SSH Key Security
```bash
# Proper permissions for SSH keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Firewall Configuration
```bash
# Allow SSH tunnel port in macOS firewall
sudo pfctl -f /etc/pf.conf
```

### VPN Compatibility
- Some VPNs may conflict with SOCKS proxies
- Try connecting tunnel before or after VPN connection
- Consider split-tunneling if available

## Useful External Resources

- **SSH Tunneling Guide**: https://www.ssh.com/academy/ssh/tunneling
- **macOS Network Configuration**: https://support.apple.com/guide/mac-help/set-up-a-proxy-server-mchlp2591/mac
- **ProxyChains Tutorial**: https://github.com/rofl0r/proxychains-ng
- **SSH Config Best Practices**: https://www.ssh.com/academy/ssh/config
- **macOS LaunchAgents**: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html