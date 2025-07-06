#!/bin/bash

# Mastermind VPS Toolkit - BadVPN Setup
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# BadVPN configuration
BADVPN_DIR="/opt/badvpn"
BADVPN_CONFIG_DIR="/etc/badvpn"
BADVPN_LOG_DIR="/var/log/mastermind"
UDPGW_PORT=7300
TUN2SOCKS_PORT=8888

# Show BadVPN setup menu
show_badvpn_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             BADVPN SETUP MANAGEMENT                          ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Show service status
    echo -e "${YELLOW}Service Status:${NC}"
    echo -e "  UDP Gateway: $(get_service_status "badvpn-udpgw")"
    echo -e "  Tun2Socks: $(get_service_status "badvpn-tun2socks")"
    
    # Show port status
    echo -e "${YELLOW}Port Status:${NC}"
    echo -e "  UDP Gateway ($UDPGW_PORT): $(get_port_status $UDPGW_PORT)"
    echo -e "  Tun2Socks ($TUN2SOCKS_PORT): $(get_port_status $TUN2SOCKS_PORT)"
    
    # Show installation status
    echo -e "${YELLOW}Installation Status:${NC}"
    if command_exists badvpn-udpgw; then
        echo -e "  BadVPN: ${GREEN}Installed${NC}"
    else
        echo -e "  BadVPN: ${RED}Not Installed${NC}"
    fi
    
    echo
    echo -e "${YELLOW}  [1] Install BadVPN${NC}"
    echo -e "${YELLOW}  [2] Configure UDP Gateway${NC}"
    echo -e "${YELLOW}  [3] Configure Tun2Socks${NC}"
    echo -e "${YELLOW}  [4] Start BadVPN Services${NC}"
    echo -e "${YELLOW}  [5] Stop BadVPN Services${NC}"
    echo -e "${YELLOW}  [6] Monitor Connections${NC}"
    echo -e "${YELLOW}  [7] Performance Tuning${NC}"
    echo -e "${YELLOW}  [8] Client Configuration${NC}"
    echo -e "${YELLOW}  [9] Troubleshooting${NC}"
    echo -e "${YELLOW}  [0] Back to Protocol Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Install BadVPN
install_badvpn() {
    log_info "Installing BadVPN..."
    
    # Check if already installed
    if command_exists badvpn-udpgw; then
        log_warn "BadVPN is already installed"
        if ! confirm "Reinstall BadVPN?"; then
            return
        fi
    fi
    
    # Install dependencies
    log_info "Installing build dependencies..."
    apt update
    apt install -y build-essential cmake git libssl-dev pkg-config
    
    # Create build directory
    mkdir -p /tmp/badvpn-build
    cd /tmp/badvpn-build
    
    # Clone BadVPN source
    log_info "Downloading BadVPN source code..."
    git clone https://github.com/ambrop72/badvpn.git
    cd badvpn
    
    # Build BadVPN
    log_info "Building BadVPN..."
    mkdir build
    cd build
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 -DBUILD_TUN2SOCKS=1
    make -j$(nproc)
    
    # Install BadVPN
    log_info "Installing BadVPN..."
    cp udpgw/badvpn-udpgw /usr/local/bin/
    cp tun2socks/badvpn-tun2socks /usr/local/bin/
    
    # Set permissions
    chmod +x /usr/local/bin/badvpn-udpgw
    chmod +x /usr/local/bin/badvpn-tun2socks
    
    # Create directories
    mkdir -p "$BADVPN_CONFIG_DIR"
    mkdir -p "$BADVPN_LOG_DIR"
    
    # Clean up
    cd /
    rm -rf /tmp/badvpn-build
    
    if command_exists badvpn-udpgw; then
        log_info "BadVPN installed successfully"
        
        # Create systemd services
        create_badvpn_services
        
        log_info "BadVPN services created"
    else
        log_error "Failed to install BadVPN"
    fi
    
    wait_for_key
}

# Create BadVPN systemd services
create_badvpn_services() {
    log_info "Creating BadVPN systemd services..."
    
    # UDP Gateway service
    cat > /etc/systemd/system/badvpn-udpgw.service << EOF
[Unit]
Description=BadVPN UDP Gateway
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 0.0.0.0:$UDPGW_PORT --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Tun2Socks service
    cat > /etc/systemd/system/badvpn-tun2socks.service << EOF
[Unit]
Description=BadVPN Tun2Socks
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/badvpn-tun2socks --tundev tun0 --netif-ipaddr 10.0.0.2 --netif-netmask 255.255.255.0 --socks-server-addr 127.0.0.1:$PYTHON_PROXY_PORT
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    log_info "BadVPN systemd services created"
}

# Configure UDP Gateway
configure_udp_gateway() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           UDP GATEWAY CONFIGURATION                          ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Current Configuration:${NC}"
    echo -e "  Listen Port: $UDPGW_PORT"
    echo -e "  Max Clients: 1000"
    echo -e "  Max Connections per Client: 10"
    echo
    
    local new_port
    new_port=$(get_input "UDP Gateway port" "validate_port" "$UDPGW_PORT")
    
    local max_clients
    max_clients=$(get_input "Maximum clients" "validate_number" "1000")
    
    local max_connections
    max_connections=$(get_input "Maximum connections per client" "validate_number" "10")
    
    local bind_addr
    bind_addr=$(get_input "Bind address" "validate_ip" "0.0.0.0")
    
    # Update service configuration
    cat > /etc/systemd/system/badvpn-udpgw.service << EOF
[Unit]
Description=BadVPN UDP Gateway
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr $bind_addr:$new_port --max-clients $max_clients --max-connections-for-client $max_connections
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Update firewall
    ufw allow $new_port/udp
    
    # Reload systemd
    systemctl daemon-reload
    
    log_info "UDP Gateway configuration updated"
    
    if confirm "Restart UDP Gateway service?"; then
        systemctl restart badvpn-udpgw
    fi
    
    wait_for_key
}

# Configure Tun2Socks
configure_tun2socks() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           TUN2SOCKS CONFIGURATION                            ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Current Configuration:${NC}"
    echo -e "  TUN Device: tun0"
    echo -e "  IP Address: 10.0.0.2"
    echo -e "  Netmask: 255.255.255.0"
    echo -e "  SOCKS Server: 127.0.0.1:$PYTHON_PROXY_PORT"
    echo
    
    local tun_device
    tun_device=$(get_input "TUN device name" "" "tun0")
    
    local tun_ip
    tun_ip=$(get_input "TUN IP address" "validate_ip" "10.0.0.2")
    
    local tun_netmask
    tun_netmask=$(get_input "TUN netmask" "validate_ip" "255.255.255.0")
    
    local socks_server
    socks_server=$(get_input "SOCKS server address" "" "127.0.0.1")
    
    local socks_port
    socks_port=$(get_input "SOCKS server port" "validate_port" "$PYTHON_PROXY_PORT")
    
    # Update service configuration
    cat > /etc/systemd/system/badvpn-tun2socks.service << EOF
[Unit]
Description=BadVPN Tun2Socks
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/badvpn-tun2socks --tundev $tun_device --netif-ipaddr $tun_ip --netif-netmask $tun_netmask --socks-server-addr $socks_server:$socks_port
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    log_info "Tun2Socks configuration updated"
    
    if confirm "Restart Tun2Socks service?"; then
        systemctl restart badvpn-tun2socks
    fi
    
    wait_for_key
}

# Start BadVPN services
start_badvpn_services() {
    log_info "Starting BadVPN services..."
    
    # Check if BadVPN is installed
    if ! command_exists badvpn-udpgw; then
        log_error "BadVPN is not installed"
        if confirm "Install BadVPN now?"; then
            install_badvpn
            return
        else
            return
        fi
    fi
    
    # Start UDP Gateway
    systemctl enable badvpn-udpgw
    systemctl start badvpn-udpgw
    
    # Start Tun2Socks
    systemctl enable badvpn-tun2socks
    systemctl start badvpn-tun2socks
    
    sleep 2
    
    # Check service status
    if is_service_running "badvpn-udpgw"; then
        log_info "UDP Gateway service started successfully"
    else
        log_error "Failed to start UDP Gateway service"
    fi
    
    if is_service_running "badvpn-tun2socks"; then
        log_info "Tun2Socks service started successfully"
    else
        log_error "Failed to start Tun2Socks service"
    fi
    
    # Show service status
    echo
    echo -e "${YELLOW}Service Status:${NC}"
    systemctl status badvpn-udpgw --no-pager -l
    echo
    systemctl status badvpn-tun2socks --no-pager -l
    
    wait_for_key
}

# Stop BadVPN services
stop_badvpn_services() {
    log_info "Stopping BadVPN services..."
    
    # Stop services
    systemctl stop badvpn-udpgw
    systemctl stop badvpn-tun2socks
    
    # Disable services
    systemctl disable badvpn-udpgw
    systemctl disable badvpn-tun2socks
    
    # Remove TUN interface
    ip link delete tun0 2>/dev/null || true
    
    log_info "BadVPN services stopped"
    
    wait_for_key
}

# Monitor connections
monitor_connections() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           BADVPN CONNECTION MONITOR                          ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Service Status:${NC}"
    echo -e "  UDP Gateway: $(get_service_status "badvpn-udpgw")"
    echo -e "  Tun2Socks: $(get_service_status "badvpn-tun2socks")"
    echo
    
    echo -e "${YELLOW}Network Interfaces:${NC}"
    ip link show | grep -E "(tun|tap)" || echo "  No TUN/TAP interfaces found"
    echo
    
    echo -e "${YELLOW}UDP Gateway Connections:${NC}"
    local udp_connections=$(netstat -un | grep ":$UDPGW_PORT " | wc -l)
    echo -e "  Active UDP connections: $udp_connections"
    echo
    
    echo -e "${YELLOW}Process Information:${NC}"
    ps aux | grep badvpn | grep -v grep
    echo
    
    echo -e "${YELLOW}Memory Usage:${NC}"
    local udpgw_mem=$(ps -o pid,vsz,rss,comm -p $(pgrep badvpn-udpgw) 2>/dev/null | tail -1)
    local tun2socks_mem=$(ps -o pid,vsz,rss,comm -p $(pgrep badvpn-tun2socks) 2>/dev/null | tail -1)
    
    if [ -n "$udpgw_mem" ]; then
        echo -e "  UDP Gateway: $udpgw_mem"
    fi
    
    if [ -n "$tun2socks_mem" ]; then
        echo -e "  Tun2Socks: $tun2socks_mem"
    fi
    
    echo
    echo -e "${YELLOW}Recent Log Entries:${NC}"
    journalctl -u badvpn-udpgw -n 5 --no-pager | tail -5
    echo
    
    if confirm "Enable real-time monitoring?"; then
        echo -e "${YELLOW}Real-time monitoring (Press Ctrl+C to exit):${NC}"
        echo
        
        while true; do
            clear
            echo -e "${YELLOW}BadVPN Real-time Monitor - $(date)${NC}"
            echo
            
            # Show connections
            local current_udp=$(netstat -un | grep ":$UDPGW_PORT " | wc -l)
            echo -e "UDP Gateway connections: $current_udp"
            
            # Show processes
            ps aux | grep badvpn | grep -v grep
            
            # Show network stats
            echo
            echo -e "${YELLOW}Network Statistics:${NC}"
            cat /proc/net/dev | grep tun0 2>/dev/null || echo "TUN interface not found"
            
            sleep 5
        done
    fi
    
    wait_for_key
}

# Performance tuning
performance_tuning() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           PERFORMANCE TUNING                                 ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}BadVPN Performance Optimization${NC}"
    echo
    
    if confirm "Apply performance optimizations?"; then
        log_info "Applying performance optimizations..."
        
        # Kernel parameters for better networking performance
        cat >> /etc/sysctl.conf << EOF

# BadVPN Performance Tuning
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 30000
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 9
EOF
        
        # Apply kernel parameters
        sysctl -p
        
        # Optimize UDP Gateway service
        cat > /etc/systemd/system/badvpn-udpgw.service << EOF
[Unit]
Description=BadVPN UDP Gateway (Optimized)
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 0.0.0.0:$UDPGW_PORT --max-clients 5000 --max-connections-for-client 20
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
LimitNOFILE=65536
LimitNPROC=32768

[Install]
WantedBy=multi-user.target
EOF
        
        # Reload systemd
        systemctl daemon-reload
        
        log_info "Performance optimizations applied"
        
        if confirm "Restart BadVPN services to apply changes?"; then
            systemctl restart badvpn-udpgw
            systemctl restart badvpn-tun2socks
        fi
    fi
    
    wait_for_key
}

# Client configuration
client_configuration() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           CLIENT CONFIGURATION                               ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    local server_ip=$(get_public_ip)
    
    echo -e "${YELLOW}BadVPN Client Configuration:${NC}"
    echo
    
    echo -e "${YELLOW}UDP Gateway Settings:${NC}"
    echo -e "  Server: $server_ip"
    echo -e "  Port: $UDPGW_PORT"
    echo -e "  Protocol: UDP"
    echo
    
    echo -e "${YELLOW}SOCKS5 Proxy Settings:${NC}"
    echo -e "  Server: $server_ip"
    echo -e "  Port: $PYTHON_PROXY_PORT"
    echo -e "  Protocol: SOCKS5"
    echo
    
    echo -e "${YELLOW}Android Configuration:${NC}"
    echo -e "  1. Download HTTP Injector or similar app"
    echo -e "  2. Configure SOCKS proxy: $server_ip:$PYTHON_PROXY_PORT"
    echo -e "  3. Enable UDP Gateway: $server_ip:$UDPGW_PORT"
    echo -e "  4. Set payload/config as needed"
    echo
    
    echo -e "${YELLOW}OpenVPN Configuration:${NC}"
    echo -e "  Add to OpenVPN config:"
    echo -e "  socks-proxy $server_ip $PYTHON_PROXY_PORT"
    echo -e "  dhcp-option DNS 8.8.8.8"
    echo -e "  dhcp-option DNS 8.8.4.4"
    echo
    
    echo -e "${YELLOW}HTTP Injector Configuration:${NC}"
    cat > /tmp/http_injector_config.txt << EOF
{
    "proxy": {
        "type": "socks5",
        "host": "$server_ip",
        "port": $PYTHON_PROXY_PORT
    },
    "udpgw": {
        "host": "$server_ip",
        "port": $UDPGW_PORT
    },
    "dns": {
        "primary": "8.8.8.8",
        "secondary": "8.8.4.4"
    }
}
EOF
    
    echo -e "  Configuration file created: /tmp/http_injector_config.txt"
    echo
    
    echo -e "${YELLOW}SSH UDP Configuration:${NC}"
    echo -e "  SSH Command: ssh -D $PYTHON_PROXY_PORT user@$server_ip"
    echo -e "  UDP Gateway: $server_ip:$UDPGW_PORT"
    echo
    
    if confirm "Generate QR code for mobile configuration?"; then
        if command_exists qrencode; then
            local config_url="socks5://$server_ip:$PYTHON_PROXY_PORT?udpgw=$server_ip:$UDPGW_PORT"
            echo
            echo -e "${YELLOW}QR Code for mobile configuration:${NC}"
            qrencode -t UTF8 "$config_url"
            echo
        else
            log_warn "QR code generator not available"
        fi
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
    
    echo -e "${YELLOW}BadVPN Troubleshooting Guide${NC}"
    echo
    
    echo -e "${YELLOW}1. Service Issues:${NC}"
    echo -e "   Problem: Service won't start"
    echo -e "   Solution: Check logs with 'journalctl -u badvpn-udpgw'"
    echo -e "   Solution: Verify port availability"
    echo -e "   Solution: Check file permissions"
    echo
    
    echo -e "${YELLOW}2. Connection Issues:${NC}"
    echo -e "   Problem: Clients can't connect"
    echo -e "   Solution: Check firewall settings"
    echo -e "   Solution: Verify server IP and port"
    echo -e "   Solution: Test with telnet/nc"
    echo
    
    echo -e "${YELLOW}3. Performance Issues:${NC}"
    echo -e "   Problem: Slow connections"
    echo -e "   Solution: Apply performance tuning"
    echo -e "   Solution: Increase max clients"
    echo -e "   Solution: Check system resources"
    echo
    
    echo -e "${YELLOW}4. TUN Interface Issues:${NC}"
    echo -e "   Problem: TUN interface not created"
    echo -e "   Solution: Enable TUN/TAP in kernel"
    echo -e "   Solution: Check permissions"
    echo -e "   Solution: Load tun module"
    echo
    
    echo -e "${YELLOW}Current Status Check:${NC}"
    echo
    
    # Check services
    echo -e "${YELLOW}Service Status:${NC}"
    systemctl is-active badvpn-udpgw && echo -e "  UDP Gateway: ${GREEN}Active${NC}" || echo -e "  UDP Gateway: ${RED}Inactive${NC}"
    systemctl is-active badvpn-tun2socks && echo -e "  Tun2Socks: ${GREEN}Active${NC}" || echo -e "  Tun2Socks: ${RED}Inactive${NC}"
    echo
    
    # Check ports
    echo -e "${YELLOW}Port Status:${NC}"
    netstat -tuln | grep ":$UDPGW_PORT " && echo -e "  UDP Gateway port: ${GREEN}Open${NC}" || echo -e "  UDP Gateway port: ${RED}Closed${NC}"
    netstat -tuln | grep ":$PYTHON_PROXY_PORT " && echo -e "  SOCKS5 port: ${GREEN}Open${NC}" || echo -e "  SOCKS5 port: ${RED}Closed${NC}"
    echo
    
    # Check TUN interface
    echo -e "${YELLOW}TUN Interface:${NC}"
    ip link show tun0 2>/dev/null && echo -e "  TUN interface: ${GREEN}Available${NC}" || echo -e "  TUN interface: ${RED}Not found${NC}"
    echo
    
    # Check processes
    echo -e "${YELLOW}Running Processes:${NC}"
    ps aux | grep badvpn | grep -v grep || echo -e "  No BadVPN processes found"
    echo
    
    # Check logs
    echo -e "${YELLOW}Recent Errors:${NC}"
    journalctl -u badvpn-udpgw -n 3 --no-pager | grep -i error || echo -e "  No recent errors in UDP Gateway"
    journalctl -u badvpn-tun2socks -n 3 --no-pager | grep -i error || echo -e "  No recent errors in Tun2Socks"
    echo
    
    echo -e "${YELLOW}Quick Fix Commands:${NC}"
    echo -e "  systemctl restart badvpn-udpgw"
    echo -e "  systemctl restart badvpn-tun2socks"
    echo -e "  modprobe tun"
    echo -e "  ufw allow $UDPGW_PORT/udp"
    echo -e "  journalctl -u badvpn-udpgw -f"
    echo
    
    wait_for_key
}

# Validate number
validate_number() {
    local number=$1
    if [[ $number =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Main function
main() {
    while true; do
        show_badvpn_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) install_badvpn ;;
            2) configure_udp_gateway ;;
            3) configure_tun2socks ;;
            4) start_badvpn_services ;;
            5) stop_badvpn_services ;;
            6) monitor_connections ;;
            7) performance_tuning ;;
            8) client_configuration ;;
            9) troubleshooting ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
