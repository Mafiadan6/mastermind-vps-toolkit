#!/bin/bash

# Mastermind VPS Toolkit - Fixed Interactive Menu System
# Version: 4.0.0 - Clean Layout Design
# Fixed overlapping and layout issues

set -e

# Simple Color Definitions (no arrays to avoid conflicts)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BRIGHT_GREEN='\033[0;92m'
BRIGHT_CYAN='\033[0;96m'
BRIGHT_YELLOW='\033[0;93m'
RESET='\033[0m'

# Configuration
MASTERMIND_HOME="/opt/mastermind"
VERSION="4.0.0"

# Load configuration
if [ -f "$MASTERMIND_HOME/core/config.cfg" ]; then
    source "$MASTERMIND_HOME/core/config.cfg"
fi

# Load helper functions
if [ -f "$MASTERMIND_HOME/core/helpers.sh" ]; then
    source "$MASTERMIND_HOME/core/helpers.sh"
fi

# Terminal dimensions
get_terminal_width() {
    tput cols 2>/dev/null || echo 80
}

# Clear screen function
clear_screen() {
    clear
    echo
}

# Print centered text
print_centered() {
    local text="$1"
    local width=$(get_terminal_width)
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s\n" $padding "" "$text"
}

# Draw separator line
draw_separator() {
    local width=$(get_terminal_width)
    printf '%*s\n' "$width" '' | tr ' ' '='
}

# System information display
show_system_info() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d',' -f1 || echo "N/A")
    local memory_usage=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}' || echo "N/A")
    local disk_usage=$(df -h / | awk 'NR==2{printf "%s", $5}' || echo "N/A")
    local uptime=$(uptime -p 2>/dev/null | sed 's/up //' || echo "N/A")
    
    echo -e "${CYAN}System Status:${RESET}"
    echo -e "  CPU: ${cpu_usage}% | Memory: ${memory_usage}% | Disk: ${disk_usage} | Uptime: ${uptime}"
}

# Service status check
check_service_status() {
    local service="$1"
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${GREEN}●${RESET}"
    else
        echo -e "${RED}●${RESET}"
    fi
}

# Main header
show_header() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    draw_separator
    print_centered "MASTERMIND VPS TOOLKIT v${VERSION}"
    print_centered "Advanced VPS Management & Network Tools"
    echo -e "${RESET}"
    draw_separator
    echo
    show_system_info
    echo
}

# Main menu display
show_main_menu() {
    show_header
    
    echo -e "${BRIGHT_YELLOW}Main Menu:${RESET}"
    echo
    echo -e "${WHITE}  ${CYAN}[1]${RESET} User Administration      ${CYAN}[8]${RESET} System Monitoring"
    echo -e "${WHITE}  ${CYAN}[2]${RESET} Protocol Management      ${CYAN}[9]${RESET} Branding & QR Codes"
    echo -e "${WHITE}  ${CYAN}[3]${RESET} Network Optimization     ${CYAN}[10]${RESET} System Tools"
    echo -e "${WHITE}  ${CYAN}[4]${RESET} Security Center          ${CYAN}[11]${RESET} Advanced Settings"
    echo -e "${WHITE}  ${CYAN}[5]${RESET} V2Ray Management         ${CYAN}[12]${RESET} Documentation"
    echo -e "${WHITE}  ${CYAN}[6]${RESET} Domain & SSL             ${CYAN}[13]${RESET} Support & Info"
    echo -e "${WHITE}  ${CYAN}[7]${RESET} Backup & Restore        ${CYAN}[0]${RESET}  Exit"
    echo
    
    # Service status indicators
    echo -e "${YELLOW}Service Status:${RESET}"
    echo -e "  Python Proxy: $(check_service_status 'python-proxy')  V2Ray: $(check_service_status 'v2ray')  SSH: $(check_service_status 'ssh')  Nginx: $(check_service_status 'nginx')"
    echo
    
    draw_separator
    echo -n -e "${BRIGHT_GREEN}Select option [0-13]: ${RESET}"
}

# Submenu: User Administration
show_user_menu() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "USER ADMINISTRATION"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}User Management:${RESET}"
    echo
    echo -e "${WHITE}  ${CYAN}[1]${RESET} Add SSH User             ${CYAN}[6]${RESET} Password Management"
    echo -e "${WHITE}  ${CYAN}[2]${RESET} Remove User              ${CYAN}[7]${RESET} SSH Key Management"
    echo -e "${WHITE}  ${CYAN}[3]${RESET} Modify User              ${CYAN}[8]${RESET} User Activity Monitor"
    echo -e "${WHITE}  ${CYAN}[4]${RESET} List Users               ${CYAN}[9]${RESET} Usage Limits"
    echo -e "${WHITE}  ${CYAN}[5]${RESET} User Permissions         ${CYAN}[0]${RESET} Back to Main Menu"
    echo
    draw_separator
    echo -n -e "${BRIGHT_GREEN}Select option [0-9]: ${RESET}"
}

# Submenu: Protocol Management
show_protocol_menu() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "PROTOCOL MANAGEMENT"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}Available Protocols:${RESET}"
    echo
    echo -e "${WHITE}  ${CYAN}[1]${RESET} Python Proxy Suite       ${CYAN}[6]${RESET} Dropbear SSH"
    echo -e "${WHITE}  ${CYAN}[2]${RESET} V2Ray Configuration      ${CYAN}[7]${RESET} BadVPN Setup"
    echo -e "${WHITE}  ${CYAN}[3]${RESET} Squid Proxy              ${CYAN}[8]${RESET} TCP Bypass"
    echo -e "${WHITE}  ${CYAN}[4]${RESET} SSH TLS                  ${CYAN}[9]${RESET} Service Manager"
    echo -e "${WHITE}  ${CYAN}[5]${RESET} OpenVPN                  ${CYAN}[0]${RESET} Back to Main Menu"
    echo
    draw_separator
    echo -n -e "${BRIGHT_GREEN}Select option [0-9]: ${RESET}"
}

# Submenu: Network Optimization
show_network_menu() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "NETWORK OPTIMIZATION"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}Optimization Tools:${RESET}"
    echo
    echo -e "${WHITE}  ${CYAN}[1]${RESET} BBR Congestion Control   ${CYAN}[5]${RESET} Network Diagnostics"
    echo -e "${WHITE}  ${CYAN}[2]${RESET} Kernel Tuning           ${CYAN}[6]${RESET} Bandwidth Monitor"
    echo -e "${WHITE}  ${CYAN}[3]${RESET} UDP Optimization         ${CYAN}[7]${RESET} Connection Limits"
    echo -e "${WHITE}  ${CYAN}[4]${RESET} TCP Optimization         ${CYAN}[0]${RESET} Back to Main Menu"
    echo
    draw_separator
    echo -n -e "${BRIGHT_GREEN}Select option [0-7]: ${RESET}"
}

# Submenu: Security Center
show_security_menu() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "SECURITY CENTER"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}Security Tools:${RESET}"
    echo
    echo -e "${WHITE}  ${CYAN}[1]${RESET} Firewall Management      ${CYAN}[6]${RESET} Security Audit"
    echo -e "${WHITE}  ${CYAN}[2]${RESET} Fail2Ban Setup           ${CYAN}[7]${RESET} Port Scanner"
    echo -e "${WHITE}  ${CYAN}[3]${RESET} SSH Hardening            ${CYAN}[8]${RESET} Intrusion Detection"
    echo -e "${WHITE}  ${CYAN}[4]${RESET} SSL/TLS Certificates     ${CYAN}[9]${RESET} Log Analysis"
    echo -e "${WHITE}  ${CYAN}[5]${RESET} Access Control           ${CYAN}[0]${RESET} Back to Main Menu"
    echo
    draw_separator
    echo -n -e "${BRIGHT_GREEN}Select option [0-9]: ${RESET}"
}

# Menu handlers
handle_user_menu() {
    while true; do
        show_user_menu
        read -r choice
        case $choice in
            1) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" add_user
                else
                    echo "User manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" remove_user
                else
                    echo "User manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" modify_user
                else
                    echo "User manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" list_users
                else
                    echo "User manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            5) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" permissions
                else
                    echo "User manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            6) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" password_mgmt
                else
                    echo "User manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" ssh_keys
                else
                    echo "User manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            8) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" activity_monitor
                else
                    echo "User manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            9) 
                if [ -f "$MASTERMIND_HOME/users/usage_limits.py" ]; then
                    python3 "$MASTERMIND_HOME/users/usage_limits.py" get_report
                    read -p "Press Enter to continue..."
                else
                    echo "Usage limits system not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            0) return ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

handle_protocol_menu() {
    while true; do
        show_protocol_menu
        read -r choice
        case $choice in
            1) 
                if [ -f "$MASTERMIND_HOME/protocols/proxy_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/protocols/proxy_manager.sh"
                else
                    echo "Proxy manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2) 
                if [ -f "$MASTERMIND_HOME/protocols/v2ray_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/protocols/v2ray_manager.sh"
                else
                    echo "V2Ray manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3) 
                if [ -f "$MASTERMIND_HOME/protocols/squid_proxy.sh" ]; then
                    bash "$MASTERMIND_HOME/protocols/squid_proxy.sh"
                else
                    echo "Squid proxy not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4) 
                if [ -f "$MASTERMIND_HOME/protocols/ssh_suite.sh" ]; then
                    bash "$MASTERMIND_HOME/protocols/ssh_suite.sh"
                else
                    echo "SSH suite not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            5) 
                echo "OpenVPN setup coming soon..."
                read -p "Press Enter to continue..."
                ;;
            6) 
                echo "Dropbear SSH setup coming soon..."
                read -p "Press Enter to continue..."
                ;;
            7) 
                if [ -f "$MASTERMIND_HOME/protocols/badvpn_setup.sh" ]; then
                    bash "$MASTERMIND_HOME/protocols/badvpn_setup.sh"
                else
                    echo "BadVPN setup not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            8) 
                if [ -f "$MASTERMIND_HOME/protocols/tcp_bypass.sh" ]; then
                    bash "$MASTERMIND_HOME/protocols/tcp_bypass.sh"
                else
                    echo "TCP bypass not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            9) 
                if [ -f "$MASTERMIND_HOME/core/service_ctl.sh" ]; then
                    bash "$MASTERMIND_HOME/core/service_ctl.sh"
                else
                    echo "Service manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            0) return ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

handle_network_menu() {
    while true; do
        show_network_menu
        read -r choice
        case $choice in
            1) 
                if [ -f "$MASTERMIND_HOME/network/bbr.sh" ]; then
                    bash "$MASTERMIND_HOME/network/bbr.sh"
                else
                    echo "BBR script not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2) 
                if [ -f "$MASTERMIND_HOME/network/kernel_tuning.sh" ]; then
                    bash "$MASTERMIND_HOME/network/kernel_tuning.sh"
                else
                    echo "Kernel tuning script not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3) 
                if [ -f "$MASTERMIND_HOME/network/udp_optimizer.sh" ]; then
                    bash "$MASTERMIND_HOME/network/udp_optimizer.sh"
                else
                    echo "UDP optimizer not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4) echo "TCP optimization coming soon..." && read -p "Press Enter to continue..." ;;
            5) echo "Network diagnostics coming soon..." && read -p "Press Enter to continue..." ;;
            6) echo "Bandwidth monitor coming soon..." && read -p "Press Enter to continue..." ;;
            7) echo "Connection limits coming soon..." && read -p "Press Enter to continue..." ;;
            0) return ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

handle_security_menu() {
    while true; do
        show_security_menu
        read -r choice
        case $choice in
            1) 
                if [ -f "$MASTERMIND_HOME/security/firewall_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/security/firewall_manager.sh"
                else
                    echo "Firewall manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2) 
                if [ -f "$MASTERMIND_HOME/security/fail2ban_setup.sh" ]; then
                    bash "$MASTERMIND_HOME/security/fail2ban_setup.sh"
                else
                    echo "Fail2ban setup not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3) echo "SSH hardening coming soon..." && read -p "Press Enter to continue..." ;;
            4) echo "SSL/TLS certificates coming soon..." && read -p "Press Enter to continue..." ;;
            5) echo "Access control coming soon..." && read -p "Press Enter to continue..." ;;
            6) 
                if [ -f "$MASTERMIND_HOME/security/audit_tool.sh" ]; then
                    bash "$MASTERMIND_HOME/security/audit_tool.sh"
                else
                    echo "Security audit tool not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7) echo "Port scanner coming soon..." && read -p "Press Enter to continue..." ;;
            8) echo "Intrusion detection coming soon..." && read -p "Press Enter to continue..." ;;
            9) echo "Log analysis coming soon..." && read -p "Press Enter to continue..." ;;
            0) return ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

# Main program loop
main() {
    while true; do
        show_main_menu
        read -r choice
        
        case $choice in
            1) handle_user_menu ;;
            2) handle_protocol_menu ;;
            3) handle_network_menu ;;
            4) handle_security_menu ;;
            5) 
                if [ -f "$MASTERMIND_HOME/protocols/v2ray_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/protocols/v2ray_manager.sh"
                else
                    echo "V2Ray manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            6) 
                if [ -f "$MASTERMIND_HOME/protocols/domain_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/protocols/domain_manager.sh"
                else
                    echo "Domain manager not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7) echo "Backup & restore coming soon..." && read -p "Press Enter to continue..." ;;
            8) echo "System monitoring coming soon..." && read -p "Press Enter to continue..." ;;
            9) 
                if [ -f "$MASTERMIND_HOME/branding/qr_generator.py" ]; then
                    python3 "$MASTERMIND_HOME/branding/qr_generator.py"
                    read -p "Press Enter to continue..."
                else
                    echo "QR generator not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            10) echo "System tools coming soon..." && read -p "Press Enter to continue..." ;;
            11) echo "Advanced settings coming soon..." && read -p "Press Enter to continue..." ;;
            12) 
                if [ -f "$MASTERMIND_HOME/README.md" ]; then
                    cat "$MASTERMIND_HOME/README.md" | less
                else
                    echo "Documentation not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            13) 
                clear_screen
                echo -e "${BRIGHT_CYAN}"
                print_centered "MASTERMIND VPS TOOLKIT SUPPORT"
                echo -e "${RESET}"
                draw_separator
                echo
                echo -e "${YELLOW}Support Information:${RESET}"
                echo -e "  Version: ${VERSION}"
                echo -e "  GitHub: https://github.com/Mafiadan6/mastermind-vps-toolkit"
                echo -e "  Contact: @bitcockli on Telegram"
                echo
                echo -e "${YELLOW}System Information:${RESET}"
                echo -e "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -o)"
                echo -e "  Kernel: $(uname -r)"
                echo -e "  Architecture: $(uname -m)"
                echo
                read -p "Press Enter to continue..."
                ;;
            0) 
                clear_screen
                echo -e "${BRIGHT_GREEN}"
                print_centered "Thank you for using Mastermind VPS Toolkit!"
                echo -e "${RESET}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid option. Please select 0-13.${RESET}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Handle script arguments
if [ $# -gt 0 ]; then
    case "$1" in
        "user_admin") handle_user_menu ;;
        "protocols") handle_protocol_menu ;;
        "network") handle_network_menu ;;
        "security") handle_security_menu ;;
        *) main ;;
    esac
else
    main
fi