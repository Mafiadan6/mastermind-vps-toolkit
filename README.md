# 🎯 Mastermind VPS Toolkit

<div align="center">

![Version](https://img.shields.io/badge/version-3.0.0-brightgreen.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian-orange.svg)
![Shell](https://img.shields.io/badge/shell-bash-lightgrey.svg)

**A comprehensive terminal-based VPS management toolkit designed for advanced network administrators and system engineers.**

*Modern • Colorful • User-Friendly • Powerful*

</div>

---

## ✨ What's New in v3.0.0

🎨 **Complete UI/UX Redesign**
- Modern colorful interface with bright color schemes
- Numbered menu options with visual icons (📋 🚀 ⚡ 👥 🔒)
- Enhanced progress bars with real-time visual feedback
- Professional dashboard layout with organized sections

🔧 **Enhanced Functionality**
- Fixed arithmetic errors in system monitoring
- Improved service status indicators with color coding
- Added Quick Actions menu for common tasks
- Real-time system monitoring with auto-refresh

💡 **User Experience Improvements**
- Clear numbered navigation (1-9, A, R, 0)
- Visual status indicators for all services
- Better error handling and user feedback
- Responsive design that works on any terminal size

---

## 🚀 Key Features

### 🎮 Interactive Interface
- **Modern Terminal UI**: Colorful, intuitive menu system with numbered options
- **Real-time Monitoring**: Live system metrics with visual progress bars
- **Smart Navigation**: Easy-to-use numbered menus with icons and descriptions
- **Quick Actions**: One-click access to common administrative tasks

### 🌐 Network Protocols
- **Python Proxy Suite**: SOCKS5, HTTP, WebSocket proxies with custom branding
- **V2Ray Integration**: VLESS, VMESS, Trojan protocols with TLS encryption
- **SSH Ecosystem**: Enhanced SSH, Dropbear, SSH-UDP tunneling solutions
- **TCP Bypass**: High-performance TCP proxy and bypass technologies
- **BadVPN Support**: UDP over TCP tunneling for enhanced connectivity

### ⚡ Performance Optimization
- **BBR Congestion Control**: Latest TCP BBR algorithm for better throughput
- **Kernel Tuning**: Advanced kernel parameter optimization
- **UDP Enhancement**: Optimized UDP performance settings
- **Memory Management**: Intelligent resource allocation and monitoring

### 🔒 Security Arsenal
- **Advanced User Management**: SSH key generation, user administration
- **Intelligent Firewall**: UFW integration with custom security rules
- **Fail2ban Protection**: Automated intrusion prevention and blocking
- **Security Auditing**: Comprehensive system security assessment

### 🎨 Branding & Customization
- **Custom Server Branding**: Personalized banners and server identity
- **QR Code Generation**: Dynamic QR codes for easy connection sharing
- **Multi-port Servers**: Custom HTTP response servers with branding
- **Logo Integration**: Add your logo to QR codes and interfaces

---

## 📋 System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Ubuntu 20.04+ / Debian 10+ | Ubuntu 22.04 LTS |
| **RAM** | 512MB | 1GB+ |
| **Storage** | 2GB free space | 5GB+ |
| **CPU** | 1 vCPU | 2+ vCPU |
| **Network** | Internet connectivity | Stable connection |
| **Access** | Root privileges | Dedicated admin user |

---

## ⚡ Quick Start

### 🚀 One-Line Installation
```bash
curl -sSL https://raw.githubusercontent.com/mafiadan6/mastermind-vps-toolkit/main/install.sh | sudo bash
```

### 📦 Manual Installation
```bash
# 1. Clone the repository
git clone https://github.com/mafiadan6/mastermind-vps-toolkit.git
cd mastermind-vps-toolkit

# 2. Make installer executable and run
chmod +x install.sh
sudo ./install.sh

# 3. Initialize the system
sudo /opt/mastermind/core/first_run.sh

# 4. Launch the management interface
sudo /opt/mastermind/core/menu.sh
```

### 🎯 Quick Access
```bash
# Create convenient alias
echo 'alias mastermind="sudo /opt/mastermind/core/menu.sh"' >> ~/.bashrc
source ~/.bashrc

# Now simply run:
mastermind
```

---

## 🎮 Usage Guide

### 🏠 Main Menu Navigation

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                            📋 MAIN NAVIGATION MENU                            ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  [1] 🚀 Protocol Management     [2] ⚡ Network Optimization     ║
║      SOCKS5, V2Ray, SSH Suite           BBR, Kernel Tuning, UDP        ║
║                                                                               ║
║  [3] 👥 User Administration     [4] 🔒 Security Center         ║
║      Add/Remove Users, SSH Keys          Firewall, Fail2ban, Audit      ║
║                                                                               ║
║  [5] 📊 System Monitoring       [6] 🎨 Branding & QR Codes    ║
║      Logs, Performance, Alerts          Custom Banners, QR Generator    ║
║                                                                               ║
║  [9] 📱 Quick Actions           [A] 🔧 Advanced Settings       ║
║      Common Tasks, Shortcuts            Expert Configuration            ║
║                                                                               ║
║  [R] 🔄 Refresh Display         [0] ❌ Exit Dashboard         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

### 📱 Quick Actions Menu

Access common tasks instantly:

- **🔄 Restart All Services** - Restart critical system services
- **📊 System Health Check** - Comprehensive system diagnostics
- **🧹 Clear System Logs** - Clean up log files and free space
- **🚀 Performance Boost** - Apply system optimizations
- **🔐 Generate SSH Keys** - Create new SSH key pairs
- **📋 Show Connection QR** - Display connection QR codes
- **🌐 Update System** - System package updates
- **📈 Real-time Monitor** - Live system monitoring

### 🎨 Visual Features

**System Performance Dashboard**
```
┌─ System Performance ─────────────────────────────────────────────────────────┐
│ CPU Usage:    [████████░░░░░░░░░░░░░░░]   32.4%                              │
│ Memory:       [██████████░░░░░░░░░░░░░]   41.2%                              │
│ Disk /:       [███░░░░░░░░░░░░░░░░░░░░░]   12%                               │
│                                                                               │
│ Load Average: 0.45, 0.32, 0.28          Uptime: 2 days, 14 hours           │
│ SSH Users:    3                          Processes: 156                      │
│ Open Ports:   8                                                              │
└───────────────────────────────────────────────────────────────────────────────┘
```

**Service Status Indicators**
```
┌─ Service Status ─────────────────────────────────────────────────────────────┐
│ ssh                  ● Running                                               │
│ nginx                ● Running                                               │
│ fail2ban             ● Running                                               │
│ ufw                  ● Running                                               │
│ python-proxy         ● Stopped                                               │
│ tcp-bypass           ● Running                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Component Overview

### 🐍 Python Proxy Suite
```python
# Advanced proxy implementations
- SOCKS5 Proxy with authentication
- HTTP/HTTPS proxy with CONNECT support  
- WebSocket to TCP proxy bridge
- Custom branded HTTP response servers
```

### 🌐 Network Protocols
- **V2Ray**: Modern proxy protocol with encryption
- **SSH Tunneling**: Enhanced SSH with UDP support
- **TCP Bypass**: High-performance proxy solutions
- **BadVPN**: UDP over TCP tunneling

### ⚡ Performance Tools
- **BBR Algorithm**: Latest congestion control
- **Kernel Optimization**: Network stack tuning
- **Memory Management**: Resource optimization
- **Connection Scaling**: Handle thousands of connections

### 🔒 Security Suite
- **Advanced Firewall**: UFW with custom rules
- **Intrusion Prevention**: Fail2ban protection
- **User Management**: Secure user environments
- **SSH Hardening**: Enhanced SSH security

---

## 📊 Monitoring & Analytics

### Real-time Metrics
- **System Resources**: CPU, Memory, Disk usage
- **Network Activity**: Connections, bandwidth, latency
- **Service Health**: Status monitoring and alerts
- **Performance Trends**: Historical data analysis

### Logging System
```bash
/var/log/mastermind/
├── system.log          # System operations
├── proxy.log           # Proxy service logs  
├── security.log        # Security events
├── performance.log     # Performance metrics
└── error.log          # Error tracking
```

---

## 🔐 Security Best Practices

### 🛡️ Built-in Security
- **Fail2ban Integration**: Automatic IP blocking
- **UFW Firewall**: Advanced rule management
- **SSH Hardening**: Secure configurations
- **User Isolation**: Secure environment separation

### 🔒 Recommended Settings
- Use SSH keys instead of passwords
- Enable two-factor authentication
- Regular security updates
- Monitor system logs
- Limit user privileges

---

## 🤝 Contributing

We welcome contributions from the community!

### 🚀 Getting Started
1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### 📝 Development Guidelines
- Follow bash scripting best practices
- Use 4-space indentation
- Add comprehensive comments
- Test on clean Ubuntu/Debian systems
- Update documentation for new features

### 🧪 Testing
```bash
# Syntax check
bash -n core/menu.sh

# Test installation
./install.sh --test

# Verify all components
sudo /opt/mastermind/core/menu.sh --verify
```

---

## 📝 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🆘 Support & Documentation

### 📚 Documentation
- [Installation Guide](DEPLOYMENT.md) - Detailed setup instructions
- [Port Configuration](PORT_MAPPING.md) - Network port management
- [Troubleshooting](GITHUB_UPLOAD.md) - Common issues and solutions

### 🐛 Reporting Issues
When reporting issues, please include:
- Operating system version
- Installation method used
- Complete error messages
- Steps to reproduce

### 💬 Community
- **GitHub Issues**: Bug reports and feature requests
- **Discussions**: General questions and community help
- **Wiki**: Community-contributed documentation

---

## 🎯 Roadmap

### 🔮 Upcoming Features
- [ ] Web-based management interface
- [ ] Docker container support
- [ ] Multi-server dashboard
- [ ] Advanced analytics
- [ ] REST API integration
- [ ] Mobile app companion

### 📈 Version History
- **v3.0.0** (2025-07-06) - Complete UI/UX redesign with modern interface
- **v2.0.0** (2025-07-05) - Major refactoring and enhanced features  
- **v1.0.0** (2025-01-01) - Initial release with core functionality

---

<div align="center">

### 🌟 Star this repository if you find it useful!

**Made with ❤️ by the Mastermind VPS Team**

*Empowering system administrators with modern tools*

[⭐ Star](https://github.com/mafiadan6/mastermind-vps-toolkit) • [🍴 Fork](https://github.com/mafiadan6/mastermind-vps-toolkit/fork) • [📝 Issues](https://github.com/mafiadan6/mastermind-vps-toolkit/issues) • [📖 Wiki](https://github.com/mafiadan6/mastermind-vps-toolkit/wiki)

</div>