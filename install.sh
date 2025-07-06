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

# Check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        error "This script must be run as root"
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
    if ! ping -c 1 google.com &> /dev/null; then
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
        python3-certbot-nginx
    
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
    
    # Main installation directory
    INSTALL_DIR="/opt/mastermind"
    mkdir -p $INSTALL_DIR
    
    # Create subdirectories
    mkdir -p $INSTALL_DIR/{core,protocols,network,security,branding,users,monitoring,backup,systemd,config,logs,docs}
    
    # Create log directories
    mkdir -p /var/log/mastermind/{protocols,network,security,monitoring}
    
    # Create configuration directories
    mkdir -p /etc/mastermind/{protocols,network,security,branding}
    
    # Set permissions
    chown -R root:root $INSTALL_DIR
    chmod -R 755 $INSTALL_DIR
    
    log "Directory structure created"
}

# Install core files
install_core_files() {
    log "Installing core files..."
    
    # Copy all files to installation directory
    cp -r core/* /opt/mastermind/core/
    cp -r protocols/* /opt/mastermind/protocols/
    cp -r network/* /opt/mastermind/network/
    cp -r security/* /opt/mastermind/security/
    cp -r branding/* /opt/mastermind/branding/
    cp -r users/* /opt/mastermind/users/
    cp -r monitoring/* /opt/mastermind/monitoring/
    cp -r backup/* /opt/mastermind/backup/
    cp -r systemd/* /opt/mastermind/systemd/
    cp -r config/* /opt/mastermind/config/
    cp -r docs/* /opt/mastermind/docs/
    
    # Make scripts executable
    find /opt/mastermind -name "*.sh" -exec chmod +x {} \;
    find /opt/mastermind -name "*.py" -exec chmod +x {} \;
    
    log "Core files installed"
}

# Install systemd services
install_services() {
    log "Installing systemd services..."
    
    # Copy service files
    cp /opt/mastermind/systemd/*.service /etc/systemd/system/
    
    # Reload systemd
    systemctl daemon-reload
    
    # Create default configuration files
    cat > /etc/default/python-proxy << EOF
# Python Proxy Configuration
SOCKS_PORT=8080
RESPONSE_MSG="Mastermind VPS Toolkit"
RESPONSE_PORTS="101,200,300,301"
EOF
    
    cat > /etc/default/tcp-bypass << EOF
# TCP Bypass Configuration
BYPASS_PORT=12345
SOCKS_UPSTREAM=127.0.0.1:8080
EOF
    
    log "Systemd services installed"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    # Reset UFW
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow 22/tcp
    
    # Allow proxy ports
    ufw allow 8080/tcp
    ufw allow 101/tcp
    ufw allow 200/tcp
    ufw allow 300/tcp
    ufw allow 301/tcp
    
    # Allow web ports
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Enable UFW
    ufw --force enable
    
    log "Firewall configured"
}

# Create menu shortcut
create_menu_shortcut() {
    log "Creating menu shortcut..."
    
    # Create menu command
    cat > /usr/local/bin/mastermind << 'EOF'
#!/bin/bash
/opt/mastermind/core/menu.sh "$@"
EOF
    
    chmod +x /usr/local/bin/mastermind
    
    # Create alias
    echo "alias menu='mastermind'" >> /etc/bash.bashrc
    echo "alias mm='mastermind'" >> /etc/bash.bashrc
    
    log "Menu shortcut created. Use 'mastermind' or 'menu' command to start"
}

# Run first-time setup
run_first_setup() {
    log "Running first-time setup..."
    
    # Generate default SSH banner
    /opt/mastermind/core/banner_setup.sh
    
    # Initialize configuration
    /opt/mastermind/core/first_run.sh
    
    log "First-time setup completed"
}

# Verify installation
verify_installation() {
    log "Verifying installation..."
    
    # Check if main menu exists
    if [ ! -f "/opt/mastermind/core/menu.sh" ]; then
        error "Main menu not found"
        exit 1
    fi
    
    # Check if services are installed
    if [ ! -f "/etc/systemd/system/python-proxy.service" ]; then
        error "Python proxy service not found"
        exit 1
    fi
    
    # Check if firewall is active
    if ! ufw status | grep -q "Status: active"; then
        warning "Firewall is not active"
    fi
    
    log "Installation verification completed"
}

# Main installation function
main() {
    show_banner
    
    echo -e "${BLUE}Starting Mastermind VPS Toolkit Installation...${NC}"
    echo
    
    check_root
    check_requirements
    update_system
    install_dependencies
    create_users
    create_directories
    install_core_files
    install_services
    configure_firewall
    create_menu_shortcut
    run_first_setup
    verify_installation
    
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    INSTALLATION COMPLETED SUCCESSFULLY!                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}To start the Mastermind VPS Toolkit, run:${NC}"
    echo -e "${CYAN}  mastermind${NC}  or  ${CYAN}menu${NC}"
    echo
    echo -e "${YELLOW}For documentation, check:${NC}"
    echo -e "${CYAN}  /opt/mastermind/docs/${NC}"
    echo
    echo -e "${YELLOW}Service status:${NC}"
    echo -e "${CYAN}  systemctl status python-proxy${NC}"
    echo -e "${CYAN}  systemctl status tcp-bypass${NC}"
    echo
    echo -e "${GREEN}Happy networking!${NC}"
}

# Run main function
main "$@"
