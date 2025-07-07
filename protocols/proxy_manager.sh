#!/bin/bash

# Mastermind VPS Toolkit - Python Proxy Manager
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Show proxy management menu
show_proxy_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                         PYTHON PROXY SUITE MANAGEMENT                        ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Show service status
    local service_status=$(get_service_status "python-proxy")
    echo -e "${YELLOW}Service Status:${NC} $service_status"
    
    # Show port status
    echo -e "${YELLOW}Port Status:${NC}"
    echo -e "  SOCKS5 ($SOCKS_PORT): $(get_port_status $SOCKS_PORT)"
    
    # Convert RESPONSE_PORTS string to array
    IFS=',' read -ra PORTS_ARRAY <<< "$RESPONSE_PORTS"
    for port in "${PORTS_ARRAY[@]}"; do
        echo -e "  HTTP Response ($port): $(get_port_status $port)"
    done
    
    echo
    echo -e "${YELLOW}  [1] Start/Restart Proxy Suite${NC}"
    echo -e "${YELLOW}  [2] Stop Proxy Suite${NC}"
    echo -e "${YELLOW}  [3] Configure SOCKS5 Port${NC}"
    echo -e "${YELLOW}  [4] Configure Response Ports${NC}"
    echo -e "${YELLOW}  [5] Change Response Message${NC}"
    echo -e "${YELLOW}  [6] View Proxy Logs${NC}"
    echo -e "${YELLOW}  [7] Connection Statistics${NC}"
    echo -e "${YELLOW}  [8] Test Proxy Connectivity${NC}"
    echo -e "${YELLOW}  [9] Advanced Configuration${NC}"
    echo -e "${YELLOW}  [0] Back to Protocol Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Start/restart proxy suite
start_proxy_suite() {
    log_info "Starting Python Proxy Suite..."
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "python-proxy.service"; then
        log_error "Python proxy service not found. Installing..."
        install_proxy_service
    fi
    
    # Start the service
    systemctl restart python-proxy
    sleep 2
    
    if is_service_running "python-proxy"; then
        log_info "Python Proxy Suite started successfully"
        echo
        echo -e "${GREEN}✓ SOCKS5 Proxy: Running on port $SOCKS_PORT${NC}"
        IFS=',' read -ra PORTS_ARRAY <<< "$RESPONSE_PORTS"
        for port in "${PORTS_ARRAY[@]}"; do
            echo -e "${GREEN}✓ HTTP Response Server: Running on port $port${NC}"
        done
    else
        log_error "Failed to start Python Proxy Suite"
        echo
        echo -e "${RED}Service logs:${NC}"
        journalctl -u python-proxy -n 10 --no-pager
    fi
    
    echo
    wait_for_key
}

# Stop proxy suite
stop_proxy_suite() {
    log_info "Stopping Python Proxy Suite..."
    
    systemctl stop python-proxy
    
    if ! is_service_running "python-proxy"; then
        log_info "Python Proxy Suite stopped successfully"
    else
        log_error "Failed to stop Python Proxy Suite"
    fi
    
    wait_for_key
}

# Configure SOCKS5 port
configure_socks5_port() {
    echo
    echo -e "${YELLOW}Current SOCKS5 port: $SOCKS_PORT${NC}"
    echo
    
    local new_port
    new_port=$(get_input "Enter new SOCKS5 port" "validate_port" "$SOCKS_PORT")
    
    if [ "$new_port" != "$SOCKS_PORT" ]; then
        # Update configuration
        sed -i "s/SOCKS_PORT=.*/SOCKS_PORT=$new_port/" /opt/mastermind/core/config.cfg
        
        # Update firewall
        ufw delete allow $SOCKS_PORT/tcp 2>/dev/null || true
        ufw allow $new_port/tcp
        
        log_info "SOCKS5 port updated to $new_port"
        
        if confirm "Restart proxy service to apply changes?"; then
            systemctl restart python-proxy
        fi
    fi
    
    wait_for_key
}

# Configure response ports
configure_response_ports() {
    echo
    echo -e "${YELLOW}Current response ports: $RESPONSE_PORTS${NC}"
    echo
    
    local new_ports
    new_ports=$(get_input "Enter new response ports (comma-separated)" "" "$RESPONSE_PORTS")
    
    if [ "$new_ports" != "$RESPONSE_PORTS" ]; then
        # Update configuration
        sed -i "s/RESPONSE_PORTS=.*/RESPONSE_PORTS=\"$new_ports\"/" /opt/mastermind/core/config.cfg
        
        # Update firewall for new ports
        IFS=',' read -ra PORTS <<< "$new_ports"
        for port in "${PORTS[@]}"; do
            port=$(echo "$port" | tr -d ' ')
            if validate_port "$port"; then
                # Update firewall
                ufw allow $port/tcp
            fi
        done
        
        log_info "Response ports updated"
        
        if confirm "Restart proxy service to apply changes?"; then
            systemctl restart python-proxy
        fi
    fi
    
    wait_for_key
}

# Change response message
change_response_message() {
    echo
    echo -e "${YELLOW}Current response message: $RESPONSE_MSG${NC}"
    echo
    
    local new_message
    new_message=$(get_input "Enter new response message" "" "$RESPONSE_MSG")
    
    if [ "$new_message" != "$RESPONSE_MSG" ]; then
        # Update configuration
        sed -i "s/RESPONSE_MSG=.*/RESPONSE_MSG=\"$new_message\"/" /etc/default/python-proxy
        sed -i "s/BRAND_MESSAGE=.*/BRAND_MESSAGE=\"$new_message\"/" /opt/mastermind/core/config.cfg
        
        log_info "Response message updated"
        
        if confirm "Restart proxy service to apply changes?"; then
            systemctl restart python-proxy
        fi
    fi
    
    wait_for_key
}

# View proxy logs
view_proxy_logs() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           PYTHON PROXY LOGS                                  ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Showing last 50 lines of proxy logs...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
    echo
    
    sleep 2
    
    # Show logs
    journalctl -u python-proxy -n 50 -f
}

# Connection statistics
show_connection_stats() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           CONNECTION STATISTICS                               ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # SOCKS5 connections
    local socks5_connections=$(netstat -an | grep ":$PYTHON_PROXY_PORT " | grep ESTABLISHED | wc -l)
    echo -e "${YELLOW}SOCKS5 Proxy (Port $PYTHON_PROXY_PORT):${NC}"
    echo -e "  Active connections: ${GREEN}$socks5_connections${NC}"
    echo -e "  Listening: $(get_port_status $PYTHON_PROXY_PORT)"
    echo
    
    # HTTP Response servers
    echo -e "${YELLOW}HTTP Response Servers:${NC}"
    for port in "${RESPONSE_PORTS[@]}"; do
        local http_connections=$(netstat -an | grep ":$port " | grep ESTABLISHED | wc -l)
        echo -e "  Port $port: ${GREEN}$http_connections${NC} connections, $(get_port_status $port)"
    done
    echo
    
    # System statistics
    echo -e "${YELLOW}System Statistics:${NC}"
    echo -e "  CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')"
    echo -e "  Memory Usage: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
    echo -e "  Network Connections: $(netstat -an | grep ESTABLISHED | wc -l)"
    echo
    
    # Service uptime
    local uptime=$(systemctl show python-proxy --property=ActiveEnterTimestamp | cut -d= -f2)
    if [ -n "$uptime" ] && [ "$uptime" != "0" ]; then
        echo -e "${YELLOW}Service Uptime:${NC}"
        echo -e "  Started: $uptime"
    fi
    
    echo
    wait_for_key
}

# Test proxy connectivity
test_proxy_connectivity() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           PROXY CONNECTIVITY TEST                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Testing proxy connectivity..."
    echo
    
    # Test SOCKS5 proxy
    echo -e "${YELLOW}Testing SOCKS5 proxy (port $PYTHON_PROXY_PORT)...${NC}"
    if netstat -tuln | grep -q ":$PYTHON_PROXY_PORT "; then
        echo -e "${GREEN}✓ SOCKS5 proxy is listening on port $PYTHON_PROXY_PORT${NC}"
        
        # Test connection
        if timeout 5 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/$PYTHON_PROXY_PORT" 2>/dev/null; then
            echo -e "${GREEN}✓ SOCKS5 proxy is accepting connections${NC}"
        else
            echo -e "${RED}✗ SOCKS5 proxy is not accepting connections${NC}"
        fi
    else
        echo -e "${RED}✗ SOCKS5 proxy is not listening on port $PYTHON_PROXY_PORT${NC}"
    fi
    echo
    
    # Test HTTP response servers
    echo -e "${YELLOW}Testing HTTP response servers...${NC}"
    for port in "${RESPONSE_PORTS[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            echo -e "${GREEN}✓ HTTP server is listening on port $port${NC}"
            
            # Test HTTP response
            local response=$(curl -s -m 5 "http://127.0.0.1:$port" 2>/dev/null)
            if [[ "$response" == *"$RESPONSE_MSG"* ]]; then
                echo -e "${GREEN}✓ HTTP server on port $port is responding correctly${NC}"
            else
                echo -e "${YELLOW}? HTTP server on port $port is responding but content may be incorrect${NC}"
            fi
        else
            echo -e "${RED}✗ HTTP server is not listening on port $port${NC}"
        fi
    done
    echo
    
    # Test external connectivity
    echo -e "${YELLOW}Testing external connectivity...${NC}"
    if curl -s -m 5 google.com > /dev/null; then
        echo -e "${GREEN}✓ External connectivity is working${NC}"
    else
        echo -e "${RED}✗ External connectivity is not working${NC}"
    fi
    echo
    
    wait_for_key
}

# Advanced configuration
advanced_configuration() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           ADVANCED CONFIGURATION                             ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] Edit Service Configuration${NC}"
        echo -e "${YELLOW}  [2] Configure Logging Level${NC}"
        echo -e "${YELLOW}  [3] Enable/Disable WebSocket Proxy${NC}"
        echo -e "${YELLOW}  [4] Enable/Disable HTTP Proxy${NC}"
        echo -e "${YELLOW}  [5] Configure SSL/TLS${NC}"
        echo -e "${YELLOW}  [6] Backup Configuration${NC}"
        echo -e "${YELLOW}  [7] Restore Configuration${NC}"
        echo -e "${YELLOW}  [0] Back to Proxy Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) edit_service_config ;;
            2) configure_logging_level ;;
            3) toggle_websocket_proxy ;;
            4) toggle_http_proxy ;;
            5) configure_ssl_tls ;;
            6) backup_configuration ;;
            7) restore_configuration ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Edit service configuration
edit_service_config() {
    echo
    echo -e "${YELLOW}Editing service configuration...${NC}"
    echo
    
    # Backup current configuration
    backup_file /etc/default/python-proxy
    
    # Edit configuration
    nano /etc/default/python-proxy
    
    if confirm "Restart service to apply changes?"; then
        systemctl restart python-proxy
    fi
    
    wait_for_key
}

# Configure logging level
configure_logging_level() {
    echo
    echo -e "${YELLOW}Current logging level: ${LOG_LEVEL:-INFO}${NC}"
    echo
    echo -e "${YELLOW}Available levels:${NC}"
    echo -e "  1. DEBUG (most verbose)"
    echo -e "  2. INFO (default)"
    echo -e "  3. WARNING"
    echo -e "  4. ERROR"
    echo -e "  5. CRITICAL (least verbose)"
    echo
    
    read -p "Choose logging level [1-5]: " level_choice
    
    case $level_choice in
        1) new_level="DEBUG" ;;
        2) new_level="INFO" ;;
        3) new_level="WARNING" ;;
        4) new_level="ERROR" ;;
        5) new_level="CRITICAL" ;;
        *) 
            echo -e "${RED}Invalid choice${NC}"
            wait_for_key
            return
            ;;
    esac
    
    # Update configuration
    sed -i "s/LOG_LEVEL=.*/LOG_LEVEL=$new_level/" /etc/default/python-proxy
    
    log_info "Logging level updated to $new_level"
    
    if confirm "Restart service to apply changes?"; then
        systemctl restart python-proxy
    fi
    
    wait_for_key
}

# Toggle WebSocket proxy
toggle_websocket_proxy() {
    local current_state=$(grep "ENABLE_WEBSOCKET" /etc/default/python-proxy | cut -d= -f2 | tr -d '"')
    
    echo
    echo -e "${YELLOW}Current WebSocket proxy state: ${current_state:-true}${NC}"
    echo
    
    if [ "$current_state" = "true" ]; then
        if confirm "Disable WebSocket proxy?"; then
            sed -i "s/ENABLE_WEBSOCKET=.*/ENABLE_WEBSOCKET=false/" /etc/default/python-proxy
            log_info "WebSocket proxy disabled"
        fi
    else
        if confirm "Enable WebSocket proxy?"; then
            sed -i "s/ENABLE_WEBSOCKET=.*/ENABLE_WEBSOCKET=true/" /etc/default/python-proxy
            log_info "WebSocket proxy enabled"
        fi
    fi
    
    if confirm "Restart service to apply changes?"; then
        systemctl restart python-proxy
    fi
    
    wait_for_key
}

# Toggle HTTP proxy
toggle_http_proxy() {
    local current_state=$(grep "ENABLE_HTTP_PROXY" /etc/default/python-proxy | cut -d= -f2 | tr -d '"')
    
    echo
    echo -e "${YELLOW}Current HTTP proxy state: ${current_state:-true}${NC}"
    echo
    
    if [ "$current_state" = "true" ]; then
        if confirm "Disable HTTP proxy?"; then
            sed -i "s/ENABLE_HTTP_PROXY=.*/ENABLE_HTTP_PROXY=false/" /etc/default/python-proxy
            log_info "HTTP proxy disabled"
        fi
    else
        if confirm "Enable HTTP proxy?"; then
            sed -i "s/ENABLE_HTTP_PROXY=.*/ENABLE_HTTP_PROXY=true/" /etc/default/python-proxy
            log_info "HTTP proxy enabled"
        fi
    fi
    
    if confirm "Restart service to apply changes?"; then
        systemctl restart python-proxy
    fi
    
    wait_for_key
}

# Configure SSL/TLS
configure_ssl_tls() {
    echo
    echo -e "${YELLOW}SSL/TLS Configuration${NC}"
    echo
    echo -e "${YELLOW}This feature is coming soon...${NC}"
    echo
    wait_for_key
}

# Backup configuration
backup_configuration() {
    echo
    log_info "Creating configuration backup..."
    
    local backup_dir="/opt/mastermind/backup/proxy"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="proxy_config_${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    # Create backup
    tar -czf "$backup_dir/$backup_file" \
        /etc/default/python-proxy \
        /opt/mastermind/protocols/python_proxy.py \
        /etc/systemd/system/python-proxy.service \
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
    
    local backup_dir="/opt/mastermind/backup/proxy"
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
                
                # Restart service
                systemctl restart python-proxy
                
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

# Install proxy service
install_proxy_service() {
    log_info "Installing Python proxy service..."
    
    # Copy service file
    cp /opt/mastermind/systemd/python-proxy.service /etc/systemd/system/
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable python-proxy
    
    log_info "Python proxy service installed"
}

# Main function
main() {
    while true; do
        show_proxy_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) start_proxy_suite ;;
            2) stop_proxy_suite ;;
            3) configure_socks5_port ;;
            4) configure_response_ports ;;
            5) change_response_message ;;
            6) view_proxy_logs ;;
            7) show_connection_stats ;;
            8) test_proxy_connectivity ;;
            9) advanced_configuration ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
