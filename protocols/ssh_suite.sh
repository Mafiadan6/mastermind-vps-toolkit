#!/bin/bash

# Mastermind VPS Toolkit - SSH Suite Manager
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# SSH Suite configuration
DROPBEAR_PORT=444
DROPBEAR_PORT_2=445
SSH_UDP_PORT=2222
STUNNEL_PORT=443

# Show SSH suite menu
show_ssh_suite_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                            SSH SUITE MANAGEMENT                              ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Show service status
    echo -e "${YELLOW}Service Status:${NC}"
    echo -e "  OpenSSH: $(get_service_status "ssh")"
    echo -e "  Dropbear: $(get_service_status "dropbear")"
    echo -e "  Stunnel: $(get_service_status "stunnel4")"
    
    # Show port status
    echo -e "${YELLOW}Port Status:${NC}"
    echo -e "  SSH ($SSH_PORT): $(get_port_status $SSH_PORT)"
    echo -e "  Dropbear ($DROPBEAR_PORT): $(get_port_status $DROPBEAR_PORT)"
    echo -e "  Dropbear-2 ($DROPBEAR_PORT_2): $(get_port_status $DROPBEAR_PORT_2)"
    echo -e "  SSH-UDP ($SSH_UDP_PORT): $(get_port_status $SSH_UDP_PORT)"
    echo -e "  Stunnel ($STUNNEL_PORT): $(get_port_status $STUNNEL_PORT)"
    
    echo
    echo -e "${YELLOW}  [1] Configure OpenSSH${NC}"
    echo -e "${YELLOW}  [2] Setup Dropbear${NC}"
    echo -e "${YELLOW}  [3] Configure SSH-UDP${NC}"
    echo -e "${YELLOW}  [4] Setup Stunnel (SSL)${NC}"
    echo -e "${YELLOW}  [5] Multi-port SSH${NC}"
    echo -e "${YELLOW}  [6] SSH Key Management${NC}"
    echo -e "${YELLOW}  [7] Connection Monitoring${NC}"
    echo -e "${YELLOW}  [8] Security Hardening${NC}"
    echo -e "${YELLOW}  [9] Backup/Restore Config${NC}"
    echo -e "${YELLOW}  [0] Back to Protocol Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Configure OpenSSH
configure_openssh() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                            OPENSSH CONFIGURATION                             ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}Current SSH Port: $SSH_PORT${NC}"
        echo -e "${YELLOW}Service Status: $(get_service_status "ssh")${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Change SSH Port${NC}"
        echo -e "${YELLOW}  [2] Configure Authentication${NC}"
        echo -e "${YELLOW}  [3] Enable/Disable Root Login${NC}"
        echo -e "${YELLOW}  [4] Configure SSH Banner${NC}"
        echo -e "${YELLOW}  [5] Set Connection Limits${NC}"
        echo -e "${YELLOW}  [6] View SSH Configuration${NC}"
        echo -e "${YELLOW}  [7] Restart SSH Service${NC}"
        echo -e "${YELLOW}  [0] Back to SSH Suite Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) change_ssh_port ;;
            2) configure_ssh_auth ;;
            3) toggle_root_login ;;
            4) configure_ssh_banner ;;
            5) set_connection_limits ;;
            6) view_ssh_config ;;
            7) restart_ssh_service ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Change SSH port
change_ssh_port() {
    echo
    echo -e "${YELLOW}Current SSH port: $SSH_PORT${NC}"
    echo
    
    local new_port
    new_port=$(get_input "Enter new SSH port" "validate_port" "$SSH_PORT")
    
    if [ "$new_port" != "$SSH_PORT" ]; then
        # Backup SSH configuration
        backup_file /etc/ssh/sshd_config
        
        # Update SSH port
        sed -i "s/^#\?Port .*/Port $new_port/" /etc/ssh/sshd_config
        
        # Update firewall
        ufw allow $new_port/tcp
        
        # Update configuration
        sed -i "s/SSH_PORT=.*/SSH_PORT=\"$new_port\"/" /opt/mastermind/core/config.cfg
        
        log_info "SSH port changed to $new_port"
        log_warn "Please update your firewall rules and reconnect using the new port"
        
        if confirm "Restart SSH service now?"; then
            systemctl restart ssh
        fi
    fi
    
    wait_for_key
}

# Configure SSH authentication
configure_ssh_auth() {
    echo
    echo -e "${YELLOW}SSH Authentication Configuration${NC}"
    echo
    
    echo -e "${YELLOW}Authentication Methods:${NC}"
    echo -e "  [1] Password Authentication"
    echo -e "  [2] Public Key Authentication"
    echo -e "  [3] Both (Password + Public Key)"
    echo -e "  [4] Public Key Only (Disable Password)"
    echo
    
    read -p "Choose authentication method [1-4]: " auth_choice
    
    case $auth_choice in
        1)
            sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
            sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/' /etc/ssh/sshd_config
            log_info "Password authentication enabled"
            ;;
        2)
            sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
            sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
            log_info "Public key authentication enabled"
            ;;
        3)
            sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
            sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
            log_info "Both authentication methods enabled"
            ;;
        4)
            sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
            sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
            log_info "Public key only authentication enabled"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            wait_for_key
            return
            ;;
    esac
    
    if confirm "Restart SSH service to apply changes?"; then
        systemctl restart ssh
    fi
    
    wait_for_key
}

# Toggle root login
toggle_root_login() {
    echo
    local current_setting=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')
    echo -e "${YELLOW}Current root login setting: ${current_setting:-"default"}${NC}"
    echo
    
    echo -e "${YELLOW}Root Login Options:${NC}"
    echo -e "  [1] Permit root login"
    echo -e "  [2] Prohibit root login"
    echo -e "  [3] Permit root login without password"
    echo -e "  [4] Permit root login with forced commands only"
    echo
    
    read -p "Choose option [1-4]: " root_choice
    
    case $root_choice in
        1)
            sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
            log_info "Root login enabled"
            ;;
        2)
            sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
            log_info "Root login disabled"
            ;;
        3)
            sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config
            log_info "Root login without password enabled"
            ;;
        4)
            sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin forced-commands-only/' /etc/ssh/sshd_config
            log_info "Root login with forced commands only enabled"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            wait_for_key
            return
            ;;
    esac
    
    if confirm "Restart SSH service to apply changes?"; then
        systemctl restart ssh
    fi
    
    wait_for_key
}

# Configure SSH banner
configure_ssh_banner() {
    echo
    echo -e "${YELLOW}SSH Banner Configuration${NC}"
    echo
    
    echo -e "${YELLOW}Current banner file: ${NC}"
    grep "^Banner" /etc/ssh/sshd_config 2>/dev/null || echo "No banner configured"
    echo
    
    if confirm "Configure custom SSH banner?"; then
        /opt/mastermind/core/banner_setup.sh customize
    fi
    
    wait_for_key
}

# Set connection limits
set_connection_limits() {
    echo
    echo -e "${YELLOW}SSH Connection Limits${NC}"
    echo
    
    local max_auth_tries=$(get_input "Max authentication tries" "validate_number" "3")
    local max_sessions=$(get_input "Max sessions per connection" "validate_number" "2")
    local max_startups=$(get_input "Max concurrent unauthenticated connections" "validate_number" "10")
    
    # Update SSH configuration
    sed -i "s/^#\?MaxAuthTries.*/MaxAuthTries $max_auth_tries/" /etc/ssh/sshd_config
    sed -i "s/^#\?MaxSessions.*/MaxSessions $max_sessions/" /etc/ssh/sshd_config
    sed -i "s/^#\?MaxStartups.*/MaxStartups $max_startups/" /etc/ssh/sshd_config
    
    log_info "SSH connection limits updated"
    
    if confirm "Restart SSH service to apply changes?"; then
        systemctl restart ssh
    fi
    
    wait_for_key
}

# View SSH configuration
view_ssh_config() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             SSH CONFIGURATION                                ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Active SSH configuration:${NC}"
    echo
    grep -v "^#" /etc/ssh/sshd_config | grep -v "^$"
    echo
    
    wait_for_key
}

# Restart SSH service
restart_ssh_service() {
    log_info "Restarting SSH service..."
    
    if systemctl restart ssh; then
        log_info "SSH service restarted successfully"
    else
        log_error "Failed to restart SSH service"
        echo
        echo -e "${RED}Service logs:${NC}"
        journalctl -u ssh -n 10 --no-pager
    fi
    
    wait_for_key
}

# Setup Dropbear
setup_dropbear() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             DROPBEAR SETUP                                   ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    if ! command_exists dropbear; then
        log_info "Installing Dropbear SSH server..."
        apt update
        apt install -y dropbear
    fi
    
    echo -e "${YELLOW}Dropbear Configuration:${NC}"
    echo
    
    local dropbear_port
    dropbear_port=$(get_input "Dropbear port" "validate_port" "$DROPBEAR_PORT")
    
    # Configure Dropbear
    cat > /etc/default/dropbear << EOF
# Dropbear SSH server configuration
NO_START=0
DROPBEAR_PORT=$dropbear_port
DROPBEAR_EXTRA_ARGS="-w -s -g"
DROPBEAR_BANNER="/etc/ssh/mastermind_banner"
DROPBEAR_RECEIVE_WINDOW=65536
EOF
    
    # Update firewall
    ufw allow $dropbear_port/tcp
    
    # Start Dropbear
    systemctl enable dropbear
    systemctl restart dropbear
    
    if is_service_running "dropbear"; then
        log_info "Dropbear SSH server started on port $dropbear_port"
    else
        log_error "Failed to start Dropbear SSH server"
    fi
    
    wait_for_key
}

# Configure SSH-UDP
configure_ssh_udp() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             SSH-UDP CONFIGURATION                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    if ! command_exists badvpn-udpgw; then
        log_info "Installing BadVPN UDP gateway..."
        apt update
        apt install -y badvpn
    fi
    
    echo -e "${YELLOW}SSH-UDP Configuration:${NC}"
    echo
    
    local udp_port
    udp_port=$(get_input "UDP gateway port" "validate_port" "$SSH_UDP_PORT")
    
    # Create UDP gateway service
    cat > /etc/systemd/system/udp-gateway.service << EOF
[Unit]
Description=UDP Gateway for SSH-UDP
After=network.target

[Service]
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 0.0.0.0:$udp_port --max-clients 1000
User=nobody
Group=nogroup
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    # Update firewall
    ufw allow $udp_port/udp
    
    # Start UDP gateway
    systemctl daemon-reload
    systemctl enable udp-gateway
    systemctl start udp-gateway
    
    if is_service_running "udp-gateway"; then
        log_info "SSH-UDP gateway started on port $udp_port"
    else
        log_error "Failed to start SSH-UDP gateway"
    fi
    
    wait_for_key
}

# Setup Stunnel (SSL)
setup_stunnel() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             STUNNEL SSL SETUP                                ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    if ! command_exists stunnel4; then
        log_info "Installing Stunnel..."
        apt update
        apt install -y stunnel4
    fi
    
    echo -e "${YELLOW}Stunnel Configuration:${NC}"
    echo
    
    local stunnel_port
    stunnel_port=$(get_input "Stunnel port" "validate_port" "$STUNNEL_PORT")
    
    # Generate SSL certificate
    generate_stunnel_cert
    
    # Configure Stunnel
    cat > /etc/stunnel/ssh.conf << EOF
[ssh]
accept = $stunnel_port
connect = 127.0.0.1:$SSH_PORT
cert = /etc/stunnel/stunnel.pem
key = /etc/stunnel/stunnel.key
EOF
    
    # Enable Stunnel
    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
    
    # Update firewall
    ufw allow $stunnel_port/tcp
    
    # Start Stunnel
    systemctl restart stunnel4
    
    if is_service_running "stunnel4"; then
        log_info "Stunnel SSL tunnel started on port $stunnel_port"
    else
        log_error "Failed to start Stunnel SSL tunnel"
    fi
    
    wait_for_key
}

# Generate Stunnel certificate
generate_stunnel_cert() {
    log_info "Generating SSL certificate for Stunnel..."
    
    # Generate private key
    openssl genrsa -out /etc/stunnel/stunnel.key 2048
    
    # Generate certificate
    openssl req -new -x509 -key /etc/stunnel/stunnel.key -out /etc/stunnel/stunnel.pem -days 365 -subj "/C=US/ST=State/L=City/O=Organization/CN=$(hostname)"
    
    # Set permissions
    chmod 600 /etc/stunnel/stunnel.key
    chmod 644 /etc/stunnel/stunnel.pem
    
    log_info "SSL certificate generated"
}

# Multi-port SSH
setup_multiport_ssh() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             MULTI-PORT SSH SETUP                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Configure multiple SSH ports:${NC}"
    echo
    
    local ports
    ports=$(get_input "Additional SSH ports (comma-separated)" "" "2222,8080,8443")
    
    IFS=',' read -ra PORT_ARRAY <<< "$ports"
    
    for port in "${PORT_ARRAY[@]}"; do
        port=$(echo "$port" | tr -d ' ')
        if validate_port "$port"; then
            # Create SSH service on additional port
            create_ssh_service_on_port "$port"
            log_info "SSH service configured on port $port"
        else
            log_error "Invalid port: $port"
        fi
    done
    
    wait_for_key
}

# Create SSH service on specific port
create_ssh_service_on_port() {
    local port=$1
    
    # Copy SSH configuration
    cp /etc/ssh/sshd_config "/etc/ssh/sshd_config_$port"
    
    # Update port in configuration
    sed -i "s/^Port .*/Port $port/" "/etc/ssh/sshd_config_$port"
    
    # Create systemd service
    cat > "/etc/systemd/system/ssh-$port.service" << EOF
[Unit]
Description=OpenBSD Secure Shell server on port $port
After=network.target auditd.service
ConditionPathExists=!/etc/ssh/sshd_not_to_be_run

[Service]
EnvironmentFile=-/etc/default/ssh
ExecStart=/usr/sbin/sshd -D -f /etc/ssh/sshd_config_$port
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartPreventExitStatus=255
Type=notify
NotifyAccess=main

[Install]
WantedBy=multi-user.target
EOF
    
    # Update firewall
    ufw allow $port/tcp
    
    # Start service
    systemctl daemon-reload
    systemctl enable "ssh-$port"
    systemctl start "ssh-$port"
}

# SSH key management
ssh_key_management() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             SSH KEY MANAGEMENT                               ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Generate SSH Key Pair${NC}"
        echo -e "${YELLOW}  [2] Add Public Key${NC}"
        echo -e "${YELLOW}  [3] Remove Public Key${NC}"
        echo -e "${YELLOW}  [4] List Authorized Keys${NC}"
        echo -e "${YELLOW}  [5] Backup Keys${NC}"
        echo -e "${YELLOW}  [0] Back to SSH Suite Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) generate_ssh_keypair ;;
            2) add_public_key ;;
            3) remove_public_key ;;
            4) list_authorized_keys ;;
            5) backup_ssh_keys ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Generate SSH key pair
generate_ssh_keypair() {
    echo
    echo -e "${YELLOW}Generate SSH Key Pair${NC}"
    echo
    
    local key_type
    key_type=$(get_input "Key type (rsa/ed25519)" "" "ed25519")
    
    local key_size
    if [ "$key_type" = "rsa" ]; then
        key_size=$(get_input "Key size (2048/4096)" "validate_number" "2048")
    fi
    
    local key_name
    key_name=$(get_input "Key name" "" "mastermind_key")
    
    local key_path="/root/.ssh/$key_name"
    
    # Generate key pair
    if [ "$key_type" = "ed25519" ]; then
        ssh-keygen -t ed25519 -f "$key_path" -N ""
    else
        ssh-keygen -t rsa -b "$key_size" -f "$key_path" -N ""
    fi
    
    log_info "SSH key pair generated:"
    log_info "Private key: $key_path"
    log_info "Public key: $key_path.pub"
    
    echo
    echo -e "${YELLOW}Public key content:${NC}"
    cat "$key_path.pub"
    echo
    
    wait_for_key
}

# Add public key
add_public_key() {
    echo
    echo -e "${YELLOW}Add Public Key${NC}"
    echo
    
    local username
    username=$(get_input "Username" "" "root")
    
    local public_key
    public_key=$(get_input "Public key content" "" "")
    
    if [ -n "$public_key" ]; then
        # Create .ssh directory if it doesn't exist
        mkdir -p "/home/$username/.ssh"
        
        # Add public key to authorized_keys
        echo "$public_key" >> "/home/$username/.ssh/authorized_keys"
        
        # Set permissions
        chmod 700 "/home/$username/.ssh"
        chmod 600 "/home/$username/.ssh/authorized_keys"
        chown -R "$username:$username" "/home/$username/.ssh"
        
        log_info "Public key added for user $username"
    else
        log_error "No public key provided"
    fi
    
    wait_for_key
}

# Remove public key
remove_public_key() {
    echo
    echo -e "${YELLOW}Remove Public Key${NC}"
    echo
    
    local username
    username=$(get_input "Username" "" "root")
    
    local authorized_keys_file
    if [ "$username" = "root" ]; then
        authorized_keys_file="/root/.ssh/authorized_keys"
    else
        authorized_keys_file="/home/$username/.ssh/authorized_keys"
    fi
    
    if [ -f "$authorized_keys_file" ]; then
        echo -e "${YELLOW}Current authorized keys:${NC}"
        cat -n "$authorized_keys_file"
        echo
        
        local line_number
        line_number=$(get_input "Line number to remove" "validate_number" "")
        
        if [ -n "$line_number" ]; then
            sed -i "${line_number}d" "$authorized_keys_file"
            log_info "Public key removed from line $line_number"
        fi
    else
        log_error "Authorized keys file not found for user $username"
    fi
    
    wait_for_key
}

# List authorized keys
list_authorized_keys() {
    echo
    echo -e "${YELLOW}List Authorized Keys${NC}"
    echo
    
    local username
    username=$(get_input "Username" "" "root")
    
    local authorized_keys_file
    if [ "$username" = "root" ]; then
        authorized_keys_file="/root/.ssh/authorized_keys"
    else
        authorized_keys_file="/home/$username/.ssh/authorized_keys"
    fi
    
    if [ -f "$authorized_keys_file" ]; then
        echo -e "${YELLOW}Authorized keys for user $username:${NC}"
        cat -n "$authorized_keys_file"
    else
        log_warn "No authorized keys found for user $username"
    fi
    
    echo
    wait_for_key
}

# Backup SSH keys
backup_ssh_keys() {
    echo
    log_info "Creating SSH keys backup..."
    
    local backup_dir="/opt/mastermind/backup/ssh"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="ssh_keys_${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    # Create backup
    tar -czf "$backup_dir/$backup_file" /etc/ssh/ /root/.ssh/ /home/*/.ssh/ 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_info "SSH keys backup created: $backup_dir/$backup_file"
    else
        log_error "Failed to create SSH keys backup"
    fi
    
    wait_for_key
}

# Connection monitoring
connection_monitoring() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           SSH CONNECTION MONITORING                           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Active SSH connections:${NC}"
    echo
    
    # Show active SSH connections
    netstat -tnpa | grep ':22\|:444\|:2222' | grep ESTABLISHED
    echo
    
    echo -e "${YELLOW}SSH login attempts (last 20):${NC}"
    echo
    
    # Show recent SSH login attempts
    grep "sshd" /var/log/auth.log | tail -20
    echo
    
    echo -e "${YELLOW}Failed SSH login attempts:${NC}"
    echo
    
    # Show failed login attempts
    grep "Failed password" /var/log/auth.log | tail -10
    echo
    
    wait_for_key
}

# Security hardening
security_hardening() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             SSH SECURITY HARDENING                           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Applying SSH security hardening..."
    
    # Backup current configuration
    backup_file /etc/ssh/sshd_config
    
    # Apply security settings
    cat >> /etc/ssh/sshd_config << EOF

# Mastermind Security Hardening
Protocol 2
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
UseDNS no
AllowUsers root
DenyUsers nobody
X11Forwarding no
AllowTcpForwarding no
GatewayPorts no
PermitTunnel no
EOF
    
    # Test configuration
    if sshd -t; then
        log_info "SSH security hardening applied successfully"
        
        if confirm "Restart SSH service to apply changes?"; then
            systemctl restart ssh
        fi
    else
        log_error "SSH configuration test failed"
        # Restore backup
        mv /etc/ssh/sshd_config.bak /etc/ssh/sshd_config 2>/dev/null
    fi
    
    wait_for_key
}

# Main function
main() {
    while true; do
        show_ssh_suite_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) configure_openssh ;;
            2) setup_dropbear ;;
            3) configure_ssh_udp ;;
            4) setup_stunnel ;;
            5) setup_multiport_ssh ;;
            6) ssh_key_management ;;
            7) connection_monitoring ;;
            8) security_hardening ;;
            9) echo -e "${YELLOW}Backup/Restore feature coming soon...${NC}" ; sleep 2 ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
