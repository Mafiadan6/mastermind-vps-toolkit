#!/bin/bash

# Mastermind VPS Toolkit - Fail2Ban Setup
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Show Fail2Ban menu
show_fail2ban_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             FAIL2BAN SETUP                                   ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Show Fail2Ban status
    if command_exists fail2ban-client; then
        echo -e "${YELLOW}Fail2Ban Status:${NC} $(get_service_status "fail2ban")"
        
        # Show jail status
        local active_jails=$(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | tr -d ' \t')
        echo -e "${YELLOW}Active Jails:${NC} ${active_jails:-"None"}"
        
        # Show banned IPs count
        local banned_count=0
        if [ -n "$active_jails" ]; then
            for jail in $(echo $active_jails | tr ',' ' '); do
                local jail_banned=$(fail2ban-client status $jail 2>/dev/null | grep "Currently banned" | awk '{print $4}')
                banned_count=$((banned_count + jail_banned))
            done
        fi
        echo -e "${YELLOW}Total Banned IPs:${NC} $banned_count"
    else
        echo -e "${YELLOW}Fail2Ban Status:${NC} ${RED}Not Installed${NC}"
    fi
    
    echo
    echo -e "${YELLOW}  [1] Install/Configure Fail2Ban${NC}"
    echo -e "${YELLOW}  [2] Manage Jails${NC}"
    echo -e "${YELLOW}  [3] View Banned IPs${NC}"
    echo -e "${YELLOW}  [4] Unban IP Address${NC}"
    echo -e "${YELLOW}  [5] Configure Protection Rules${NC}"
    echo -e "${YELLOW}  [6] View Logs${NC}"
    echo -e "${YELLOW}  [7] Statistics${NC}"
    echo -e "${YELLOW}  [8] Advanced Configuration${NC}"
    echo -e "${YELLOW}  [9] Backup/Restore Config${NC}"
    echo -e "${YELLOW}  [0] Back to Security Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Install and configure Fail2Ban
install_fail2ban() {
    log_info "Installing and configuring Fail2Ban..."
    
    # Install Fail2Ban
    if ! command_exists fail2ban-client; then
        apt update
        apt install -y fail2ban
    fi
    
    # Create custom configuration
    create_fail2ban_config
    
    # Enable and start service
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    if is_service_running "fail2ban"; then
        log_info "Fail2Ban installed and configured successfully"
    else
        log_error "Failed to start Fail2Ban service"
    fi
    
    wait_for_key
}

# Create Fail2Ban configuration
create_fail2ban_config() {
    log_info "Creating Fail2Ban configuration..."
    
    # Create jail.local configuration
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
# Mastermind VPS Toolkit Fail2Ban Configuration
ignoreip = 127.0.0.1/8 ::1
bantime = 3600
findtime = 600
maxretry = 3
backend = auto
usedns = warn
logencoding = auto
enabled = false
filter = %(__name__)s
destemail = $ADMIN_EMAIL
sender = fail2ban@$(hostname)
mta = sendmail
protocol = tcp
chain = INPUT
port = 0:65535
fail2ban_agent = Fail2Ban/%(fail2ban_version)s

# SSH protection
[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

# Dropbear protection (if enabled)
[dropbear]
enabled = false
port = 444
filter = dropbear
logpath = /var/log/auth.log
maxretry = 3

# HTTP/HTTPS protection
[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3

[nginx-noscript]
enabled = true
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noproxy]
enabled = true
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2

# Custom proxy protection
[proxy-auth]
enabled = true
filter = proxy-auth
logpath = /var/log/mastermind/python-proxy.log
maxretry = 5
bantime = 7200

# Postfix protection (if email is configured)
[postfix]
enabled = false
filter = postfix
logpath = /var/log/mail.log
maxretry = 3

# FTP protection (if FTP is enabled)
[vsftpd]
enabled = false
filter = vsftpd
logpath = /var/log/vsftpd.log
maxretry = 3

# MySQL protection (if MySQL is installed)
[mysqld-auth]
enabled = false
filter = mysqld-auth
logpath = /var/log/mysql/error.log
maxretry = 3

# Custom brute force protection
[recidive]
enabled = true
filter = recidive
logpath = /var/log/fail2ban.log
action = iptables-allports[name=recidive,protocol=all]
bantime = 86400
findtime = 86400
maxretry = 5
EOF

    # Create custom proxy filter
    cat > /etc/fail2ban/filter.d/proxy-auth.conf << 'EOF'
# Fail2Ban filter for proxy authentication failures
[Definition]
failregex = ^.*Authentication failed for .*<HOST>.*$
            ^.*Invalid SOCKS.*from.*<HOST>.*$
            ^.*Connection refused.*<HOST>.*$
ignoreregex =
EOF

    # Create recidive filter if not exists
    if [ ! -f /etc/fail2ban/filter.d/recidive.conf ]; then
        cat > /etc/fail2ban/filter.d/recidive.conf << 'EOF'
# Fail2Ban filter for repeat offenders
[Definition]
failregex = ^%(__prefix_line)s(?:WARNING|NOTICE)?\s*\[.*\]\s*Ban <HOST>$
ignoreregex =
EOF
    fi
    
    log_info "Fail2Ban configuration created"
}

# Manage jails
manage_jails() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             JAIL MANAGEMENT                                 ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        # Show current jail status
        if command_exists fail2ban-client; then
            echo -e "${YELLOW}Current Jail Status:${NC}"
            fail2ban-client status 2>/dev/null || echo "Fail2Ban not running"
            echo
        fi
        
        echo -e "${YELLOW}  [1] Enable/Disable Jail${NC}"
        echo -e "${YELLOW}  [2] View Jail Status${NC}"
        echo -e "${YELLOW}  [3] Reload Jail${NC}"
        echo -e "${YELLOW}  [4] Add Custom Jail${NC}"
        echo -e "${YELLOW}  [5] Remove Jail${NC}"
        echo -e "${YELLOW}  [0] Back to Fail2Ban Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) toggle_jail ;;
            2) view_jail_status ;;
            3) reload_jail ;;
            4) add_custom_jail ;;
            5) remove_jail ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Enable/disable jail
toggle_jail() {
    echo
    echo -e "${YELLOW}Available jails:${NC}"
    grep "^\[" /etc/fail2ban/jail.local | grep -v "DEFAULT" | tr -d '[]'
    echo
    
    local jail_name=$(get_input "Jail name" "" "")
    
    if [ -n "$jail_name" ]; then
        echo -e "${YELLOW}Actions:${NC}"
        echo -e "  [1] Enable jail"
        echo -e "  [2] Disable jail"
        echo
        
        read -p "Choose action [1-2]: " action
        
        case $action in
            1)
                sed -i "/^\[$jail_name\]/,/^\[/ s/enabled = false/enabled = true/" /etc/fail2ban/jail.local
                systemctl reload fail2ban
                log_info "Jail $jail_name enabled"
                ;;
            2)
                sed -i "/^\[$jail_name\]/,/^\[/ s/enabled = true/enabled = false/" /etc/fail2ban/jail.local
                systemctl reload fail2ban
                log_info "Jail $jail_name disabled"
                ;;
            *)
                echo -e "${RED}Invalid action${NC}"
                ;;
        esac
    fi
    
    wait_for_key
}

# View jail status
view_jail_status() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                               JAIL STATUS                                     ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    if command_exists fail2ban-client; then
        # Overall status
        fail2ban-client status
        echo
        
        # Individual jail status
        local jails=$(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | tr -d ' \t' | tr ',' ' ')
        
        for jail in $jails; do
            echo -e "${YELLOW}Jail: $jail${NC}"
            fail2ban-client status $jail 2>/dev/null
            echo
        done
    else
        echo "Fail2Ban not installed or not running"
    fi
    
    wait_for_key
}

# Reload jail
reload_jail() {
    echo
    local jail_name=$(get_input "Jail name to reload (or 'all' for all jails)" "" "all")
    
    if [ "$jail_name" = "all" ]; then
        systemctl reload fail2ban
        log_info "All jails reloaded"
    else
        fail2ban-client reload $jail_name
        log_info "Jail $jail_name reloaded"
    fi
    
    wait_for_key
}

# Add custom jail
add_custom_jail() {
    echo
    echo -e "${YELLOW}Add Custom Jail${NC}"
    echo
    
    local jail_name=$(get_input "Jail name" "" "")
    local log_path=$(get_input "Log file path" "" "/var/log/auth.log")
    local filter_name=$(get_input "Filter name" "" "$jail_name")
    local max_retry=$(get_input "Max retry attempts" "validate_number" "3")
    local ban_time=$(get_input "Ban time (seconds)" "validate_number" "3600")
    local port=$(get_input "Port (optional)" "" "")
    
    # Add jail to configuration
    cat >> /etc/fail2ban/jail.local << EOF

# Custom jail: $jail_name
[$jail_name]
enabled = true
filter = $filter_name
logpath = $log_path
maxretry = $max_retry
bantime = $ban_time
EOF
    
    if [ -n "$port" ]; then
        echo "port = $port" >> /etc/fail2ban/jail.local
    fi
    
    # Create basic filter if it doesn't exist
    if [ ! -f "/etc/fail2ban/filter.d/$filter_name.conf" ]; then
        echo
        echo -e "${YELLOW}Creating basic filter for $filter_name${NC}"
        local fail_regex=$(get_input "Failure regex pattern" "" "Failed.*<HOST>")
        
        cat > "/etc/fail2ban/filter.d/$filter_name.conf" << EOF
# Custom filter: $filter_name
[Definition]
failregex = $fail_regex
ignoreregex =
EOF
    fi
    
    # Reload Fail2Ban
    systemctl reload fail2ban
    
    log_info "Custom jail $jail_name added"
    wait_for_key
}

# Remove jail
remove_jail() {
    echo
    local jail_name=$(get_input "Jail name to remove" "" "")
    
    if [ -n "$jail_name" ]; then
        if confirm "Remove jail $jail_name?"; then
            # Remove jail from configuration
            sed -i "/^\[$jail_name\]/,/^$/d" /etc/fail2ban/jail.local
            
            # Reload Fail2Ban
            systemctl reload fail2ban
            
            log_info "Jail $jail_name removed"
        fi
    fi
    
    wait_for_key
}

# View banned IPs
view_banned_ips() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                               BANNED IPS                                     ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    if command_exists fail2ban-client; then
        local jails=$(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | tr -d ' \t' | tr ',' ' ')
        
        for jail in $jails; do
            echo -e "${YELLOW}Jail: $jail${NC}"
            local banned_ips=$(fail2ban-client status $jail 2>/dev/null | grep "Banned IP list" | cut -d: -f2 | tr -d ' \t')
            
            if [ -n "$banned_ips" ]; then
                echo "$banned_ips" | tr ' ' '\n' | sed 's/^/  /'
            else
                echo "  No banned IPs"
            fi
            echo
        done
    else
        echo "Fail2Ban not installed or not running"
    fi
    
    wait_for_key
}

# Unban IP address
unban_ip() {
    echo
    local ip_address=$(get_input "IP address to unban" "validate_ip" "")
    
    if [ -n "$ip_address" ]; then
        # Try to unban from all jails
        local jails=$(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | tr -d ' \t' | tr ',' ' ')
        
        local unbanned=false
        for jail in $jails; do
            if fail2ban-client unban $ip_address --jail=$jail 2>/dev/null; then
                log_info "IP $ip_address unbanned from jail $jail"
                unbanned=true
            fi
        done
        
        if [ "$unbanned" = false ]; then
            log_warn "IP $ip_address was not found in any jail"
        fi
    fi
    
    wait_for_key
}

# Configure protection rules
configure_protection() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           PROTECTION RULES                                 ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] SSH Protection${NC}"
        echo -e "${YELLOW}  [2] Web Server Protection${NC}"
        echo -e "${YELLOW}  [3] Proxy Protection${NC}"
        echo -e "${YELLOW}  [4] Custom Service Protection${NC}"
        echo -e "${YELLOW}  [5] Global Settings${NC}"
        echo -e "${YELLOW}  [0] Back to Fail2Ban Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) configure_ssh_protection ;;
            2) configure_web_protection ;;
            3) configure_proxy_protection ;;
            4) configure_custom_protection ;;
            5) configure_global_settings ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Configure SSH protection
configure_ssh_protection() {
    echo
    echo -e "${YELLOW}SSH Protection Configuration${NC}"
    echo
    
    local max_retry=$(get_input "Max retry attempts" "validate_number" "3")
    local ban_time=$(get_input "Ban time (seconds)" "validate_number" "3600")
    local find_time=$(get_input "Find time (seconds)" "validate_number" "600")
    
    # Update SSH jail configuration
    sed -i "/^\[sshd\]/,/^\[/ s/maxretry = .*/maxretry = $max_retry/" /etc/fail2ban/jail.local
    sed -i "/^\[sshd\]/,/^\[/ s/bantime = .*/bantime = $ban_time/" /etc/fail2ban/jail.local
    sed -i "/^\[sshd\]/,/^\[/ s/findtime = .*/findtime = $find_time/" /etc/fail2ban/jail.local
    
    systemctl reload fail2ban
    
    log_info "SSH protection configured"
    wait_for_key
}

# Configure web protection
configure_web_protection() {
    echo
    echo -e "${YELLOW}Web Server Protection Configuration${NC}"
    echo
    
    if confirm "Enable aggressive web protection?"; then
        # Enable all web-related jails
        sed -i "/^\[nginx-http-auth\]/,/^\[/ s/enabled = false/enabled = true/" /etc/fail2ban/jail.local
        sed -i "/^\[nginx-noscript\]/,/^\[/ s/enabled = false/enabled = true/" /etc/fail2ban/jail.local
        sed -i "/^\[nginx-badbots\]/,/^\[/ s/enabled = false/enabled = true/" /etc/fail2ban/jail.local
        sed -i "/^\[nginx-noproxy\]/,/^\[/ s/enabled = false/enabled = true/" /etc/fail2ban/jail.local
        
        systemctl reload fail2ban
        log_info "Web server protection enabled"
    fi
    
    wait_for_key
}

# Configure proxy protection
configure_proxy_protection() {
    echo
    echo -e "${YELLOW}Proxy Protection Configuration${NC}"
    echo
    
    local max_retry=$(get_input "Max retry attempts for proxy" "validate_number" "5")
    local ban_time=$(get_input "Ban time for proxy abuse (seconds)" "validate_number" "7200")
    
    # Update proxy jail configuration
    sed -i "/^\[proxy-auth\]/,/^\[/ s/maxretry = .*/maxretry = $max_retry/" /etc/fail2ban/jail.local
    sed -i "/^\[proxy-auth\]/,/^\[/ s/bantime = .*/bantime = $ban_time/" /etc/fail2ban/jail.local
    sed -i "/^\[proxy-auth\]/,/^\[/ s/enabled = false/enabled = true/" /etc/fail2ban/jail.local
    
    systemctl reload fail2ban
    
    log_info "Proxy protection configured"
    wait_for_key
}

# Configure custom protection
configure_custom_protection() {
    echo
    echo -e "${YELLOW}Custom Service Protection${NC}"
    echo
    echo -e "${YELLOW}Use 'Add Custom Jail' option from the main jail management menu.${NC}"
    echo
    
    wait_for_key
}

# Configure global settings
configure_global_settings() {
    echo
    echo -e "${YELLOW}Global Fail2Ban Settings${NC}"
    echo
    
    local default_ban_time=$(get_input "Default ban time (seconds)" "validate_number" "3600")
    local default_find_time=$(get_input "Default find time (seconds)" "validate_number" "600")
    local default_max_retry=$(get_input "Default max retry" "validate_number" "3")
    
    # Update global settings
    sed -i "s/^bantime = .*/bantime = $default_ban_time/" /etc/fail2ban/jail.local
    sed -i "s/^findtime = .*/findtime = $default_find_time/" /etc/fail2ban/jail.local
    sed -i "s/^maxretry = .*/maxretry = $default_max_retry/" /etc/fail2ban/jail.local
    
    if [ -n "$ADMIN_EMAIL" ]; then
        sed -i "s/^destemail = .*/destemail = $ADMIN_EMAIL/" /etc/fail2ban/jail.local
    fi
    
    systemctl reload fail2ban
    
    log_info "Global settings updated"
    wait_for_key
}

# View logs
view_logs() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                               FAIL2BAN LOGS                                  ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Choose log type:${NC}"
    echo -e "  [1] Fail2Ban main log"
    echo -e "  [2] Recent bans"
    echo -e "  [3] Recent unbans"
    echo -e "  [4] Live log monitoring"
    echo
    
    read -p "Enter your choice [1-4]: " log_choice
    
    case $log_choice in
        1)
            tail -50 /var/log/fail2ban.log 2>/dev/null || echo "Log file not found"
            ;;
        2)
            grep "Ban " /var/log/fail2ban.log | tail -20 2>/dev/null || echo "No recent bans"
            ;;
        3)
            grep "Unban " /var/log/fail2ban.log | tail -20 2>/dev/null || echo "No recent unbans"
            ;;
        4)
            echo -e "${YELLOW}Live log monitoring (Press Ctrl+C to exit):${NC}"
            tail -f /var/log/fail2ban.log 2>/dev/null || echo "Log file not found"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    echo
    wait_for_key
}

# Statistics
show_statistics() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             FAIL2BAN STATISTICS                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    if [ -f /var/log/fail2ban.log ]; then
        echo -e "${YELLOW}Ban Statistics:${NC}"
        local total_bans=$(grep -c "Ban " /var/log/fail2ban.log 2>/dev/null || echo "0")
        local total_unbans=$(grep -c "Unban " /var/log/fail2ban.log 2>/dev/null || echo "0")
        echo -e "  Total bans: $total_bans"
        echo -e "  Total unbans: $total_unbans"
        echo
        
        echo -e "${YELLOW}Top 10 Banned IPs:${NC}"
        grep "Ban " /var/log/fail2ban.log | awk '{print $NF}' | sort | uniq -c | sort -nr | head -10 | sed 's/^/  /'
        echo
        
        echo -e "${YELLOW}Bans by Jail:${NC}"
        grep "Ban " /var/log/fail2ban.log | awk '{print $6}' | sort | uniq -c | sort -nr | sed 's/^/  /'
        echo
        
        echo -e "${YELLOW}Recent Activity (Last 24 hours):${NC}"
        local today=$(date -d "1 day ago" "+%Y-%m-%d")
        local recent_bans=$(grep "$today" /var/log/fail2ban.log | grep -c "Ban " 2>/dev/null || echo "0")
        echo -e "  Bans in last 24h: $recent_bans"
        echo
    else
        echo "No log file found"
    fi
    
    wait_for_key
}

# Advanced configuration
advanced_configuration() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           ADVANCED CONFIGURATION                           ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Edit jail.local${NC}"
        echo -e "${YELLOW}  [2] Create Custom Filter${NC}"
        echo -e "${YELLOW}  [3] Configure Actions${NC}"
        echo -e "${YELLOW}  [4] Whitelist Management${NC}"
        echo -e "${YELLOW}  [5] Email Notifications${NC}"
        echo -e "${YELLOW}  [0] Back to Fail2Ban Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) edit_jail_config ;;
            2) create_custom_filter ;;
            3) configure_actions ;;
            4) whitelist_management ;;
            5) email_notifications ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Edit jail configuration
edit_jail_config() {
    echo
    echo -e "${YELLOW}Editing jail.local configuration...${NC}"
    echo
    
    # Backup current configuration
    backup_file /etc/fail2ban/jail.local
    
    # Edit configuration
    nano /etc/fail2ban/jail.local
    
    if confirm "Reload Fail2Ban to apply changes?"; then
        systemctl reload fail2ban
    fi
    
    wait_for_key
}

# Create custom filter
create_custom_filter() {
    echo
    echo -e "${YELLOW}Create Custom Filter${NC}"
    echo
    
    local filter_name=$(get_input "Filter name" "" "")
    local fail_regex=$(get_input "Failure regex pattern" "" "")
    local ignore_regex=$(get_input "Ignore regex pattern (optional)" "" "")
    
    if [ -n "$filter_name" ] && [ -n "$fail_regex" ]; then
        cat > "/etc/fail2ban/filter.d/$filter_name.conf" << EOF
# Custom filter: $filter_name
[Definition]
failregex = $fail_regex
ignoreregex = $ignore_regex
EOF
        
        log_info "Custom filter $filter_name created"
    fi
    
    wait_for_key
}

# Configure actions
configure_actions() {
    echo
    echo -e "${YELLOW}Configure Actions${NC}"
    echo
    echo -e "${YELLOW}Available actions:${NC}"
    ls /etc/fail2ban/action.d/ | head -10
    echo
    echo -e "${YELLOW}This feature allows customizing ban/unban actions.${NC}"
    echo -e "${YELLOW}Default actions are usually sufficient for most cases.${NC}"
    echo
    
    wait_for_key
}

# Whitelist management
whitelist_management() {
    echo
    echo -e "${YELLOW}Whitelist Management${NC}"
    echo
    
    echo -e "${YELLOW}Current whitelist (ignoreip):${NC}"
    grep "ignoreip" /etc/fail2ban/jail.local | head -1 | cut -d= -f2
    echo
    
    if confirm "Add IP to whitelist?"; then
        local ip_address=$(get_input "IP address or network to whitelist" "validate_ip_or_network" "")
        
        if [ -n "$ip_address" ]; then
            # Add to ignoreip list
            sed -i "s/ignoreip = \(.*\)/ignoreip = \1 $ip_address/" /etc/fail2ban/jail.local
            
            systemctl reload fail2ban
            log_info "IP $ip_address added to whitelist"
        fi
    fi
    
    wait_for_key
}

# Email notifications
email_notifications() {
    echo
    echo -e "${YELLOW}Email Notifications${NC}"
    echo
    
    local email=$(get_input "Admin email address" "" "$ADMIN_EMAIL")
    
    if [ -n "$email" ]; then
        sed -i "s/destemail = .*/destemail = $email/" /etc/fail2ban/jail.local
        
        if confirm "Enable email notifications for all jails?"; then
            sed -i 's/action = %(action_)s/action = %(action_mw)s/' /etc/fail2ban/jail.local
        fi
        
        systemctl reload fail2ban
        log_info "Email notifications configured"
    fi
    
    wait_for_key
}

# Backup/restore configuration
backup_restore_config() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           BACKUP/RESTORE CONFIG                            ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Backup Configuration${NC}"
        echo -e "${YELLOW}  [2] Restore Configuration${NC}"
        echo -e "${YELLOW}  [3] View Backups${NC}"
        echo -e "${YELLOW}  [0] Back to Fail2Ban Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-3]: " choice
        
        case $choice in
            1) backup_config ;;
            2) restore_config ;;
            3) view_config_backups ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Backup configuration
backup_config() {
    echo
    log_info "Creating Fail2Ban configuration backup..."
    
    local backup_dir="/opt/mastermind/backup/fail2ban"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="fail2ban_config_${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    # Create backup
    tar -czf "$backup_dir/$backup_file" /etc/fail2ban/ 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_info "Configuration backup created: $backup_dir/$backup_file"
    else
        log_error "Failed to create backup"
    fi
    
    wait_for_key
}

# Restore configuration
restore_config() {
    echo
    echo -e "${YELLOW}Available backups:${NC}"
    ls -la /opt/mastermind/backup/fail2ban/ 2>/dev/null || echo "No backups found"
    echo
    
    local backup_file=$(get_input "Backup filename" "" "")
    
    if [ -f "/opt/mastermind/backup/fail2ban/$backup_file" ]; then
        if confirm "Restore Fail2Ban configuration from $backup_file?"; then
            # Extract backup
            tar -xzf "/opt/mastermind/backup/fail2ban/$backup_file" -C /
            
            # Reload Fail2Ban
            systemctl reload fail2ban
            
            log_info "Configuration restored from $backup_file"
        fi
    else
        log_error "Backup file not found"
    fi
    
    wait_for_key
}

# View configuration backups
view_config_backups() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             CONFIGURATION BACKUPS                           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    local backup_dir="/opt/mastermind/backup/fail2ban"
    if [ -d "$backup_dir" ]; then
        ls -la "$backup_dir"
    else
        echo "No backups found"
    fi
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
        show_fail2ban_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) install_fail2ban ;;
            2) manage_jails ;;
            3) view_banned_ips ;;
            4) unban_ip ;;
            5) configure_protection ;;
            6) view_logs ;;
            7) show_statistics ;;
            8) advanced_configuration ;;
            9) backup_restore_config ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
