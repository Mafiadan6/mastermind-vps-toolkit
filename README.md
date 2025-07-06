# Mastermind VPS Toolkit

A comprehensive terminal-based VPS management toolkit for proxy services, network optimization, and system administration on Ubuntu/Debian systems.

## Features

### VPS Toolkit Components
- **Proxy Services**: SOCKS5, HTTP, and WebSocket proxy implementations
- **Network Optimization**: BBR congestion control, kernel tuning, UDP optimization
- **Security Tools**: Fail2ban setup, firewall management, system auditing
- **Protocol Support**: V2Ray, SSH ecosystem, TCP bypass, BadVPN
- **QR Code Generation**: Dynamic configuration QR codes
- **Custom Response Servers**: Multi-port HTTP response servers with branding

## Quick Start

### Prerequisites
- Python 3.8+ (for VPS toolkit)
- Ubuntu 20.04+ or Debian 10+ (for VPS deployment)
- Root or sudo access

### One-Command Auto Installation

```bash
# Download and install directly from GitHub (Recommended)
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/install.sh | sudo bash
```

### Manual Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mafiadan6/mastermind-vps-toolkit.git
   cd mastermind-vps-toolkit
   ```

2. **Run the auto installer**
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   ```

### VPS Installation

1. **Run the installation script**
   ```bash
   sudo chmod +x install.sh
   sudo ./install.sh
   ```

2. **Initialize the system**
   ```bash
   sudo /opt/mastermind/core/first_run.sh
   ```

3. **Access the management menu**
   ```bash
   sudo /opt/mastermind/core/menu.sh
   ```

## Project Structure

```
mastermind-vps-toolkit/
├── protocols/             # VPS proxy and protocol implementations
│   ├── python_proxy.py    # SOCKS5, HTTP, WebSocket proxies
│   ├── v2ray_manager.sh   # V2Ray protocol management
│   ├── ssh_suite.sh       # SSH tunneling and management
│   ├── tcp_bypass.sh      # TCP bypass protocols
│   └── badvpn_setup.sh    # BadVPN configuration
├── security/              # Security and auditing tools
│   ├── audit_tool.sh      # Comprehensive security audit
│   ├── firewall_manager.sh # UFW firewall management
│   └── fail2ban_setup.sh  # Intrusion prevention setup
├── network/               # Network optimization scripts
│   ├── bbr.sh            # BBR congestion control
│   ├── kernel_tuning.sh  # Kernel parameter optimization
│   └── udp_optimizer.sh  # UDP performance tuning
├── branding/              # Custom branding and QR generation
│   ├── qr_generator.py   # Dynamic QR code generation
│   ├── response_servers.py # Custom HTTP response servers
│   └── banner_generator.sh # Custom banner creation
├── core/                  # Core system management
│   ├── menu.sh           # Main management interface
│   ├── service_ctl.sh    # Service control utilities
│   ├── first_run.sh      # Initial system setup
│   └── helpers.sh        # Common utility functions
├── users/                 # User management utilities
└── install.sh            # Main installation script
```

## Configuration

### VPS Configuration

The main configuration file is located at `/opt/mastermind/core/config.cfg`:

```bash
# Core Configuration
INSTALL_DIR="/opt/mastermind"
DATA_DIR="/opt/mastermind/data"
LOG_DIR="/var/log/mastermind"

# Service Ports
SOCKS_PORT=8080
HTTP_PROXY_PORT=8888
WEBSOCKET_PORT=8443
RESPONSE_PORTS=(80 443 8000 8080 9000)

# Security
ENABLE_FAIL2BAN=true
ENABLE_UFW=true
```

## VPS Toolkit Usage

### Service Management
```bash
# Start all services
sudo systemctl start python-proxy
sudo systemctl start tcp-bypass

# Check service status
sudo systemctl status python-proxy

# View logs
sudo journalctl -u python-proxy -f
```

### Network Optimization
```bash
# Enable BBR congestion control
sudo /opt/mastermind/network/bbr.sh

# Apply kernel tuning
sudo /opt/mastermind/network/kernel_tuning.sh

# Optimize UDP performance
sudo /opt/mastermind/network/udp_optimizer.sh
```

### Security Auditing
```bash
# Run security audit
sudo /opt/mastermind/security/audit_tool.sh

# Setup firewall
sudo /opt/mastermind/security/firewall_manager.sh
```

### QR Code Generation
```bash
# Generate SOCKS5 proxy QR
python3 /opt/mastermind/branding/qr_generator.py --socks5 --username user --password pass

# Generate SSH connection QR
python3 /opt/mastermind/branding/qr_generator.py --ssh --username root --port 22
```

## Management Interface

### Access the Main Menu
```bash
sudo /opt/mastermind/core/menu.sh
```

### Service Control
```bash
# Control individual services
sudo /opt/mastermind/core/service_ctl.sh

# View service status
sudo /opt/mastermind/core/service_ctl.sh status
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and test thoroughly
4. Commit your changes: `git commit -am 'Add new feature'`
5. Push to the branch: `git push origin feature-name`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the documentation in `/docs`
- Review the system logs in `/var/log/mastermind`

## Security

If you discover a security vulnerability, please send an email to the maintainer instead of creating a public issue.

## Acknowledgments

- Built with modern web technologies and best practices
- Inspired by the need for comprehensive VPS management tools
- Uses industry-standard security and networking protocols