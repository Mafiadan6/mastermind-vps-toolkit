#!/bin/bash

# Mastermind VPS Toolkit - V2Ray Manager
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# V2Ray configuration
V2RAY_CONFIG_DIR="/opt/mastermind/config"
V2RAY_CONFIG_FILE="$V2RAY_CONFIG_DIR/v2ray.json"
V2RAY_LOG_FILE="/var/log/mastermind/v2ray.log"

# Show V2Ray management menu
show_v2ray_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             V2RAY MANAGEMENT                                 ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Show service status
    local service_status=$(get_service_status "v2ray")
    echo -e "${YELLOW}Service Status:${NC} $service_status"
    echo -e "${YELLOW}Port Status:${NC} $(get_port_status $V2RAY_PORT)"
    
    # Show configuration info
    if [ -f "$V2RAY_CONFIG_FILE" ]; then
        local protocol=$(jq -r '.inbounds[0].protocol' "$V2RAY_CONFIG_FILE" 2>/dev/null)
        local port=$(jq -r '.inbounds[0].port' "$V2RAY_CONFIG_FILE" 2>/dev/null)
        echo -e "${YELLOW}Protocol:${NC} ${protocol:-N/A}"
        echo -e "${YELLOW}Port:${NC} ${port:-N/A}"
    fi
    
    echo
    echo -e "${YELLOW}  [1] Install V2Ray${NC}"
    echo -e "${YELLOW}  [2] Start/Restart V2Ray${NC}"
    echo -e "${YELLOW}  [3] Stop V2Ray${NC}"
    echo -e "${YELLOW}  [4] Configure VLESS${NC}"
    echo -e "${YELLOW}  [5] Configure VMESS${NC}"
    echo -e "${YELLOW}  [6] Configure WebSocket${NC}"
    echo -e "${YELLOW}  [7] Generate Client Config${NC}"
    echo -e "${YELLOW}  [8] View Logs${NC}"
    echo -e "${YELLOW}  [9] Advanced Settings${NC}"
    echo -e "${YELLOW}  [0] Back to Protocol Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Install V2Ray
install_v2ray() {
    log_info "Installing V2Ray..."
    
    # Check if already installed
    if command_exists v2ray; then
        log_warn "V2Ray is already installed"
        if ! confirm "Reinstall V2Ray?"; then
            return
        fi
    fi
    
    # Download and install V2Ray
    curl -Ls https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh | bash
    
    if [ $? -eq 0 ]; then
        log_info "V2Ray installed successfully"
        
        # Create configuration directory
        mkdir -p "$V2RAY_CONFIG_DIR"
        
        # Create default configuration
        create_default_config
        
        # Enable and start service
        systemctl enable v2ray
        systemctl start v2ray
        
        log_info "V2Ray service enabled and started"
    else
        log_error "Failed to install V2Ray"
    fi
    
    wait_for_key
}

# Create default V2Ray configuration
create_default_config() {
    log_info "Creating default V2Ray configuration..."
    
    local uuid=$(uuidgen)
    
    cat > "$V2RAY_CONFIG_FILE" << EOF
{
    "log": {
        "loglevel": "info",
        "access": "/var/log/mastermind/v2ray-access.log",
        "error": "/var/log/mastermind/v2ray-error.log"
    },
    "inbounds": [
        {
            "port": $V2RAY_PORT,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid",
                        "level": 0,
                        "email": "admin@mastermind.local"
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
            "protocol": "freedom",
            "settings": {}
        }
    ]
}
EOF
    
    log_info "Default configuration created with UUID: $uuid"
}

# Start/restart V2Ray
start_v2ray() {
    log_info "Starting V2Ray service..."
    
    # Check if V2Ray is installed
    if ! command_exists v2ray; then
        log_error "V2Ray is not installed"
        if confirm "Install V2Ray now?"; then
            install_v2ray
            return
        else
            return
        fi
    fi
    
    # Validate configuration
    if ! validate_config; then
        log_error "Invalid V2Ray configuration"
        return
    fi
    
    # Start service
    systemctl restart v2ray
    
    sleep 2
    
    if is_service_running "v2ray"; then
        log_info "V2Ray service started successfully"
    else
        log_error "Failed to start V2Ray service"
        echo
        echo -e "${RED}Service logs:${NC}"
        journalctl -u v2ray -n 10 --no-pager
    fi
    
    wait_for_key
}

# Stop V2Ray
stop_v2ray() {
    log_info "Stopping V2Ray service..."
    
    systemctl stop v2ray
    
    if ! is_service_running "v2ray"; then
        log_info "V2Ray service stopped successfully"
    else
        log_error "Failed to stop V2Ray service"
    fi
    
    wait_for_key
}

# Configure VLESS
configure_vless() {
    echo
    echo -e "${YELLOW}VLESS Configuration${NC}"
    echo
    
    local uuid=$(get_input "Client UUID (leave empty to generate)" "" "$(uuidgen)")
    local port=$(get_input "Port" "validate_port" "$V2RAY_PORT")
    local path=$(get_input "WebSocket Path" "" "/mastermind")
    local email=$(get_input "Client Email" "" "admin@mastermind.local")
    
    # Create VLESS configuration
    cat > "$V2RAY_CONFIG_FILE" << EOF
{
    "log": {
        "loglevel": "info",
        "access": "/var/log/mastermind/v2ray-access.log",
        "error": "/var/log/mastermind/v2ray-error.log"
    },
    "inbounds": [
        {
            "port": $port,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid",
                        "level": 0,
                        "email": "$email"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "$path"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ]
}
EOF
    
    log_info "VLESS configuration created"
    log_info "UUID: $uuid"
    log_info "Port: $port"
    log_info "Path: $path"
    
    if confirm "Restart V2Ray to apply changes?"; then
        systemctl restart v2ray
    fi
    
    wait_for_key
}

# Configure VMESS
configure_vmess() {
    echo
    echo -e "${YELLOW}VMESS Configuration${NC}"
    echo
    
    local uuid=$(get_input "Client UUID (leave empty to generate)" "" "$(uuidgen)")
    local port=$(get_input "Port" "validate_port" "$V2RAY_PORT")
    local path=$(get_input "WebSocket Path" "" "/mastermind")
    local email=$(get_input "Client Email" "" "admin@mastermind.local")
    local alterId=$(get_input "Alter ID" "validate_number" "0")
    
    # Create VMESS configuration
    cat > "$V2RAY_CONFIG_FILE" << EOF
{
    "log": {
        "loglevel": "info",
        "access": "/var/log/mastermind/v2ray-access.log",
        "error": "/var/log/mastermind/v2ray-error.log"
    },
    "inbounds": [
        {
            "port": $port,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid",
                        "level": 0,
                        "alterId": $alterId,
                        "email": "$email"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "$path"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ]
}
EOF
    
    log_info "VMESS configuration created"
    log_info "UUID: $uuid"
    log_info "Port: $port"
    log_info "Path: $path"
    log_info "Alter ID: $alterId"
    
    if confirm "Restart V2Ray to apply changes?"; then
        systemctl restart v2ray
    fi
    
    wait_for_key
}

# Configure WebSocket
configure_websocket() {
    echo
    echo -e "${YELLOW}WebSocket Configuration${NC}"
    echo
    
    local path=$(get_input "WebSocket Path" "" "/mastermind")
    local headers=$(get_input "Custom Headers (optional)" "" "")
    
    # Update current configuration
    if [ -f "$V2RAY_CONFIG_FILE" ]; then
        # Use jq to update WebSocket settings
        jq --arg path "$path" '.inbounds[0].streamSettings.wsSettings.path = $path' "$V2RAY_CONFIG_FILE" > /tmp/v2ray_temp.json
        mv /tmp/v2ray_temp.json "$V2RAY_CONFIG_FILE"
        
        log_info "WebSocket configuration updated"
        log_info "Path: $path"
        
        if confirm "Restart V2Ray to apply changes?"; then
            systemctl restart v2ray
        fi
    else
        log_error "V2Ray configuration file not found"
    fi
    
    wait_for_key
}

# Generate client configuration
generate_client_config() {
    echo
    echo -e "${YELLOW}Client Configuration Generator${NC}"
    echo
    
    if [ ! -f "$V2RAY_CONFIG_FILE" ]; then
        log_error "V2Ray configuration file not found"
        wait_for_key
        return
    fi
    
    # Extract configuration details
    local protocol=$(jq -r '.inbounds[0].protocol' "$V2RAY_CONFIG_FILE")
    local port=$(jq -r '.inbounds[0].port' "$V2RAY_CONFIG_FILE")
    local uuid=$(jq -r '.inbounds[0].settings.clients[0].id' "$V2RAY_CONFIG_FILE")
    local path=$(jq -r '.inbounds[0].streamSettings.wsSettings.path' "$V2RAY_CONFIG_FILE")
    local server_ip=$(get_public_ip)
    
    echo -e "${YELLOW}Client Configuration:${NC}"
    echo
    echo -e "${CYAN}Protocol:${NC} $protocol"
    echo -e "${CYAN}Server:${NC} $server_ip"
    echo -e "${CYAN}Port:${NC} $port"
    echo -e "${CYAN}UUID:${NC} $uuid"
    echo -e "${CYAN}Path:${NC} $path"
    echo
    
    # Generate client config JSON
    cat > /tmp/client_config.json << EOF
{
    "server": "$server_ip",
    "server_port": $port,
    "uuid": "$uuid",
    "protocol": "$protocol",
    "path": "$path",
    "security": "none",
    "network": "ws"
}
EOF
    
    echo -e "${YELLOW}Client configuration saved to: /tmp/client_config.json${NC}"
    
    # Generate QR code if available
    if command_exists qrencode; then
        local config_string="$protocol://$uuid@$server_ip:$port?path=$path&security=none&type=ws#Mastermind-VPS"
        qrencode -t UTF8 "$config_string"
        echo
        echo -e "${YELLOW}QR Code generated above${NC}"
    fi
    
    wait_for_key
}

# View logs
view_logs() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                               V2RAY LOGS                                     ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Choose log type:${NC}"
    echo -e "  [1] Service logs (systemd)"
    echo -e "  [2] Access logs"
    echo -e "  [3] Error logs"
    echo -e "  [4] All logs"
    echo
    
    read -p "Enter your choice [1-4]: " log_choice
    
    case $log_choice in
        1) journalctl -u v2ray -f ;;
        2) tail -f /var/log/mastermind/v2ray-access.log 2>/dev/null || echo "Access log not found" ;;
        3) tail -f /var/log/mastermind/v2ray-error.log 2>/dev/null || echo "Error log not found" ;;
        4) 
            echo -e "${YELLOW}Service logs:${NC}"
            journalctl -u v2ray -n 20 --no-pager
            echo
            echo -e "${YELLOW}Access logs:${NC}"
            tail -20 /var/log/mastermind/v2ray-access.log 2>/dev/null || echo "Access log not found"
            echo
            echo -e "${YELLOW}Error logs:${NC}"
            tail -20 /var/log/mastermind/v2ray-error.log 2>/dev/null || echo "Error log not found"
            wait_for_key
            ;;
        *) echo -e "${RED}Invalid choice${NC}" ; sleep 2 ;;
    esac
}

# Advanced settings
advanced_settings() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           V2RAY ADVANCED SETTINGS                           ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] Edit Raw Configuration${NC}"
        echo -e "${YELLOW}  [2] Add Multiple Clients${NC}"
        echo -e "${YELLOW}  [3] Configure Routing${NC}"
        echo -e "${YELLOW}  [4] Configure DNS${NC}"
        echo -e "${YELLOW}  [5] Backup Configuration${NC}"
        echo -e "${YELLOW}  [6] Restore Configuration${NC}"
        echo -e "${YELLOW}  [7] Reset to Default${NC}"
        echo -e "${YELLOW}  [0] Back to V2Ray Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) edit_raw_config ;;
            2) add_multiple_clients ;;
            3) configure_routing ;;
            4) configure_dns ;;
            5) backup_config ;;
            6) restore_config ;;
            7) reset_to_default ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Edit raw configuration
edit_raw_config() {
    echo
    echo -e "${YELLOW}Editing V2Ray configuration...${NC}"
    echo
    
    # Backup current configuration
    backup_file "$V2RAY_CONFIG_FILE"
    
    # Edit configuration
    nano "$V2RAY_CONFIG_FILE"
    
    # Validate configuration
    if validate_config; then
        if confirm "Configuration is valid. Restart V2Ray to apply changes?"; then
            systemctl restart v2ray
        fi
    else
        log_error "Invalid configuration. Please check the syntax."
    fi
    
    wait_for_key
}

# Add multiple clients
add_multiple_clients() {
    echo
    echo -e "${YELLOW}Add Multiple Clients${NC}"
    echo
    
    local count=$(get_input "Number of clients to add" "validate_number" "1")
    
    for ((i=1; i<=count; i++)); do
        local uuid=$(uuidgen)
        local email=$(get_input "Email for client $i" "" "client$i@mastermind.local")
        
        # Add client to configuration using jq
        jq --arg uuid "$uuid" --arg email "$email" '.inbounds[0].settings.clients += [{"id": $uuid, "level": 0, "email": $email}]' "$V2RAY_CONFIG_FILE" > /tmp/v2ray_temp.json
        mv /tmp/v2ray_temp.json "$V2RAY_CONFIG_FILE"
        
        log_info "Added client $i: $email ($uuid)"
    done
    
    if confirm "Restart V2Ray to apply changes?"; then
        systemctl restart v2ray
    fi
    
    wait_for_key
}

# Configure routing
configure_routing() {
    echo
    echo -e "${YELLOW}Routing Configuration${NC}"
    echo
    echo -e "${YELLOW}This feature is coming soon...${NC}"
    echo
    wait_for_key
}

# Configure DNS
configure_dns() {
    echo
    echo -e "${YELLOW}DNS Configuration${NC}"
    echo
    echo -e "${YELLOW}This feature is coming soon...${NC}"
    echo
    wait_for_key
}

# Backup configuration
backup_config() {
    echo
    log_info "Creating V2Ray configuration backup..."
    
    local backup_dir="/opt/mastermind/backup/v2ray"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="v2ray_config_${timestamp}.json"
    
    mkdir -p "$backup_dir"
    
    if [ -f "$V2RAY_CONFIG_FILE" ]; then
        cp "$V2RAY_CONFIG_FILE" "$backup_dir/$backup_file"
        log_info "Configuration backup created: $backup_dir/$backup_file"
    else
        log_error "V2Ray configuration file not found"
    fi
    
    wait_for_key
}

# Restore configuration
restore_config() {
    echo
    echo -e "${YELLOW}Available configuration backups:${NC}"
    echo
    
    local backup_dir="/opt/mastermind/backup/v2ray"
    if [ -d "$backup_dir" ]; then
        ls -la "$backup_dir"/*.json 2>/dev/null
        echo
        
        local backup_file
        backup_file=$(get_input "Enter backup filename (without path)" "" "")
        
        if [ -f "$backup_dir/$backup_file" ]; then
            if confirm "Restore configuration from $backup_file?"; then
                cp "$backup_dir/$backup_file" "$V2RAY_CONFIG_FILE"
                log_info "Configuration restored from $backup_file"
                
                if confirm "Restart V2Ray to apply changes?"; then
                    systemctl restart v2ray
                fi
            fi
        else
            log_error "Backup file not found: $backup_file"
        fi
    else
        log_warn "No backup directory found"
    fi
    
    wait_for_key
}

# Reset to default
reset_to_default() {
    if confirm "Reset V2Ray configuration to default?"; then
        create_default_config
        log_info "Configuration reset to default"
        
        if confirm "Restart V2Ray to apply changes?"; then
            systemctl restart v2ray
        fi
    fi
    
    wait_for_key
}

# Validate configuration
validate_config() {
    if [ -f "$V2RAY_CONFIG_FILE" ]; then
        v2ray test -config "$V2RAY_CONFIG_FILE" >/dev/null 2>&1
        return $?
    else
        return 1
    fi
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
        show_v2ray_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) install_v2ray ;;
            2) start_v2ray ;;
            3) stop_v2ray ;;
            4) configure_vless ;;
            5) configure_vmess ;;
            6) configure_websocket ;;
            7) generate_client_config ;;
            8) view_logs ;;
            9) advanced_settings ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
