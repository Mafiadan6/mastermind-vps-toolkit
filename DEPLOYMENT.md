# Deployment Guide - Mastermind VPS Toolkit

## GitHub Upload Instructions

### 1. Initialize Git Repository

```bash
# Navigate to your project directory
cd mastermind-vps-toolkit

# Initialize Git repository
git init

# Configure Git with your credentials
git config user.name "mafiadan6"
git config user.email "tyreakrobinson@gmail.com"

# Add all files to staging
git add .

# Create initial commit
git commit -m "Initial commit: Mastermind VPS Toolkit v1.0.0"
```

### 2. Create GitHub Repository

1. Go to [GitHub](https://github.com) and sign in with your account
2. Click the "+" icon in the top right corner
3. Select "New repository"
4. Set repository name: `mastermind-vps-toolkit`
5. Set description: "A comprehensive VPS management toolkit with web interface and terminal-based tools"
6. Make it Public (or Private if preferred)
7. **Do NOT** initialize with README, .gitignore, or license (we already have these)
8. Click "Create repository"

### 3. Upload to GitHub

```bash
# Add GitHub remote repository
git remote add origin https://github.com/mafiadan6/mastermind-vps-toolkit.git

# Push to GitHub
git branch -M main
git push -u origin main
```

If you encounter authentication issues, use your Personal Access Token:
- Username: `mafiadan6`
- Password: Your GitHub Personal Access Token (ghp_...)

## VPS Deployment Instructions

### System Requirements
- Ubuntu 20.04+ or Debian 10+
- Minimum: 1 vCPU, 512MB RAM, 10GB disk
- Recommended: 2 vCPU, 1GB RAM, 20GB disk
- Root or sudo access

### Quick VPS Setup

1. **Clone the repository on your VPS**
   ```bash
   git clone https://github.com/mafiadan6/mastermind-vps-toolkit.git
   cd mastermind-vps-toolkit
   ```

2. **Make installation script executable**
   ```bash
   chmod +x install.sh
   ```

3. **Run the installer**
   ```bash
   sudo ./install.sh
   ```

4. **Complete first-time setup**
   ```bash
   sudo /opt/mastermind/core/first_run.sh
   ```

5. **Access the management interface**
   ```bash
   sudo /opt/mastermind/core/menu.sh
   ```

### Advanced Configuration

#### Custom Port Configuration
Edit `/opt/mastermind/core/config.cfg` to modify default ports:
```bash
# Service Ports
SOCKS_PORT=8080          # SOCKS5 proxy port
HTTP_PROXY_PORT=8888     # HTTP proxy port  
WEBSOCKET_PORT=8443      # WebSocket proxy port
RESPONSE_PORTS=(80 443 8000 8080 9000)  # HTTP response server ports
```

#### Service Management
```bash
# Enable/disable specific services
sudo systemctl enable python-proxy
sudo systemctl enable tcp-bypass

# Configure autostart
sudo /opt/mastermind/core/service_ctl.sh enable-all
```

### Firewall Configuration

```bash
# Allow SSH, HTTP, HTTPS
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

# Allow VPS toolkit ports if needed
sudo ufw allow 8080  # SOCKS5
sudo ufw allow 8888  # HTTP Proxy
sudo ufw allow 8443  # WebSocket

# Enable firewall
sudo ufw --force enable
```

### Monitoring and Maintenance

1. **Check service status**
   ```bash
   sudo systemctl status mastermind-web
   sudo journalctl -u mastermind-web -f
   ```

2. **Monitor VPS services**
   ```bash
   sudo /opt/mastermind/core/menu.sh
   ```

3. **View logs**
   ```bash
   sudo tail -f /var/log/mastermind/*.log
   ```

4. **Run security audit**
   ```bash
   sudo /opt/mastermind/security/audit_tool.sh
   ```

### Troubleshooting

#### Common Issues

1. **Service won't start**
   - Check logs: `sudo journalctl -u mastermind-web -n 50`
   - Verify environment variables in `.env`
   - Ensure database is accessible

2. **Database connection errors**
   - Verify DATABASE_URL format
   - Check network connectivity to database
   - Ensure user has proper permissions

3. **Permission errors**
   - Check file ownership: `sudo chown -R www-data:www-data /path/to/project`
   - Verify service user has read access to files

4. **VPS toolkit services not starting**
   - Check Python dependencies: `pip3 list`
   - Verify service configuration files in `/etc/systemd/system/`
   - Check for port conflicts: `sudo netstat -tulpn | grep :8080`

### Security Best Practices

1. **Regular Updates**
   ```bash
   sudo apt update && sudo apt upgrade
   npm update
   ```

2. **Monitor Failed Login Attempts**
   ```bash
   sudo grep "Failed password" /var/log/auth.log | tail -10
   ```

3. **Regular Backups**
   ```bash
   # Database backup
   pg_dump mastermind > backup_$(date +%Y%m%d).sql
   
   # Configuration backup
   sudo tar -czf /tmp/mastermind_config_$(date +%Y%m%d).tar.gz /opt/mastermind/
   ```

4. **Fail2ban Setup**
   ```bash
   sudo /opt/mastermind/security/fail2ban_setup.sh
   ```

## Support

For deployment issues:
1. Check the logs first
2. Review the documentation
3. Create an issue on GitHub with:
   - Operating system details
   - Error messages
   - Steps to reproduce
   - Log excerpts