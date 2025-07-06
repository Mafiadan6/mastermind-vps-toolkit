#!/bin/bash

# Mastermind VPS Toolkit - Squid Proxy Manager
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Squid Proxy configuration
SQUID_PORT=3128
SQUID_TRANSPARENT_PORT=3129
SQUID_SSL_PORT=8443

# Show Squid proxy menu
show_squid_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                            SQUID PROXY MANAGEMENT                            ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Show service status
    echo -e "${YELLOW}Service Status:${NC}"
    echo -e "  Squid: $(get_service_status "squid")"
    
    # Show port status
    echo -e "${YELLOW}Port Status:${NC}"
    echo -e "  HTTP Proxy ($SQUID_PORT): $(get_port_status $SQUID_PORT)"
    echo -e "  Transparent Proxy ($SQUID_TRANSPARENT_PORT): $(get_port_status $SQUID_TRANSPARENT_PORT)"
    echo -e "  SSL Proxy ($SQUID_SSL_PORT): $(get_port_status $SQUID_SSL_PORT)"
    
    echo
    echo -e "${YELLOW}  [1] Install/Configure Squid${NC}"
    echo -e "${YELLOW}  [2] Start/Stop Squid${NC}"
    echo -e "${YELLOW}  [3] Configure Ports${NC}"
    echo -e "${YELLOW}  [4] Authentication Setup${NC}"
    echo -e "${YELLOW}  [5] Access Control${NC}"
    echo -e "${YELLOW}  [6] SSL/HTTPS Setup${NC}"
    echo -e "${YELLOW}  [7] Transparent Proxy${NC}"
    echo -e "${YELLOW}  [8] Cache Configuration${NC}"
    echo -e "${YELLOW}  [9] Monitoring & Logs${NC}"
    echo -e "${YELLOW}  [0] Back to Protocol Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Install and configure Squid
install_squid() {
    echo
    echo -e "${YELLOW}Installing Squid Proxy...${NC}"
    echo
    
    # Check if already installed
    if command -v squid &> /dev/null; then
        log_warn "Squid is already installed"
        if ! confirm "Reinstall Squid?"; then
            return
        fi
    fi
    
    # Install Squid
    log_info "Installing Squid proxy server..."
    apt update
    apt install -y squid squid-common squid-langpack
    
    # Create backup of original config
    cp /etc/squid/squid.conf /etc/squid/squid.conf.backup
    
    # Create mastermind configuration
    create_squid_config
    
    # Create authentication file
    create_squid_auth
    
    # Start and enable service
    systemctl enable squid
    systemctl start squid
    
    log_info "Squid proxy installed and configured"
    
    # Show connection details
    echo
    echo -e "${GREEN}Squid Proxy Configuration:${NC}"
    echo -e "  HTTP Proxy: $PUBLIC_IP:$SQUID_PORT"
    echo -e "  Transparent Proxy: $PUBLIC_IP:$SQUID_TRANSPARENT_PORT"
    echo -e "  SSL Proxy: $PUBLIC_IP:$SQUID_SSL_PORT"
    echo -e "  Username: squid_user"
    echo -e "  Password: $(cat /etc/squid/passwd | cut -d: -f2)"
    
    wait_for_key
}

# Create Squid configuration
create_squid_config() {
    log_info "Creating Squid configuration..."
    
    cat > /etc/squid/squid.conf << EOF
# Mastermind VPS Toolkit - Squid Configuration
# Generated on $(date)

# Network options
http_port $SQUID_PORT
http_port $SQUID_TRANSPARENT_PORT transparent
https_port $SQUID_SSL_PORT cert=/etc/squid/squid.crt key=/etc/squid/squid.key

# Authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 2 hours
auth_param basic casesensitive off

# Access Control Lists
acl localnet src 0.0.0.1-0.255.255.255
acl localnet src 10.0.0.0/8
acl localnet src 100.64.0.0/10
acl localnet src 169.254.0.0/16
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl localnet src fc00::/7
acl localnet src fe80::/10

acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT

# Authentication required
acl authenticated_users proxy_auth REQUIRED

# Access rules
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localnet
http_access allow authenticated_users
http_access deny all

# Squid normally listens to port 3128
# http_port 3128

# Uncomment and adjust the following to add a disk cache directory.
cache_dir ufs /var/spool/squid 100 16 256

# Leave coredumps in the first cache dir
coredump_dir /var/spool/squid

# Add any of your own refresh_pattern entries above these.
refresh_pattern ^ftp:        1440    20%    10080
refresh_pattern ^gopher:    1440    0%    1440
refresh_pattern -i (/cgi-bin/|\\?) 0    0%    0
refresh_pattern .        0    20%    4320

# Logging
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log
cache_store_log /var/log/squid/store.log

# DNS
dns_nameservers 8.8.8.8 1.1.1.1

# Performance
maximum_object_size 4096 KB
maximum_object_size_in_memory 64 KB
memory_replacement_policy lru
cache_replacement_policy lru

# Hide proxy info
forwarded_for delete
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access Cache-Control deny all

# Custom error pages
error_directory /usr/share/squid/errors/English

EOF
}

# Create authentication file
create_squid_auth() {
    log_info "Creating Squid authentication..."
    
    # Generate random password
    local squid_password=$(generate_password 12)
    
    # Create password file
    echo "squid_user:$(openssl passwd -apr1 $squid_password)" > /etc/squid/passwd
    chown proxy:proxy /etc/squid/passwd
    chmod 600 /etc/squid/passwd
    
    # Store password for display
    echo "$squid_password" > /tmp/squid_password
}

# Generate SSL certificate for HTTPS proxy
generate_squid_ssl() {
    log_info "Generating SSL certificate for Squid..."
    
    # Create SSL directory
    mkdir -p /etc/squid/ssl
    
    # Generate private key
    openssl genrsa -out /etc/squid/squid.key 2048
    
    # Generate certificate
    openssl req -new -key /etc/squid/squid.key -out /etc/squid/squid.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=$PUBLIC_IP"
    openssl x509 -req -days 365 -in /etc/squid/squid.csr -signkey /etc/squid/squid.key -out /etc/squid/squid.crt
    
    # Set permissions
    chown proxy:proxy /etc/squid/squid.key /etc/squid/squid.crt
    chmod 600 /etc/squid/squid.key
    chmod 644 /etc/squid/squid.crt
    
    log_info "SSL certificate generated"
}

# Configure Squid ports
configure_squid_ports() {
    echo
    echo -e "${YELLOW}Configure Squid Ports${NC}"
    echo
    
    echo -e "${YELLOW}Current ports:${NC}"
    echo -e "  HTTP Proxy: $SQUID_PORT"
    echo -e "  Transparent Proxy: $SQUID_TRANSPARENT_PORT"
    echo -e "  SSL Proxy: $SQUID_SSL_PORT"
    echo
    
    if confirm "Change HTTP proxy port?"; then
        local new_port=$(get_input "New HTTP proxy port" "validate_port" "$SQUID_PORT")
        if [ "$new_port" != "$SQUID_PORT" ]; then
            SQUID_PORT=$new_port
            update_config_value "SQUID_PORT" "$SQUID_PORT"
        fi
    fi
    
    if confirm "Change transparent proxy port?"; then
        local new_port=$(get_input "New transparent proxy port" "validate_port" "$SQUID_TRANSPARENT_PORT")
        if [ "$new_port" != "$SQUID_TRANSPARENT_PORT" ]; then
            SQUID_TRANSPARENT_PORT=$new_port
            update_config_value "SQUID_TRANSPARENT_PORT" "$SQUID_TRANSPARENT_PORT"
        fi
    fi
    
    if confirm "Change SSL proxy port?"; then
        local new_port=$(get_input "New SSL proxy port" "validate_port" "$SQUID_SSL_PORT")
        if [ "$new_port" != "$SQUID_SSL_PORT" ]; then
            SQUID_SSL_PORT=$new_port
            update_config_value "SQUID_SSL_PORT" "$SQUID_SSL_PORT"
        fi
    fi
    
    # Recreate configuration with new ports
    create_squid_config
    systemctl restart squid
    
    log_info "Squid ports updated"
    wait_for_key
}

# Start/Stop Squid service
control_squid_service() {
    echo
    echo -e "${YELLOW}Squid Service Control${NC}"
    echo
    
    local status=$(systemctl is-active squid)
    echo -e "Current status: $status"
    echo
    
    if [ "$status" = "active" ]; then
        echo -e "${YELLOW}  [1] Stop Squid${NC}"
        echo -e "${YELLOW}  [2] Restart Squid${NC}"
        echo -e "${YELLOW}  [3] Reload Configuration${NC}"
        echo -e "${YELLOW}  [0] Back${NC}"
        echo
        
        read -p "Enter your choice [0-3]: " choice
        
        case $choice in
            1)
                systemctl stop squid
                log_info "Squid stopped"
                ;;
            2)
                systemctl restart squid
                log_info "Squid restarted"
                ;;
            3)
                systemctl reload squid
                log_info "Squid configuration reloaded"
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
    else
        echo -e "${YELLOW}  [1] Start Squid${NC}"
        echo -e "${YELLOW}  [2] Enable Auto-start${NC}"
        echo -e "${YELLOW}  [0] Back${NC}"
        echo
        
        read -p "Enter your choice [0-2]: " choice
        
        case $choice in
            1)
                systemctl start squid
                log_info "Squid started"
                ;;
            2)
                systemctl enable squid
                systemctl start squid
                log_info "Squid enabled and started"
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
    fi
    
    wait_for_key
}

# Monitor Squid logs
monitor_squid_logs() {
    echo
    echo -e "${YELLOW}Squid Log Monitor${NC}"
    echo
    
    echo -e "${YELLOW}  [1] View Access Log${NC}"
    echo -e "${YELLOW}  [2] View Cache Log${NC}"
    echo -e "${YELLOW}  [3] View Store Log${NC}"
    echo -e "${YELLOW}  [4] Real-time Access Log${NC}"
    echo -e "${YELLOW}  [5] Connection Statistics${NC}"
    echo -e "${YELLOW}  [0] Back${NC}"
    echo
    
    read -p "Enter your choice [0-5]: " choice
    
    case $choice in
        1)
            if [ -f /var/log/squid/access.log ]; then
                echo -e "${YELLOW}Recent access log entries:${NC}"
                tail -n 20 /var/log/squid/access.log
            else
                echo -e "${RED}Access log not found${NC}"
            fi
            ;;
        2)
            if [ -f /var/log/squid/cache.log ]; then
                echo -e "${YELLOW}Recent cache log entries:${NC}"
                tail -n 20 /var/log/squid/cache.log
            else
                echo -e "${RED}Cache log not found${NC}"
            fi
            ;;
        3)
            if [ -f /var/log/squid/store.log ]; then
                echo -e "${YELLOW}Recent store log entries:${NC}"
                tail -n 20 /var/log/squid/store.log
            else
                echo -e "${RED}Store log not found${NC}"
            fi
            ;;
        4)
            echo -e "${YELLOW}Real-time access log (Press Ctrl+C to stop):${NC}"
            tail -f /var/log/squid/access.log
            ;;
        5)
            show_squid_stats
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    wait_for_key
}

# Show Squid statistics
show_squid_stats() {
    echo
    echo -e "${YELLOW}Squid Statistics:${NC}"
    echo
    
    if systemctl is-active squid &> /dev/null; then
        # Connection count
        local connections=$(netstat -an | grep ":$SQUID_PORT " | wc -l)
        echo -e "  Active connections: $connections"
        
        # Cache statistics
        if [ -f /var/log/squid/access.log ]; then
            local total_requests=$(wc -l < /var/log/squid/access.log)
            local hits=$(grep "TCP_HIT" /var/log/squid/access.log | wc -l)
            local misses=$(grep "TCP_MISS" /var/log/squid/access.log | wc -l)
            
            echo -e "  Total requests: $total_requests"
            echo -e "  Cache hits: $hits"
            echo -e "  Cache misses: $misses"
            
            if [ $total_requests -gt 0 ]; then
                local hit_ratio=$(( hits * 100 / total_requests ))
                echo -e "  Hit ratio: $hit_ratio%"
            fi
        fi
        
        # Disk usage
        if [ -d /var/spool/squid ]; then
            local cache_size=$(du -sh /var/spool/squid 2>/dev/null | cut -f1)
            echo -e "  Cache size: $cache_size"
        fi
    else
        echo -e "${RED}Squid is not running${NC}"
    fi
}

# Main Squid menu handler
handle_squid_menu() {
    while true; do
        show_squid_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) install_squid ;;
            2) control_squid_service ;;
            3) configure_squid_ports ;;
            4) configure_squid_auth ;;
            5) configure_squid_access ;;
            6) setup_squid_ssl ;;
            7) setup_transparent_proxy ;;
            8) configure_squid_cache ;;
            9) monitor_squid_logs ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Configure Squid authentication
configure_squid_auth() {
    echo
    echo -e "${YELLOW}Configure Squid Authentication${NC}"
    echo
    
    if [ -f /etc/squid/passwd ]; then
        echo -e "${YELLOW}Current users:${NC}"
        cut -d: -f1 /etc/squid/passwd | sed 's/^/  /'
        echo
    fi
    
    echo -e "${YELLOW}  [1] Add User${NC}"
    echo -e "${YELLOW}  [2] Remove User${NC}"
    echo -e "${YELLOW}  [3] Change Password${NC}"
    echo -e "${YELLOW}  [4] Disable Authentication${NC}"
    echo -e "${YELLOW}  [5] Enable Authentication${NC}"
    echo -e "${YELLOW}  [0] Back${NC}"
    echo
    
    read -p "Enter your choice [0-5]: " choice
    
    case $choice in
        1) add_squid_user ;;
        2) remove_squid_user ;;
        3) change_squid_password ;;
        4) disable_squid_auth ;;
        5) enable_squid_auth ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
    
    wait_for_key
}

# Add Squid user
add_squid_user() {
    local username=$(get_input "Username" "" "")
    local password=$(get_input "Password" "" "")
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        log_error "Username and password cannot be empty"
        return
    fi
    
    # Add user to password file
    echo "$username:$(openssl passwd -apr1 $password)" >> /etc/squid/passwd
    
    # Reload Squid
    systemctl reload squid
    
    log_info "User $username added to Squid"
}

# Remove Squid user
remove_squid_user() {
    local username=$(get_input "Username to remove" "" "")
    
    if [ -z "$username" ]; then
        log_error "Username cannot be empty"
        return
    fi
    
    # Remove user from password file
    sed -i "/^$username:/d" /etc/squid/passwd
    
    # Reload Squid
    systemctl reload squid
    
    log_info "User $username removed from Squid"
}

# Setup SSL/HTTPS proxy
setup_squid_ssl() {
    echo
    echo -e "${YELLOW}Setup SSL/HTTPS Proxy${NC}"
    echo
    
    if [ ! -f /etc/squid/squid.crt ]; then
        log_info "Generating SSL certificate..."
        generate_squid_ssl
    else
        log_info "SSL certificate already exists"
    fi
    
    # Update configuration to enable SSL
    if ! grep -q "https_port" /etc/squid/squid.conf; then
        echo "https_port $SQUID_SSL_PORT cert=/etc/squid/squid.crt key=/etc/squid/squid.key" >> /etc/squid/squid.conf
        systemctl restart squid
        log_info "SSL proxy enabled on port $SQUID_SSL_PORT"
    else
        log_info "SSL proxy already configured"
    fi
    
    wait_for_key
}

# Setup transparent proxy
setup_transparent_proxy() {
    echo
    echo -e "${YELLOW}Setup Transparent Proxy${NC}"
    echo
    
    log_info "Configuring transparent proxy..."
    
    # Add iptables rules for transparent proxy
    iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port $SQUID_TRANSPARENT_PORT
    iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-port $SQUID_TRANSPARENT_PORT
    
    # Make rules persistent
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save
    fi
    
    log_info "Transparent proxy configured"
    wait_for_key
}

# Configure Squid cache
configure_squid_cache() {
    echo
    echo -e "${YELLOW}Configure Squid Cache${NC}"
    echo
    
    local cache_size=$(get_input "Cache size in MB" "validate_number" "100")
    local cache_dir=$(get_input "Cache directory" "" "/var/spool/squid")
    
    # Update cache configuration
    sed -i "s|cache_dir ufs.*|cache_dir ufs $cache_dir $cache_size 16 256|" /etc/squid/squid.conf
    
    # Initialize cache
    squid -z
    
    # Restart Squid
    systemctl restart squid
    
    log_info "Cache configured with ${cache_size}MB in $cache_dir"
    wait_for_key
}

# Configure access control
configure_squid_access() {
    echo
    echo -e "${YELLOW}Configure Access Control${NC}"
    echo
    
    echo -e "${YELLOW}  [1] Allow All Access${NC}"
    echo -e "${YELLOW}  [2] Local Network Only${NC}"
    echo -e "${YELLOW}  [3] Authenticated Users Only${NC}"
    echo -e "${YELLOW}  [4] Custom IP Range${NC}"
    echo -e "${YELLOW}  [0] Back${NC}"
    echo
    
    read -p "Enter your choice [0-4]: " choice
    
    case $choice in
        1)
            # Allow all access
            sed -i '/http_access allow authenticated_users/a http_access allow all' /etc/squid/squid.conf
            systemctl reload squid
            log_info "Access control set to allow all"
            ;;
        2)
            # Local network only
            sed -i 's/http_access allow all/http_access allow localnet/' /etc/squid/squid.conf
            systemctl reload squid
            log_info "Access control set to local network only"
            ;;
        3)
            # Authenticated users only (default)
            log_info "Access control already set to authenticated users only"
            ;;
        4)
            local ip_range=$(get_input "IP range (e.g., 192.168.1.0/24)" "" "")
            if [ -n "$ip_range" ]; then
                echo "acl custom_range src $ip_range" >> /etc/squid/squid.conf
                sed -i '/http_access allow authenticated_users/a http_access allow custom_range' /etc/squid/squid.conf
                systemctl reload squid
                log_info "Access control set to custom IP range: $ip_range"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    wait_for_key
}

# Main function
main() {
    handle_squid_menu
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi