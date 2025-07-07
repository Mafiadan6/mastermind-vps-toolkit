#!/bin/bash

# Mastermind VPS Toolkit - Domain Manager
# Version: 1.0.0

# Load configuration and helper functions
MASTERMIND_HOME="${MASTERMIND_HOME:-/opt/mastermind}"
if [ -f "$MASTERMIND_HOME/core/helpers.sh" ]; then
    source "$MASTERMIND_HOME/core/helpers.sh"
elif [ -f "core/helpers.sh" ]; then
    source "core/helpers.sh"
fi

# Domain management menu
show_domain_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           DOMAIN & SSL MANAGEMENT                            ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}  [1] Install SSL Certificate (Let's Encrypt)${NC}"
    echo -e "${YELLOW}  [2] Install SSL Certificate (Manual)${NC}"
    echo -e "${YELLOW}  [3] List Installed Certificates${NC}"
    echo -e "${YELLOW}  [4] Remove SSL Certificate${NC}"
    echo -e "${YELLOW}  [5] Renew SSL Certificate${NC}"
    echo -e "${YELLOW}  [6] Test SSL Certificate${NC}"
    echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Install SSL certificate using Let's Encrypt
install_letsencrypt_cert() {
    echo
    echo -e "${YELLOW}Install Let's Encrypt SSL Certificate${NC}"
    echo
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}Installing certbot...${NC}"
        apt update
        apt install -y certbot
    fi
    
    local domain=$(get_input "Domain name" "" "")
    local email=$(get_input "Email address for Let's Encrypt" "" "")
    
    if [ -z "$domain" ] || [ -z "$email" ]; then
        log_error "Domain and email are required"
        wait_for_key
        return
    fi
    
    # Stop nginx if running to avoid port conflicts
    systemctl stop nginx 2>/dev/null || true
    
    # Generate certificate
    log_info "Generating SSL certificate for $domain..."
    certbot certonly --standalone --non-interactive --agree-tos --email "$email" -d "$domain"
    
    if [ $? -eq 0 ]; then
        # Copy certificates to V2Ray directory
        mkdir -p /etc/ssl/certs /etc/ssl/private
        cp "/etc/letsencrypt/live/$domain/fullchain.pem" "/etc/ssl/certs/$domain.crt"
        cp "/etc/letsencrypt/live/$domain/privkey.pem" "/etc/ssl/private/$domain.key"
        
        # Set proper permissions
        chmod 644 "/etc/ssl/certs/$domain.crt"
        chmod 600 "/etc/ssl/private/$domain.key"
        
        log_success "SSL certificate installed successfully for $domain"
        echo -e "${GREEN}Certificate files:${NC}"
        echo -e "  Certificate: /etc/ssl/certs/$domain.crt"
        echo -e "  Private Key: /etc/ssl/private/$domain.key"
        
        # Save domain info
        echo "Domain: $domain" > /opt/mastermind/configs/ssl_domains.txt
        echo "Certificate: /etc/ssl/certs/$domain.crt" >> /opt/mastermind/configs/ssl_domains.txt
        echo "Private Key: /etc/ssl/private/$domain.key" >> /opt/mastermind/configs/ssl_domains.txt
        echo "Installed: $(date)" >> /opt/mastermind/configs/ssl_domains.txt
        
    else
        log_error "Failed to generate SSL certificate"
        echo -e "${RED}Common issues:${NC}"
        echo -e "  • Domain doesn't point to this server"
        echo -e "  • Port 80 is blocked"
        echo -e "  • Domain is not accessible from internet"
    fi
    
    # Restart nginx if it was running
    systemctl start nginx 2>/dev/null || true
    
    wait_for_key
}

# Install SSL certificate manually
install_manual_cert() {
    echo
    echo -e "${YELLOW}Install Manual SSL Certificate${NC}"
    echo
    
    local domain=$(get_input "Domain name" "" "")
    
    if [ -z "$domain" ]; then
        log_error "Domain name is required"
        wait_for_key
        return
    fi
    
    echo -e "${YELLOW}Please provide the certificate files:${NC}"
    local cert_file=$(get_input "Certificate file path (.crt or .pem)" "" "")
    local key_file=$(get_input "Private key file path (.key)" "" "")
    
    if [ ! -f "$cert_file" ]; then
        log_error "Certificate file not found: $cert_file"
        wait_for_key
        return
    fi
    
    if [ ! -f "$key_file" ]; then
        log_error "Private key file not found: $key_file"
        wait_for_key
        return
    fi
    
    # Create directories
    mkdir -p /etc/ssl/certs /etc/ssl/private
    
    # Copy certificate files
    cp "$cert_file" "/etc/ssl/certs/$domain.crt"
    cp "$key_file" "/etc/ssl/private/$domain.key"
    
    # Set proper permissions
    chmod 644 "/etc/ssl/certs/$domain.crt"
    chmod 600 "/etc/ssl/private/$domain.key"
    
    log_success "Manual SSL certificate installed for $domain"
    echo -e "${GREEN}Certificate files:${NC}"
    echo -e "  Certificate: /etc/ssl/certs/$domain.crt"
    echo -e "  Private Key: /etc/ssl/private/$domain.key"
    
    # Save domain info
    echo "Domain: $domain" >> /opt/mastermind/configs/ssl_domains.txt
    echo "Certificate: /etc/ssl/certs/$domain.crt" >> /opt/mastermind/configs/ssl_domains.txt
    echo "Private Key: /etc/ssl/private/$domain.key" >> /opt/mastermind/configs/ssl_domains.txt
    echo "Installed: $(date)" >> /opt/mastermind/configs/ssl_domains.txt
    
    wait_for_key
}

# List installed certificates
list_certificates() {
    echo
    echo -e "${YELLOW}Installed SSL Certificates${NC}"
    echo
    
    if [ -f "/opt/mastermind/configs/ssl_domains.txt" ]; then
        echo -e "${GREEN}Domain certificates:${NC}"
        cat /opt/mastermind/configs/ssl_domains.txt
    else
        echo -e "${YELLOW}No certificates found${NC}"
    fi
    
    echo
    echo -e "${YELLOW}Certificate files in /etc/ssl/certs/:${NC}"
    if [ -d "/etc/ssl/certs" ]; then
        ls -la /etc/ssl/certs/*.crt 2>/dev/null || echo "No .crt files found"
    fi
    
    echo
    echo -e "${YELLOW}Let's Encrypt certificates:${NC}"
    if [ -d "/etc/letsencrypt/live" ]; then
        ls -la /etc/letsencrypt/live/ 2>/dev/null || echo "No Let's Encrypt certificates found"
    fi
    
    wait_for_key
}

# Remove SSL certificate
remove_certificate() {
    echo
    echo -e "${YELLOW}Remove SSL Certificate${NC}"
    echo
    
    local domain=$(get_input "Domain name to remove" "" "")
    
    if [ -z "$domain" ]; then
        log_error "Domain name is required"
        wait_for_key
        return
    fi
    
    if confirm "Remove SSL certificate for $domain?"; then
        # Remove certificate files
        rm -f "/etc/ssl/certs/$domain.crt"
        rm -f "/etc/ssl/private/$domain.key"
        
        # Remove Let's Encrypt certificate if exists
        if [ -d "/etc/letsencrypt/live/$domain" ]; then
            certbot delete --cert-name "$domain" --non-interactive 2>/dev/null || true
        fi
        
        log_success "SSL certificate removed for $domain"
    fi
    
    wait_for_key
}

# Renew SSL certificate
renew_certificate() {
    echo
    echo -e "${YELLOW}Renew SSL Certificate${NC}"
    echo
    
    if command -v certbot &> /dev/null; then
        log_info "Renewing Let's Encrypt certificates..."
        certbot renew --quiet
        
        if [ $? -eq 0 ]; then
            log_success "Certificates renewed successfully"
            
            # Update V2Ray certificate files
            for domain_dir in /etc/letsencrypt/live/*/; do
                if [ -d "$domain_dir" ]; then
                    domain=$(basename "$domain_dir")
                    cp "$domain_dir/fullchain.pem" "/etc/ssl/certs/$domain.crt"
                    cp "$domain_dir/privkey.pem" "/etc/ssl/private/$domain.key"
                    chmod 644 "/etc/ssl/certs/$domain.crt"
                    chmod 600 "/etc/ssl/private/$domain.key"
                    log_info "Updated certificate for $domain"
                fi
            done
            
            # Restart V2Ray to use new certificates
            systemctl restart v2ray 2>/dev/null || true
            
        else
            log_error "Certificate renewal failed"
        fi
    else
        log_error "Certbot not installed"
    fi
    
    wait_for_key
}

# Test SSL certificate
test_certificate() {
    echo
    echo -e "${YELLOW}Test SSL Certificate${NC}"
    echo
    
    local domain=$(get_input "Domain name to test" "" "")
    local port=$(get_input "Port to test" "" "443")
    
    if [ -z "$domain" ]; then
        log_error "Domain name is required"
        wait_for_key
        return
    fi
    
    echo -e "${YELLOW}Testing SSL certificate for $domain:$port...${NC}"
    
    # Test certificate validity
    if command -v openssl &> /dev/null; then
        echo | openssl s_client -servername "$domain" -connect "$domain:$port" 2>/dev/null | openssl x509 -noout -dates
        
        if [ $? -eq 0 ]; then
            log_success "SSL certificate is valid"
        else
            log_error "SSL certificate test failed"
        fi
    else
        log_error "OpenSSL not installed"
    fi
    
    # Test with curl
    if command -v curl &> /dev/null; then
        echo
        echo -e "${YELLOW}Testing HTTPS connection...${NC}"
        curl -I "https://$domain:$port" --max-time 10
        
        if [ $? -eq 0 ]; then
            log_success "HTTPS connection successful"
        else
            log_error "HTTPS connection failed"
        fi
    fi
    
    wait_for_key
}

# Main function
main() {
    case ${1:-"menu"} in
        "letsencrypt") install_letsencrypt_cert ;;
        "manual") install_manual_cert ;;
        "list") list_certificates ;;
        "remove") remove_certificate ;;
        "renew") renew_certificate ;;
        "test") test_certificate ;;
        "menu"|*)
            while true; do
                show_domain_menu
                read -p "Enter your choice [0-6]: " choice
                
                case $choice in
                    1) install_letsencrypt_cert ;;
                    2) install_manual_cert ;;
                    3) list_certificates ;;
                    4) remove_certificate ;;
                    5) renew_certificate ;;
                    6) test_certificate ;;
                    0) exit 0 ;;
                    *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
                esac
            done
            ;;
    esac
}

# Run main function
main "$@"