# 🚀 MasterMind VPS Toolkit - Professional Deployment Guide

## Overview
Complete deployment guide for the MasterMind VPS Toolkit v5.1.0 with advanced proxy services, mobile app integration, and comprehensive system management.

---

## 🎯 **Quick Start (Recommended)**

### **One-Line Installation**
```bash
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/install.sh | bash
```

### **Post-Installation Access**
```bash
# Access main menu
mastermind

# Or direct path
cd /opt/mastermind && ./menu.sh
```

---

## 📋 **Pre-Installation Requirements**

### **Server Specifications**
- **Operating System**: Ubuntu 20.04+ or Debian 10+
- **Architecture**: x86_64 (AMD64)
- **CPU**: 1 vCPU minimum (2+ recommended for heavy usage)
- **RAM**: 512MB minimum (1GB+ recommended)
- **Storage**: 1GB free space minimum
- **Network**: Public IP address with root access

### **Required Ports**
Ensure these ports are available and not blocked by your hosting provider:
```
22    - SSH access
80    - V2Ray VLESS WebSocket
443   - SSH TLS / HTTPS
1080  - SOCKS5 Proxy
8080  - WebSocket-SSH Proxy (Mobile apps)
8888  - HTTP Proxy
9000  - Response Server 1
9001  - Response Server 2  
9002  - Response Server 3
9003  - Response Server 4
```

---

## 🔧 **Installation Methods**

### **Method 1: Automated Installation (Recommended)**
```bash
# Download and run installer
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/install.sh | bash

# The installer will:
# - Update system packages
# - Install required dependencies
# - Configure proxy services  
# - Set up firewall rules
# - Create systemd services
# - Configure user management
# - Set up SSH banners
```

### **Method 2: Manual Download and Install**
```bash
# Download installer
wget https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/install.sh

# Make executable
chmod +x install.sh

# Run installation
./install.sh
```

### **Method 3: Git Clone Installation**
```bash
# Clone repository
git clone https://github.com/Mafiadan6/mastermind-vps-toolkit.git

# Change directory
cd mastermind-vps-toolkit

# Run installer
./install.sh
```

---

## ⚙️ **Configuration Options**

### **Environment Variables**
The toolkit supports custom configuration through environment variables:

```bash
# Proxy Configuration
export SOCKS_PORT=1080
export HTTP_PROXY_PORT=8888
export WEBSOCKET_PORT=8080
export RESPONSE_PORTS="9000,9001,9002,9003"

# SSH Configuration
export SSH_PORT=22
export SSH_USER=root

# Usage Limits
export DEFAULT_DATA_LIMIT_GB=10
export DEFAULT_DAYS_LIMIT=30
export DEFAULT_CONNECTION_LIMIT=5
```

### **Custom Installation Directory**
```bash
# Install to custom directory
export INSTALL_DIR="/opt/custom-mastermind"
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/install.sh | bash
```

---

## 🛡️ **Security Setup**

### **Firewall Configuration**
The installer automatically configures UFW firewall:
```bash
# Manual firewall setup (if needed)
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 1080/tcp  # SOCKS5
ufw allow 8080/tcp  # WebSocket
ufw allow 8888/tcp  # HTTP Proxy
ufw allow 9000:9003/tcp  # Response servers
ufw enable
```

### **Fail2Ban Protection**
Automatic intrusion detection is configured for:
- SSH brute force attacks
- Proxy service abuse
- HTTP response server flooding

### **SSL/TLS Configuration**
For enhanced security, SSL certificates are automatically generated:
```bash
# Manual SSL setup (if needed)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/mastermind/ssl/server.key \
  -out /opt/mastermind/ssl/server.crt
```

---

## 📱 **Mobile App Integration**

### **NPV Tunnel Configuration**
```
Server Host: YOUR_VPS_IP
Server Port: 8080
Protocol: WebSocket
Response Port: 9001
```

### **HTTP Injector Setup**
```
Proxy Host: YOUR_VPS_IP
Proxy Port: 8888
WebSocket URL: ws://YOUR_VPS_IP:8080
Custom Response: Port 9002
```

### **V2RayNG Mobile Client**
```
Protocol: VLESS
Address: YOUR_VPS_IP
Port: 80
UUID: [Generated during installation]
Path: /
Transport: WebSocket
Security: none (for port 80)
```

---

## 🔄 **Service Management**

### **Systemd Services**
The toolkit creates these systemd services:
```bash
# Main proxy service
systemctl status python-proxy
systemctl start python-proxy
systemctl stop python-proxy
systemctl restart python-proxy

# V2Ray service
systemctl status v2ray-service
systemctl start v2ray-service

# Enable auto-start
systemctl enable python-proxy v2ray-service
```

### **Manual Service Control**
```bash
# Start all services
/opt/mastermind/core/service_ctl.sh start

# Stop all services  
/opt/mastermind/core/service_ctl.sh stop

# Restart all services
/opt/mastermind/core/service_ctl.sh restart

# Check service status
/opt/mastermind/core/service_ctl.sh status
```

---

## 👥 **User Management**

### **Creating SSH Users**
```bash
# Interactive user creation
/opt/mastermind/users/user_manager.sh

# Command line user creation
/opt/mastermind/users/user_manager.sh create username password 10GB 30days

# Set usage limits
python3 /opt/mastermind/users/usage_limits.py add_user username premium 50 90 10
```

### **Managing User Limits**
```bash
# View user usage report
python3 /opt/mastermind/users/usage_limits.py get_report

# Check specific user limits
python3 /opt/mastermind/users/usage_limits.py get_user_limits username

# Disable user account
python3 /opt/mastermind/users/usage_limits.py disable_user username
```

---

## 🔍 **Testing and Verification**

### **Automatic Service Testing**
```bash
# Run comprehensive test suite
python3 /opt/mastermind/test_proxy_setup.py

# Test specific services
python3 /opt/mastermind/test_proxy_setup.py --socks5
python3 /opt/mastermind/test_proxy_setup.py --websocket
python3 /opt/mastermind/test_proxy_setup.py --http
```

### **Manual Port Testing**
```bash
# Check listening ports
netstat -tuln | grep -E ':(1080|8080|8888|9000|9001|9002|9003) '

# Test SOCKS5 proxy
curl --socks5 127.0.0.1:1080 http://httpbin.org/ip

# Test HTTP proxy
curl --proxy http://127.0.0.1:8888 http://httpbin.org/ip

# Test response servers
for port in 9000 9001 9002 9003; do
  curl -s http://127.0.0.1:$port
done
```

### **Connection Testing from Mobile**
```bash
# Generate QR codes for mobile configuration
python3 /opt/mastermind/branding/qr_generator.py generate_socks5_qr
python3 /opt/mastermind/branding/qr_generator.py generate_ssh_qr
python3 /opt/mastermind/branding/qr_generator.py generate_v2ray_qr
```

---

## 🚨 **Troubleshooting**

### **Common Issues and Solutions**

#### **Port Already in Use**
```bash
# Check what's using the port
lsof -i :8080

# Kill process using port
kill -9 $(lsof -t -i:8080)

# Restart services
systemctl restart python-proxy
```

#### **Service Won't Start**
```bash
# Check service logs
journalctl -u python-proxy -f

# Check configuration
/opt/mastermind/core/menu.sh advanced

# Validate configuration files
python3 -c "import json; json.load(open('/opt/mastermind/core/config.json'))"
```

#### **Mobile App Can't Connect**
```bash
# Verify firewall allows connections
ufw status

# Test external connectivity
telnet YOUR_VPS_IP 8080
telnet YOUR_VPS_IP 8888

# Check if services bind to 0.0.0.0
netstat -tuln | grep '0.0.0.0:'
```

#### **High CPU/Memory Usage**
```bash
# Monitor resource usage
top -p $(pgrep -f python_proxy)

# Limit concurrent connections
# Edit /opt/mastermind/core/config.cfg
MAX_CONNECTIONS=50

# Restart services
systemctl restart python-proxy
```

---

## 📊 **Monitoring and Logs**

### **Log Locations**
```bash
# Service logs
/var/log/mastermind/proxy.log
/var/log/mastermind/v2ray.log
/var/log/mastermind/users.log

# System logs
journalctl -u python-proxy
journalctl -u v2ray-service

# Access logs
tail -f /var/log/mastermind/access.log
```

### **Performance Monitoring**
```bash
# Real-time monitoring from menu
mastermind monitor

# Command line monitoring
watch -n 1 'ps aux | grep python_proxy'
watch -n 1 'netstat -tuln | grep -E ":(1080|8080|8888|9000|9001|9002|9003) "'
```

---

## 🔄 **Maintenance and Updates**

### **Regular Maintenance**
```bash
# Update system packages
mastermind update

# Clean log files
/opt/mastermind/core/menu.sh tools cleanup

# Backup configuration
/opt/mastermind/core/menu.sh tools backup
```

### **Version Updates**
```bash
# Check for updates
curl -s https://api.github.com/repos/Mafiadan6/mastermind-vps-toolkit/releases/latest

# Reinstall with backup
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/reinstall.sh | bash
```

---

## 🗑️ **Uninstallation**

### **Complete Removal**
```bash
# Complete uninstall (removes everything)
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/uninstall.sh | bash

# Or from menu
mastermind → System Tools → Complete Uninstall
```

The uninstall script removes:
- All proxy services and configurations
- Firewall rules and fail2ban setup
- SSH banners and MOTD
- User accounts created by toolkit
- All log files and backups
- SSL certificates
- Systemd service files
- Complete /opt/mastermind directory

---

## 💡 **Best Practices**

### **Security Recommendations**
1. Change default SSH port after installation
2. Use SSH key authentication instead of passwords
3. Regularly update the system and toolkit
4. Monitor logs for suspicious activity
5. Set appropriate user limits to prevent abuse

### **Performance Optimization**
1. Use SSD storage for better I/O performance
2. Configure BBR congestion control (automatic)
3. Optimize kernel parameters (automatic)
4. Monitor and limit concurrent connections
5. Use CDN for high-traffic scenarios

### **Backup Strategy**
1. Regular configuration backups using built-in tools
2. Database backups for user data
3. SSL certificate backups
4. Document custom configurations

---

## 🎯 **Advanced Configuration**

### **Custom Proxy Responses**
Edit response templates in:
```bash
/opt/mastermind/protocols/python_proxy.py
# Modify RESPONSE_TEMPLATES for custom handshake responses
```

### **V2Ray Custom Configurations**
```bash
# Edit V2Ray configuration
/opt/mastermind/protocols/v2ray_manager.sh config

# Custom UUID generation
uuidgen > /opt/mastermind/v2ray/uuid.txt
```

### **Firewall Customization**
```bash
# Custom firewall rules
/opt/mastermind/security/firewall_setup.sh custom

# Geographic IP blocking
# Edit /opt/mastermind/security/country_blocks.conf
```

---

## 📞 **Support and Community**

- **GitHub Issues**: [Report bugs and request features](https://github.com/Mafiadan6/mastermind-vps-toolkit/issues)
- **Documentation**: [Complete docs in repository](https://github.com/Mafiadan6/mastermind-vps-toolkit)
- **Updates**: Watch the repository for latest releases

---

**🎉 Congratulations! Your MasterMind VPS Toolkit is now deployed and ready for professional use!**