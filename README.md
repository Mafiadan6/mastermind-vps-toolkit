# 🚀 Mastermind VPS Toolkit

A comprehensive terminal-based VPS management toolkit designed for network administrators and system engineers. Provides powerful tools for SSH administration, proxy services, network optimization, and advanced protocol management.

[![Version](https://img.shields.io/badge/version-4.0.0-blue.svg)](https://github.com/Mafiadan6/mastermind-vps-toolkit)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian-orange.svg)](https://github.com/Mafiadan6/mastermind-vps-toolkit)

## 📋 Table of Contents

- [Features](#-features)
- [Quick Installation](#-quick-installation)
- [System Requirements](#-system-requirements)
- [Usage](#-usage)
- [Port Configuration](#-port-configuration)
- [User Management](#-user-management)
- [Protocols Supported](#-protocols-supported)
- [Security Features](#-security-features)
- [Documentation](#-documentation)
- [Support](#-support)

## ✨ Features

### 🔐 User Management
- **SSH User Creation** with proper credential display and connection info
- **Usage Limits System** with data (GB), time (days), and connection limits
- **Automatic Enforcement** - users disabled when limits exceeded
- **Real-time Monitoring** of user activity and resource usage

### 🌐 Protocol Support
- **SOCKS5 Proxy** (Port 1080) - Standard proxy protocol
- **WebSocket Proxy** (Port 8080) - For modern web applications
- **HTTP Proxy** (Port 8888) - Traditional HTTP proxy
- **SSH Server Responses** - Custom responses for tunneling apps
- **V2Ray VLESS/VMESS** - Advanced proxy protocol
- **TCP Bypass** - Network optimization

### 🛡️ Security & Monitoring
- **Fail2Ban Integration** - Automated intrusion prevention
- **UFW Firewall Management** - Simple firewall configuration
- **SSH Hardening** - Security best practices
- **Real-time System Monitoring** - CPU, memory, disk usage

### 🎨 Advanced Features
- **QR Code Generation** - Connection configs for mobile apps
- **Custom SSH Responses** - For tunneling apps like NPV Tunnel
- **Network Optimization** - BBR, kernel tuning, UDP optimization
- **Service Management** - systemd integration
- **Clean Terminal UI** - Modern, non-overlapping menu system

## 🚀 Quick Installation

### One-Line Install
```bash
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/install.sh | sudo bash
```

### Manual Installation
```bash
# Download and extract
wget https://github.com/Mafiadan6/mastermind-vps-toolkit/archive/main.zip
unzip main.zip
cd mastermind-vps-toolkit-main

# Run installer
sudo bash install.sh
```

### Post-Installation
```bash
# Start the menu system
sudo mastermind

# Or run directly
sudo /opt/mastermind/core/menu.sh
```

## 📊 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04+ or Debian 10+
- **RAM**: 512 MB (1 GB recommended)
- **CPU**: 1 vCPU
- **Storage**: 1 GB free space
- **Network**: Public IP address

### Recommended Setup
- **OS**: Ubuntu 22.04 LTS
- **RAM**: 2 GB
- **CPU**: 2 vCPU
- **Storage**: 5 GB SSD
- **Network**: Unmetered bandwidth

## 🎯 Usage

### Starting the Toolkit
```bash
# Launch main menu
sudo mastermind
```

### Common Tasks

#### Creating SSH Users with Limits
```bash
# Interactive SSH user creation
sudo /opt/mastermind/users/user_manager.sh add_user

# CLI user creation with limits
python3 /opt/mastermind/users/usage_limits.py add_user username ssh 10 30 5
```

#### Managing Services
```bash
# Check proxy status
sudo systemctl status python-proxy

# Restart services
sudo systemctl restart python-proxy v2ray nginx
```

#### Monitoring Usage
```bash
# Check user usage
python3 /opt/mastermind/users/usage_limits.py get_report

# Monitor specific user
python3 /opt/mastermind/users/usage_limits.py get_report username
```

## 🔌 Port Configuration

### Core Services
| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| SOCKS5 Proxy | 1080 | TCP | Standard SOCKS5 proxy |
| WebSocket Proxy | 8080 | TCP/WS | WebSocket tunneling |
| HTTP Proxy | 8888 | TCP | HTTP proxy service |

### SSH Server Responses
These ports serve SSH server responses for tunneling apps:
| Port | Response Type | Apps |
|------|---------------|------|
| 80 | SSH-2.0-dropbear_2020.81 | NPV Tunnel, HTTP Custom |
| 8080 | HTTP/1.1 101 with styling | HTTP Injector |
| 8888 | Full styled server message | Custom tunneling apps |
| 443 | HTTP/1.1 101 with styling | HTTPS tunneling |

### Protocol Services
| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| V2Ray VLESS | 80 | TCP | V2Ray protocol |
| SSH TLS | 443 | TCP | SSH over TLS |
| Dropbear | 444,445 | TCP | Alternative SSH |

## 👥 User Management

### SSH User Creation
The toolkit provides enhanced SSH user creation with:
- **Visual credential display** with connection information
- **Automatic usage limits** integration
- **Complete connection details** including SSH commands
- **Professional formatting** for easy copying

### Usage Limits System
- **Data Limits**: Set per-user data usage limits in GB
- **Time Limits**: Account validity periods in days
- **Connection Limits**: Maximum concurrent connections
- **Automatic Enforcement**: Users automatically disabled when limits exceeded
- **Real-time Tracking**: Monitor usage and sessions

### Example Usage Limits
```bash
# Add user with 10GB, 30 days, 5 connections
python3 /opt/mastermind/users/usage_limits.py add_user john ssh 10 30 5

# Check user limits
python3 /opt/mastermind/users/usage_limits.py check_limits john

# Generate usage report
python3 /opt/mastermind/users/usage_limits.py get_report
```

## 🌐 Protocols Supported

### Primary Protocols
- **SOCKS5** - Industry standard proxy protocol
- **WebSocket** - Modern web tunneling
- **HTTP Proxy** - Traditional web proxy
- **V2Ray VLESS/VMESS** - Advanced proxy with encryption

### SSH Ecosystem
- **OpenSSH** - Standard SSH server
- **Dropbear** - Lightweight SSH server
- **SSH TLS** - SSH over TLS tunnel

### Additional Features
- **TCP Bypass** - Network optimization
- **BadVPN** - VPN solution
- **Squid Proxy** - High-performance HTTP proxy

## 🛡️ Security Features

### Built-in Security
- **Fail2Ban** - Automatic IP blocking for failed attempts
- **UFW Firewall** - Simple firewall management
- **SSH Key Management** - Secure authentication
- **User Isolation** - Proper permission management

### Network Security
- **Port Management** - Controlled port access
- **Connection Monitoring** - Real-time connection tracking
- **Usage Auditing** - Comprehensive logging
- **Intrusion Detection** - Automated threat detection

## 📚 Documentation

### Configuration Files
- `core/config.cfg` - Main configuration
- `users/usage_limits.py` - Usage tracking system
- `python-proxy.service` - systemd service configuration

### Log Files
- `/var/log/mastermind/` - Main log directory
- `/var/log/mastermind/usage-limits.log` - Usage tracking logs
- `/var/log/mastermind/user-management.log` - User management logs

### Key Scripts
- `core/menu.sh` - Main menu system (fixed layout)
- `users/user_manager.sh` - User management
- `protocols/python_proxy.py` - Proxy services
- `install.sh` - Installation script

## 🔧 Troubleshooting

### Common Issues

#### Service Not Starting
```bash
# Check service status
sudo systemctl status python-proxy

# Check logs
sudo journalctl -u python-proxy -f

# Restart service
sudo systemctl restart python-proxy
```

#### Port Conflicts
```bash
# Check port usage
sudo netstat -tuln | grep -E ':(1080|8080|8888)'

# Kill conflicting processes
sudo fuser -k 8080/tcp
```

#### Usage Limits Not Working
```bash
# Check database
python3 /opt/mastermind/users/usage_limits.py get_report

# Reset user limits
python3 /opt/mastermind/users/usage_limits.py add_user username ssh 10 30 5
```

## 🤝 Support

### Getting Help
- **GitHub Issues**: [Report bugs and feature requests](https://github.com/Mafiadan6/mastermind-vps-toolkit/issues)
- **Telegram**: Contact @bitcockli for support
- **Documentation**: Check `/opt/mastermind/` directory for detailed docs

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Reporting Issues
Please include:
- OS version and architecture
- Error messages or logs
- Steps to reproduce
- Expected vs actual behavior

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for network administrators and system engineers
- Designed for production VPS environments
- Optimized for Ubuntu 22.04 LTS
- Community-driven development

---

**Mastermind VPS Toolkit v4.0.0** - Advanced VPS Management Made Simple