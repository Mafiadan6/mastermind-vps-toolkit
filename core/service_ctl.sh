#!/bin/bash

# Mastermind VPS Toolkit - Service Control
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh

# Service definitions
SERVICES=(
    "python-proxy:Python Proxy Suite"
    "tcp-bypass:TCP Bypass Proxy"
    "v2ray:V2Ray Server"
    "badvpn:BadVPN Service"
    "fail2ban:Fail2Ban Protection"
    "nginx:Nginx Web Server"
)

# Service control menu
show_service_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             SERVICE CONTROLS                                 ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    local i=1
    for service in "${SERVICES[@]}"; do
        local service_name=$(echo "$service" | cut -d':' -f1)
        local service_desc=$(echo "$service" | cut -d':' -f2)
        local status=$(get_service_status "$service_name")
        
        printf "  ${YELLOW}[%d]${NC} %-25s - %s\n" "$i" "$service_desc" "$status"
        ((i++))
    done
    
    echo
    echo -e "${YELLOW}  [a] Start All Services${NC}"
    echo -e "${YELLOW}  [b] Stop All Services${NC}"
    echo -e "${YELLOW}  [c] Restart All Services${NC}"
    echo -e "${YELLOW}  [d] Service Status Overview${NC}"
    echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Individual service control
control_service() {
    local service_index=$1
    local service_name=$(echo "${SERVICES[$((service_index-1))]}" | cut -d':' -f1)
    local service_desc=$(echo "${SERVICES[$((service_index-1))]}" | cut -d':' -f2)
    
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                        $service_desc CONTROL                               ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}Service:${NC} $service_desc"
        echo -e "${YELLOW}Status:${NC} $(get_service_status "$service_name")"
        echo -e "${YELLOW}Enabled:${NC} $(systemctl is-enabled "$service_name" 2>/dev/null || echo 'disabled')"
        echo
        echo -e "${YELLOW}  [1] Start Service${NC}"
        echo -e "${YELLOW}  [2] Stop Service${NC}"
        echo -e "${YELLOW}  [3] Restart Service${NC}"
        echo -e "${YELLOW}  [4] Enable Auto-start${NC}"
        echo -e "${YELLOW}  [5] Disable Auto-start${NC}"
        echo -e "${YELLOW}  [6] View Logs${NC}"
        echo -e "${YELLOW}  [7] Service Configuration${NC}"
        echo -e "${YELLOW}  [0] Back to Service Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) start_service "$service_name" ; wait_for_key ;;
            2) stop_service "$service_name" ; wait_for_key ;;
            3) restart_service "$service_name" ; wait_for_key ;;
            4) enable_service "$service_name" ; wait_for_key ;;
            5) disable_service "$service_name" ; wait_for_key ;;
            6) view_service_logs "$service_name" ;;
            7) edit_service_config "$service_name" ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Start all services
start_all_services() {
    echo -e "${CYAN}Starting all services...${NC}"
    echo
    
    for service in "${SERVICES[@]}"; do
        local service_name=$(echo "$service" | cut -d':' -f1)
        local service_desc=$(echo "$service" | cut -d':' -f2)
        
        echo -e "${YELLOW}Starting $service_desc...${NC}"
        if start_service "$service_name"; then
            echo -e "${GREEN}✓ $service_desc started${NC}"
        else
            echo -e "${RED}✗ Failed to start $service_desc${NC}"
        fi
        echo
    done
    
    wait_for_key
}

# Stop all services
stop_all_services() {
    echo -e "${CYAN}Stopping all services...${NC}"
    echo
    
    for service in "${SERVICES[@]}"; do
        local service_name=$(echo "$service" | cut -d':' -f1)
        local service_desc=$(echo "$service" | cut -d':' -f2)
        
        echo -e "${YELLOW}Stopping $service_desc...${NC}"
        if stop_service "$service_name"; then
            echo -e "${GREEN}✓ $service_desc stopped${NC}"
        else
            echo -e "${RED}✗ Failed to stop $service_desc${NC}"
        fi
        echo
    done
    
    wait_for_key
}

# Restart all services
restart_all_services() {
    echo -e "${CYAN}Restarting all services...${NC}"
    echo
    
    for service in "${SERVICES[@]}"; do
        local service_name=$(echo "$service" | cut -d':' -f1)
        local service_desc=$(echo "$service" | cut -d':' -f2)
        
        echo -e "${YELLOW}Restarting $service_desc...${NC}"
        if restart_service "$service_name"; then
            echo -e "${GREEN}✓ $service_desc restarted${NC}"
        else
            echo -e "${RED}✗ Failed to restart $service_desc${NC}"
        fi
        echo
    done
    
    wait_for_key
}

# Service status overview
show_status_overview() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           SERVICE STATUS OVERVIEW                            ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    printf "%-25s %-10s %-10s %-15s\n" "Service" "Status" "Enabled" "Port"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    for service in "${SERVICES[@]}"; do
        local service_name=$(echo "$service" | cut -d':' -f1)
        local service_desc=$(echo "$service" | cut -d':' -f2)
        local status=$(get_service_status "$service_name")
        local enabled=$(systemctl is-enabled "$service_name" 2>/dev/null || echo 'disabled')
        local port=$(get_service_port "$service_name")
        
        printf "%-25s %-10s %-10s %-15s\n" "$service_desc" "$status" "$enabled" "$port"
    done
    
    echo
    echo -e "${CYAN}System Information:${NC}"
    echo -e "  Uptime: $(uptime -p)"
    echo -e "  Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo -e "  Memory Usage: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
    echo -e "  Disk Usage: $(df / | tail -1 | awk '{print $5}')"
    echo
    
    wait_for_key
}

# Get service port
get_service_port() {
    local service_name=$1
    
    case $service_name in
        "python-proxy") echo "8080" ;;
        "tcp-bypass") echo "12345" ;;
        "v2ray") echo "443" ;;
        "badvpn") echo "7300" ;;
        "nginx") echo "80,443" ;;
        *) echo "N/A" ;;
    esac
}

# View service logs
view_service_logs() {
    local service_name=$1
    
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                            $service_name LOGS                                ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Showing last 50 lines of $service_name logs...${NC}"
    echo -e "${YELLOW}Press 'q' to exit log viewer${NC}"
    echo
    
    sleep 2
    journalctl -u "$service_name" -n 50 -f
}

# Edit service configuration
edit_service_config() {
    local service_name=$1
    local config_file
    
    case $service_name in
        "python-proxy") config_file="/etc/default/python-proxy" ;;
        "tcp-bypass") config_file="/etc/redsocks.conf" ;;
        "v2ray") config_file="/opt/mastermind/config/v2ray.json" ;;
        "nginx") config_file="/etc/nginx/sites-available/default" ;;
        *) 
            echo -e "${RED}No configuration file found for $service_name${NC}"
            wait_for_key
            return
            ;;
    esac
    
    if [ -f "$config_file" ]; then
        echo -e "${YELLOW}Editing $config_file...${NC}"
        sleep 1
        nano "$config_file"
        
        if confirm "Restart $service_name service to apply changes?"; then
            restart_service "$service_name"
        fi
    else
        echo -e "${RED}Configuration file not found: $config_file${NC}"
        wait_for_key
    fi
}

# Main function
main() {
    local action=${1:-"menu"}
    
    case $action in
        "status")
            show_status_overview
            ;;
        "start")
            start_all_services
            ;;
        "stop")
            stop_all_services
            ;;
        "restart")
            restart_all_services
            ;;
        "menu"|*)
            while true; do
                show_service_menu
                read -p "Enter your choice: " choice
                
                case $choice in
                    [1-6])
                        if [ "$choice" -le "${#SERVICES[@]}" ]; then
                            control_service "$choice"
                        else
                            echo -e "${RED}Invalid service number.${NC}"
                            sleep 2
                        fi
                        ;;
                    a|A) start_all_services ;;
                    b|B) stop_all_services ;;
                    c|C) restart_all_services ;;
                    d|D) show_status_overview ;;
                    0) exit 0 ;;
                    *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
                esac
            done
            ;;
    esac
}

# Run main function
main "$@"
