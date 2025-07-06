#!/bin/bash

# Mastermind VPS Toolkit - Firewall Manager
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Show firewall management menu
show_firewall_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           FIREWALL MANAGEMENT                               ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Show firewall status
    local ufw_status=$(ufw status | head -1 | awk '{print $2}')
    echo -e "${YELLOW}Firewall Status:${NC} $([ "$ufw_status" = "active" ] && echo -e "${GREEN}ACTIVE${NC}" || echo -e "${RED}INACTIVE${NC}")"
    
    # Show active rules count
    local rules_count=$(ufw status numbered | grep -c "^\[")
    echo -e "${YELLOW}Active Rules:${NC} $rules_count"
    
    # Show default policies
    local default_incoming=$(ufw status verbose | grep "Default:" | awk '{print $2}')
    local default_outgoing=$(ufw status verbose | grep "Default:" | awk '{print $4}')
    echo -e "${YELLOW}Default Policy:${NC} Incoming: $default_incoming, Outgoing: $default_outgoing"
    
    echo
    echo -e "${YELLOW}  [1] Enable/Disable Firewall${NC}"
    echo -e "${YELLOW}  [2] Manage Rules${NC}"
    echo -e "${YELLOW}  [3] Default Policies${NC}"
    echo -e "${YELLOW}  [4] Port Management${NC}"
    echo -e "${YELLOW}  [5] IP Whitelist/Blacklist${NC}"
    echo -e "${YELLOW}  [6] Quick Security Setup${NC}"
    echo -e "${YELLOW}  [7] View Firewall Status${NC}"
    echo -e "${YELLOW}  [8] Backup/Restore Rules${NC}"
    echo -e "${YELLOW}  [9] Reset Firewall${NC}"
    echo -e "${YELLOW}  [0] Back to Security Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Enable/disable firewall
toggle_firewall() {
    local status=$(ufw status | head -1 | awk '{print $2}')
    
    if [ "$status" = "active" ]; then
        if confirm "Disable firewall? This will remove all protection."; then
            ufw --force disable
            log_info "Firewall disabled"
        fi
    else
        if confirm "Enable firewall?"; then
            ufw --force enable
            log_info "Firewall enabled"
        fi
    fi
    
    wait_for_key
}

# Manage firewall rules
manage_rules() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             RULE MANAGEMENT                                 ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}Current Rules:${NC}"
        ufw status numbered | grep -E "^\[" | head -20
        echo
        
        echo -e "${YELLOW}  [1] Add Rule${NC}"
        echo -e "${YELLOW}  [2] Delete Rule${NC}"
        echo -e "${YELLOW}  [3] Modify Rule${NC}"
        echo -e "${YELLOW}  [4] View All Rules${NC}"
        echo -e "${YELLOW}  [0] Back to Firewall Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-4]: " choice
        
        case $choice in
            1) add_rule ;;
            2) delete_rule ;;
            3) modify_rule ;;
            4) view_all_rules ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Add firewall rule
add_rule() {
    echo
    echo -e "${YELLOW}Add Firewall Rule${NC}"
    echo
    
    echo -e "${YELLOW}Rule types:${NC}"
    echo -e "  [1] Allow port"
    echo -e "  [2] Deny port"
    echo -e "  [3] Allow from IP"
    echo -e "  [4] Deny from IP"
    echo -e "  [5] Allow service"
    echo -e "  [6] Custom rule"
    echo
    
    read -p "Choose rule type [1-6]: " rule_type
    
    case $rule_type in
        1)
            local port=$(get_input "Port number" "validate_port" "")
            local protocol=$(get_input "Protocol (tcp/udp/both)" "" "tcp")
            
            if [ "$protocol" = "both" ]; then
                ufw allow $port
            else
                ufw allow $port/$protocol
            fi
            log_info "Allow rule added for port $port"
            ;;
        2)
            local port=$(get_input "Port number" "validate_port" "")
            local protocol=$(get_input "Protocol (tcp/udp/both)" "" "tcp")
            
            if [ "$protocol" = "both" ]; then
                ufw deny $port
            else
                ufw deny $port/$protocol
            fi
            log_info "Deny rule added for port $port"
            ;;
        3)
            local ip=$(get_input "IP address" "validate_ip" "")
            ufw allow from $ip
            log_info "Allow rule added for IP $ip"
            ;;
        4)
            local ip=$(get_input "IP address" "validate_ip" "")
            ufw deny from $ip
            log_info "Deny rule added for IP $ip"
            ;;
        5)
            local service=$(get_input "Service name (ssh/http/https/etc)" "" "")
            ufw allow $service
            log_info "Allow rule added for service $service"
            ;;
        6)
            local custom_rule=$(get_input "Custom rule (e.g., allow from 192.168.1.0/24 to any port 22)" "" "")
            ufw $custom_rule
            log_info "Custom rule added: $custom_rule"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    wait_for_key
}

# Delete firewall rule
delete_rule() {
    echo
    echo -e "${YELLOW}Delete Firewall Rule${NC}"
    echo
    
    echo -e "${YELLOW}Current rules:${NC}"
    ufw status numbered
    echo
    
    local rule_number=$(get_input "Rule number to delete" "validate_number" "")
    
    if [ -n "$rule_number" ]; then
        if confirm "Delete rule number $rule_number?"; then
            ufw --force delete $rule_number
            log_info "Rule $rule_number deleted"
        fi
    fi
    
    wait_for_key
}

# Modify firewall rule
modify_rule() {
    echo
    echo -e "${YELLOW}Modify Firewall Rule${NC}"
    echo
    echo -e "${YELLOW}To modify a rule, first delete it then add a new one.${NC}"
    echo
    
    delete_rule
    add_rule
}

# View all rules
view_all_rules() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                               ALL FIREWALL RULES                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    ufw status verbose
    echo
    
    wait_for_key
}

# Default policies
default_policies() {
    echo
    echo -e "${YELLOW}Default Firewall Policies${NC}"
    echo
    
    echo -e "${YELLOW}Current default policies:${NC}"
    ufw status verbose | grep "Default:"
    echo
    
    echo -e "${YELLOW}Incoming policy:${NC}"
    echo -e "  [1] Allow (not recommended)"
    echo -e "  [2] Deny (recommended)"
    echo -e "  [3] Reject"
    echo
    
    read -p "Choose incoming policy [1-3]: " incoming
    
    case $incoming in
        1) ufw default allow incoming ;;
        2) ufw default deny incoming ;;
        3) ufw default reject incoming ;;
        *) echo -e "${RED}Invalid choice${NC}" ; return ;;
    esac
    
    echo
    echo -e "${YELLOW}Outgoing policy:${NC}"
    echo -e "  [1] Allow (recommended)"
    echo -e "  [2] Deny"
    echo -e "  [3] Reject"
    echo
    
    read -p "Choose outgoing policy [1-3]: " outgoing
    
    case $outgoing in
        1) ufw default allow outgoing ;;
        2) ufw default deny outgoing ;;
        3) ufw default reject outgoing ;;
        *) echo -e "${RED}Invalid choice${NC}" ; return ;;
    esac
    
    log_info "Default policies updated"
    wait_for_key
}

# Port management
port_management() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             PORT MANAGEMENT                                 ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Open Required Ports${NC}"
        echo -e "${YELLOW}  [2] Close Unnecessary Ports${NC}"
        echo -e "${YELLOW}  [3] Port Scan Detection${NC}"
        echo -e "${YELLOW}  [4] Custom Port Range${NC}"
        echo -e "${YELLOW}  [0] Back to Firewall Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-4]: " choice
        
        case $choice in
            1) open_required_ports ;;
            2) close_unnecessary_ports ;;
            3) port_scan_detection ;;
            4) custom_port_range ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Open required ports
open_required_ports() {
    echo
    echo -e "${YELLOW}Opening required ports for Mastermind VPS Toolkit...${NC}"
    echo
    
    # SSH port
    ufw allow $SSH_PORT/tcp
    echo -e "  ✓ SSH port $SSH_PORT opened"
    
    # Python proxy port
    ufw allow $PYTHON_PROXY_PORT/tcp
    echo -e "  ✓ SOCKS5 proxy port $PYTHON_PROXY_PORT opened"
    
    # Response server ports
    for port in "${RESPONSE_PORTS[@]}"; do
        ufw allow $port/tcp
        echo -e "  ✓ HTTP response port $port opened"
    done
    
    # V2Ray port
    ufw allow $V2RAY_PORT/tcp
    echo -e "  ✓ V2Ray port $V2RAY_PORT opened"
    
    # BadVPN UDP port
    ufw allow $BADVPN_PORT/udp
    echo -e "  ✓ BadVPN UDP port $BADVPN_PORT opened"
    
    # Web ports
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo -e "  ✓ Web ports 80 and 443 opened"
    
    log_info "Required ports opened"
    wait_for_key
}

# Close unnecessary ports
close_unnecessary_ports() {
    echo
    echo -e "${YELLOW}Closing unnecessary ports...${NC}"
    echo
    
    # Common unnecessary ports
    local unnecessary_ports=(21 23 25 53 110 143 993 995 1433 3306 3389 5432)
    
    for port in "${unnecessary_ports[@]}"; do
        ufw deny $port
        echo -e "  ✓ Port $port closed"
    done
    
    log_info "Unnecessary ports closed"
    wait_for_key
}

# Port scan detection
port_scan_detection() {
    echo
    echo -e "${YELLOW}Port Scan Detection${NC}"
    echo
    
    # Add rate limiting rules
    ufw limit ssh
    ufw limit 22/tcp
    
    # Add logging for denied connections
    ufw logging on
    
    log_info "Port scan detection enabled"
    echo -e "  ✓ Rate limiting enabled for SSH"
    echo -e "  ✓ Logging enabled for monitoring"
    
    wait_for_key
}

# Custom port range
custom_port_range() {
    echo
    echo -e "${YELLOW}Custom Port Range Management${NC}"
    echo
    
    local start_port=$(get_input "Start port" "validate_port" "")
    local end_port=$(get_input "End port" "validate_port" "")
    local action=$(get_input "Action (allow/deny)" "" "allow")
    local protocol=$(get_input "Protocol (tcp/udp)" "" "tcp")
    
    if [ "$start_port" -gt "$end_port" ]; then
        log_error "Start port must be less than end port"
        wait_for_key
        return
    fi
    
    ufw $action $start_port:$end_port/$protocol
    log_info "Port range $start_port:$end_port/$protocol $action rule added"
    
    wait_for_key
}

# IP whitelist/blacklist
ip_management() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           IP WHITELIST/BLACKLIST                           ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Add IP to Whitelist${NC}"
        echo -e "${YELLOW}  [2] Add IP to Blacklist${NC}"
        echo -e "${YELLOW}  [3] Remove IP from Lists${NC}"
        echo -e "${YELLOW}  [4] View IP Lists${NC}"
        echo -e "${YELLOW}  [5] Country-based Blocking${NC}"
        echo -e "${YELLOW}  [0] Back to Firewall Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) whitelist_ip ;;
            2) blacklist_ip ;;
            3) remove_ip ;;
            4) view_ip_lists ;;
            5) country_blocking ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Whitelist IP
whitelist_ip() {
    echo
    echo -e "${YELLOW}Add IP to Whitelist${NC}"
    echo
    
    local ip=$(get_input "IP address or network (e.g., 192.168.1.1 or 192.168.1.0/24)" "validate_ip_or_network" "")
    
    if [ -n "$ip" ]; then
        ufw allow from $ip
        log_info "IP $ip added to whitelist"
    fi
    
    wait_for_key
}

# Blacklist IP
blacklist_ip() {
    echo
    echo -e "${YELLOW}Add IP to Blacklist${NC}"
    echo
    
    local ip=$(get_input "IP address or network (e.g., 192.168.1.1 or 192.168.1.0/24)" "validate_ip_or_network" "")
    
    if [ -n "$ip" ]; then
        ufw deny from $ip
        log_info "IP $ip added to blacklist"
    fi
    
    wait_for_key
}

# Remove IP from lists
remove_ip() {
    echo
    echo -e "${YELLOW}Remove IP from Lists${NC}"
    echo
    
    echo -e "${YELLOW}Current IP-based rules:${NC}"
    ufw status numbered | grep -E "(ALLOW|DENY).*from"
    echo
    
    local rule_number=$(get_input "Rule number to remove" "validate_number" "")
    
    if [ -n "$rule_number" ]; then
        if confirm "Remove rule number $rule_number?"; then
            ufw --force delete $rule_number
            log_info "IP rule $rule_number removed"
        fi
    fi
    
    wait_for_key
}

# View IP lists
view_ip_lists() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                               IP LISTS                                       ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Whitelisted IPs (ALLOW rules):${NC}"
    ufw status | grep "ALLOW" | grep "from"
    echo
    
    echo -e "${YELLOW}Blacklisted IPs (DENY rules):${NC}"
    ufw status | grep "DENY" | grep "from"
    echo
    
    wait_for_key
}

# Country-based blocking
country_blocking() {
    echo
    echo -e "${YELLOW}Country-based Blocking${NC}"
    echo
    echo -e "${YELLOW}This feature requires additional tools and IP databases.${NC}"
    echo -e "${YELLOW}Consider using fail2ban with geoip for advanced blocking.${NC}"
    echo
    
    wait_for_key
}

# Quick security setup
quick_security_setup() {
    if confirm "Apply quick security setup? This will configure basic firewall protection."; then
        log_info "Applying quick security setup..."
        
        # Reset firewall
        ufw --force reset
        
        # Set default policies
        ufw default deny incoming
        ufw default allow outgoing
        
        # Allow required services
        open_required_ports
        
        # Enable rate limiting on SSH
        ufw limit ssh
        
        # Enable logging
        ufw logging on
        
        # Enable firewall
        ufw --force enable
        
        log_info "Quick security setup completed"
        
        echo
        echo -e "${GREEN}Security setup completed:${NC}"
        echo -e "  ✓ Default policies set (deny incoming, allow outgoing)"
        echo -e "  ✓ Required ports opened"
        echo -e "  ✓ SSH rate limiting enabled"
        echo -e "  ✓ Logging enabled"
        echo -e "  ✓ Firewall enabled"
    fi
    
    wait_for_key
}

# View firewall status
view_firewall_status() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             FIREWALL STATUS                                  ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    ufw status verbose
    echo
    
    echo -e "${YELLOW}Recent firewall activity:${NC}"
    tail -20 /var/log/ufw.log 2>/dev/null || echo "No recent activity"
    echo
    
    wait_for_key
}

# Backup/restore rules
backup_restore_rules() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           BACKUP/RESTORE RULES                             ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Backup Rules${NC}"
        echo -e "${YELLOW}  [2] Restore Rules${NC}"
        echo -e "${YELLOW}  [3] View Backups${NC}"
        echo -e "${YELLOW}  [0] Back to Firewall Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-3]: " choice
        
        case $choice in
            1) backup_rules ;;
            2) restore_rules ;;
            3) view_backups ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Backup firewall rules
backup_rules() {
    echo
    log_info "Creating firewall rules backup..."
    
    local backup_dir="/opt/mastermind/backup/firewall"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="firewall_rules_${timestamp}.txt"
    
    mkdir -p "$backup_dir"
    
    # Backup UFW rules
    ufw status numbered > "$backup_dir/$backup_file"
    
    # Backup UFW configuration
    cp -r /etc/ufw "$backup_dir/ufw_config_${timestamp}/"
    
    log_info "Firewall rules backed up to $backup_dir/$backup_file"
    
    wait_for_key
}

# Restore firewall rules
restore_rules() {
    echo
    echo -e "${YELLOW}Available backups:${NC}"
    ls -la /opt/mastermind/backup/firewall/ 2>/dev/null || echo "No backups found"
    echo
    
    local backup_file=$(get_input "Backup filename" "" "")
    
    if [ -f "/opt/mastermind/backup/firewall/$backup_file" ]; then
        if confirm "Restore firewall rules from $backup_file?"; then
            log_warn "Manual restoration required - please review backup file and apply rules manually"
            cat "/opt/mastermind/backup/firewall/$backup_file"
        fi
    else
        log_error "Backup file not found"
    fi
    
    wait_for_key
}

# View backups
view_backups() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             FIREWALL BACKUPS                                ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    local backup_dir="/opt/mastermind/backup/firewall"
    if [ -d "$backup_dir" ]; then
        ls -la "$backup_dir"
    else
        echo "No backups found"
    fi
    echo
    
    wait_for_key
}

# Reset firewall
reset_firewall() {
    if confirm "Reset firewall to default state? This will remove all rules."; then
        ufw --force reset
        log_info "Firewall reset to default state"
        
        if confirm "Apply basic security configuration?"; then
            quick_security_setup
        fi
    fi
    
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
        show_firewall_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) toggle_firewall ;;
            2) manage_rules ;;
            3) default_policies ;;
            4) port_management ;;
            5) ip_management ;;
            6) quick_security_setup ;;
            7) view_firewall_status ;;
            8) backup_restore_rules ;;
            9) reset_firewall ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
