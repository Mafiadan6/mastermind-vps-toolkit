#!/bin/bash

# Mastermind VPS Toolkit - First Run Setup
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh

# First run configuration
first_run_setup() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           FIRST RUN CONFIGURATION                            ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Welcome to Mastermind VPS Toolkit!"
    echo
    
    # Get server information
    echo -e "${YELLOW}Please provide the following information:${NC}"
    echo
    
    # Server name
    local server_name
    server_name=$(get_input "Server Name" "" "$(hostname)")
    
    # Admin email
    local admin_email
    admin_email=$(get_input "Admin Email" "validate_email" "admin@example.com")
    
    # Default SSH port
    local ssh_port
    ssh_port=$(get_input "SSH Port" "validate_port" "22")
    
    # Branding message
    local brand_message
    brand_message=$(get_input "Branding Message" "" "Mastermind VPS Toolkit")
    
    # Generate configuration
    generate_config "$server_name" "$admin_email" "$ssh_port" "$brand_message"
    
    # Initialize services
    initialize_services
    
    # Setup branding
    setup_branding "$brand_message"
    
    # Final setup
    finalize_setup
    
    echo
    log_info "First run setup completed successfully!"
    echo
    wait_for_key
}

# Validate email address
validate_email() {
    local email=$1
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Generate configuration file
generate_config() {
    local server_name=$1
    local admin_email=$2
    local ssh_port=$3
    local brand_message=$4
    
    log_info "Generating configuration..."
    
    cat > /opt/mastermind/core/config.cfg << EOF
# Mastermind VPS Toolkit Configuration
# Generated on: $(date)

# Server Information
SERVER_NAME="$server_name"
ADMIN_EMAIL="$admin_email"
SSH_PORT="$ssh_port"
BRAND_MESSAGE="$brand_message"

# Service Configuration
PYTHON_PROXY_PORT=8080
TCP_BYPASS_PORT=12345
V2RAY_PORT=443
BADVPN_PORT=7300

# Response Server Ports
RESPONSE_PORTS=(101 200 300 301)

# Network Configuration
ENABLE_BBR=true
ENABLE_FAST_OPEN=true
ENABLE_FORWARDING=true

# Security Configuration
ENABLE_FAIL2BAN=true
ENABLE_FIREWALL=true
MAX_LOGIN_ATTEMPTS=5
BAN_TIME=3600

# Monitoring Configuration
ENABLE_MONITORING=true
LOG_LEVEL="INFO"
BACKUP_RETENTION_DAYS=30

# Branding Configuration
CUSTOM_BANNER=true
CUSTOM_RESPONSES=true
QR_CODE_SIZE=256

# Installation Information
INSTALL_DATE="$(date)"
VERSION="1.0.0"
EOF
    
    log_info "Configuration file generated: /opt/mastermind/core/config.cfg"
}

# Initialize services
initialize_services() {
    log_info "Initializing services..."
    
    # Create service environment files
    create_service_configs
    
    # Start core services
    systemctl daemon-reload
    
    # Enable and start python-proxy
    systemctl enable python-proxy
    systemctl start python-proxy
    
    # Enable and start tcp-bypass
    systemctl enable tcp-bypass
    systemctl start tcp-bypass
    
    # Setup fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    log_info "Core services initialized"
}

# Create service configuration files
create_service_configs() {
    log_info "Creating service configurations..."
    
    # Python proxy configuration
    cat > /etc/default/python-proxy << EOF
# Python Proxy Service Configuration
SOCKS_PORT=8080
RESPONSE_MSG="Mastermind VPS Toolkit"
RESPONSE_PORTS="101,200,300,301"
ENABLE_WEBSOCKET=true
ENABLE_HTTP_PROXY=true
LOG_LEVEL=INFO
EOF
    
    # TCP bypass configuration
    cat > /etc/redsocks.conf << EOF
base {
    log_debug = off;
    log_info = on;
    log = "syslog";
    daemon = on;
    redirector = iptables;
}

redsocks {
    local_ip = 0.0.0.0;
    local_port = 12345;
    ip = 127.0.0.1;
    port = 8080;
    type = socks5;
}
EOF
    
    # V2Ray configuration
    cat > /opt/mastermind/config/v2ray.json << EOF
{
    "log": {
        "loglevel": "info"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$(uuidgen)",
                        "level": 0
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/mastermind"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOF
    
    log_info "Service configurations created"
}

# Setup branding
setup_branding() {
    local brand_message=$1
    
    log_info "Setting up branding..."
    
    # Create custom SSH banner
    cat > /etc/ssh/mastermind_banner << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║                           $brand_message                                      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  Server: $(hostname)                                                         ║
║  IP: $(get_public_ip)                                                        ║
║  Time: $(date)                                                               ║
║                                                                              ║
║  Unauthorized access is prohibited and will be prosecuted.                  ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    
    # Update SSH configuration
    if ! grep -q "Banner /etc/ssh/mastermind_banner" /etc/ssh/sshd_config; then
        echo "Banner /etc/ssh/mastermind_banner" >> /etc/ssh/sshd_config
        systemctl restart sshd
    fi
    
    log_info "Branding setup completed"
}

# Finalize setup
finalize_setup() {
    log_info "Finalizing setup..."
    
    # Create installation marker
    cat > /opt/mastermind/.installed << EOF
INSTALLED=true
INSTALL_DATE="$(date)"
VERSION="1.0.0"
EOF
    
    # Set permissions
    chown -R root:root /opt/mastermind
    chmod -R 755 /opt/mastermind
    
    # Create log files
    touch /var/log/mastermind/install.log
    touch /var/log/mastermind/services.log
    touch /var/log/mastermind/security.log
    
    # Setup logrotate
    cat > /etc/logrotate.d/mastermind << EOF
/var/log/mastermind/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
    
    log_info "Setup finalized"
}

# Check if first run is needed
check_first_run() {
    if [ ! -f "/opt/mastermind/.installed" ]; then
        return 0  # First run needed
    else
        return 1  # Already installed
    fi
}

# Main function
main() {
    if check_first_run; then
        first_run_setup
    else
        log_info "Mastermind VPS Toolkit is already configured"
        echo
        echo -e "${YELLOW}To reconfigure, remove /opt/mastermind/.installed and run this script again${NC}"
        echo
        wait_for_key
    fi
}

# Run main function
main "$@"
