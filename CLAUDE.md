# TunnelCity - SSH SOCKS5 Tunnel Manager

Cross-platform SSH tunnel management scripts for creating SOCKS5 proxies.

## Project Structure

- `tunnelcity.sh` - Bash version for Unix/Linux/macOS
- `tunnelcity.ps1` - PowerShell version for Windows 11
- `README-Windows.md` - Windows-specific setup instructions
- `.env` - Configuration file (not tracked in git)

## Configuration

All SSH connection details should be stored in `.env` file:

```bash
SSH_USER=your_username
SSH_HOST=your_server
LOCAL_PORT=8080
```

## Development Guidelines

- Keep both bash and PowerShell versions feature-compatible
- Use environment variables for all server-specific configuration
- Test on target platforms before releasing
- Follow security best practices for SSH key management

## Features

- Cross-platform SSH tunnel management
- SOCKS5 proxy creation
- Background/foreground operation modes
- Process management and cleanup
- Connection testing and status monitoring
- Colored console output

## Security Notes

- Never commit SSH keys or server hostnames to the repository
- Use SSH key authentication only (no passwords)
- Validate all user inputs
- Clean up processes on exit