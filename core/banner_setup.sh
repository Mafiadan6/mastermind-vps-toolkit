#!/bin/bash

# Mastermind VPS Toolkit - Banner Setup
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Setup SSH banner
setup_ssh_banner() {
    log_info "Setting up SSH banner..."
    
    local banner_text=${1:-"$BRAND_MESSAGE"}
    local server_name=${2:-"$SERVER_NAME"}
    
    # Create banner file
    cat > /etc/ssh/mastermind_banner << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║                           $banner_text                                       ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  Server: $server_name                                                        ║
║  IP: $(get_public_ip)                                                        ║
║  Time: $(date)                                                               ║
║                                                                              ║
║  Unauthorized access is prohibited and will be prosecuted.                  ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    
    # Update SSH configuration
    if ! grep -q "Banner /etc/ssh/mastermind_banner" /etc/ssh/sshd_config; then
        backup_file /etc/ssh/sshd_config
        echo "Banner /etc/ssh/mastermind_banner" >> /etc/ssh/sshd_config
        systemctl restart sshd
        log_info "SSH banner configured and SSH service restarted"
    else
        log_info "SSH banner already configured"
    fi
}

# Setup MOTD
setup_motd() {
    log_info "Setting up MOTD..."
    
    # Create dynamic MOTD
    cat > /etc/update-motd.d/01-mastermind << 'EOF'
#!/bin/bash

# Load configuration
source /opt/mastermind/core/config.cfg 2>/dev/null || true
source /opt/mastermind/core/helpers.sh 2>/dev/null || true

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
echo -e "  SSH Port: ${GREEN}$(grep -E '^Port|^#Port' /etc/ssh/sshd_config | tail -1 | awk '{print $2}' || echo '22')${NC}"

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
    
    # Remove default Ubuntu MOTD files
    chmod -x /etc/update-motd.d/10-help-text 2>/dev/null || true
    chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null || true
    chmod -x /etc/update-motd.d/80-esm 2>/dev/null || true
    chmod -x /etc/update-motd.d/95-hwe-eol 2>/dev/null || true
    
    log_info "MOTD configured"
}

# Setup login banner
setup_login_banner() {
    log_info "Setting up login banner..."
    
    cat > /etc/issue << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║                           MASTERMIND VPS TOOLKIT                             ║
║                                                                              ║
║  Server: \l                                                                  ║
║  Date: \d                                                                    ║
║  Time: \t                                                                    ║
║                                                                              ║
║  Unauthorized access is prohibited and will be prosecuted.                  ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF
    
    # Network login banner
    cp /etc/issue /etc/issue.net
    
    log_info "Login banner configured"
}

# Interactive banner customization
customize_banner() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             BANNER CUSTOMIZATION                             ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] Change Banner Message${NC}"
        echo -e "${YELLOW}  [2] Change Server Name${NC}"
        echo -e "${YELLOW}  [3] Preview SSH Banner${NC}"
        echo -e "${YELLOW}  [4] Preview MOTD${NC}"
        echo -e "${YELLOW}  [5] Reset to Default${NC}"
        echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) 
                echo
                local new_message
                new_message=$(get_input "Enter new banner message" "" "$BRAND_MESSAGE")
                if [ -n "$new_message" ]; then
                    sed -i "s/BRAND_MESSAGE=.*/BRAND_MESSAGE=\"$new_message\"/" /opt/mastermind/core/config.cfg
                    setup_ssh_banner "$new_message"
                    setup_motd
                    log_info "Banner message updated"
                fi
                wait_for_key
                ;;
            2)
                echo
                local new_server_name
                new_server_name=$(get_input "Enter new server name" "" "$SERVER_NAME")
                if [ -n "$new_server_name" ]; then
                    sed -i "s/SERVER_NAME=.*/SERVER_NAME=\"$new_server_name\"/" /opt/mastermind/core/config.cfg
                    setup_ssh_banner "$BRAND_MESSAGE" "$new_server_name"
                    setup_motd
                    log_info "Server name updated"
                fi
                wait_for_key
                ;;
            3)
                echo
                echo -e "${YELLOW}SSH Banner Preview:${NC}"
                echo
                cat /etc/ssh/mastermind_banner
                echo
                wait_for_key
                ;;
            4)
                echo
                echo -e "${YELLOW}MOTD Preview:${NC}"
                echo
                /etc/update-motd.d/01-mastermind
                echo
                wait_for_key
                ;;
            5)
                if confirm "Reset banner to default settings?"; then
                    setup_ssh_banner
                    setup_motd
                    setup_login_banner
                    log_info "Banner reset to default"
                fi
                wait_for_key
                ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Main function
main() {
    local action=${1:-"setup"}
    
    case $action in
        "setup")
            setup_ssh_banner
            setup_motd
            setup_login_banner
            log_info "All banners configured successfully"
            ;;
        "customize")
            customize_banner
            ;;
        "ssh")
            setup_ssh_banner
            ;;
        "motd")
            setup_motd
            ;;
        "login")
            setup_login_banner
            ;;
        *)
            echo "Usage: $0 {setup|customize|ssh|motd|login}"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
