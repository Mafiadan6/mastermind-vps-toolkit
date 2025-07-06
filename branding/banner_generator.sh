#!/bin/bash

# Mastermind VPS Toolkit - Banner Generator
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Show banner generator menu
show_banner_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             BANNER GENERATOR                                 ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Current Banner Configuration:${NC}"
    if [ -f "/etc/ssh/mastermind_banner" ]; then
        echo -e "  SSH Banner: ${GREEN}Configured${NC}"
    else
        echo -e "  SSH Banner: ${RED}Not configured${NC}"
    fi
    
    if grep -q "Banner" /etc/ssh/sshd_config; then
        echo -e "  SSH Banner Enabled: ${GREEN}Yes${NC}"
    else
        echo -e "  SSH Banner Enabled: ${RED}No${NC}"
    fi
    
    echo
    echo -e "${YELLOW}  [1] Create ASCII Art Banner${NC}"
    echo -e "${YELLOW}  [2] Create Simple Text Banner${NC}"
    echo -e "${YELLOW}  [3] Create Custom Banner${NC}"
    echo -e "${YELLOW}  [4] Apply Pre-made Templates${NC}"
    echo -e "${YELLOW}  [5] Configure SSH Banner${NC}"
    echo -e "${YELLOW}  [6] Configure MOTD Banner${NC}"
    echo -e "${YELLOW}  [7] Preview Current Banner${NC}"
    echo -e "${YELLOW}  [8] Remove Banner${NC}"
    echo -e "${YELLOW}  [0] Back to Branding Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Create ASCII art banner
create_ascii_banner() {
    echo
    echo -e "${YELLOW}ASCII Art Banner Generator${NC}"
    echo
    
    local title=$(get_input "Banner title" "" "$BRAND_MESSAGE")
    local subtitle=$(get_input "Subtitle (optional)" "" "VPS Toolkit")
    
    echo
    echo -e "${YELLOW}Available ASCII art styles:${NC}"
    echo -e "  [1] Block letters"
    echo -e "  [2] 3D style"
    echo -e "  [3] Shadow style"
    echo -e "  [4] Slant style"
    echo -e "  [5] Custom figlet font"
    echo
    
    read -p "Choose style [1-5]: " style_choice
    
    local figlet_font=""
    case $style_choice in
        1) figlet_font="block" ;;
        2) figlet_font="isometric1" ;;
        3) figlet_font="shadow" ;;
        4) figlet_font="slant" ;;
        5) 
            figlet_font=$(get_input "Figlet font name" "" "standard")
            ;;
        *) figlet_font="standard" ;;
    esac
    
    # Install figlet if not available
    if ! command_exists figlet; then
        log_info "Installing figlet..."
        apt update && apt install -y figlet
    fi
    
    # Generate ASCII art banner
    local banner_file="/tmp/mastermind_banner.txt"
    
    cat > "$banner_file" << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
EOF
    
    # Add ASCII art title
    if command_exists figlet; then
        figlet -f "$figlet_font" -w 78 "$title" | sed 's/^/║ /' | sed 's/$/ ║/' >> "$banner_file"
    else
        echo "║                           $title                                              ║" >> "$banner_file"
    fi
    
    cat >> "$banner_file" << EOF
╠══════════════════════════════════════════════════════════════════════════════╣
EOF
    
    if [ -n "$subtitle" ]; then
        local subtitle_padding=$(( (74 - ${#subtitle}) / 2 ))
        printf "║%*s%s%*s║\n" $subtitle_padding "" "$subtitle" $subtitle_padding "" >> "$banner_file"
    fi
    
    cat >> "$banner_file" << EOF
║                                                                              ║
║  Server: $(hostname)                                                         ║
║  IP: $(get_public_ip)                                                        ║
║  Time: $(date)                                                               ║
║                                                                              ║
║  Unauthorized access is prohibited and will be prosecuted.                  ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    
    echo
    echo -e "${YELLOW}Generated banner preview:${NC}"
    cat "$banner_file"
    echo
    
    if confirm "Apply this banner?"; then
        cp "$banner_file" /etc/ssh/mastermind_banner
        configure_ssh_banner_setting
        log_info "ASCII art banner applied"
    fi
    
    rm -f "$banner_file"
    wait_for_key
}

# Create simple text banner
create_simple_banner() {
    echo
    echo -e "${YELLOW}Simple Text Banner Generator${NC}"
    echo
    
    local title=$(get_input "Banner title" "" "$BRAND_MESSAGE")
    local message=$(get_input "Welcome message" "" "Welcome to the server")
    local warning=$(get_input "Warning message" "" "Unauthorized access is prohibited")
    
    local banner_file="/etc/ssh/mastermind_banner"
    
    cat > "$banner_file" << EOF
================================================================================
                               $title
================================================================================

$message

Server Information:
  Hostname: $(hostname)
  IP Address: $(get_public_ip)
  Current Time: $(date)

Security Notice:
$warning

================================================================================
EOF
    
    echo
    echo -e "${YELLOW}Generated banner:${NC}"
    cat "$banner_file"
    echo
    
    configure_ssh_banner_setting
    log_info "Simple text banner created and applied"
    
    wait_for_key
}

# Create custom banner
create_custom_banner() {
    echo
    echo -e "${YELLOW}Custom Banner Creator${NC}"
    echo
    
    local banner_file="/etc/ssh/mastermind_banner"
    
    echo -e "${YELLOW}Enter your custom banner content.${NC}"
    echo -e "${YELLOW}You can use the following variables:${NC}"
    echo -e "  \$HOSTNAME - Server hostname"
    echo -e "  \$IP - Public IP address"
    echo -e "  \$DATE - Current date"
    echo -e "  \$TIME - Current time"
    echo
    echo -e "${YELLOW}Press Ctrl+D when finished.${NC}"
    echo
    
    # Read custom banner content
    local custom_content=""
    while IFS= read -r line; do
        custom_content+="$line"$'\n'
    done
    
    # Process variables
    custom_content=${custom_content//\$HOSTNAME/$(hostname)}
    custom_content=${custom_content//\$IP/$(get_public_ip)}
    custom_content=${custom_content//\$DATE/$(date +%Y-%m-%d)}
    custom_content=${custom_content//\$TIME/$(date +%H:%M:%S)}
    
    # Save banner
    echo "$custom_content" > "$banner_file"
    
    echo
    echo -e "${YELLOW}Custom banner preview:${NC}"
    cat "$banner_file"
    echo
    
    if confirm "Apply this custom banner?"; then
        configure_ssh_banner_setting
        log_info "Custom banner applied"
    fi
    
    wait_for_key
}

# Apply pre-made templates
apply_templates() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             BANNER TEMPLATES                                ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Security-focused Template${NC}"
        echo -e "${YELLOW}  [2] Professional Template${NC}"
        echo -e "${YELLOW}  [3] Minimalist Template${NC}"
        echo -e "${YELLOW}  [4] Hacker-style Template${NC}"
        echo -e "${YELLOW}  [5] Corporate Template${NC}"
        echo -e "${YELLOW}  [0] Back to Banner Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Choose template [0-5]: " template_choice
        
        case $template_choice in
            1) apply_security_template ;;
            2) apply_professional_template ;;
            3) apply_minimalist_template ;;
            4) apply_hacker_template ;;
            5) apply_corporate_template ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Security-focused template
apply_security_template() {
    local banner_file="/etc/ssh/mastermind_banner"
    
    cat > "$banner_file" << 'EOF'
###############################################################################
#                                                                             #
#                          *** RESTRICTED ACCESS ***                         #
#                                                                             #
###############################################################################

WARNING: This system is restricted to authorized users only.

All activities on this system are monitored and recorded. 
Unauthorized access is strictly prohibited and will be prosecuted 
to the full extent of the law.

By continuing, you acknowledge that you have authorized access 
and agree to comply with all applicable policies.

System Information:
  - Server: $(hostname)
  - IP: $(get_public_ip)
  - Time: $(date)

If you are not an authorized user, disconnect immediately.

###############################################################################
EOF
    
    # Process variables
    sed -i "s/\$(hostname)/$(hostname)/g" "$banner_file"
    sed -i "s/\$(get_public_ip)/$(get_public_ip)/g" "$banner_file"
    sed -i "s/\$(date)/$(date)/g" "$banner_file"
    
    preview_and_apply_banner "$banner_file" "Security-focused"
}

# Professional template
apply_professional_template() {
    local banner_file="/etc/ssh/mastermind_banner"
    
    cat > "$banner_file" << EOF
┌──────────────────────────────────────────────────────────────────────────────┐
│                           $BRAND_MESSAGE                                     │
└──────────────────────────────────────────────────────────────────────────────┘

Welcome to our secure server environment.

Server Details:
  Hostname: $(hostname)
  IP Address: $(get_public_ip)
  System Time: $(date)
  Timezone: $(date +%Z)

Please ensure you follow all security protocols and company policies.
All sessions are logged for security and compliance purposes.

For technical support, contact: $ADMIN_EMAIL

────────────────────────────────────────────────────────────────────────────────
EOF
    
    preview_and_apply_banner "$banner_file" "Professional"
}

# Minimalist template
apply_minimalist_template() {
    local banner_file="/etc/ssh/mastermind_banner"
    
    cat > "$banner_file" << EOF
$BRAND_MESSAGE
$(hostname) | $(get_public_ip) | $(date +%Y-%m-%d)

Authorized access only.
EOF
    
    preview_and_apply_banner "$banner_file" "Minimalist"
}

# Hacker-style template
apply_hacker_template() {
    local banner_file="/etc/ssh/mastermind_banner"
    
    cat > "$banner_file" << 'EOF'
▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
█                                                                            █
█  ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ███╗   ███╗██╗███╗   █
█  ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  █
█  ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ █
█  ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗█
█  ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████
█  ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══█
█                                                                            █
▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

> System.status: ONLINE
> Node.id: $(hostname)
> Network.ip: $(get_public_ip)
> Timestamp: $(date +%s)

> Access.level: RESTRICTED
> Auth.required: TRUE
> Monitoring.enabled: TRUE

[!] Unauthorized intrusion attempts will be traced and reported.
EOF
    
    # Process variables
    sed -i "s/\$(hostname)/$(hostname)/g" "$banner_file"
    sed -i "s/\$(get_public_ip)/$(get_public_ip)/g" "$banner_file"
    sed -i "s/\$(date +%s)/$(date +%s)/g" "$banner_file"
    
    preview_and_apply_banner "$banner_file" "Hacker-style"
}

# Corporate template
apply_corporate_template() {
    local banner_file="/etc/ssh/mastermind_banner"
    
    cat > "$banner_file" << EOF
================================================================================
                              CORPORATE NETWORK
                               $BRAND_MESSAGE
================================================================================

NOTICE: This is a private computer system. Access is restricted to authorized
personnel only. All activities are monitored and logged in accordance with
corporate security policies.

Server Information:
  Location: $(hostname)
  IP Address: $(get_public_ip)
  Session Start: $(date)
  Administrator: $ADMIN_EMAIL

By accessing this system, you agree to:
  • Comply with all corporate IT policies
  • Use the system for authorized business purposes only
  • Report any security incidents immediately

For assistance, contact IT Support at $ADMIN_EMAIL

================================================================================
                     © $(date +%Y) Company Name. All rights reserved.
================================================================================
EOF
    
    preview_and_apply_banner "$banner_file" "Corporate"
}

# Preview and apply banner
preview_and_apply_banner() {
    local banner_file=$1
    local template_name=$2
    
    echo
    echo -e "${YELLOW}$template_name template preview:${NC}"
    cat "$banner_file"
    echo
    
    if confirm "Apply this $template_name template?"; then
        configure_ssh_banner_setting
        log_info "$template_name banner template applied"
    fi
    
    wait_for_key
}

# Configure SSH banner setting
configure_ssh_banner_setting() {
    # Enable banner in SSH configuration
    if ! grep -q "^Banner" /etc/ssh/sshd_config; then
        echo "Banner /etc/ssh/mastermind_banner" >> /etc/ssh/sshd_config
    else
        sed -i 's|^Banner.*|Banner /etc/ssh/mastermind_banner|' /etc/ssh/sshd_config
    fi
    
    # Restart SSH service to apply changes
    systemctl restart sshd
    
    log_info "SSH banner configuration updated"
}

# Configure MOTD banner
configure_motd_banner() {
    echo
    echo -e "${YELLOW}MOTD Banner Configuration${NC}"
    echo
    
    if confirm "Create dynamic MOTD banner?"; then
        # Create dynamic MOTD script
        cat > /etc/update-motd.d/01-mastermind << 'EOF'
#!/bin/bash

# Load configuration
source /opt/mastermind/core/config.cfg 2>/dev/null || true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${WHITE}                           MASTERMIND VPS TOOLKIT                             ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo

# System Information
echo -e "${YELLOW}System Information:${NC}"
echo -e "  Hostname: ${GREEN}$(hostname)${NC}"
echo -e "  Kernel: ${GREEN}$(uname -r)${NC}"
echo -e "  Uptime: ${GREEN}$(uptime -p)${NC}"
echo -e "  Load: ${GREEN}$(uptime | awk -F'load average:' '{print $2}')${NC}"
echo -e "  Memory: ${GREEN}$(free -h | grep '^Mem:' | awk '{print $3"/"$2}')${NC}"
echo -e "  Disk: ${GREEN}$(df -h / | tail -1 | awk '{print $3"/"$2" ("$5")"}')${NC}"

# Network Information
echo
echo -e "${YELLOW}Network Information:${NC}"
echo -e "  Public IP: ${GREEN}$(curl -s ifconfig.me 2>/dev/null || echo 'Unknown')${NC}"

# Service Status
echo
echo -e "${YELLOW}Service Status:${NC}"
services=("python-proxy" "tcp-bypass" "v2ray" "fail2ban")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "  $service: ${GREEN}RUNNING${NC}"
    else
        echo -e "  $service: ${RED}STOPPED${NC}"
    fi
done

echo
echo -e "${CYAN}Run 'mastermind' or 'menu' to access the control panel${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
echo
EOF
        
        chmod +x /etc/update-motd.d/01-mastermind
        
        # Disable other MOTD components
        chmod -x /etc/update-motd.d/10-help-text 2>/dev/null || true
        chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null || true
        chmod -x /etc/update-motd.d/80-esm 2>/dev/null || true
        chmod -x /etc/update-motd.d/95-hwe-eol 2>/dev/null || true
        
        log_info "Dynamic MOTD banner configured"
    fi
    
    wait_for_key
}

# Preview current banner
preview_banner() {
    echo
    echo -e "${YELLOW}Current SSH Banner:${NC}"
    if [ -f "/etc/ssh/mastermind_banner" ]; then
        cat /etc/ssh/mastermind_banner
    else
        echo "No SSH banner configured"
    fi
    
    echo
    echo -e "${YELLOW}Current MOTD:${NC}"
    if [ -f "/etc/update-motd.d/01-mastermind" ]; then
        /etc/update-motd.d/01-mastermind
    else
        echo "No custom MOTD configured"
    fi
    
    echo
    wait_for_key
}

# Remove banner
remove_banner() {
    if confirm "Remove all custom banners?"; then
        # Remove SSH banner
        if [ -f "/etc/ssh/mastermind_banner" ]; then
            rm -f /etc/ssh/mastermind_banner
            log_info "SSH banner file removed"
        fi
        
        # Remove banner setting from SSH config
        sed -i '/^Banner/d' /etc/ssh/sshd_config
        
        # Remove custom MOTD
        if [ -f "/etc/update-motd.d/01-mastermind" ]; then
            rm -f /etc/update-motd.d/01-mastermind
            log_info "Custom MOTD removed"
        fi
        
        # Re-enable default MOTD components
        chmod +x /etc/update-motd.d/10-help-text 2>/dev/null || true
        
        # Restart SSH service
        systemctl restart sshd
        
        log_info "All custom banners removed"
    fi
    
    wait_for_key
}

# Main function
main() {
    while true; do
        show_banner_menu
        read -p "Enter your choice [0-8]: " choice
        
        case $choice in
            1) create_ascii_banner ;;
            2) create_simple_banner ;;
            3) create_custom_banner ;;
            4) apply_templates ;;
            5) configure_ssh_banner_setting ;;
            6) configure_motd_banner ;;
            7) preview_banner ;;
            8) remove_banner ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
