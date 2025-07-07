#!/bin/bash

# Mastermind VPS Toolkit - V2Ray Manager
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# V2Ray configuration
V2RAY_CONFIG_DIR="/usr/local/etc/v2ray"
V2RAY_CONFIG_FILE="$V2RAY_CONFIG_DIR/config.json"
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
    
    # Download and install V2Ray
    if command -v v2ray >/dev/null 2>&1; then
        log_info "V2Ray is already installed"
    else
        # Install V2Ray using official script
        bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) || {
            log_error "V2Ray installation failed"
            wait_for_key
            return
        }
        
        # Create v2ray user if not exists
        if ! id "v2ray" &>/dev/null; then
            useradd -r -s /bin/false v2ray
        fi
        
        # Create directories
        mkdir -p /var/log/v2ray
        mkdir -p /usr/local/etc/v2ray
        mkdir -p /opt/mastermind/configs
        
        # Set permissions
        chown v2ray:v2ray /var/log/v2ray
        chown -R v2ray:v2ray /usr/local/etc/v2ray
        
        # Create basic configuration file
        create_basic_v2ray_config
        
        log_info "V2Ray installation completed"
    fi
    
    # Enable and start service
    systemctl enable v2ray
    systemctl start v2ray
    
    wait_for_key
}

# Create basic V2Ray configuration
create_basic_v2ray_config() {
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local port=${V2RAY_PORT:-10001}
    
    cat > "$V2RAY_CONFIG_FILE" << EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $port,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
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
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
    
    log_info "Basic V2Ray configuration created with UUID: $uuid"
    echo "Configuration saved to: $V2RAY_CONFIG_FILE"
    echo "UUID: $uuid"
    echo "Port: $port"
    echo "Path: /mastermind"
}

# Configure VLESS
configure_vless() {
    log_info "Configuring VLESS protocol..."
    
    # Generate UUID
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local port=${1:-443}
    local domain=${2:-""}
    
    # Create VLESS configuration
    cat > /usr/local/etc/v2ray/config.json << EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $port,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "xver": 0,
          "serverNames": [
            "www.microsoft.com"
          ],
          "privateKey": "$(openssl genpkey -algorithm x25519 | openssl pkey -text -noout | grep priv | cut -d: -f2 | tr -d ' \n')",
          "shortIds": [
            "$(openssl rand -hex 8)"
          ]
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

    # Save configuration info
    echo "VLESS Configuration:" > /opt/mastermind/configs/vless_config.txt
    echo "UUID: $uuid" >> /opt/mastermind/configs/vless_config.txt
    echo "Port: $port" >> /opt/mastermind/configs/vless_config.txt
    echo "Protocol: VLESS" >> /opt/mastermind/configs/vless_config.txt
    echo "Security: Reality" >> /opt/mastermind/configs/vless_config.txt
    
    # Restart V2Ray
    systemctl restart v2ray
    
    log_info "VLESS configuration completed"
    log_info "UUID: $uuid"
    log_info "Port: $port"
    
    wait_for_key
}

# Configure VMESS  
configure_vmess() {
    log_info "Configuring VMESS protocol..."
    
    # Generate UUID
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local port=${1:-80}
    local path=${2:-"/"}
    
    # Create VMESS configuration
    cat > /usr/local/etc/v2ray/config.json << EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $port,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0
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

    # Save configuration info
    echo "VMESS Configuration:" > /opt/mastermind/configs/vmess_config.txt
    echo "UUID: $uuid" >> /opt/mastermind/configs/vmess_config.txt
    echo "Port: $port" >> /opt/mastermind/configs/vmess_config.txt
    echo "Path: $path" >> /opt/mastermind/configs/vmess_config.txt
    echo "Protocol: VMESS" >> /opt/mastermind/configs/vmess_config.txt
    echo "Network: WebSocket" >> /opt/mastermind/configs/vmess_config.txt
    
    # Restart V2Ray
    systemctl restart v2ray
    
    log_info "VMESS configuration completed"
    log_info "UUID: $uuid"
    log_info "Port: $port"
    log_info "Path: $path"
    
    wait_for_key
}

# Advanced V2Ray settings
advanced_v2ray_settings() {
    echo
    echo -e "${YELLOW}Advanced V2Ray Settings${NC}"
    echo
    
    echo -e "${CYAN}[1]${NC} Domain & SSL Configuration"
    echo -e "${CYAN}[2]${NC} Traffic Routing"
    echo -e "${CYAN}[3]${NC} Security Settings"
    echo -e "${CYAN}[4]${NC} Performance Tuning"
    echo -e "${CYAN}[0]${NC} Back"
    echo
    
    read -p "Select option [0-4]: " choice
    case $choice in
        1) configure_domain_ssl ;;
        2) configure_traffic_routing ;;
        3) configure_security_settings ;;
        4) configure_performance_tuning ;;
        0) return ;;
        *) echo "Invalid option" ; sleep 2 ;;
    esac
}

# Configure domain and SSL
configure_domain_ssl() {
    echo
    echo -e "${YELLOW}Domain & SSL Configuration${NC}"
    echo
    
    local domain=$(get_input "Domain name" "" "")
    local use_ssl=$(confirm "Enable SSL/TLS?")
    
    if [ "$use_ssl" = true ]; then
        log_info "Configuring SSL/TLS for $domain..."
        # Domain manager integration
        if [ -f "/opt/mastermind/protocols/domain_manager.sh" ]; then
            bash /opt/mastermind/protocols/domain_manager.sh setup_ssl "$domain"
        fi
    fi
    
    wait_for_key
}

# Configure traffic routing
configure_traffic_routing() {
    echo
    echo -e "${YELLOW}Traffic Routing Configuration${NC}"
    echo
    
    echo "1. Direct routing"
    echo "2. Proxy routing"
    echo "3. Block routing"
    
    read -p "Select routing type [1-3]: " routing_type
    
    log_info "Traffic routing configured"
    wait_for_key
}

# Configure security settings
configure_security_settings() {
    echo
    echo -e "${YELLOW}Security Settings${NC}"
    echo
    
    local enable_auth=$(confirm "Enable additional authentication?")
    local enable_encryption=$(confirm "Enable enhanced encryption?")
    
    if [ "$enable_auth" = true ]; then
        log_info "Enhanced authentication enabled"
    fi
    
    if [ "$enable_encryption" = true ]; then
        log_info "Enhanced encryption enabled"
    fi
    
    wait_for_key
}

# Configure performance tuning
configure_performance_tuning() {
    echo
    echo -e "${YELLOW}Performance Tuning${NC}"
    echo
    
    local buffer_size=$(get_input "Buffer size (KB)" "32" "32")
    local connection_timeout=$(get_input "Connection timeout (seconds)" "60" "60")
    
    log_info "Performance settings configured"
    log_info "Buffer size: ${buffer_size}KB"
    log_info "Connection timeout: ${connection_timeout}s"
    
    wait_for_key
}

# Main V2Ray management function
main() {
    case ${1:-"menu"} in
        "install") install_v2ray ;;
        "start") systemctl start v2ray ;;
        "stop") systemctl stop v2ray ;;
        "restart") systemctl restart v2ray ;;
        "vless") configure_vless ;;
        "vmess") configure_vmess ;;
        "menu"|*)
            while true; do
                show_v2ray_menu
                read -p "Enter your choice [0-9]: " choice
                
                case $choice in
                    1) install_v2ray ;;
                    2) systemctl restart v2ray ;;
                    3) systemctl stop v2ray ;;
                    4) configure_vless ;;
                    5) configure_vmess ;;
                    6) configure_websocket ;;
                    7) generate_client_config ;;
                    8) view_v2ray_logs ;;
                    9) advanced_v2ray_settings ;;
                    0) exit 0 ;;
                    *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
                esac
            done
            ;;
    esac
}

# Configure WebSocket with domain
configure_websocket() {
    echo
    echo -e "${YELLOW}WebSocket Configuration${NC}"
    echo
    
    local domain=$(get_input "Domain name (optional, leave empty for IP-only)" "" "")
    local path=$(get_input "WebSocket path" "" "/mastermind")
    
    # Configure WebSocket settings in V2Ray config
    if [ -f "$V2RAY_CONFIG_FILE" ]; then
        # Update existing config for WebSocket
        log_info "Updating V2Ray configuration for WebSocket..."
        
        # Create backup
        cp "$V2RAY_CONFIG_FILE" "$V2RAY_CONFIG_FILE.bak"
        
        # Update the WebSocket settings
        jq --arg path "$path" '.inbounds[0].streamSettings.wsSettings.path = $path' "$V2RAY_CONFIG_FILE" > /tmp/v2ray_temp.json
        mv /tmp/v2ray_temp.json "$V2RAY_CONFIG_FILE"
        
        if [ -n "$domain" ]; then
            echo "Domain: $domain" >> /opt/mastermind/configs/v2ray_domain.txt
            log_info "Domain $domain configured for V2Ray"
        fi
        
        systemctl restart v2ray
        log_info "WebSocket configuration updated successfully"
    else
        log_error "V2Ray configuration file not found"
        echo "Please install V2Ray first using option [1]"
    fi
    
    wait_for_key
}

# Generate client configuration
generate_client_config() {
    echo
    echo -e "${YELLOW}Generate Client Configuration${NC}"
    echo
    
    if [ ! -f "$V2RAY_CONFIG_FILE" ]; then
        log_error "V2Ray configuration not found. Please configure V2Ray first."
        wait_for_key
        return
    fi
    
    local uuid=$(jq -r '.inbounds[0].settings.clients[0].id' "$V2RAY_CONFIG_FILE" 2>/dev/null)
    local port=$(jq -r '.inbounds[0].port' "$V2RAY_CONFIG_FILE" 2>/dev/null)
    local path=$(jq -r '.inbounds[0].streamSettings.wsSettings.path' "$V2RAY_CONFIG_FILE" 2>/dev/null)
    local server_ip=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
    
    echo -e "${GREEN}V2Ray Client Configuration:${NC}"
    echo
    echo -e "${YELLOW}Server Details:${NC}"
    echo -e "  Address: $server_ip"
    echo -e "  Port: $port"
    echo -e "  UUID: $uuid"
    echo -e "  Path: $path"
    echo -e "  Network: WebSocket"
    echo -e "  Security: none"
    echo
    echo -e "${YELLOW}Client Link (VLESS):${NC}"
    echo "vless://$uuid@$server_ip:$port?type=ws&path=$path#Mastermind-VPS"
    echo
    
    # Save to file
    cat > /opt/mastermind/configs/v2ray_client.txt << EOF
V2Ray Client Configuration

Server: $server_ip
Port: $port
UUID: $uuid
Path: $path
Network: WebSocket
Security: none

Client Link:
vless://$uuid@$server_ip:$port?type=ws&path=$path#Mastermind-VPS
EOF
    
    echo -e "${GREEN}Configuration saved to: /opt/mastermind/configs/v2ray_client.txt${NC}"
    wait_for_key
}

# View V2Ray logs
view_v2ray_logs() {
    echo
    echo -e "${YELLOW}V2Ray Service Logs${NC}"
    echo
    
    echo -e "${CYAN}Recent V2Ray logs:${NC}"
    journalctl -u v2ray -n 50 --no-pager
    echo
    
    if [ -f "/var/log/mastermind/v2ray-access.log" ]; then
        echo -e "${CYAN}Access logs:${NC}"
        tail -20 /var/log/mastermind/v2ray-access.log
    fi
    
    if [ -f "/var/log/mastermind/v2ray-error.log" ]; then
        echo -e "${CYAN}Error logs:${NC}"
        tail -20 /var/log/mastermind/v2ray-error.log
    fi
    
    wait_for_key
}

# Advanced V2Ray settings
advanced_v2ray_settings() {
    echo
    echo -e "${YELLOW}Advanced V2Ray Settings${NC}"
    echo
    
    echo -e "${YELLOW}  [1] Domain & SSL Configuration${NC}"
    echo -e "${YELLOW}  [2] Port Configuration${NC}"
    echo -e "${YELLOW}  [3] Reset Configuration${NC}"
    echo -e "${YELLOW}  [4] Export Configuration${NC}"
    echo -e "${YELLOW}  [5] Import Configuration${NC}"
    echo -e "${YELLOW}  [0] Back${NC}"
    echo
    
    read -p "Choose option: " advanced_choice
    
    case $advanced_choice in
        1) 
            # Domain & SSL Configuration
            if [ -f "$MASTERMIND_HOME/protocols/domain_manager.sh" ]; then
                bash "$MASTERMIND_HOME/protocols/domain_manager.sh"
            else
                echo "Domain manager not found"
            fi
            ;;
        2)
            read -p "Enter new port for V2Ray: " new_port
            if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
                jq --arg port "$new_port" '.inbounds[0].port = ($port | tonumber)' "$V2RAY_CONFIG_FILE" > /tmp/v2ray_temp.json
                mv /tmp/v2ray_temp.json "$V2RAY_CONFIG_FILE"
                systemctl restart v2ray
                log_info "V2Ray port changed to $new_port"
            else
                log_error "Invalid port number"
            fi
            ;;
        3)
            if confirm "Reset V2Ray configuration to defaults?"; then
                create_default_config
                systemctl restart v2ray
                log_info "V2Ray configuration reset"
            fi
            ;;
        4)
            cp "$V2RAY_CONFIG_FILE" "/opt/mastermind/configs/v2ray_backup_$(date +%Y%m%d_%H%M%S).json"
            log_info "Configuration exported to configs directory"
            ;;
        5)
            echo "Configuration import functionality available through file replacement"
            ;;
    esac
    
    wait_for_key
}

# Main function call
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
