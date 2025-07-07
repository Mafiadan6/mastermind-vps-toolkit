# 🚀 Mastermind VPS Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-5.3.0-blue.svg)](https://github.com/Mafiadan6/mastermind-vps-toolkit)
[![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian-orange.svg)](https://ubuntu.com/)

A comprehensive terminal-based VPS management toolkit designed for network administrators and system engineers. Provides powerful tools for SSH administration, proxy management, network optimization, and complete VPS setup with an enhanced interactive CLI experience.

## ✨ Features

### 🔒 **Complete Proxy Suite**
- **SOCKS5 Proxy** (Port 1080) - Standard proxy for apps & browsers
- **WebSocket Tunnel** (Port 8080) - For NPV Tunnel, HTTP Injector, etc.
- **HTTP Proxy** (Port 8888) - Web browser proxy with CONNECT support
- **Response Servers** (Ports 9000-9003) - MasterMind branded response ports

### 🌐 **Advanced Protocols**
- **V2Ray VLESS/VMESS** - Advanced proxy protocol with WebSocket support
- **SSH TLS Tunnel** (Port 443) - SSL/TLS encrypted SSH connections
- **Dropbear SSH** (Ports 444-445) - Lightweight SSH server
- **TCP Bypass** - Network optimization and traffic routing

### 👥 **User Management**
- SSH user creation optimized for mobile apps
- Usage limits with data/time/connection controls
- User activity monitoring and reporting
- Bulk user operations and permissions management

### 🔧 **System Administration**
- Network optimization (BBR, TCP tuning, UDP optimization)
- Security center (firewall, fail2ban, SSH hardening)
- SSL/TLS certificate management with Let's Encrypt
- Real-time system monitoring and diagnostics
- Complete backup and restore functionality

### 📱 **Mobile App Support**
Optimized configurations for popular mobile tunneling applications:
- **NPV Tunnel** - WebSocket configuration
- **HTTP Injector** - HTTP proxy setup
- **HTTP Custom** - Custom response configurations
- **TLS Tunnel** - SSL/TLS encryption support

## 🚀 Quick Installation

### Automatic Installation (Recommended)
```bash
# Download and run the installer
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/install.sh | sudo bash

# Or download first and inspect
wget https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/install.sh
sudo bash install.sh
```

### Manual Installation
```bash
# Clone the repository
git clone https://github.com/Mafiadan6/mastermind-vps-toolkit.git
cd mastermind-vps-toolkit

# Make installer executable and run
chmod +x install.sh
sudo ./install.sh
```

## 📋 System Requirements

- **Operating System**: Ubuntu 20.04+ or Debian 10+
- **RAM**: Minimum 512MB (1GB recommended)
- **CPU**: 1 vCPU minimum
- **Storage**: 2GB available space
- **Network**: Internet connection for installation
- **Privileges**: Root access (sudo)

## 🎯 Quick Start Guide

### 1. Access the Main Menu
```bash
# After installation, access the toolkit
mastermind

# Or use shortcuts
menu
mm
mvps
```

### 2. Mobile App Setup (Most Popular)
1. Choose **[9] Quick Setup Wizard**
2. Select **[1] Mobile Apps Setup**
3. Follow the step-by-step configuration
4. Get ready-to-use connection details

### 3. Create SSH Users
1. Choose **[1] User Administration**
2. Select **[1] Add SSH User**
3. Follow the mobile-friendly setup process
4. Get connection details for your tunneling apps

## 📱 Mobile App Configuration

### NPV Tunnel Configuration
```
Server Host: YOUR_VPS_IP
Server Port: 8080
Protocol: WebSocket
SSH Host: YOUR_VPS_IP
SSH Port: 443
Username: [your_username]
Password: [your_password]
```

### HTTP Injector Configuration
```
Proxy Type: HTTP
Server: YOUR_VPS_IP:8888
WebSocket: ws://YOUR_VPS_IP:8080
SSH Host: YOUR_VPS_IP:443
Username: [your_username] 
Password: [your_password]
```

### Browser Proxy Setup
```
SOCKS5: YOUR_VPS_IP:1080
HTTP: YOUR_VPS_IP:8888
```

## 🔧 Advanced Features

### V2Ray Management
- VLESS/VMESS protocol support
- WebSocket transport configuration
- Client configuration generation
- Domain and SSL integration

### Network Optimization
- **BBR Congestion Control** - Improved network performance
- **TCP Optimization** - Fast Open, window scaling, buffer tuning
- **UDP Optimization** - Enhanced UDP performance
- **Network Diagnostics** - Speed tests, connection monitoring

### Security Features
- **Firewall Management** - UFW integration with custom rules
- **Fail2ban Setup** - Intrusion prevention and IP blocking
- **SSH Hardening** - Key-only auth, port changes, timeouts
- **SSL/TLS Certificates** - Automated Let's Encrypt integration

### System Monitoring
- Real-time CPU, memory, and disk usage
- Active connection monitoring
- Service status checking
- Port availability monitoring
- Log analysis and viewing

## 🛠️ Service Management

### Start All Services
```bash
# Start the main proxy service
sudo systemctl start python-proxy

# Check service status
sudo systemctl status python-proxy

# View real-time logs
sudo journalctl -u python-proxy -f
```

### Port Status Check
```bash
# Check if all ports are listening
netstat -tuln | grep -E ':(1080|8080|8888|9000|9001|9002|9003) '

# Or use the built-in test script
python3 /opt/mastermind/test_proxy_setup.py
```

## 🔄 Maintenance

### Update Toolkit
```bash
# From the main menu: [11] Advanced Settings → [9] Update Toolkit
# Or manually:
cd /opt/mastermind && git pull
```

### Backup Configuration
```bash
# From the main menu: [7] Backup & Restore
# Creates backup of all configurations and user data
```

### View Logs
```bash
# Main toolkit logs
sudo tail -f /var/log/mastermind/mastermind.log

# Service logs
sudo journalctl -u python-proxy -f

# System logs
sudo tail -f /var/log/syslog
```

## 🔄 Reinstall & Uninstall

### Complete Reinstallation
```bash
# Download and run reinstall script
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/reinstall.sh | bash

# Or if already installed (from menu: [10] System Tools → [11])
sudo /opt/mastermind/reinstall.sh
```

### Complete Uninstallation
```bash
# Download and run uninstall script
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/uninstall.sh | bash

# Or if already installed (from menu: [10] System Tools → [10])
sudo /opt/mastermind/uninstall.sh
```

**What the uninstall script removes:**
- All proxy services and configurations
- Open ports closed and firewall rules removed
- SSH banners and MOTD restored
- User accounts and access removed
- System services and cron jobs removed
- Log files and backups deleted
- SSL certificates and configurations removed
- All toolkit files and directories deleted

Your system will be restored to its pre-installation state.

## 🧪 Testing Your Installation

### Automated Testing
```bash
# Run comprehensive test suite
python3 /opt/mastermind/test_proxy_setup.py
```

### Manual Testing
```bash
# Test SOCKS5 proxy
curl --socks5 YOUR_VPS_IP:1080 https://httpbin.org/ip

# Test HTTP proxy  
curl --proxy YOUR_VPS_IP:8888 https://httpbin.org/ip

# Test WebSocket connection
wscat -c ws://YOUR_VPS_IP:8080

# Check all open ports
sudo netstat -tulpn | grep LISTEN
```

## 📁 Project Structure

```
/opt/mastermind/
├── core/                 # Core system files
│   ├── menu.sh          # Main interactive menu
│   ├── helpers.sh       # Helper functions
│   ├── config.cfg       # Main configuration
│   └── service_ctl.sh   # Service control
├── protocols/           # Protocol implementations
│   ├── python_proxy.py  # Main proxy suite
│   ├── v2ray_manager.sh # V2Ray management
│   ├── domain_manager.sh # Domain & SSL
│   └── ssh_suite.sh     # SSH configurations
├── users/               # User management
│   ├── user_manager.sh  # SSH user creation
│   └── usage_limits.py  # Usage tracking
├── security/            # Security tools
│   ├── firewall_manager.sh
│   ├── fail2ban_setup.sh
│   └── audit_tool.sh
├── network/             # Network optimization
│   ├── bbr.sh
│   ├── kernel_tuning.sh
│   └── udp_optimizer.sh
└── branding/            # QR codes & branding
    ├── qr_generator.py
    └── response_servers.py
```

## 🐛 Troubleshooting

### Common Issues

**Services not starting:**
```bash
# Check service status
sudo systemctl status python-proxy

# Restart services
sudo systemctl restart python-proxy

# Check logs for errors
sudo journalctl -u python-proxy -n 50
```

**Ports not accessible:**
```bash
# Check if ports are listening
sudo netstat -tulpn | grep LISTEN

# Check firewall rules
sudo ufw status

# Test local connectivity
telnet localhost 1080
```

**SSH connection issues:**
```bash
# Verify SSH configuration
sudo ssh -p 443 username@localhost

# Check SSH logs
sudo tail -f /var/log/auth.log

# Restart SSH service
sudo systemctl restart ssh
```

### Performance Optimization

**Enable BBR (if not auto-enabled):**
```bash
echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
sysctl -p
```

**Optimize system for high connections:**
```bash
echo 'net.core.somaxconn = 65535' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog = 5000' >> /etc/sysctl.conf
sysctl -p
```

## 🤝 Contributing

We welcome contributions! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup
```bash
git clone https://github.com/Mafiadan6/mastermind-vps-toolkit.git
cd mastermind-vps-toolkit

# Test changes locally
sudo bash install.sh

# Run tests
python3 test_proxy_setup.py
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for the VPS and tunneling community
- Optimized for mobile tunneling applications
- Inspired by network administration best practices

## 📞 Support

- **GitHub Issues**: [Create an issue](https://github.com/Mafiadan6/mastermind-vps-toolkit/issues)
- **Documentation**: Check the `/docs` folder for detailed guides
- **Community**: Share your configurations and tips

---

**Made with ❤️ for the VPS community**

*Mastermind VPS Toolkit v5.3.0 - Complete VPS Management Solution*