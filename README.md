# 🔥 MasterMind VPS Toolkit v5.1.0 Complete Edition

<div align="center">

![MasterMind Logo](https://img.shields.io/badge/MasterMind-VPS%20Toolkit-blue?style=for-the-badge&logo=linux&logoColor=white)
[![Version](https://img.shields.io/badge/Version-5.1.0-green?style=for-the-badge)](https://github.com/Mafiadan6/mastermind-vps-toolkit)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-orange?style=for-the-badge&logo=ubuntu)](https://ubuntu.com)

**Professional VPS Management Toolkit with Advanced Proxy Services**

*Complete solution for network administrators, system engineers, and VPS enthusiasts*

</div>

---

## 🚀 **Quick Installation**

```bash
# One-line installation (recommended)
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/install.sh | bash

# Alternative: Download and run
wget https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/install.sh
chmod +x install.sh
./install.sh
```

## 📱 **Mobile App Ready**

Perfect for tunneling applications:
- **NPV Tunnel**: WebSocket proxy on port 8080
- **HTTP Injector**: Custom response servers 9000-9003  
- **V2RayNG**: VLESS/VMESS configurations included
- **AnonyTun**: HTTP proxy support on port 8888

---

## ⚡ **Key Features**

### 🛡️ **Advanced Proxy Suite**
- **SOCKS5 Proxy** (Port 1080) - Standard SOCKS5 with authentication
- **WebSocket-SSH Proxy** (Port 8080) - Mobile app compatible with SSH tunneling
- **HTTP Proxy** (Port 8888) - Web browser and app proxy with CONNECT support
- **Response Servers** (Ports 9000-9003) - Custom branded responses for tunneling apps

### 🔧 **System Management**
- **Interactive Terminal Menu** - Modern UI with color-coded options
- **User Administration** - SSH user creation with usage limits
- **Network Optimization** - BBR congestion control and kernel tuning
- **Security Center** - Firewall management and intrusion detection
- **System Monitoring** - Real-time stats and performance analysis

### 📊 **Usage Limits & Tracking**
- **Data Limits** - Configurable GB limits per user
- **Time Limits** - Account validity periods
- **Connection Limits** - Maximum concurrent connections
- **Automatic Enforcement** - Users disabled when limits exceeded

### 🎨 **Branding & QR Codes**
- **Custom SSH Banners** - Professional server identification
- **QR Code Generation** - Connection configs for mobile apps
- **Branded Responses** - Custom HTTP responses with MasterMind branding

---

## 🖥️ **System Requirements**

| Component | Requirement |
|-----------|-------------|
| **OS** | Ubuntu 20.04+ / Debian 10+ |
| **CPU** | 1 vCPU minimum (2+ recommended) |
| **RAM** | 512MB minimum (1GB+ recommended) |
| **Storage** | 1GB free space |
| **Network** | Public IP address |
| **Ports** | 22, 80, 443, 1080, 8080, 8888, 9000-9003 |

---

## 📋 **Port Configuration**

### **Core Proxy Services**
```
🔹 SOCKS5 Proxy:          Port 1080  (Standard SOCKS5)
🔹 WebSocket-SSH Proxy:    Port 8080  (Mobile apps)
🔹 HTTP Proxy:             Port 8888  (Browser proxy)
```

### **Response Servers (MasterMind Branded)**
```
🔸 Response Server 1:      Port 9000  (Dropbear simulation)
🔸 Response Server 2:      Port 9001  (Custom responses)
🔸 Response Server 3:      Port 9002  (HTTP/1.1 101)
🔸 Response Server 4:      Port 9003  (OpenSSH simulation)
```

### **VPS Protocol Ports**
```
🔺 V2Ray VLESS:           Port 80    (HTTP WebSocket)
🔺 SSH TLS:               Port 443   (HTTPS/SSL)
🔺 Dropbear SSH:          Port 444   (Additional SSH)
🔺 Dropbear SSH:          Port 445   (Additional SSH)
```

---

## 🎯 **Usage Guide**

### **1. Access Main Menu**
```bash
mastermind
# or
cd /opt/mastermind && ./menu.sh
```

### **2. Quick Setup for Mobile Apps**
```bash
# Run the mobile setup wizard
mastermind mobile
```

### **3. Create SSH Users**
```bash
# Access user management
mastermind users
```

### **4. Monitor System**
```bash
# Real-time monitoring
mastermind monitor
```

---

## 📱 **Mobile App Configuration**

### **NPV Tunnel Setup**
```
Server Host: YOUR_VPS_IP
Server Port: 8080
Protocol: WebSocket
Response Port: 9001 (recommended)
```

### **HTTP Injector Setup**
```
Proxy Host: YOUR_VPS_IP
Proxy Port: 8888
WebSocket: ws://YOUR_VPS_IP:8080
Custom Response: Port 9002
```

### **V2RayNG Configuration**
```
Protocol: VLESS
Address: YOUR_VPS_IP
Port: 80
Path: /
Transport: WebSocket
```

---

## 🛠️ **Management Commands**

### **Service Control**
```bash
# Start all services
systemctl start python-proxy v2ray-service

# Check service status
systemctl status python-proxy

# View logs
journalctl -u python-proxy -f
```

### **User Management**
```bash
# Create SSH user with limits
/opt/mastermind/users/user_manager.sh create username password 10GB 30days

# List users and usage
python3 /opt/mastermind/users/usage_limits.py get_report
```

### **Network Testing**
```bash
# Test proxy functionality
python3 /opt/mastermind/test_proxy_setup.py

# Check open ports
netstat -tuln | grep -E ':(1080|8080|8888|9000|9001|9002|9003) '
```

---

## 🔄 **Lifecycle Management**

### **Reinstall (with backup)**
```bash
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/reinstall.sh | bash
```

### **Complete Uninstall**
```bash
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/uninstall.sh | bash
```

### **Update System**
```bash
# From main menu: Option 6 → Option 1
mastermind update
```

---

## 🏗️ **Project Structure**

```
mastermind-vps-toolkit/
├── install.sh                 # Main installation script
├── uninstall.sh              # Complete removal script
├── reinstall.sh              # Backup and reinstall script
├── core/
│   ├── menu.sh               # Interactive main menu
│   ├── config.cfg            # Configuration settings
│   ├── helpers.sh            # Utility functions
│   └── service_ctl.sh        # Service management
├── protocols/
│   ├── python_proxy.py       # Main proxy suite
│   ├── v2ray_manager.sh      # V2Ray configuration
│   └── ssh_suite.sh          # SSH service management
├── users/
│   ├── user_manager.sh       # User administration
│   └── usage_limits.py       # Usage tracking system
├── security/
│   ├── firewall_setup.sh     # Firewall configuration
│   └── fail2ban_setup.sh     # Intrusion detection
├── network/
│   └── optimization.sh       # Network performance tuning
└── branding/
    ├── qr_generator.py       # QR code generation
    └── response_servers.py   # Custom HTTP responses
```

---

## 🔒 **Security Features**

- **SSH Key Authentication** - Secure access with key pairs
- **Fail2Ban Integration** - Automatic IP blocking for brute force
- **UFW Firewall** - Properly configured firewall rules
- **SSL/TLS Support** - Encrypted connections for V2Ray
- **User Isolation** - Separate user environments
- **Usage Monitoring** - Track and limit resource usage

---

## 🤝 **Contributing**

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🆘 **Support & Documentation**

- **Installation Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Port Mapping**: [PORT_MAPPING.md](PORT_MAPPING.md)
- **GitHub Upload**: [GITHUB_UPLOAD.md](GITHUB_UPLOAD.md)
- **Issues**: [GitHub Issues](https://github.com/Mafiadan6/mastermind-vps-toolkit/issues)

---

## 📈 **Changelog**

### **v5.1.0 Complete Edition** *(Latest)*
- ✅ Enhanced user experience with Quick Setup Wizard
- ✅ Improved proxy listings with clear service descriptions
- ✅ Mobile app focus with NPV Tunnel and HTTP Injector configuration
- ✅ Step-by-step setup wizards with automatic service testing
- ✅ Complete lifecycle management (install/uninstall/reinstall)
- ✅ Fixed System Tools menu with options 10-11 integration
- ✅ Verified Proxy Structure v2.0 with proper port isolation

### **v5.0.0 Complete System**
- ✅ Complete menu system overhaul with full functionality
- ✅ All proxy services tested and working correctly
- ✅ Comprehensive user management with usage limits
- ✅ Enhanced security center and system monitoring
- ✅ Professional branding and QR code generation

---

<div align="center">

### **🌟 Star this repository if it helped you! 🌟**

**Made with ❤️ by the MasterMind Team**

[![GitHub stars](https://img.shields.io/github/stars/Mafiadan6/mastermind-vps-toolkit?style=social)](https://github.com/Mafiadan6/mastermind-vps-toolkit/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/Mafiadan6/mastermind-vps-toolkit?style=social)](https://github.com/Mafiadan6/mastermind-vps-toolkit/network)

</div>