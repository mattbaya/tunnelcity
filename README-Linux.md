# TunnelCity Setup Guide - Linux

This guide covers setting up and using TunnelCity SSH tunnels on Linux, including system-wide and application-specific proxy configuration.

## Prerequisites

### 1. SSH Client (Pre-installed)
Most Linux distributions come with SSH pre-installed. Verify by running:
```bash
ssh -V
```

If not installed:
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install openssh-client

# CentOS/RHEL/Fedora
sudo yum install openssh-clients  # CentOS/RHEL 7
sudo dnf install openssh-clients  # Fedora/RHEL 8+

# Arch Linux
sudo pacman -S openssh
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
SSH_KEY=~/.ssh/id_ed25519
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

### System-Wide Proxy Configuration (Recommended)

#### Method 1: Environment Variables (Session-based)
```bash
# Enable SOCKS5 proxy for current session
export ALL_PROXY=socks5://127.0.0.1:8080
export all_proxy=socks5://127.0.0.1:8080
export HTTPS_PROXY=socks5://127.0.0.1:8080
export HTTP_PROXY=socks5://127.0.0.1:8080
export https_proxy=socks5://127.0.0.1:8080
export http_proxy=socks5://127.0.0.1:8080

# Disable proxy
unset ALL_PROXY all_proxy HTTPS_PROXY HTTP_PROXY https_proxy http_proxy

# Check current proxy settings
env | grep -i proxy
```

#### Method 2: Shell Profile (Persistent)
Add to `~/.bashrc`, `~/.zshrc`, or `~/.profile`:

```bash
# Proxy management functions
proxy_on() {
    export ALL_PROXY=socks5://127.0.0.1:8080
    export all_proxy=socks5://127.0.0.1:8080
    export HTTPS_PROXY=socks5://127.0.0.1:8080
    export HTTP_PROXY=socks5://127.0.0.1:8080
    export https_proxy=socks5://127.0.0.1:8080
    export http_proxy=socks5://127.0.0.1:8080
    echo "✅ SOCKS5 proxy enabled (127.0.0.1:8080)"
}

proxy_off() {
    unset ALL_PROXY all_proxy HTTPS_PROXY HTTP_PROXY https_proxy http_proxy
    echo "❌ Proxy disabled"
}

proxy_status() {
    if [ -n "$ALL_PROXY" ] || [ -n "$HTTP_PROXY" ]; then
        echo "🟢 Proxy is ENABLED"
        env | grep -i proxy
    else
        echo "🔴 Proxy is DISABLED"
    fi
}

# Usage:
# proxy_on    - Enable system proxy
# proxy_off   - Disable system proxy
# proxy_status - Check proxy status
```

Then reload your shell:
```bash
source ~/.bashrc  # or ~/.zshrc
```

#### Method 3: Desktop Environment Settings

#### GNOME (Ubuntu, Fedora, etc.)
```bash
# Command line configuration
gsettings set org.gnome.system.proxy mode 'manual'
gsettings set org.gnome.system.proxy.socks host '127.0.0.1'
gsettings set org.gnome.system.proxy.socks port 8080

# Disable proxy
gsettings set org.gnome.system.proxy mode 'none'

# Check current settings
gsettings get org.gnome.system.proxy mode
gsettings get org.gnome.system.proxy.socks host
gsettings get org.gnome.system.proxy.socks port
```

**GUI Method (GNOME)**:
1. **Settings** > **Network** > **Network Proxy**
2. Select **Manual**
3. Set **Socks Host**: `127.0.0.1`, **Port**: `8080`
4. Click **Apply**

#### KDE Plasma
```bash
# KDE uses different configuration
# Edit ~/.kde/share/config/kioslaverc or use System Settings

# GUI Method:
# System Settings > Network > Settings > Proxy
# Select "Use proxy server"
# Set SOCKS proxy: 127.0.0.1:8080
```

#### XFCE
**GUI Method**:
1. **Settings** > **Network** > **Proxy**
2. Select **Manual proxy configuration**
3. Set **SOCKS Host**: `127.0.0.1`, **Port**: `8080`

**Important Notes**:
- Environment variables (Method 1 & 2) work with most command-line applications
- Desktop environment settings (Method 3) work with GUI applications that respect system proxy
- Some applications may need individual configuration if they don't respect system settings


## Application-Specific Configuration

### Terminal Applications

**curl**:
```bash
curl --socks5 127.0.0.1:8080 https://ifconfig.me
```

**wget**:
```bash
# Use environment variables or add to ~/.wgetrc
echo "use_proxy=yes" >> ~/.wgetrc
echo "socks_proxy=127.0.0.1:8080" >> ~/.wgetrc
```

**git** (for GitHub/GitLab over SSH):
```bash
# Add to ~/.ssh/config
cat >> ~/.ssh/config << 'EOF'
Host github.com
    ProxyCommand nc -X 5 -x 127.0.0.1:8080 %h %p

Host gitlab.com
    ProxyCommand nc -X 5 -x 127.0.0.1:8080 %h %p
EOF
```

### Browsers

**Firefox (Recommended - Best SOCKS5 Support)**
1. **Preferences** > **Network Settings**
2. Select **Manual proxy configuration**
3. **SOCKS Host**: `127.0.0.1`, **Port**: `8080`
4. Select **SOCKS v5**
5. Check **Proxy DNS when using SOCKS v5**

**Chrome/Chromium**
```bash
# Launch with SOCKS proxy
google-chrome --proxy-server="socks5://127.0.0.1:8080"

# Create desktop entry for convenience
cat > ~/.local/share/applications/chrome-proxy.desktop << 'EOF'
[Desktop Entry]
Name=Chrome (Proxy)
Exec=google-chrome --proxy-server="socks5://127.0.0.1:8080"
Icon=google-chrome
Type=Application
Categories=Network;WebBrowser;
EOF
```

**Note**: Firefox has the best native SOCKS5 support of all browsers.


## Testing Your Setup

### Verify Proxy is Working
```bash
# Test with and without proxy
curl https://ifconfig.me
proxy_on
curl https://ifconfig.me
proxy_off

# Test SOCKS proxy directly
curl --socks5 127.0.0.1:8080 https://ifconfig.me
```

### DNS Testing
```bash
# Test DNS resolution through proxy
dig @8.8.8.8 google.com
proxy_on
dig @8.8.8.8 google.com
```

## Troubleshooting

### Common Issues

**Permission denied for SSH keys**:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

**Environment variables not working**:
```bash
# Check if variables are set
printenv | grep -i proxy

# Make sure to source your shell profile
source ~/.bashrc
```

**Desktop environment not respecting proxy**:
- Restart your session after changing proxy settings
- Some applications may need to be restarted
- Check if applications have their own proxy settings

### Log Locations
- SSH client: No persistent logs by default
- System logs: `journalctl` or `/var/log/`
- Desktop environment logs: `~/.xsession-errors`

## Security Considerations

### SSH Key Security
```bash
# Proper permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Use SSH agent
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
```

### Firewall Configuration
```bash
# UFW (Ubuntu)
sudo ufw allow out 8080

# iptables
sudo iptables -A OUTPUT -p tcp --dport 8080 -j ACCEPT
```

## Useful External Resources

- **SSH Tunneling Guide**: https://www.ssh.com/academy/ssh/tunneling
- **ProxyChains Tutorial**: https://github.com/rofl0r/proxychains-ng
- **Linux Network Configuration**: https://wiki.archlinux.org/title/Proxy_server
- **GNOME Network Settings**: https://help.gnome.org/users/gnome-help/stable/net-proxy.html.en