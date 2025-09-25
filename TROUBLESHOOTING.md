# TunnelCity Troubleshooting Guide

## SSH Channel Connection Errors

### Understanding "channel X: open failed: connect failed: Connection refused"

These errors are **normal** and occur when applications try to connect through your SOCKS proxy to destinations that refuse the connection. They are not failures of your tunnel itself.

#### What Causes These Errors:

1. **Remote servers blocking connections** - Many websites/services block certain connection attempts
2. **Non-existent services** - Applications trying to reach ports that aren't listening
3. **Firewall restrictions** - The remote server's firewall blocking outbound connections
4. **DNS/IP resolution issues** - Connections being made to incorrect addresses
5. **Advertisement/tracking blockers** - Browser extensions blocking ad domains
6. **Background app connections** - System apps making network requests through the proxy

#### Common Sources:
- **Web browsers**: Ad networks, analytics, CDNs that block certain connections
- **System updates**: macOS/Windows checking for updates through the proxy
- **Background apps**: Apps making API calls that fail through the proxy
- **DNS over HTTPS**: Browsers trying to use DoH servers that block proxy connections

### Suppressing Channel Error Messages

The updated scripts now include `-o LogLevel=ERROR` to reduce these messages. For complete suppression:

#### Method 1: Script-level Suppression (Recommended)
The new scripts already suppress most connection warnings while preserving important error messages.

#### Method 2: Complete SSH Output Suppression
If you still see too many messages, redirect SSH output:

**Bash version** - modify the SSH command:
```bash
ssh -D "$LOCAL_PORT" -C -N \
    -i "$SSH_KEY" \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -o LogLevel=QUIET \
    "$SSH_USER@$SSH_HOST" 2>/dev/null
```

**PowerShell version** - redirect stderr:
```powershell
& ssh -D $LOCAL_PORT -C -N -i $SSH_KEY -o LogLevel=QUIET "$SSH_USER@$SSH_HOST" 2>$null
```

#### Method 3: SSH Client Configuration
Add to `~/.ssh/config` (Unix) or `%USERPROFILE%\.ssh\config` (Windows):
```
Host your_server.com
    LogLevel ERROR
    # or LogLevel QUIET for complete suppression
```

### Monitoring What's Being Refused

To understand what connections are being refused, you can:

#### 1. Enable Detailed Logging Temporarily
```bash
# Run with verbose logging to see connection details
ssh -D 8080 -C -N -v your_user@your_server.com
```

#### 2. Use netstat to Monitor Local Connections
```bash
# macOS/Linux
netstat -an | grep :8080

# Windows
netstat -an | findstr :8080
```

#### 3. Check Server-Side Logs
On your SSH server:
```bash
# Check SSH daemon logs
sudo journalctl -u ssh -f

# Or traditional syslog
sudo tail -f /var/log/auth.log
```

#### 4. Use tcpdump/Wireshark for Network Analysis
```bash
# Capture traffic on the server (requires root)
sudo tcpdump -i any -n port 22

# Focus on refused connections
sudo tcpdump -i any -n 'tcp[tcpflags] & tcp-rst != 0'
```

### Reducing Refused Connections

#### 1. Browser Configuration
**Firefox**:
- Set `network.proxy.socks_remote_dns` to `true` in about:config
- This forces DNS resolution through the proxy

**Chrome**:
- Use `--host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE localhost"` flag
- This prevents local DNS leaks

#### 2. Application-Specific Configuration
Configure apps to:
- Use proxy for DNS resolution
- Exclude local/LAN addresses from proxy
- Set appropriate timeout values

#### 3. Server-Side Firewall Rules
If you control the SSH server, ensure it can make outbound connections:
```bash
# Allow outbound HTTP/HTTPS
sudo iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# Allow DNS
sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
```

## Other Common Issues

### SSH Connection Drops
**Symptoms**: Tunnel disconnects frequently
**Solutions**:
- Increase `ServerAliveInterval` (default: 60 seconds)
- Check network stability
- Verify SSH server configuration

### Port Already in Use
**Symptoms**: "bind: Address already in use"
**Solutions**:
```bash
# Find what's using the port
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows

# Kill the process or choose different port
```

### SSH Key Issues
**Symptoms**: Permission denied, authentication failures
**Solutions**:
```bash
# Check key permissions (macOS/Linux)
chmod 600 ~/.ssh/id_ed25519
chmod 700 ~/.ssh

# Test key authentication
ssh -i ~/.ssh/id_ed25519 -v user@server.com

# Add key to SSH agent
ssh-add ~/.ssh/id_ed25519
```

### DNS Resolution Problems
**Symptoms**: Some sites don't load, slow connections
**Solutions**:
- Configure applications to use remote DNS
- Check server's DNS configuration
- Try different DNS servers (8.8.8.8, 1.1.1.1)

### Network Changes (Laptops)
**Symptoms**: Tunnel stops working after switching networks
**Solutions**:
- Use the interactive mode with reconnect option
- Set up automatic restart scripts
- Configure network-aware tunnel management

## Getting Help

### Diagnostic Information to Collect
When seeking help, include:

1. **Operating system and version**
2. **SSH client version**: `ssh -V`
3. **Error messages** (with timestamps)
4. **Configuration** (sanitized .env file)
5. **Network environment** (home/work/public WiFi)
6. **Server accessibility**: `ssh -v user@server.com`

### Testing Commands
```bash
# Test direct SSH connection
ssh -v user@server.com

# Test SOCKS proxy
curl --socks5 127.0.0.1:8080 https://ifconfig.me

# Check tunnel status
./tunnelcity.sh status  # or .\tunnelcity.ps1 status

# Test with verbose SSH logging
ssh -D 8080 -v user@server.com
```

### Log Locations

**macOS**:
- System logs: Console.app or `log show --predicate 'process == "ssh"'`
- SSH client: No persistent logs by default

**Windows**:
- Event Viewer: Windows Logs > Application
- SSH client: No persistent logs by default

**Linux**:
- System logs: `journalctl -u ssh`
- User logs: `~/.ssh/` (if configured)

## Performance Optimization

### Reducing Connection Latency
- Use compression: `-C` flag (already enabled)
- Choose geographically closer servers
- Use faster SSH ciphers: `-c aes128-gcm@openssh.com`

### Bandwidth Management
- Monitor data usage through the tunnel
- Configure application-specific bandwidth limits
- Consider tunnel compression trade-offs

### Server Selection
- Choose servers with good international connectivity
- Prefer servers with minimal logging
- Consider multiple backup servers