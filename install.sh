#!/bin/bash

# Mastermind VPS Toolkit Installation Script
# Version: 1.0.0

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main"
INSTALL_DIR="/opt/mastermind"

# ASCII Art Banner
show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
    ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██████╗ 
    ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗
    ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║  ██║
    ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║  ██║
    ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██████╔╝
    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝ 
                                  VPS TOOLKIT v1.0.0
EOF
    echo -e "${NC}"
}

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check if running on supported OS
    if ! command -v apt &> /dev/null; then
        error "This script requires a Debian/Ubuntu-based system"
        exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        error "No internet connection. Please check your network."
        exit 1
    fi
    
    log "System requirements check passed"
}

# Update system packages
update_system() {
    log "Updating system packages..."
    apt update -y
    apt upgrade -y
    log "System packages updated"
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."
    
    # Core dependencies
    apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        curl \
        wget \
        git \
        socat \
        netcat-traditional \
        iptables \
        fail2ban \
        ufw \
        qrencode \
        jq \
        htop \
        screen \
        tmux \
        nano \
        vim \
        unzip \
        tar \
        gzip \
        build-essential \
        cmake \
        pkg-config \
        libssl-dev \
        zlib1g-dev \
        redsocks \
        dropbear \
        openssh-server \
        nginx \
        certbot \
        python3-certbot-nginx \
        uuid-runtime
    
    # Install Python packages
    pip3 install --upgrade pip
    pip3 install \
        asyncio \
        websockets \
        aiohttp \
        psutil \
        colorama \
        requests \
        qrcode \
        pillow
    
    log "Dependencies installed successfully"
}

# Create system users
create_users() {
    log "Creating system users..."
    
    # Create proxy user
    if ! id "proxy-user" &>/dev/null; then
        useradd -r -s /bin/false proxy-user
        log "Created proxy-user"
    fi
    
    # Create v2ray user
    if ! id "v2ray-user" &>/dev/null; then
        useradd -r -s /bin/false v2ray-user
        log "Created v2ray-user"
    fi
    
    # Create mastermind user for management
    if ! id "mastermind" &>/dev/null; then
        useradd -m -s /bin/bash mastermind
        usermod -aG sudo mastermind
        log "Created mastermind user"
    fi
}

# Create directory structure
create_directories() {
    log "Creating directory structure..."
    
    # Create main installation directory
    mkdir -p $INSTALL_DIR
    
    # Create subdirectories
    mkdir -p $INSTALL_DIR/{core,protocols,network,security,branding,users}
    mkdir -p $INSTALL_DIR/{qr_codes,backups,configs}
    
    # Create log directories
    mkdir -p /var/log/mastermind
    
    # Create config directories
    mkdir -p /etc/mastermind
    
    # Set permissions
    chown -R root:root $INSTALL_DIR
    chmod -R 755 $INSTALL_DIR
    chown proxy-user:proxy-user /var/log/mastermind
    chmod 755 /var/log/mastermind
    
    log "Directory structure created"
}

# Download file from GitHub with retry logic
download_file() {
    local file_path="$1"
    local dest_path="$2"
    local url="${GITHUB_REPO}/${file_path}"
    local max_retries=3
    local retry_delay=5
    local retries=0
    
    while [ $retries -lt $max_retries ]; do
        if curl -sSL --connect-timeout 10 --max-time 30 "$url" -o "$dest_path"; then
            log "Downloaded: $file_path"
            return 0
        else
            retries=$((retries + 1))
            if [ $retries -lt $max_retries ]; then
                warn "Failed to download $file_path (attempt $retries/$max_retries), retrying in ${retry_delay}s..."
                sleep $retry_delay
            else
                error "Failed to download: $file_path after $max_retries attempts"
                return 1
            fi
        fi
    done
}

# Test network connectivity
test_network() {
    log "Testing network connectivity to GitHub..."
    
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        error "No internet connection available"
        return 1
    fi
    
    if ! curl -sSL --connect-timeout 5 --max-time 10 "${GITHUB_REPO}/README.md" >/dev/null 2>&1; then
        error "Cannot connect to GitHub repository"
        return 1
    fi
    
    log "Network connectivity test passed"
    return 0
}

# Install core files from GitHub
install_core_files() {
    log "Downloading and installing core files from GitHub..."
    
    # Test network connectivity first
    if ! test_network; then
        error "Network test failed. Cannot proceed with downloads."
        return 1
    fi
    
    # Core files
    download_file "core/menu.sh" "$INSTALL_DIR/core/menu.sh"
    download_file "core/service_ctl.sh" "$INSTALL_DIR/core/service_ctl.sh"
    download_file "core/first_run.sh" "$INSTALL_DIR/core/first_run.sh"
    download_file "core/helpers.sh" "$INSTALL_DIR/core/helpers.sh"
    download_file "core/banner_setup.sh" "$INSTALL_DIR/core/banner_setup.sh"
    download_file "core/config.cfg" "$INSTALL_DIR/core/config.cfg"
    
    # Protocol files
    download_file "protocols/python_proxy.py" "$INSTALL_DIR/protocols/python_proxy.py"
    download_file "protocols/v2ray_manager.sh" "$INSTALL_DIR/protocols/v2ray_manager.sh"
    download_file "protocols/ssh_suite.sh" "$INSTALL_DIR/protocols/ssh_suite.sh"
    download_file "protocols/tcp_bypass.sh" "$INSTALL_DIR/protocols/tcp_bypass.sh"
    download_file "protocols/badvpn_setup.sh" "$INSTALL_DIR/protocols/badvpn_setup.sh"
    download_file "protocols/proxy_manager.sh" "$INSTALL_DIR/protocols/proxy_manager.sh"
    download_file "protocols/squid_proxy.sh" "$INSTALL_DIR/protocols/squid_proxy.sh"
    
    # Network files
    download_file "network/bbr.sh" "$INSTALL_DIR/network/bbr.sh"
    download_file "network/kernel_tuning.sh" "$INSTALL_DIR/network/kernel_tuning.sh"
    download_file "network/udp_optimizer.sh" "$INSTALL_DIR/network/udp_optimizer.sh"
    
    # Security files
    download_file "security/audit_tool.sh" "$INSTALL_DIR/security/audit_tool.sh"
    download_file "security/firewall_manager.sh" "$INSTALL_DIR/security/firewall_manager.sh"
    download_file "security/fail2ban_setup.sh" "$INSTALL_DIR/security/fail2ban_setup.sh"
    
    # Branding files
    download_file "branding/qr_generator.py" "$INSTALL_DIR/branding/qr_generator.py"
    download_file "branding/response_servers.py" "$INSTALL_DIR/branding/response_servers.py"
    download_file "branding/banner_generator.sh" "$INSTALL_DIR/branding/banner_generator.sh"
    
    # User management
    download_file "users/user_manager.sh" "$INSTALL_DIR/users/user_manager.sh"
    download_file "users/usage_limits.py" "$INSTALL_DIR/users/usage_limits.py"
    
    # Protocol management (missing files)
    download_file "protocols/domain_manager.sh" "$INSTALL_DIR/protocols/domain_manager.sh"
    
    # Make scripts executable
    find $INSTALL_DIR -name "*.sh" -exec chmod +x {} \;
    find $INSTALL_DIR -name "*.py" -exec chmod +x {} \;
    
    log "Core files installed successfully"
}

# Create systemd services
create_systemd_services() {
    log "Creating systemd services..."
    
    # Python proxy service
    cat > /etc/systemd/system/python-proxy.service << 'EOF'
[Unit]
Description=Mastermind Python Proxy Service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/mastermind/protocols
Environment=PYTHONPATH=/opt/mastermind/protocols
Environment=SOCKS_PORT=1080
Environment=HTTP_PROXY_PORT=8888
Environment=WEBSOCKET_PORT=444
Environment=WEBSOCKET_PROXY_TARGET=8080
Environment=LOG_LEVEL=INFO
ExecStart=/usr/bin/python3 /opt/mastermind/protocols/python_proxy.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # TCP bypass service
    cat > /etc/systemd/system/tcp-bypass.service << 'EOF'
[Unit]
Description=Mastermind TCP Bypass Service
After=network.target python-proxy.service
Requires=python-proxy.service

[Service]
Type=forking
User=root
Group=root
WorkingDirectory=/opt/mastermind/protocols
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/opt/mastermind/protocols/tcp_bypass.sh start_service
ExecStop=/opt/mastermind/protocols/tcp_bypass.sh stop_service
ExecReload=/opt/mastermind/protocols/tcp_bypass.sh reload_service
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    systemctl daemon-reload
    
    log "Systemd services created"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    # Reset UFW to ensure clean state
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow 22/tcp
    
    # Allow proxy ports (Proxy Structure v2.0)
    ufw allow 1080/tcp comment 'SOCKS5 Proxy'
    ufw allow 444/tcp comment 'WebSocket Proxy'
    ufw allow 8080/tcp comment 'WebSocket Proxy Target'
    ufw allow 445/tcp comment 'Dropbear SSH'
    ufw allow 8888/tcp comment 'HTTP Proxy'
    
    # Allow response server ports
    ufw allow 80/tcp comment 'HTTP/V2Ray'
    ufw allow 443/tcp comment 'HTTPS/SSH-TLS'
    ufw allow 9000/tcp comment 'Response Server 1'
    ufw allow 9001/tcp comment 'Response Server 2'
    ufw allow 9002/tcp comment 'Response Server 3'
    ufw allow 9003/tcp comment 'Response Server 4'
    
    # Enable UFW
    ufw --force enable
    
    log "Firewall configured successfully"
}

# Create configuration files
create_config_files() {
    log "Creating configuration files..."
    
    # Create main configuration
    cat > /etc/mastermind.conf << 'EOF'
# Mastermind VPS Toolkit Configuration
# Version: 1.0.0

[CORE]
INSTALL_DIR=/opt/mastermind
LOG_DIR=/var/log/mastermind
DATA_DIR=/opt/mastermind/data

[PORTS]
SOCKS_PORT=1080
HTTP_PROXY_PORT=8888
WEBSOCKET_PORT=444
WEBSOCKET_PROXY_TARGET=8080
RESPONSE_PORTS=9000,9001,9002,9003

[SECURITY]
ENABLE_FAIL2BAN=true
ENABLE_UFW=true
ENABLE_MONITORING=true

[BRANDING]
CUSTOM_BANNER=true
CUSTOM_RESPONSES=true
QR_CODE_SIZE=256
EOF

    # Create environment file for services
    cat > /etc/default/mastermind << 'EOF'
# Mastermind VPS Toolkit Environment Variables
MASTERMIND_HOME=/opt/mastermind
MASTERMIND_USER=proxy-user
SOCKS_PORT=1080
HTTP_PROXY_PORT=8888
WEBSOCKET_PORT=444
WEBSOCKET_PROXY_TARGET=8080
EOF
    
    log "Configuration files created"
}

# Create menu shortcut
create_menu_shortcut() {
    log "Creating menu shortcuts..."
    
    # Create main command
    cat > /usr/local/bin/mastermind << 'EOF'
#!/bin/bash
# Mastermind VPS Toolkit Menu Launcher
exec /opt/mastermind/core/menu.sh "$@"
EOF
    
    chmod +x /usr/local/bin/mastermind
    
    # Create aliases in bashrc
    cat >> /etc/bash.bashrc << 'EOF'

# Mastermind VPS Toolkit Aliases
alias menu='mastermind'
alias mm='mastermind'
alias mvps='mastermind'
EOF
    
    log "Menu shortcuts created"
}

# Setup fail2ban
setup_fail2ban() {
    log "Configuring fail2ban..."
    
    # Create custom jail for mastermind
    cat > /etc/fail2ban/jail.d/mastermind.conf << 'EOF'
[mastermind-proxy]
enabled = true
port = 444,8080,8888
filter = mastermind-proxy
logpath = /var/log/mastermind/*.log
maxretry = 5
bantime = 3600
findtime = 600

[sshd]
enabled = true
maxretry = 3
bantime = 86400
findtime = 600
EOF

    # Create filter for mastermind logs
    cat > /etc/fail2ban/filter.d/mastermind-proxy.conf << 'EOF'
[Definition]
failregex = ^.*Failed authentication from <HOST>.*$
            ^.*Invalid connection attempt from <HOST>.*$
            ^.*Blocked request from <HOST>.*$
ignoreregex =
EOF

    # Restart fail2ban
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    log "Fail2ban configured"
}

# Verify installation
verify_installation() {
    log "Verifying installation..."
    
    # Check if main menu exists
    if [ ! -f "$INSTALL_DIR/core/menu.sh" ]; then
        error "Main menu not found"
        return 1
    fi
    
    # Check if services exist
    if [ ! -f "/etc/systemd/system/python-proxy.service" ]; then
        error "Python proxy service not found"
        return 1
    fi
    
    # Check if firewall is active
    if ! ufw status | grep -q "Status: active"; then
        warning "Firewall is not active"
    fi
    
    # Check if mastermind command works
    if ! command -v mastermind &> /dev/null; then
        error "Mastermind command not found"
        return 1
    fi
    
    log "Installation verification completed successfully"
    return 0
}

# Post-installation setup
post_install_setup() {
    log "Running post-installation setup..."
    
    # Create backup directory first
    mkdir -p /opt/mastermind/backups
    chown proxy-user:proxy-user /opt/mastermind/backups
    
    # Create log files with proper permissions
    touch /var/log/mastermind/python-proxy.log
    touch /var/log/mastermind/tcp-bypass.log
    chown proxy-user:proxy-user /var/log/mastermind/*.log
    
    # Reload systemd daemon
    systemctl daemon-reload
    
    # Enable and start services
    systemctl enable python-proxy
    systemctl enable tcp-bypass
    
    # Generate initial configuration with error handling
    if [ -f "$INSTALL_DIR/core/first_run.sh" ]; then
        bash "$INSTALL_DIR/core/first_run.sh" || {
            log "Warning: First run setup had issues, continuing..."
        }
    fi
    
    # Generate SSH banner with error handling
    if [ -f "$INSTALL_DIR/core/banner_setup.sh" ]; then
        bash "$INSTALL_DIR/core/banner_setup.sh" || {
            log "Warning: Banner setup had issues, continuing..."
        }
    fi
    
    log "Post-installation setup completed"
}

# Cleanup function
cleanup_on_error() {
    error "Installation failed. Cleaning up..."
    
    # Stop and disable services if they exist
    systemctl stop python-proxy 2>/dev/null || true
    systemctl stop tcp-bypass 2>/dev/null || true
    systemctl disable python-proxy 2>/dev/null || true
    systemctl disable tcp-bypass 2>/dev/null || true
    
    # Remove service files
    rm -f /etc/systemd/system/python-proxy.service
    rm -f /etc/systemd/system/tcp-bypass.service
    
    # Remove installation directory
    rm -rf $INSTALL_DIR
    
    # Remove config files
    rm -f /etc/mastermind.conf
    rm -f /etc/default/mastermind
    
    # Remove shortcuts
    rm -f /usr/local/bin/mastermind
    
    systemctl daemon-reload
    
    exit 1
}

# Set error trap
trap cleanup_on_error ERR

# Main installation function
main() {
    show_banner
    
    echo -e "${BLUE}Starting Mastermind VPS Toolkit Installation...${NC}"
    echo
    
    # Installation steps
    check_root
    check_requirements
    update_system
    install_dependencies
    create_users
    create_directories
    install_core_files
    create_systemd_services
    configure_firewall
    create_config_files
    create_menu_shortcut
    setup_fail2ban
    post_install_setup
    verify_installation
    
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    INSTALLATION COMPLETED SUCCESSFULLY!                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Quick Start Commands:${NC}"
    echo -e "${CYAN}  mastermind${NC}     - Open main menu"
    echo -e "${CYAN}  menu${NC}          - Open main menu (alias)"
    echo -e "${CYAN}  mm${NC}            - Open main menu (short alias)"
    echo
    echo -e "${YELLOW}Service Management:${NC}"
    echo -e "${CYAN}  systemctl start python-proxy${NC}"
    echo -e "${CYAN}  systemctl status python-proxy${NC}"
    echo -e "${CYAN}  systemctl enable python-proxy${NC}"
    echo
    echo -e "${YELLOW}Configuration:${NC}"
    echo -e "${CYAN}  /etc/mastermind.conf${NC}        - Main configuration"
    echo -e "${CYAN}  /opt/mastermind/core/${NC}       - Core scripts"
    echo -e "${CYAN}  /var/log/mastermind/${NC}       - Log files"
    echo
    echo -e "${YELLOW}Firewall Status:${NC}"
    ufw status numbered | head -10
    echo
    echo -e "${GREEN}Installation completed! Run '${CYAN}mastermind${GREEN}' to get started.${NC}"
    echo
    echo -e "${CYAN}📋 Available Scripts:${NC}"
    echo -e "${WHITE}• Main Menu:     sudo /opt/mastermind/core/menu.sh${NC}"
    echo -e "${WHITE}• Reinstall:     sudo /opt/mastermind/reinstall.sh${NC}"
    echo -e "${WHITE}• Uninstall:     sudo /opt/mastermind/uninstall.sh${NC}"
}

# Run main function
main "$@"