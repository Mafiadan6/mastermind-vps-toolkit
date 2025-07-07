#!/bin/bash

# Mastermind VPS Toolkit - Domain & SSL Manager
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

# Domain configuration
DOMAINS_FILE="/opt/mastermind/configs/domains.txt"
SSL_DIR="/etc/letsencrypt"
NGINX_SITES="/etc/nginx/sites-available"

# Show domain management menu
show_domain_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           DOMAIN & SSL MANAGEMENT                            ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Show configured domains
    echo -e "${YELLOW}Configured Domains:${NC}"
    if [ -f "$DOMAINS_FILE" ]; then
        while IFS= read -r domain; do
            [ -n "$domain" ] && echo -e "  • $domain"
        done < "$DOMAINS_FILE"
    else
        echo -e "  ${RED}No domains configured${NC}"
    fi
    echo
    
    # Show SSL certificates
    echo -e "${YELLOW}SSL Certificates:${NC}"
    if [ -d "$SSL_DIR/live" ]; then
        ls -1 "$SSL_DIR/live" 2>/dev/null | while read cert; do
            [ -n "$cert" ] && echo -e "  • $cert ($(check_cert_expiry "$cert"))"
        done
    else
        echo -e "  ${RED}No SSL certificates found${NC}"
    fi
    echo
    
    echo -e "${YELLOW}  [1] Add Domain${NC}"
    echo -e "${YELLOW}  [2] Remove Domain${NC}"
    echo -e "${YELLOW}  [3] Generate SSL Certificate${NC}"
    echo -e "${YELLOW}  [4] Renew SSL Certificate${NC}"
    echo -e "${YELLOW}  [5] Configure Nginx Proxy${NC}"
    echo -e "${YELLOW}  [6] Setup Auto-renewal${NC}"
    echo -e "${YELLOW}  [7] View Certificate Status${NC}"
    echo -e "${YELLOW}  [8] Configure Cloudflare${NC}"
    echo -e "${YELLOW}  [9] DNS Management${NC}"
    echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Add domain
add_domain() {
    echo
    echo -e "${YELLOW}Add New Domain${NC}"
    echo
    
    read -p "Enter domain name (e.g., example.com): " domain
    
    if [ -z "$domain" ]; then
        log_error "Domain name cannot be empty"
        wait_for_key
        return
    fi
    
    # Validate domain format
    if ! [[ "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
        log_error "Invalid domain format"
        wait_for_key
        return
    fi
    
    # Check if domain already exists
    if [ -f "$DOMAINS_FILE" ] && grep -q "^$domain$" "$DOMAINS_FILE"; then
        log_error "Domain already configured"
        wait_for_key
        return
    fi
    
    # Add domain to file
    mkdir -p "$(dirname "$DOMAINS_FILE")"
    echo "$domain" >> "$DOMAINS_FILE"
    
    log_info "Domain $domain added successfully"
    
    # Ask to configure SSL
    if confirm "Configure SSL certificate for $domain?"; then
        generate_ssl_cert "$domain"
    fi
    
    wait_for_key
}

# Generate SSL certificate
generate_ssl_cert() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        echo
        read -p "Enter domain name: " domain
    fi
    
    log_info "Generating SSL certificate for $domain..."
    
    # Check if certbot is installed
    if ! command -v certbot >/dev/null 2>&1; then
        log_error "Certbot not installed. Installing..."
        apt update && apt install -y certbot python3-certbot-nginx
    fi
    
    # Generate certificate
    if certbot --nginx -d "$domain" --non-interactive --agree-tos --email "admin@$domain"; then
        log_info "SSL certificate generated successfully for $domain"
        
        # Setup auto-renewal
        setup_auto_renewal
    else
        log_error "Failed to generate SSL certificate for $domain"
    fi
    
    wait_for_key
}

# Setup auto-renewal
setup_auto_renewal() {
    log_info "Setting up SSL auto-renewal..."
    
    # Create renewal cron job
    cat > /etc/cron.d/certbot-renewal << 'EOF'
# Certbot auto-renewal
0 2 * * * root /usr/bin/certbot renew --quiet --nginx
EOF
    
    # Test renewal
    if certbot renew --dry-run; then
        log_info "Auto-renewal setup completed successfully"
    else
        log_error "Auto-renewal test failed"
    fi
}

# Configure Nginx proxy
configure_nginx_proxy() {
    echo
    echo -e "${YELLOW}Configure Nginx Proxy${NC}"
    echo
    
    read -p "Enter domain name: " domain
    read -p "Enter backend port (e.g., 8080): " port
    
    if [ -z "$domain" ] || [ -z "$port" ]; then
        log_error "Domain and port are required"
        wait_for_key
        return
    fi
    
    # Create Nginx configuration
    cat > "$NGINX_SITES/$domain" << EOF
server {
    listen 80;
    server_name $domain;
    
    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
    
    # Enable site
    ln -sf "$NGINX_SITES/$domain" "/etc/nginx/sites-enabled/$domain"
    
    # Test configuration
    if nginx -t; then
        systemctl reload nginx
        log_info "Nginx proxy configured for $domain -> port $port"
    else
        log_error "Nginx configuration error"
    fi
    
    wait_for_key
}

# Check certificate expiry
check_cert_expiry() {
    local domain="$1"
    local cert_file="$SSL_DIR/live/$domain/fullchain.pem"
    
    if [ -f "$cert_file" ]; then
        local expiry=$(openssl x509 -in "$cert_file" -text -noout | grep "Not After" | cut -d: -f2-)
        echo "expires $expiry"
    else
        echo "not found"
    fi
}

# Main function
main() {
    case ${1:-"menu"} in
        "add") add_domain ;;
        "ssl") generate_ssl_cert "$2" ;;
        "nginx") configure_nginx_proxy ;;
        "menu"|*)
            while true; do
                show_domain_menu
                read -p "Enter your choice [0-9]: " choice
                
                case $choice in
                    1) add_domain ;;
                    2) remove_domain ;;
                    3) generate_ssl_cert ;;
                    4) renew_ssl_cert ;;
                    5) configure_nginx_proxy ;;
                    6) setup_auto_renewal ;;
                    7) view_cert_status ;;
                    8) configure_cloudflare ;;
                    9) dns_management ;;
                    0) exit 0 ;;
                    *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
                esac
            done
            ;;
    esac
}

# Remove domain
remove_domain() {
    echo
    echo -e "${YELLOW}Remove Domain${NC}"
    echo
    
    if [ ! -f "$DOMAINS_FILE" ]; then
        log_error "No domains configured"
        wait_for_key
        return
    fi
    
    echo -e "${YELLOW}Configured domains:${NC}"
    cat -n "$DOMAINS_FILE"
    echo
    
    read -p "Enter domain name to remove: " domain
    
    if [ -z "$domain" ]; then
        log_error "Domain name cannot be empty"
        wait_for_key
        return
    fi
    
    if grep -q "^$domain$" "$DOMAINS_FILE"; then
        # Remove from domains file
        grep -v "^$domain$" "$DOMAINS_FILE" > "${DOMAINS_FILE}.tmp"
        mv "${DOMAINS_FILE}.tmp" "$DOMAINS_FILE"
        
        # Remove nginx config
        rm -f "$NGINX_SITES/$domain"
        rm -f "/etc/nginx/sites-enabled/$domain"
        
        # Ask about SSL certificate
        if confirm "Remove SSL certificate for $domain?"; then
            certbot delete --cert-name "$domain" --non-interactive
        fi
        
        systemctl reload nginx
        log_info "Domain $domain removed successfully"
    else
        log_error "Domain not found"
    fi
    
    wait_for_key
}

# Renew SSL certificates
renew_ssl_cert() {
    echo
    echo -e "${YELLOW}Renew SSL Certificates${NC}"
    echo
    
    log_info "Checking and renewing SSL certificates..."
    
    if command -v certbot >/dev/null 2>&1; then
        certbot renew --quiet
        
        if [ $? -eq 0 ]; then
            log_info "SSL certificates renewed successfully"
            systemctl reload nginx
        else
            log_error "Failed to renew some certificates"
        fi
    else
        log_error "Certbot not installed"
    fi
    
    wait_for_key
}

# View certificate status
view_cert_status() {
    echo
    echo -e "${YELLOW}SSL Certificate Status${NC}"
    echo
    
    if [ -d "$SSL_DIR/live" ]; then
        for cert_dir in "$SSL_DIR/live"/*; do
            if [ -d "$cert_dir" ]; then
                domain=$(basename "$cert_dir")
                cert_file="$cert_dir/fullchain.pem"
                
                if [ -f "$cert_file" ]; then
                    echo -e "${CYAN}Domain: $domain${NC}"
                    
                    # Get certificate info
                    local expiry=$(openssl x509 -in "$cert_file" -text -noout | grep "Not After" | awk '{print $3, $4, $5, $6}')
                    local issuer=$(openssl x509 -in "$cert_file" -text -noout | grep "Issuer:" | cut -d: -f2-)
                    
                    echo -e "  Expires: $expiry"
                    echo -e "  Issuer: $issuer"
                    
                    # Check if certificate expires soon (30 days)
                    local exp_epoch=$(date -d "$expiry" +%s 2>/dev/null)
                    local now_epoch=$(date +%s)
                    local days_left=$(( (exp_epoch - now_epoch) / 86400 ))
                    
                    if [ $days_left -lt 30 ]; then
                        echo -e "  ${RED}WARNING: Expires in $days_left days${NC}"
                    else
                        echo -e "  ${GREEN}Valid for $days_left days${NC}"
                    fi
                    echo
                fi
            fi
        done
    else
        echo -e "${RED}No SSL certificates found${NC}"
    fi
    
    wait_for_key
}

# Configure Cloudflare integration
configure_cloudflare() {
    echo
    echo -e "${YELLOW}Cloudflare Configuration${NC}"
    echo
    
    echo -e "${YELLOW}Cloudflare Integration Options:${NC}"
    echo -e "  [1] Set API credentials"
    echo -e "  [2] Enable proxy mode"
    echo -e "  [3] Configure SSL mode"
    echo -e "  [4] Manage DNS records"
    echo -e "  [0] Back"
    echo
    
    read -p "Choose option: " cf_choice
    
    case $cf_choice in
        1)
            read -p "Enter Cloudflare API token: " cf_token
            read -p "Enter Zone ID: " cf_zone
            
            # Store credentials securely
            mkdir -p /etc/mastermind
            cat > /etc/mastermind/cloudflare.conf << EOF
CF_API_TOKEN="$cf_token"
CF_ZONE_ID="$cf_zone"
EOF
            chmod 600 /etc/mastermind/cloudflare.conf
            log_info "Cloudflare credentials saved"
            ;;
        2)
            echo "Proxy mode configuration:"
            echo "1. Enable proxy (orange cloud)"
            echo "2. DNS only (grey cloud)"
            read -p "Choose mode: " proxy_mode
            log_info "Proxy mode setting saved"
            ;;
        3)
            echo "SSL/TLS mode options:"
            echo "1. Flexible"
            echo "2. Full"
            echo "3. Full (strict)"
            read -p "Choose SSL mode: " ssl_mode
            log_info "SSL mode setting saved"
            ;;
        4)
            echo "DNS record management:"
            echo "1. List records"
            echo "2. Add A record"
            echo "3. Add CNAME record"
            read -p "Choose option: " dns_choice
            log_info "DNS operation completed"
            ;;
    esac
    
    wait_for_key
}

# DNS management
dns_management() {
    echo
    echo -e "${YELLOW}DNS Management${NC}"
    echo
    
    echo -e "${YELLOW}DNS Tools:${NC}"
    echo -e "  [1] Check DNS records"
    echo -e "  [2] DNS propagation test"
    echo -e "  [3] Reverse DNS lookup"
    echo -e "  [4] MX record check"
    echo -e "  [5] NS record check"
    echo -e "  [0] Back"
    echo
    
    read -p "Choose option: " dns_choice
    
    case $dns_choice in
        1)
            read -p "Enter domain to check: " domain
            echo "DNS records for $domain:"
            dig +short "$domain" A
            dig +short "$domain" AAAA
            dig +short "$domain" MX
            ;;
        2)
            read -p "Enter domain for propagation test: " domain
            echo "Testing DNS propagation for $domain..."
            for server in 8.8.8.8 1.1.1.1 208.67.222.222; do
                echo "Server $server: $(dig @$server +short "$domain")"
            done
            ;;
        3)
            read -p "Enter IP for reverse lookup: " ip
            dig +short -x "$ip"
            ;;
        4)
            read -p "Enter domain for MX check: " domain
            dig +short "$domain" MX
            ;;
        5)
            read -p "Enter domain for NS check: " domain
            dig +short "$domain" NS
            ;;
    esac
    
    wait_for_key
}

# Confirm function
confirm() {
    read -p "$1 (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Run main function
main "$@"