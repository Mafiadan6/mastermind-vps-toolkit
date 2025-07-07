#!/bin/bash

# Mastermind VPS Toolkit - TCP Bypass Proxy
# Version: 1.0.0

# Set default paths
INSTALL_DIR="/opt/mastermind"
LOG_DIR="/var/log/mastermind"

# Source helper functions and config
if [ -f "$INSTALL_DIR/core/helpers.sh" ]; then
    source "$INSTALL_DIR/core/helpers.sh"
fi

if [ -f "$INSTALL_DIR/core/config.cfg" ]; then
    source "$INSTALL_DIR/core/config.cfg"
fi

# TCP Bypass configuration
REDSOCKS_CONFIG="/etc/redsocks.conf"
REDSOCKS_PORT=12345
BYPASS_CHAIN="MASTERMIND_BYPASS"

# Show TCP bypass menu
show_tcp_bypass_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           TCP BYPASS PROXY MANAGEMENT                        ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Show service status
    echo -e "${YELLOW}Service Status:${NC}"
    echo -e "  Redsocks: $(get_service_status "redsocks")"
    echo -e "  TCP Bypass: $(get_service_status "tcp-bypass")"
    
    # Show port status
    echo -e "${YELLOW}Port Status:${NC}"
    echo -e "  Redsocks ($REDSOCKS_PORT): $(get_port_status $REDSOCKS_PORT)"
    echo -e "  SOCKS5 Upstream ($PYTHON_PROXY_PORT): $(get_port_status $PYTHON_PROXY_PORT)"
    
    # Show iptables rules
    echo -e "${YELLOW}Bypass Rules:${NC}"
    local bypass_rules=$(iptables -t nat -L $BYPASS_CHAIN 2>/dev/null | wc -l)
    if [ $bypass_rules -gt 0 ]; then
        echo -e "  Active bypass rules: ${GREEN}$bypass_rules${NC}"
    else
        echo -e "  Bypass rules: ${RED}Not configured${NC}"
    fi
    
    echo
    echo -e "${YELLOW}  [1] Install/Configure Redsocks${NC}"
    echo -e "${YELLOW}  [2] Start TCP Bypass${NC}"
    echo -e "${YELLOW}  [3] Stop TCP Bypass${NC}"
    echo -e "${YELLOW}  [4] Configure Bypass Rules${NC}"
    echo -e "${YELLOW}  [5] Configure Upstream Proxy${NC}"
    echo -e "${YELLOW}  [6] View Bypass Statistics${NC}"
    echo -e "${YELLOW}  [7] Test Bypass Connectivity${NC}"
    echo -e "${YELLOW}  [8] Advanced Configuration${NC}"
    echo -e "${YELLOW}  [9] Troubleshooting${NC}"
    echo -e "${YELLOW}  [0] Back to Protocol Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Install/Configure Redsocks
install_redsocks() {
    log_info "Installing and configuring Redsocks..."
    
    # Install Redsocks
    if ! command_exists redsocks; then
        apt update
        apt install -y redsocks
    fi
    
    # Create configuration
    create_redsocks_config
    
    # Create systemd service
    create_tcp_bypass_service
    
    # Configure iptables rules
    setup_iptables_rules
    
    log_info "Redsocks installation and configuration completed"
    wait_for_key
}

# Create Redsocks configuration
create_redsocks_config() {
    log_info "Creating Redsocks configuration..."
    
    cat > $REDSOCKS_CONFIG << EOF
base {
    log_debug = off;
    log_info = on;
    log = "syslog";
    daemon = on;
    redirector = iptables;
    user = redsocks;
    group = redsocks;
}

redsocks {
    local_ip = 0.0.0.0;
    local_port = $REDSOCKS_PORT;
    ip = 127.0.0.1;
    port = $PYTHON_PROXY_PORT;
    type = socks5;
    
    // Optional authentication
    // login = "username";
    // password = "password";
}

// HTTP proxy alternative
redsocks {
    local_ip = 0.0.0.0;
    local_port = 12346;
    ip = 127.0.0.1;
    port = 8082;
    type = http-connect;
}

// HTTPS proxy
redsocks {
    local_ip = 0.0.0.0;
    local_port = 12347;
    ip = 127.0.0.1;
    port = 8082;
    type = http-relay;
}
EOF
    
    # Set permissions
    chmod 644 $REDSOCKS_CONFIG
    
    log_info "Redsocks configuration created"
}

# Create TCP bypass service
create_tcp_bypass_service() {
    log_info "Creating TCP bypass service..."
    
    cat > /etc/systemd/system/tcp-bypass.service << EOF
[Unit]
Description=TCP Bypass Proxy Service
After=network.target python-proxy.service
Requires=python-proxy.service

[Service]
Type=forking
ExecStart=/opt/mastermind/protocols/tcp_bypass.sh start_service
ExecStop=/opt/mastermind/protocols/tcp_bypass.sh stop_service
ExecReload=/opt/mastermind/protocols/tcp_bypass.sh reload_service
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    
    log_info "TCP bypass service created"
}

# Setup iptables rules
setup_iptables_rules() {
    log_info "Setting up iptables bypass rules..."
    
    # Create bypass chain
    iptables -t nat -N $BYPASS_CHAIN 2>/dev/null || true
    
    # Clear existing rules
    iptables -t nat -F $BYPASS_CHAIN
    
    # Add bypass rules for private networks
    iptables -t nat -A $BYPASS_CHAIN -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A $BYPASS_CHAIN -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A $BYPASS_CHAIN -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A $BYPASS_CHAIN -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A $BYPASS_CHAIN -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A $BYPASS_CHAIN -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A $BYPASS_CHAIN -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A $BYPASS_CHAIN -d 240.0.0.0/4 -j RETURN
    
    # Add bypass for localhost
    iptables -t nat -A $BYPASS_CHAIN -d 127.0.0.1 -j RETURN
    
    # Redirect to redsocks
    iptables -t nat -A $BYPASS_CHAIN -p tcp -j REDIRECT --to-ports $REDSOCKS_PORT
    
    # Apply to OUTPUT chain
    iptables -t nat -A OUTPUT -p tcp -j $BYPASS_CHAIN
    
    # Save iptables rules
    save_iptables_rules
    
    log_info "Iptables bypass rules configured"
}

# Save iptables rules
save_iptables_rules() {
    # Save current rules
    iptables-save > /etc/iptables/rules.v4
    
    # Create restore script
    cat > /etc/systemd/system/iptables-restore.service << EOF
[Unit]
Description=Restore iptables rules
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable iptables-restore
    
    log_info "Iptables rules saved"
}

# Start TCP bypass
start_tcp_bypass() {
    log_info "Starting TCP bypass service..."
    
    # Check if python-proxy is running
    if ! is_service_running "python-proxy"; then
        log_error "Python proxy service is not running"
        if confirm "Start Python proxy service?"; then
            systemctl start python-proxy
            sleep 2
        else
            return
        fi
    fi
    
    # Start redsocks
    systemctl start redsocks
    
    # Start tcp-bypass service
    systemctl start tcp-bypass
    
    # Enable services
    systemctl enable redsocks
    systemctl enable tcp-bypass
    
    if is_service_running "redsocks" && is_service_running "tcp-bypass"; then
        log_info "TCP bypass service started successfully"
    else
        log_error "Failed to start TCP bypass service"
        
        # Show service status
        echo
        echo -e "${YELLOW}Service status:${NC}"
        systemctl status redsocks --no-pager -l
        echo
        systemctl status tcp-bypass --no-pager -l
    fi
    
    wait_for_key
}

# Stop TCP bypass
stop_tcp_bypass() {
    log_info "Stopping TCP bypass service..."
    
    # Stop services
    systemctl stop tcp-bypass
    systemctl stop redsocks
    
    # Remove iptables rules
    iptables -t nat -D OUTPUT -p tcp -j $BYPASS_CHAIN 2>/dev/null || true
    iptables -t nat -F $BYPASS_CHAIN 2>/dev/null || true
    iptables -t nat -X $BYPASS_CHAIN 2>/dev/null || true
    
    log_info "TCP bypass service stopped"
    
    wait_for_key
}

# Configure bypass rules
configure_bypass_rules() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           BYPASS RULES CONFIGURATION                         ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}Current bypass rules:${NC}"
        iptables -t nat -L $BYPASS_CHAIN --line-numbers 2>/dev/null || echo "No rules found"
        echo
        
        echo -e "${YELLOW}  [1] Add IP/Network to bypass${NC}"
        echo -e "${YELLOW}  [2] Remove bypass rule${NC}"
        echo -e "${YELLOW}  [3] Add domain to bypass${NC}"
        echo -e "${YELLOW}  [4] Reset to default rules${NC}"
        echo -e "${YELLOW}  [5] View all NAT rules${NC}"
        echo -e "${YELLOW}  [0] Back to TCP Bypass Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) add_ip_bypass ;;
            2) remove_bypass_rule ;;
            3) add_domain_bypass ;;
            4) reset_bypass_rules ;;
            5) view_nat_rules ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Add IP/Network to bypass
add_ip_bypass() {
    echo
    echo -e "${YELLOW}Add IP/Network to bypass${NC}"
    echo
    
    local ip_network
    ip_network=$(get_input "Enter IP address or network (e.g., 8.8.8.8 or 192.168.1.0/24)" "validate_ip_or_network" "")
    
    if [ -n "$ip_network" ]; then
        # Add rule to bypass chain
        iptables -t nat -I $BYPASS_CHAIN -d "$ip_network" -j RETURN
        
        # Save rules
        save_iptables_rules
        
        log_info "Added $ip_network to bypass rules"
    fi
    
    wait_for_key
}

# Remove bypass rule
remove_bypass_rule() {
    echo
    echo -e "${YELLOW}Remove bypass rule${NC}"
    echo
    
    # Show current rules with line numbers
    iptables -t nat -L $BYPASS_CHAIN --line-numbers
    echo
    
    local rule_number
    rule_number=$(get_input "Enter rule number to remove" "validate_number" "")
    
    if [ -n "$rule_number" ]; then
        # Remove rule
        iptables -t nat -D $BYPASS_CHAIN "$rule_number"
        
        # Save rules
        save_iptables_rules
        
        log_info "Removed rule number $rule_number"
    fi
    
    wait_for_key
}

# Add domain to bypass
add_domain_bypass() {
    echo
    echo -e "${YELLOW}Add domain to bypass${NC}"
    echo
    
    local domain
    domain=$(get_input "Enter domain name" "validate_domain" "")
    
    if [ -n "$domain" ]; then
        # Resolve domain to IP
        local ip=$(dig +short "$domain" | head -1)
        
        if [ -n "$ip" ]; then
            # Add IP to bypass
            iptables -t nat -I $BYPASS_CHAIN -d "$ip" -j RETURN
            
            # Save rules
            save_iptables_rules
            
            log_info "Added domain $domain ($ip) to bypass rules"
        else
            log_error "Could not resolve domain: $domain"
        fi
    fi
    
    wait_for_key
}

# Reset bypass rules
reset_bypass_rules() {
    if confirm "Reset bypass rules to default?"; then
        # Clear existing rules
        iptables -t nat -F $BYPASS_CHAIN
        
        # Setup default rules
        setup_iptables_rules
        
        log_info "Bypass rules reset to default"
    fi
    
    wait_for_key
}

# View NAT rules
view_nat_rules() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                               NAT RULES                                       ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}NAT table rules:${NC}"
    iptables -t nat -L -v --line-numbers
    echo
    
    wait_for_key
}

# Configure upstream proxy
configure_upstream_proxy() {
    echo
    echo -e "${YELLOW}Configure Upstream Proxy${NC}"
    echo
    
    local proxy_type
    echo -e "${YELLOW}Proxy types:${NC}"
    echo -e "  [1] SOCKS5"
    echo -e "  [2] HTTP"
    echo -e "  [3] HTTPS"
    echo
    
    read -p "Choose proxy type [1-3]: " proxy_choice
    
    case $proxy_choice in
        1) proxy_type="socks5" ;;
        2) proxy_type="http-connect" ;;
        3) proxy_type="http-relay" ;;
        *) 
            echo -e "${RED}Invalid choice${NC}"
            wait_for_key
            return
            ;;
    esac
    
    local proxy_ip
    proxy_ip=$(get_input "Proxy IP address" "validate_ip" "127.0.0.1")
    
    local proxy_port
    proxy_port=$(get_input "Proxy port" "validate_port" "$PYTHON_PROXY_PORT")
    
    local proxy_user
    proxy_user=$(get_input "Proxy username (optional)" "" "")
    
    local proxy_pass
    if [ -n "$proxy_user" ]; then
        proxy_pass=$(get_input "Proxy password" "" "")
    fi
    
    # Update redsocks configuration
    backup_file $REDSOCKS_CONFIG
    
    cat > $REDSOCKS_CONFIG << EOF
base {
    log_debug = off;
    log_info = on;
    log = "syslog";
    daemon = on;
    redirector = iptables;
    user = redsocks;
    group = redsocks;
}

redsocks {
    local_ip = 0.0.0.0;
    local_port = $REDSOCKS_PORT;
    ip = $proxy_ip;
    port = $proxy_port;
    type = $proxy_type;
EOF
    
    if [ -n "$proxy_user" ]; then
        cat >> $REDSOCKS_CONFIG << EOF
    login = "$proxy_user";
    password = "$proxy_pass";
EOF
    fi
    
    echo "}" >> $REDSOCKS_CONFIG
    
    log_info "Upstream proxy configuration updated"
    
    if confirm "Restart redsocks to apply changes?"; then
        systemctl restart redsocks
    fi
    
    wait_for_key
}

# View bypass statistics
view_bypass_statistics() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             BYPASS STATISTICS                                ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Service Status:${NC}"
    echo -e "  Redsocks: $(get_service_status "redsocks")"
    echo -e "  TCP Bypass: $(get_service_status "tcp-bypass")"
    echo
    
    echo -e "${YELLOW}Connection Statistics:${NC}"
    local redsocks_connections=$(netstat -an | grep ":$REDSOCKS_PORT " | grep ESTABLISHED | wc -l)
    echo -e "  Active connections: $redsocks_connections"
    echo
    
    echo -e "${YELLOW}Iptables Statistics:${NC}"
    iptables -t nat -L $BYPASS_CHAIN -v 2>/dev/null || echo "No statistics available"
    echo
    
    echo -e "${YELLOW}Process Information:${NC}"
    ps aux | grep redsocks | grep -v grep
    echo
    
    echo -e "${YELLOW}Log Statistics:${NC}"
    local log_entries=$(grep "redsocks" /var/log/syslog | tail -10 | wc -l)
    echo -e "  Recent log entries: $log_entries"
    echo
    
    if [ $log_entries -gt 0 ]; then
        echo -e "${YELLOW}Recent log entries:${NC}"
        grep "redsocks" /var/log/syslog | tail -5
    fi
    
    echo
    wait_for_key
}

# Test bypass connectivity
test_bypass_connectivity() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           BYPASS CONNECTIVITY TEST                           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Testing bypass connectivity..."
    echo
    
    # Test 1: Check services
    echo -e "${YELLOW}1. Service Status Test:${NC}"
    if is_service_running "redsocks"; then
        echo -e "${GREEN}✓ Redsocks service is running${NC}"
    else
        echo -e "${RED}✗ Redsocks service is not running${NC}"
    fi
    
    if is_service_running "python-proxy"; then
        echo -e "${GREEN}✓ Python proxy service is running${NC}"
    else
        echo -e "${RED}✗ Python proxy service is not running${NC}"
    fi
    echo
    
    # Test 2: Check ports
    echo -e "${YELLOW}2. Port Connectivity Test:${NC}"
    if netstat -tuln | grep -q ":$REDSOCKS_PORT "; then
        echo -e "${GREEN}✓ Redsocks is listening on port $REDSOCKS_PORT${NC}"
    else
        echo -e "${RED}✗ Redsocks is not listening on port $REDSOCKS_PORT${NC}"
    fi
    
    if netstat -tuln | grep -q ":$PYTHON_PROXY_PORT "; then
        echo -e "${GREEN}✓ SOCKS5 proxy is listening on port $PYTHON_PROXY_PORT${NC}"
    else
        echo -e "${RED}✗ SOCKS5 proxy is not listening on port $PYTHON_PROXY_PORT${NC}"
    fi
    echo
    
    # Test 3: Check iptables rules
    echo -e "${YELLOW}3. Iptables Rules Test:${NC}"
    if iptables -t nat -L $BYPASS_CHAIN >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Bypass chain exists${NC}"
        local rule_count=$(iptables -t nat -L $BYPASS_CHAIN | grep -c "RETURN\|REDIRECT")
        echo -e "${GREEN}✓ $rule_count bypass rules configured${NC}"
    else
        echo -e "${RED}✗ Bypass chain not found${NC}"
    fi
    echo
    
    # Test 4: Test actual bypass
    echo -e "${YELLOW}4. Bypass Functionality Test:${NC}"
    echo -e "${CYAN}Testing connection to google.com...${NC}"
    
    if curl -s -m 10 --connect-timeout 5 "http://google.com" > /dev/null; then
        echo -e "${GREEN}✓ External connectivity working${NC}"
    else
        echo -e "${RED}✗ External connectivity failed${NC}"
    fi
    echo
    
    # Test 5: Configuration validation
    echo -e "${YELLOW}5. Configuration Validation:${NC}"
    if [ -f "$REDSOCKS_CONFIG" ]; then
        echo -e "${GREEN}✓ Redsocks configuration file exists${NC}"
        
        # Check configuration syntax
        if redsocks -t -c $REDSOCKS_CONFIG 2>/dev/null; then
            echo -e "${GREEN}✓ Redsocks configuration is valid${NC}"
        else
            echo -e "${RED}✗ Redsocks configuration has errors${NC}"
        fi
    else
        echo -e "${RED}✗ Redsocks configuration file not found${NC}"
    fi
    echo
    
    wait_for_key
}

# Advanced configuration
advanced_configuration() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           ADVANCED CONFIGURATION                            ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] Edit Raw Redsocks Config${NC}"
        echo -e "${YELLOW}  [2] Configure Multiple Instances${NC}"
        echo -e "${YELLOW}  [3] Setup Load Balancing${NC}"
        echo -e "${YELLOW}  [4] Configure Logging${NC}"
        echo -e "${YELLOW}  [5] Performance Tuning${NC}"
        echo -e "${YELLOW}  [6] Backup Configuration${NC}"
        echo -e "${YELLOW}  [7] Restore Configuration${NC}"
        echo -e "${YELLOW}  [0] Back to TCP Bypass Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) edit_raw_config ;;
            2) configure_multiple_instances ;;
            3) setup_load_balancing ;;
            4) configure_logging ;;
            5) performance_tuning ;;
            6) backup_configuration ;;
            7) restore_configuration ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Edit raw configuration
edit_raw_config() {
    echo
    echo -e "${YELLOW}Editing Redsocks configuration...${NC}"
    echo
    
    # Backup current configuration
    backup_file $REDSOCKS_CONFIG
    
    # Edit configuration
    nano $REDSOCKS_CONFIG
    
    # Test configuration
    if redsocks -t -c $REDSOCKS_CONFIG 2>/dev/null; then
        log_info "Configuration is valid"
        
        if confirm "Restart redsocks to apply changes?"; then
            systemctl restart redsocks
        fi
    else
        log_error "Configuration has errors"
        echo
        echo -e "${RED}Configuration test output:${NC}"
        redsocks -t -c $REDSOCKS_CONFIG
    fi
    
    wait_for_key
}

# Configure multiple instances
configure_multiple_instances() {
    echo
    echo -e "${YELLOW}Configure Multiple Instances${NC}"
    echo
    echo -e "${YELLOW}This feature allows running multiple redsocks instances${NC}"
    echo -e "${YELLOW}for different proxy types or load balancing.${NC}"
    echo
    echo -e "${YELLOW}This feature is coming soon...${NC}"
    echo
    wait_for_key
}

# Setup load balancing
setup_load_balancing() {
    echo
    echo -e "${YELLOW}Setup Load Balancing${NC}"
    echo
    echo -e "${YELLOW}This feature allows distributing traffic across${NC}"
    echo -e "${YELLOW}multiple upstream proxy servers.${NC}"
    echo
    echo -e "${YELLOW}This feature is coming soon...${NC}"
    echo
    wait_for_key
}

# Configure logging
configure_logging() {
    echo
    echo -e "${YELLOW}Configure Logging${NC}"
    echo
    
    echo -e "${YELLOW}Current logging configuration:${NC}"
    grep "log" $REDSOCKS_CONFIG | head -3
    echo
    
    echo -e "${YELLOW}Log levels:${NC}"
    echo -e "  [1] Debug (most verbose)"
    echo -e "  [2] Info (default)"
    echo -e "  [3] Warning"
    echo -e "  [4] Error (least verbose)"
    echo
    
    read -p "Choose log level [1-4]: " log_choice
    
    case $log_choice in
        1) 
            sed -i 's/log_debug = off/log_debug = on/' $REDSOCKS_CONFIG
            sed -i 's/log_info = off/log_info = on/' $REDSOCKS_CONFIG
            ;;
        2)
            sed -i 's/log_debug = on/log_debug = off/' $REDSOCKS_CONFIG
            sed -i 's/log_info = off/log_info = on/' $REDSOCKS_CONFIG
            ;;
        3)
            sed -i 's/log_debug = on/log_debug = off/' $REDSOCKS_CONFIG
            sed -i 's/log_info = on/log_info = off/' $REDSOCKS_CONFIG
            ;;
        4)
            sed -i 's/log_debug = on/log_debug = off/' $REDSOCKS_CONFIG
            sed -i 's/log_info = on/log_info = off/' $REDSOCKS_CONFIG
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            wait_for_key
            return
            ;;
    esac
    
    log_info "Logging configuration updated"
    
    if confirm "Restart redsocks to apply changes?"; then
        systemctl restart redsocks
    fi
    
    wait_for_key
}

# Performance tuning
performance_tuning() {
    echo
    echo -e "${YELLOW}Performance Tuning${NC}"
    echo
    
    echo -e "${YELLOW}This will optimize system settings for TCP bypass performance.${NC}"
    echo
    
    if confirm "Apply performance optimizations?"; then
        # Network performance tuning
        cat >> /etc/sysctl.conf << EOF

# TCP Bypass Performance Tuning
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 8192
EOF
        
        # Apply settings
        sysctl -p
        
        log_info "Performance optimizations applied"
    fi
    
    wait_for_key
}

# Backup configuration
backup_configuration() {
    echo
    log_info "Creating TCP bypass configuration backup..."
    
    local backup_dir="/opt/mastermind/backup/tcp-bypass"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="tcp_bypass_config_${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    # Create backup
    tar -czf "$backup_dir/$backup_file" \
        $REDSOCKS_CONFIG \
        /etc/systemd/system/tcp-bypass.service \
        /etc/iptables/rules.v4 \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_info "Configuration backup created: $backup_dir/$backup_file"
    else
        log_error "Failed to create backup"
    fi
    
    wait_for_key
}

# Restore configuration
restore_configuration() {
    echo
    echo -e "${YELLOW}Available configuration backups:${NC}"
    echo
    
    local backup_dir="/opt/mastermind/backup/tcp-bypass"
    if [ -d "$backup_dir" ]; then
        ls -la "$backup_dir"/*.tar.gz 2>/dev/null
        echo
        
        local backup_file
        backup_file=$(get_input "Enter backup filename (without path)" "" "")
        
        if [ -f "$backup_dir/$backup_file" ]; then
            if confirm "Restore configuration from $backup_file?"; then
                log_info "Restoring configuration..."
                
                # Extract backup
                tar -xzf "$backup_dir/$backup_file" -C /
                
                # Reload systemd
                systemctl daemon-reload
                
                # Restart services
                systemctl restart redsocks
                systemctl restart tcp-bypass
                
                log_info "Configuration restored successfully"
            fi
        else
            log_error "Backup file not found: $backup_file"
        fi
    else
        log_warn "No backup directory found"
    fi
    
    wait_for_key
}

# Troubleshooting
troubleshooting() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             TROUBLESHOOTING                                  ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Common Issues and Solutions:${NC}"
    echo
    
    echo -e "${YELLOW}1. Service not starting:${NC}"
    echo -e "   - Check if upstream proxy is running"
    echo -e "   - Verify configuration syntax"
    echo -e "   - Check port conflicts"
    echo
    
    echo -e "${YELLOW}2. No traffic being bypassed:${NC}"
    echo -e "   - Check iptables rules"
    echo -e "   - Verify bypass chain exists"
    echo -e "   - Check if applications are configured"
    echo
    
    echo -e "${YELLOW}3. Connection errors:${NC}"
    echo -e "   - Check upstream proxy connectivity"
    echo -e "   - Verify proxy credentials"
    echo -e "   - Check firewall rules"
    echo
    
    echo -e "${YELLOW}4. Performance issues:${NC}"
    echo -e "   - Apply performance tuning"
    echo -e "   - Check system resources"
    echo -e "   - Monitor connection counts"
    echo
    
    echo -e "${YELLOW}Current Status:${NC}"
    echo -e "  Redsocks: $(get_service_status "redsocks")"
    echo -e "  TCP Bypass: $(get_service_status "tcp-bypass")"
    echo -e "  Python Proxy: $(get_service_status "python-proxy")"
    echo
    
    echo -e "${YELLOW}Quick Fix Commands:${NC}"
    echo -e "  systemctl restart redsocks"
    echo -e "  systemctl restart tcp-bypass"
    echo -e "  iptables -t nat -L MASTERMIND_BYPASS"
    echo
    
    wait_for_key
}

# Validate IP or network
validate_ip_or_network() {
    local input=$1
    
    # Check if it's a single IP
    if validate_ip "$input"; then
        return 0
    fi
    
    # Check if it's a network (contains /)
    if [[ "$input" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 0
    fi
    
    return 1
}

# Service management functions
start_service() {
    # Start redsocks
    redsocks -c $REDSOCKS_CONFIG
    
    # Setup iptables rules
    setup_iptables_rules
}

stop_service() {
    # Stop redsocks
    pkill redsocks
    
    # Remove iptables rules
    iptables -t nat -D OUTPUT -p tcp -j $BYPASS_CHAIN 2>/dev/null || true
    iptables -t nat -F $BYPASS_CHAIN 2>/dev/null || true
}

reload_service() {
    # Stop and start
    stop_service
    sleep 2
    start_service
}

# Main function
main() {
    case ${1:-"menu"} in
        "start_service") start_service ;;
        "stop_service") stop_service ;;
        "reload_service") reload_service ;;
        "menu"|*)
            while true; do
                show_tcp_bypass_menu
                read -p "Enter your choice [0-9]: " choice
                
                case $choice in
                    1) install_redsocks ;;
                    2) start_tcp_bypass ;;
                    3) stop_tcp_bypass ;;
                    4) configure_bypass_rules ;;
                    5) configure_upstream_proxy ;;
                    6) view_bypass_statistics ;;
                    7) test_bypass_connectivity ;;
                    8) advanced_configuration ;;
                    9) troubleshooting ;;
                    0) exit 0 ;;
                    *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
                esac
            done
            ;;
    esac
}

# Run main function
main "$@"
