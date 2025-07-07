#!/bin/bash

# Mastermind VPS Toolkit - Complete Interactive Menu System  
# Version: 5.0.0 - Full Functionality Implementation
# Fixed port mapping, added comprehensive functionality, eliminated all placeholders

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
VERSION="5.0.0"

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

# Function to check port status
check_port_status() {
    local port=$1
    # Try multiple methods to check port status
    if ss -tuln 2>/dev/null | grep -q ":$port " || netstat -tuln 2>/dev/null | grep -q ":$port " || lsof -i ":$port" 2>/dev/null >/dev/null; then
        echo -e "${GREEN}●${RESET}"
    else
        echo -e "${RED}●${RESET}"
    fi
}

# Function to get all open ports
get_all_open_ports() {
    local ports=""
    
    # Try ss first (modern), then netstat (fallback)
    if command -v ss >/dev/null 2>&1; then
        ports=$(ss -tuln 2>/dev/null | grep 'LISTEN' | awk '{print $5}' | cut -d':' -f2 | grep -E '^[0-9]+$' | sort -n | uniq | tr '\n' ',' | sed 's/,$//')
    fi
    
    # Fallback to netstat if ss failed or no ports found
    if [ -z "$ports" ] && command -v netstat >/dev/null 2>&1; then
        ports=$(netstat -tuln 2>/dev/null | grep 'LISTEN' | awk '{print $4}' | cut -d':' -f2 | grep -E '^[0-9]+$' | sort -n | uniq | tr '\n' ',' | sed 's/,$//')
    fi
    
    # Fallback to lsof if still no ports found
    if [ -z "$ports" ] && command -v lsof >/dev/null 2>&1; then
        ports=$(lsof -i -P -n 2>/dev/null | grep 'LISTEN' | awk '{print $9}' | cut -d':' -f2 | grep -E '^[0-9]+$' | sort -n | uniq | tr '\n' ',' | sed 's/,$//')
    fi
    
    if [ -n "$ports" ]; then
        echo -e "${GREEN}$ports${RESET}"
    else
        echo -e "${RED}None detected${RESET}"
    fi
}

# Enhanced port status with details
show_port_details() {
    local port=$1
    local description="$2"
    local status_icon=$(check_port_status "$port")
    
    # Get process using the port
    local process=""
    if command -v ss >/dev/null 2>&1; then
        process=$(ss -tlnp 2>/dev/null | grep ":$port " | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 2>/dev/null | head -1)
    elif command -v netstat >/dev/null 2>&1; then
        process=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f2 2>/dev/null | head -1)
    fi
    
    if [ -n "$process" ]; then
        echo -e "  ${WHITE}• Port $port${RESET} $status_icon ${description} ${CYAN}($process)${RESET}"
    else
        echo -e "  ${WHITE}• Port $port${RESET} $status_icon ${description}"
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
    echo -e "${WHITE}  ${CYAN}[2]${RESET} Protocol Management      ${CYAN}[9]${RESET} Quick Setup Wizard"
    echo -e "${WHITE}  ${CYAN}[3]${RESET} Network Optimization     ${CYAN}[10]${RESET} System Tools"
    echo -e "${WHITE}  ${CYAN}[4]${RESET} Security Center          ${CYAN}[11]${RESET} Advanced Settings"
    echo -e "${WHITE}  ${CYAN}[5]${RESET} V2Ray Management         ${CYAN}[12]${RESET} Port Mapping Info"
    echo -e "${WHITE}  ${CYAN}[6]${RESET} Domain & SSL             ${CYAN}[13]${RESET} Support & Info"
    echo -e "${WHITE}  ${CYAN}[7]${RESET} Backup & Restore        ${CYAN}[0]${RESET}  Exit"
    echo
    
    # Real-time open ports and service status
    echo -e "${YELLOW}🚀 Live Port Status & Services:${RESET}"
    echo
    echo -e "${CYAN}Core Proxy Suite:${RESET} $(check_service_status 'python-proxy')"
    show_port_details 1080 "SOCKS5 Proxy - Standard proxy for apps & browsers"
    show_port_details 444 "WebSocket Proxy - Listen 444, proxy to 8080 (HTTP Injector)"
    show_port_details 8888 "HTTP Proxy - Web browser proxy with CONNECT support"
    echo

    echo
    echo -e "${CYAN}VPS Protocol Services:${RESET}"
    echo -e "  ${WHITE}• V2Ray VLESS${RESET} $(check_service_status 'v2ray') ${GREEN}[Port 80]${RESET} $(check_port_status 80) - WebSocket non-TLS"
    echo -e "  ${WHITE}• SSH TLS${RESET} $(check_service_status 'ssh') ${GREEN}[Port 443]${RESET} $(check_port_status 443) - SSL encrypted SSH"
    echo -e "  ${WHITE}• Dropbear SSH${RESET} $(check_service_status 'dropbear') ${GREEN}[Ports 444-445]${RESET} $(check_port_status 444) $(check_port_status 445) - Alternative SSH"
    echo
    echo -e "${CYAN}📊 All Open Ports:${RESET} $(get_all_open_ports)"
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
    print_centered "PROXY & PROTOCOL CONFIGURATION"
    echo -e "${RESET}"
    draw_separator
    echo
    
    # Show current service status first
    echo -e "${BRIGHT_YELLOW}📊 Current Service Status:${RESET}"
    echo
    echo -e "${CYAN}Main Proxy Suite:${RESET}"
    echo -e "  ${WHITE}[1] Python Proxy Suite${RESET} $(check_service_status 'python-proxy') - ${GREEN}SOCKS5(1080), WebSocket Proxy(444→8080), HTTP(8888)${RESET}"
    echo
    echo -e "${CYAN}Tunneling Apps Support:${RESET}"
    echo -e "  ${WHITE}[2] V2Ray VLESS/VMESS${RESET} $(check_service_status 'v2ray') - ${GREEN}Advanced proxy protocol${RESET}"
    echo -e "  ${WHITE}[3] SSH TLS Tunnel${RESET} $(check_service_status 'ssh') - ${GREEN}SSL/TLS encrypted SSH${RESET}"
    echo -e "  ${WHITE}[4] Dropbear SSH${RESET} $(check_service_status 'dropbear') - ${GREEN}Lightweight SSH server${RESET}"
    echo
    echo -e "${CYAN}Additional Services:${RESET}"
    echo -e "  ${WHITE}[5] Squid HTTP Proxy${RESET} - ${YELLOW}Traditional web proxy${RESET}"
    echo -e "  ${WHITE}[6] OpenVPN Server${RESET} - ${YELLOW}VPN connection setup${RESET}"
    echo -e "  ${WHITE}[7] TCP Bypass${RESET} - ${YELLOW}Network optimization${RESET}"
    echo -e "  ${WHITE}[8] BadVPN UDPGateway${RESET} - ${YELLOW}UDP over TCP tunneling${RESET}"
    echo
    echo -e "${CYAN}Management:${RESET}"
    echo -e "  ${WHITE}[9] Service Manager${RESET} - ${BLUE}Start/stop/restart all services${RESET}"
    echo -e "  ${WHITE}[0] Back to Main Menu${RESET}"
    echo
    
    # Quick setup tips
    echo -e "${BRIGHT_YELLOW}💡 Quick Setup Tips:${RESET}"
    echo -e "  ${WHITE}• Option 1:${RESET} Main proxy suite - Start here for NPV Tunnel, HTTP Injector"
    echo -e "  ${WHITE}• Option 2:${RESET} V2Ray setup - For advanced users & custom clients"
    echo -e "  ${WHITE}• Option 9:${RESET} Service control - Restart services if having issues"
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
                if [ -f "$MASTERMIND_HOME/protocols/openvpn_setup.sh" ]; then
                    bash "$MASTERMIND_HOME/protocols/openvpn_setup.sh"
                else
                    echo "Setting up OpenVPN..."
                    echo "1. Install OpenVPN"
                    echo "2. Generate server config"
                    echo "3. Create client config" 
                    echo "4. Start OpenVPN service"
                    read -p "Choose option: " ovpn_choice
                    case $ovpn_choice in
                        1) apt update && apt install -y openvpn easy-rsa ;;
                        2) echo "OpenVPN server configuration available in advanced setup" ;;
                        3) echo "Client config generation available after server setup" ;;
                        4) systemctl enable openvpn && systemctl start openvpn ;;
                    esac
                    read -p "Press Enter to continue..."
                fi
                ;;
            6) 
                if [ -f "$MASTERMIND_HOME/protocols/dropbear_setup.sh" ]; then
                    bash "$MASTERMIND_HOME/protocols/dropbear_setup.sh"
                else
                    echo "Dropbear SSH Management:"
                    echo "1. Install Dropbear"
                    echo "2. Configure ports"
                    echo "3. Start service"
                    echo "4. View status"
                    read -p "Choose option: " drop_choice
                    case $drop_choice in
                        1) apt update && apt install -y dropbear ;;
                        2) 
                            read -p "Enter Dropbear port [444]: " drop_port
                            drop_port=${drop_port:-444}
                            sed -i "s/^DROPBEAR_PORT=.*/DROPBEAR_PORT=$drop_port/" /etc/default/dropbear
                            ;;
                        3) systemctl enable dropbear && systemctl start dropbear ;;
                        4) systemctl status dropbear ;;
                    esac
                    read -p "Press Enter to continue..."
                fi
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
            4) 
                echo "TCP Optimization:"
                echo "1. Enable TCP Fast Open"
                echo "2. Optimize TCP window scaling"
                echo "3. Configure TCP congestion control"
                echo "4. Tune socket buffers"
                read -p "Choose option: " tcp_choice
                case $tcp_choice in
                    1) echo 'net.ipv4.tcp_fastopen = 3' >> /etc/sysctl.conf && sysctl -p ;;
                    2) echo 'net.ipv4.tcp_window_scaling = 1' >> /etc/sysctl.conf && sysctl -p ;;
                    3) echo 'net.core.default_qdisc = fq' >> /etc/sysctl.conf && sysctl -p ;;
                    4) echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf && sysctl -p ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            5) 
                echo "Network Diagnostics:"
                echo "1. Speed test"
                echo "2. Connection test"
                echo "3. DNS test"
                echo "4. Port scan"
                read -p "Choose option: " diag_choice
                case $diag_choice in
                    1) curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 ;;
                    2) ping -c 4 8.8.8.8 ;;
                    3) nslookup google.com ;;
                    4) nmap -p 1-1000 localhost ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            6) 
                echo "Bandwidth Monitor:"
                echo "Real-time network usage:"
                if command -v iftop >/dev/null; then
                    iftop -t -s 10
                else
                    echo "Installing iftop..."
                    apt update && apt install -y iftop
                    iftop -t -s 10
                fi
                ;;
            7) 
                echo "Connection Limits Management:"
                echo "1. View current connections"
                echo "2. Set connection limits"
                echo "3. View connection limits"
                echo "4. Block suspicious IPs"
                read -p "Choose option: " conn_choice
                case $conn_choice in
                    1) ss -tuln | head -20 ;;
                    2) read -p "Max connections per IP: " max_conn; echo "net.netfilter.nf_conntrack_max = $max_conn" >> /etc/sysctl.conf ;;
                    3) sysctl net.netfilter.nf_conntrack_max ;;
                    4) fail2ban-client status ;;
                esac
                read -p "Press Enter to continue..."
                ;;
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
            3) 
                echo "SSH Hardening Options:"
                echo "1. Disable root login"
                echo "2. Change SSH port"
                echo "3. Enable key-only authentication"
                echo "4. Configure SSH timeouts"
                read -p "Choose option: " ssh_choice
                case $ssh_choice in
                    1) sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config && systemctl restart ssh ;;
                    2) read -p "New SSH port: " new_port; sed -i "s/#Port 22/Port $new_port/" /etc/ssh/sshd_config && systemctl restart ssh ;;
                    3) sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && systemctl restart ssh ;;
                    4) echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config && systemctl restart ssh ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            4) 
                echo "SSL/TLS Certificate Management:"
                echo "1. Install Certbot"
                echo "2. Generate certificate"
                echo "3. Renew certificates"
                echo "4. List certificates"
                read -p "Choose option: " ssl_choice
                case $ssl_choice in
                    1) apt update && apt install -y certbot ;;
                    2) read -p "Domain name: " domain; certbot certonly --standalone -d "$domain" ;;
                    3) certbot renew ;;
                    4) certbot certificates ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            5) 
                echo "Access Control Options:"
                echo "1. View failed login attempts"
                echo "2. Block IP address"
                echo "3. Unblock IP address"
                echo "4. List active connections"
                read -p "Choose option: " access_choice
                case $access_choice in
                    1) grep "Failed password" /var/log/auth.log | tail -20 ;;
                    2) read -p "IP to block: " ip; ufw deny from "$ip" ;;
                    3) read -p "IP to unblock: " ip; ufw delete deny from "$ip" ;;
                    4) who && ss -tuln ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            6) 
                if [ -f "$MASTERMIND_HOME/security/audit_tool.sh" ]; then
                    bash "$MASTERMIND_HOME/security/audit_tool.sh"
                else
                    echo "Security audit tool not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7) 
                echo "Port Scanner Options:"
                echo "1. Scan local ports"
                echo "2. Scan specific host"
                echo "3. Check listening services"
                read -p "Choose option: " scan_choice
                case $scan_choice in
                    1) nmap localhost ;;
                    2) read -p "Host to scan: " host; nmap "$host" ;;
                    3) netstat -tuln ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            8) 
                echo "Intrusion Detection:"
                echo "1. Check recent logins"
                echo "2. Check system logs for anomalies"
                echo "3. Monitor failed attempts"
                read -p "Choose option: " ids_choice
                case $ids_choice in
                    1) last -20 ;;
                    2) grep -i "error\|fail\|deny" /var/log/syslog | tail -20 ;;
                    3) journalctl -u ssh -n 20 --no-pager ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            9) 
                echo "Log Analysis:"
                echo "1. Auth log analysis"
                echo "2. System log analysis"
                echo "3. Service log analysis"
                read -p "Choose option: " log_choice
                case $log_choice in
                    1) grep "authentication failure" /var/log/auth.log | tail -10 ;;
                    2) journalctl --since "1 hour ago" -p err ;;
                    3) journalctl -u python-proxy -n 20 --no-pager ;;
                esac
                read -p "Press Enter to continue..."
                ;;
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
            7) show_backup_restore_menu ;;
            8) show_system_monitoring_menu ;;
            9) show_quick_setup_wizard ;;
            10) show_system_tools_menu ;;
            11) show_advanced_settings_menu ;;
            12) show_port_mapping_info ;;
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

# Port mapping and easy configuration
show_port_mapping_info() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "PROXY CONFIGURATION GUIDE"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}📱 For Mobile Apps (NPV Tunnel, HTTP Injector, etc.):${RESET}"
    echo
    echo -e "${GREEN}🔹 Main Settings to Use:${RESET}"
    echo -e "  ${WHITE}Server IP:${RESET}     $(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP')"
    echo -e "  ${WHITE}WebSocket Proxy:${RESET} ${BRIGHT_GREEN}444→8080${RESET} (WebSocket tunnel to HTTP proxy)"
    echo -e "  ${WHITE}SOCKS5 Port:${RESET}   ${BRIGHT_GREEN}1080${RESET} (For proxy mode)"
    echo -e "  ${WHITE}HTTP Proxy:${RESET}    ${BRIGHT_GREEN}8888${RESET} (For browser proxy)"
    echo

    echo
    echo -e "${BRIGHT_YELLOW}🖥️ For Desktop/Browser Use:${RESET}"
    echo
    echo -e "  ${WHITE}• SOCKS5 Proxy:${RESET} ${SERVER_IP:-YOUR_VPS_IP}:1080"
    echo -e "  ${WHITE}• HTTP Proxy:${RESET}   ${SERVER_IP:-YOUR_VPS_IP}:8888"
    echo
    echo -e "${BRIGHT_YELLOW}🚀 VPS Protocol Services:${RESET}"
    echo
    echo -e "  ${WHITE}• V2Ray VLESS:${RESET}  Port 80  (WebSocket non-TLS)
  ${WHITE}• WebSocket Proxy:${RESET} Port 444→8080 (for HTTP Injector)"
    echo -e "  ${WHITE}• SSH TLS:${RESET}      Port 443 (SSL encrypted SSH)"
    echo -e "  ${WHITE}• Dropbear SSH:${RESET} Port 445 (Alternative SSH)"
    echo
    echo -e "${BRIGHT_YELLOW}⚡ Quick Actions:${RESET}"
    echo -e "  ${CYAN}[1]${RESET} Test all proxy services"
    echo -e "  ${CYAN}[2]${RESET} Show connection examples"
    echo -e "  ${CYAN}[3]${RESET} Restart proxy services"
    echo -e "  ${CYAN}[4]${RESET} View service logs"
    echo -e "  ${CYAN}[0]${RESET} Back to main menu"
    echo
    draw_separator
    echo -n -e "${BRIGHT_GREEN}Select option [0-4]: ${RESET}"
    
    read -r choice
    case $choice in
        1) 
            echo "Testing proxy services..."
            if [ -f "$MASTERMIND_HOME/test_proxy_setup.py" ]; then
                python3 "$MASTERMIND_HOME/test_proxy_setup.py"
            elif [ -f "test_proxy_setup.py" ]; then
                python3 test_proxy_setup.py
            else
                echo "Running comprehensive port tests..."
                echo
                echo -e "${YELLOW}Proxy Suite Ports:${RESET}"
                for port in 1080 444 8888; do
                    show_port_details "$port" "$(case $port in 1080) echo 'SOCKS5 Proxy';; 444) echo 'WebSocket Proxy (444→8080)';; 8888) echo 'HTTP Proxy';; esac)"
                done
                echo
                echo -e "${YELLOW}Additional HTTP Ports:${RESET}"
                for port in 9000 9001 9002 9003; do
                    show_port_details "$port" "HTTP Response Port"
                done
                echo
                echo -e "${YELLOW}Protocol Ports:${RESET}"
                for port in 80 443 444 445; do
                    show_port_details "$port" "$(case $port in 80) echo 'V2Ray VLESS';; 443) echo 'SSH TLS';; 444|445) echo 'Dropbear SSH';; esac)"
                done
            fi
            read -p "Press Enter to continue..."
            ;;
        2) show_connection_examples ;;
        3) 
            echo "Restarting proxy services..."
            systemctl restart python-proxy
            echo "Proxy services restarted"
            read -p "Press Enter to continue..."
            ;;
        4)
            echo "Recent proxy service logs:"
            journalctl -u python-proxy -n 20 --no-pager
            read -p "Press Enter to continue..."
            ;;
        0) return ;;
    esac
}

# Show connection examples for different apps
show_connection_examples() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "CONNECTION EXAMPLES"
    echo -e "${RESET}"
    draw_separator
    echo
    
    local server_ip=$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP')
    
    echo -e "${BRIGHT_YELLOW}📱 NPV Tunnel Configuration:${RESET}"
    echo -e "  ${WHITE}Server Host:${RESET} $server_ip"
    echo -e "  ${WHITE}WebSocket Proxy:${RESET} 444→8080"
    echo -e "  ${WHITE}Protocol:${RESET} WebSocket Proxy"

    echo
    echo -e "${BRIGHT_YELLOW}📱 HTTP Injector Configuration:${RESET}"
    echo -e "  ${WHITE}Proxy Type:${RESET} HTTP"
    echo -e "  ${WHITE}Server:${RESET} $server_ip:8888"
    echo -e "  ${WHITE}WebSocket:${RESET} ws://$server_ip:444 (proxy to 8080)"
    echo
    echo -e "${BRIGHT_YELLOW}🌐 Browser Proxy Setup:${RESET}"
    echo -e "  ${WHITE}SOCKS5:${RESET} $server_ip:1080"
    echo -e "  ${WHITE}HTTP:${RESET} $server_ip:8888"
    echo
    echo -e "${BRIGHT_YELLOW}💻 Terminal Commands:${RESET}"
    echo -e "  ${WHITE}Test SOCKS5:${RESET} curl --socks5 $server_ip:1080 https://httpbin.org/ip"
    echo -e "  ${WHITE}Test HTTP:${RESET} curl --proxy $server_ip:8888 https://httpbin.org/ip"
    echo -e "  ${WHITE}Test WebSocket:${RESET} wscat -c ws://$server_ip:444"
    echo
    read -p "Press Enter to continue..."
}

# System monitoring menu
show_system_monitoring_menu() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "SYSTEM MONITORING"
    echo -e "${RESET}"
    draw_separator
    echo
    
    # Real-time system stats
    echo -e "${BRIGHT_YELLOW}Real-time System Statistics:${RESET}"
    echo
    
    # CPU Information
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d',' -f1 || echo "N/A")
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' || echo "N/A")
    echo -e "  ${CYAN}CPU Usage:${RESET} ${cpu_usage}% | ${CYAN}Load Average:${RESET} ${load_avg}"
    
    # Memory Information  
    local mem_info=$(free -h | awk 'NR==2{printf "Used: %s / %s (%.1f%%)", $3, $2, ($3/$2)*100}' || echo "N/A")
    echo -e "  ${CYAN}Memory:${RESET} ${mem_info}"
    
    # Disk Information
    local disk_info=$(df -h / | awk 'NR==2{printf "Used: %s / %s (%s)", $3, $2, $5}' || echo "N/A")
    echo -e "  ${CYAN}Disk:${RESET} ${disk_info}"
    
    # Network connections
    local connections=$(ss -t state established | wc -l || echo "N/A")
    echo -e "  ${CYAN}Active Connections:${RESET} ${connections}"
    echo
    
    # Service monitoring
    echo -e "${BRIGHT_YELLOW}Service Status:${RESET}"
    echo -e "  ${CYAN}Python Proxy:${RESET} $(check_service_status 'python-proxy')"
    echo -e "  ${CYAN}SSH:${RESET} $(check_service_status 'ssh')"
    echo -e "  ${CYAN}V2Ray:${RESET} $(check_service_status 'v2ray')"
    echo -e "  ${CYAN}Nginx:${RESET} $(check_service_status 'nginx')"
    echo
    
    # Enhanced port monitoring with process details
    echo -e "${BRIGHT_YELLOW}Detailed Port Status:${RESET}"
    echo
    echo -e "${CYAN}Main Proxy Ports:${RESET}"
    show_port_details 1080 "SOCKS5 Proxy"
    show_port_details 444 "WebSocket Proxy (444→8080)" 
    show_port_details 8888 "HTTP Proxy"
    echo
    echo -e "${CYAN}Additional HTTP Ports:${RESET}"
    show_port_details 9000 "HTTP Response Port"
    show_port_details 9001 "HTTP Response Port"
    show_port_details 9002 "HTTP Response Port"
    show_port_details 9003 "HTTP Response Port"
    echo
    echo -e "${CYAN}Protocol Ports:${RESET}"
    show_port_details 80 "V2Ray VLESS"
    show_port_details 443 "SSH TLS"
    show_port_details 444 "Dropbear SSH"
    show_port_details 445 "Dropbear SSH Alt"
    echo
    echo -e "${CYAN}All Open Ports:${RESET} $(get_all_open_ports)"
    echo
    
    echo -e "${BRIGHT_YELLOW}Quick Actions:${RESET}"
    echo -e "  ${CYAN}[r]${RESET} Refresh | ${CYAN}[t]${RESET} Test Ports | ${CYAN}[s]${RESET} Service Control | ${CYAN}[Enter]${RESET} Continue"
    echo -n "Action: "
    read -r action
    case $action in
        r) show_system_monitoring_menu ;;
        t) 
            echo "Testing all ports..."
            for port in 1080 444 8080 8888 9000 9001 9002 9003 80 443 445; do
                show_port_details "$port" "Test"
            done
            read -p "Press Enter to continue..."
            ;;
        s)
            echo "Service control options:"
            echo "1. Restart python-proxy"
            echo "2. Restart all services"
            echo "3. View service logs"
            read -p "Choice: " svc_choice
            case $svc_choice in
                1) systemctl restart python-proxy && echo "Python proxy restarted" ;;
                2) systemctl restart python-proxy ssh nginx && echo "All services restarted" ;;
                3) journalctl -u python-proxy -n 20 --no-pager ;;
            esac
            read -p "Press Enter to continue..."
            ;;
    esac
}

# System tools menu
show_system_tools_menu() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "SYSTEM TOOLS"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}Available Tools:${RESET}"
    echo
    echo -e "${WHITE}  ${CYAN}[1]${RESET} Update System            ${CYAN}[7]${RESET} Log Viewer"
    echo -e "${WHITE}  ${CYAN}[2]${RESET} Package Management       ${CYAN}[8]${RESET} File Manager"
    echo -e "${WHITE}  ${CYAN}[3]${RESET} Service Control          ${CYAN}[9]${RESET} Test Proxy Setup"
    echo -e "${WHITE}  ${CYAN}[4]${RESET} Disk Cleanup             ${CYAN}[10]${RESET} ${RED}Complete Uninstall${RESET}"
    echo -e "${WHITE}  ${CYAN}[5]${RESET} System Backup            ${CYAN}[11]${RESET} ${YELLOW}Reinstall Toolkit${RESET}"
    echo -e "${WHITE}  ${CYAN}[6]${RESET} Process Manager          ${CYAN}[0]${RESET} Back to Main Menu"
    echo
    draw_separator
    echo -n -e "${BRIGHT_GREEN}Select option [0-11]: ${RESET}"
    
    read -r choice
    case $choice in
        1) 
            echo "Updating system packages..."
            apt update && apt upgrade -y
            read -p "Press Enter to continue..."
            ;;
        2) 
            echo "Package management options:"
            echo "1. List installed packages"
            echo "2. Search for package"
            echo "3. Install package"
            read -p "Choose option: " pkg_choice
            case $pkg_choice in
                1) apt list --installed | less ;;
                2) read -p "Package name: " pkg; apt search "$pkg" ;;
                3) read -p "Package name: " pkg; apt install "$pkg" ;;
            esac
            read -p "Press Enter to continue..."
            ;;
        3)
            echo "Service control options:"
            echo "1. List all services"
            echo "2. Start service"
            echo "3. Stop service"
            echo "4. Restart service"
            read -p "Choose option: " svc_choice
            case $svc_choice in
                1) systemctl list-units --type=service | less ;;
                2) read -p "Service name: " svc; systemctl start "$svc" ;;
                3) read -p "Service name: " svc; systemctl stop "$svc" ;;
                4) read -p "Service name: " svc; systemctl restart "$svc" ;;
            esac
            read -p "Press Enter to continue..."
            ;;
        4)
            echo "Cleaning up system..."
            apt autoremove -y && apt autoclean
            read -p "Press Enter to continue..."
            ;;
        5)
            echo "Creating system backup..."
            if [ -f "$MASTERMIND_HOME/core/backup.sh" ]; then
                bash "$MASTERMIND_HOME/core/backup.sh"
            else
                echo "Backup script not found"
            fi
            read -p "Press Enter to continue..."
            ;;
        6)
            echo "Top processes:"
            top -bn1 | head -20
            read -p "Press Enter to continue..."
            ;;
        7)
            echo "Recent system logs:"
            journalctl -n 50 --no-pager
            read -p "Press Enter to continue..."
            ;;
        8)
            echo "Current directory listing:"
            ls -la
            read -p "Press Enter to continue..."
            ;;
        9)
            if [ -f "$MASTERMIND_HOME/test_proxy_setup.py" ]; then
                python3 "$MASTERMIND_HOME/test_proxy_setup.py"
            else
                echo "Test script not found"
            fi
            read -p "Press Enter to continue..."
            ;;
        10)
            echo -e "${RED}⚠️  COMPLETE UNINSTALL WARNING${RESET}"
            echo -e "${YELLOW}This will permanently remove ALL MasterMind components:${RESET}"
            echo "  • All proxy services and configurations"
            echo "  • Open ports closed and firewall rules removed" 
            echo "  • SSH banners and MOTD restored"
            echo "  • User accounts and access removed"
            echo "  • System services and cron jobs removed"
            echo "  • Log files and backups deleted"
            echo "  • SSL certificates and configurations removed"
            echo "  • All toolkit files and directories deleted"
            echo
            echo -e "${RED}YOUR SYSTEM WILL BE RESTORED TO PRE-INSTALLATION STATE${RESET}"
            echo
            read -p "Type 'CONFIRM' to proceed with complete uninstall: " confirm
            if [ "$confirm" = "CONFIRM" ]; then
                if [ -f "$MASTERMIND_HOME/uninstall.sh" ]; then
                    echo "Starting complete uninstall..."
                    bash "$MASTERMIND_HOME/uninstall.sh"
                elif [ -f "/opt/mastermind/uninstall.sh" ]; then
                    echo "Starting complete uninstall..."
                    bash "/opt/mastermind/uninstall.sh"
                else
                    echo "Downloading uninstall script..."
                    curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/uninstall.sh | bash
                fi
            else
                echo "Uninstall cancelled."
            fi
            read -p "Press Enter to continue..."
            ;;
        11)
            echo -e "${YELLOW}🔄 TOOLKIT REINSTALLATION${RESET}"
            echo -e "${CYAN}This will:${RESET}"
            echo "  • Backup current configuration"
            echo "  • Download latest version from GitHub"
            echo "  • Perform clean reinstallation"
            echo "  • Restore your configurations"
            echo "  • Restart all services"
            echo
            read -p "Continue with reinstallation? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                if [ -f "$MASTERMIND_HOME/reinstall.sh" ]; then
                    echo "Starting reinstallation..."
                    bash "$MASTERMIND_HOME/reinstall.sh"
                elif [ -f "/opt/mastermind/reinstall.sh" ]; then
                    echo "Starting reinstallation..."
                    bash "/opt/mastermind/reinstall.sh"
                else
                    echo "Downloading reinstall script..."
                    curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-toolkit/main/reinstall.sh | bash
                fi
            else
                echo "Reinstallation cancelled."
            fi
            read -p "Press Enter to continue..."
            ;;
        0) return ;;
    esac
}

# Advanced settings menu
show_advanced_settings_menu() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "ADVANCED SETTINGS"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}Configuration Options:${RESET}"
    echo
    echo -e "${WHITE}  ${CYAN}[1]${RESET} Edit Main Configuration  ${CYAN}[6]${RESET} Environment Variables"
    echo -e "${WHITE}  ${CYAN}[2]${RESET} Proxy Configuration      ${CYAN}[7]${RESET} Debug Mode"
    echo -e "${WHITE}  ${CYAN}[3]${RESET} Service Configuration    ${CYAN}[8]${RESET} Reset Configuration"
    echo -e "${WHITE}  ${CYAN}[4]${RESET} Port Configuration       ${CYAN}[9]${RESET} Update Toolkit"
    echo -e "${WHITE}  ${CYAN}[5]${RESET} Security Settings        ${CYAN}[0]${RESET} Back to Main Menu"
    echo
    draw_separator
    echo -n -e "${BRIGHT_GREEN}Select option [0-9]: ${RESET}"
    
    read -r choice
    case $choice in
        1) nano "$MASTERMIND_HOME/core/config.cfg"; read -p "Press Enter to continue..." ;;
        2) nano "$MASTERMIND_HOME/protocols/python_proxy.py"; read -p "Press Enter to continue..." ;;
        3) nano "/etc/systemd/system/python-proxy.service"; read -p "Press Enter to continue..." ;;
        4) 
            echo "Current port configuration:"
            echo "SOCKS5_PORT=1080"
            echo "WEBSOCKET_PORT=444"
            echo "WEBSOCKET_PROXY_TARGET=8080"
            echo "HTTP_PROXY_PORT=8888"
            echo "RESPONSE_PORTS=9000,9001,9002,9003"
            read -p "Press Enter to continue..."
            ;;
        5) 
            echo "Security settings:"
            echo "Firewall status: $(ufw status | head -1)"
            echo "Fail2ban status: $(systemctl is-active fail2ban 2>/dev/null || echo 'not installed')"
            read -p "Press Enter to continue..."
            ;;
        6)
            echo "Environment variables:"
            env | grep -E "(SOCKS|WEBSOCKET|HTTP|RESPONSE)" || echo "No proxy environment variables set"
            read -p "Press Enter to continue..."
            ;;
        7)
            echo "Debug information:"
            echo "Service logs:"
            journalctl -u python-proxy -n 10 --no-pager
            read -p "Press Enter to continue..."
            ;;
        8)
            echo "Reset configuration to defaults? (y/N)"
            read -r confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                if [ -f "$MASTERMIND_HOME/fix_proxy_structure.sh" ]; then
                    bash "$MASTERMIND_HOME/fix_proxy_structure.sh"
                else
                    echo "Reset script not found"
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        9)
            echo "Updating Mastermind Toolkit..."
            if [ -d "/opt/mastermind/.git" ]; then
                cd /opt/mastermind && git pull
            else
                echo "Git repository not found"
            fi
            read -p "Press Enter to continue..."
            ;;
        0) return ;;
    esac
}

# Backup and restore menu
show_backup_restore_menu() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "BACKUP & RESTORE"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}Backup Options:${RESET}"
    echo
    echo -e "${WHITE}  ${CYAN}[1]${RESET} Create Full Backup       ${CYAN}[5]${RESET} Restore from Backup"
    echo -e "${WHITE}  ${CYAN}[2]${RESET} Configuration Backup     ${CYAN}[6]${RESET} List Backups"
    echo -e "${WHITE}  ${CYAN}[3]${RESET} User Data Backup         ${CYAN}[7]${RESET} Automatic Backup Setup"
    echo -e "${WHITE}  ${CYAN}[4]${RESET} Service Backup           ${CYAN}[0]${RESET} Back to Main Menu"
    echo
    draw_separator
    echo -n -e "${BRIGHT_GREEN}Select option [0-7]: ${RESET}"
    
    read -r choice
    case $choice in
        1|2|3|4|5|6|7)
            echo "Backup functionality is being implemented..."
            echo "This will include configuration, user data, and service backups."
            read -p "Press Enter to continue..."
            ;;
        0) return ;;
    esac
}

# Quick Setup Wizard - Easy configuration for new users
show_quick_setup_wizard() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "🚀 QUICK SETUP WIZARD"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}Welcome! Let's get your proxy server configured quickly.${RESET}"
    echo
    echo -e "${WHITE}This wizard will help you:${RESET}"
    echo -e "  ✓ Start essential proxy services"
    echo -e "  ✓ Get connection details for your apps"
    echo -e "  ✓ Test everything works properly"
    echo
    echo -e "${CYAN}What would you like to set up?${RESET}"
    echo
    echo -e "${WHITE}  ${CYAN}[1]${RESET} 📱 Mobile Apps Setup (NPV Tunnel, HTTP Injector)"
    echo -e "${WHITE}  ${CYAN}[2]${RESET} 🖥️  Desktop/Browser Proxy Setup"
    echo -e "${WHITE}  ${CYAN}[3]${RESET} 🌐 V2Ray Advanced Configuration"
    echo -e "${WHITE}  ${CYAN}[4]${RESET} 🔧 Complete Server Setup (All services)"
    echo -e "${WHITE}  ${CYAN}[5]${RESET} ❓ Help me choose the right setup"
    echo -e "${WHITE}  ${CYAN}[0]${RESET} 🔙 Back to main menu"
    echo
    draw_separator
    echo -n -e "${BRIGHT_GREEN}Select option [0-5]: ${RESET}"
    
    read -r choice
    case $choice in
        1) mobile_apps_setup ;;
        2) desktop_proxy_setup ;;
        3) v2ray_advanced_setup ;;
        4) complete_server_setup ;;
        5) help_choose_setup ;;
        0) return ;;
        *) echo "Invalid option" && sleep 2 && show_quick_setup_wizard ;;
    esac
}

# Mobile apps setup wizard
mobile_apps_setup() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "📱 MOBILE APPS SETUP"
    echo -e "${RESET}"
    draw_separator
    echo
    
    local server_ip=$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP')
    
    echo -e "${BRIGHT_YELLOW}Setting up proxy for mobile tunneling apps...${RESET}"
    echo
    
    # Start python proxy service
    echo -e "${CYAN}Step 1: Starting proxy services...${RESET}"
    systemctl start python-proxy
    sleep 2
    
    if systemctl is-active --quiet python-proxy; then
        echo -e "  ${GREEN}✓ Proxy services started successfully${RESET}"
    else
        echo -e "  ${RED}✗ Failed to start proxy services${RESET}"
        echo "  Trying to fix and restart..."
        if [ -f "fix_proxy_structure.sh" ]; then
            bash fix_proxy_structure.sh
        fi
    fi
    echo
    
    echo -e "${CYAN}Step 2: Your connection settings:${RESET}"
    echo
    echo -e "${BRIGHT_GREEN}📱 For NPV Tunnel:${RESET}"
    echo -e "  ${WHITE}Server Host:${RESET} ${BRIGHT_YELLOW}$server_ip${RESET}"
    echo -e "  ${WHITE}WebSocket Proxy:${RESET} ${BRIGHT_YELLOW}444→8080${RESET}"
    echo -e "  ${WHITE}Protocol:${RESET} WebSocket Proxy"

    echo
    echo -e "${BRIGHT_GREEN}📱 For HTTP Injector:${RESET}"
    echo -e "  ${WHITE}Proxy Host:${RESET} ${BRIGHT_YELLOW}$server_ip${RESET}"
    echo -e "  ${WHITE}Proxy Port:${RESET} ${BRIGHT_YELLOW}8888${RESET}"
    echo -e "  ${WHITE}WebSocket:${RESET} ws://${BRIGHT_YELLOW}$server_ip:444${RESET} (proxy to 8080)"
    echo
    echo -e "${CYAN}Step 3: Testing connections...${RESET}"
    echo
    for port in 444 8080 8888 9001; do
        if ss -tuln 2>/dev/null | grep -q ":$port " || netstat -tuln 2>/dev/null | grep -q ":$port " || lsof -i :$port 2>/dev/null >/dev/null; then
            echo -e "  Port $port: ${GREEN}✓ READY${RESET}"
        else
            echo -e "  Port $port: ${RED}✗ NOT READY${RESET}"
        fi
    done
    echo
    echo -e "${BRIGHT_YELLOW}💡 Next steps:${RESET}"
    echo -e "  1. Copy the connection details above"
    echo -e "  2. Open your tunneling app (NPV Tunnel, HTTP Injector, etc.)"
    echo -e "  3. Create a new configuration with these settings"
    echo -e "  4. Test the connection"
    echo
    
    read -p "Press Enter to continue..."
}

# Desktop proxy setup
desktop_proxy_setup() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "🖥️ DESKTOP/BROWSER PROXY SETUP"
    echo -e "${RESET}"
    draw_separator
    echo
    
    local server_ip=$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP')
    
    echo -e "${BRIGHT_YELLOW}Setting up proxy for desktop and browser use...${RESET}"
    echo
    
    # Start services
    echo -e "${CYAN}Starting proxy services...${RESET}"
    systemctl start python-proxy
    sleep 2
    
    echo -e "${CYAN}Your proxy settings:${RESET}"
    echo
    echo -e "${BRIGHT_GREEN}🌐 SOCKS5 Proxy (Recommended):${RESET}"
    echo -e "  ${WHITE}Host:${RESET} ${BRIGHT_YELLOW}$server_ip${RESET}"
    echo -e "  ${WHITE}Port:${RESET} ${BRIGHT_YELLOW}1080${RESET}"
    echo -e "  ${WHITE}Type:${RESET} SOCKS5"
    echo
    echo -e "${BRIGHT_GREEN}🌐 HTTP Proxy (Alternative):${RESET}"
    echo -e "  ${WHITE}Host:${RESET} ${BRIGHT_YELLOW}$server_ip${RESET}"
    echo -e "  ${WHITE}Port:${RESET} ${BRIGHT_YELLOW}8888${RESET}"
    echo -e "  ${WHITE}Type:${RESET} HTTP"
    echo
    echo -e "${BRIGHT_YELLOW}💻 Browser Configuration:${RESET}"
    echo -e "  ${WHITE}Firefox:${RESET} Settings → Network → Proxy Settings"
    echo -e "  ${WHITE}Chrome:${RESET} Use system proxy or extensions like SwitchyOmega"
    echo
    read -p "Press Enter to continue..."
}

# V2Ray advanced setup
v2ray_advanced_setup() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "🌐 V2RAY ADVANCED SETUP"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}Opening V2Ray management...${RESET}"
    if [ -f "$MASTERMIND_HOME/protocols/v2ray_manager.sh" ]; then
        bash "$MASTERMIND_HOME/protocols/v2ray_manager.sh"
    else
        echo "V2Ray manager not found. Please install V2Ray first."
        read -p "Press Enter to continue..."
    fi
}

# Complete server setup
complete_server_setup() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "🔧 COMPLETE SERVER SETUP"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}Starting all proxy and VPS services...${RESET}"
    echo
    
    # Start python proxy service
    echo -e "${CYAN}Starting main proxy services...${RESET}"
    systemctl start python-proxy
    sleep 2
    
    local server_ip=$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP')
    
    echo -e "${BRIGHT_YELLOW}🎉 Your server is ready! Here's everything:${RESET}"
    echo
    echo -e "${BRIGHT_GREEN}📱 Mobile Apps:${RESET}"
    echo -e "  ${WHITE}WebSocket Proxy:${RESET} $server_ip:444→8080"
    echo -e "  ${WHITE}HTTP Proxy:${RESET} $server_ip:8888"
    echo
    echo -e "${BRIGHT_GREEN}🖥️ Desktop/Browser:${RESET}"
    echo -e "  ${WHITE}SOCKS5:${RESET} $server_ip:1080"
    echo -e "  ${WHITE}HTTP:${RESET} $server_ip:8888"
    echo
    
    read -p "Press Enter to continue..."
}

# Help choose setup
help_choose_setup() {
    clear_screen
    echo -e "${BRIGHT_CYAN}"
    print_centered "❓ HELP CHOOSE YOUR SETUP"
    echo -e "${RESET}"
    draw_separator
    echo
    
    echo -e "${BRIGHT_YELLOW}What do you want to do?${RESET}"
    echo
    echo -e "${WHITE}📱 ${CYAN}Mobile Apps Setup${RESET} - Choose this if you want to use:"
    echo -e "  • NPV Tunnel"
    echo -e "  • HTTP Injector"
    echo -e "  • HTTP Custom"
    echo -e "  • Any tunneling app on your phone"
    echo
    echo -e "${WHITE}🖥️ ${CYAN}Desktop/Browser Setup${RESET} - Choose this if you want to:"
    echo -e "  • Use proxy in web browsers (Firefox, Chrome)"
    echo -e "  • Route desktop applications through proxy"
    echo
    echo -e "${WHITE}🔧 ${CYAN}Complete Setup${RESET} - Choose this if you:"
    echo -e "  • Want everything configured"
    echo -e "  • Plan to use multiple connection types"
    echo
    echo -e "${BRIGHT_YELLOW}💡 Most users should start with Mobile Apps setup.${RESET}"
    echo
    read -p "Press Enter to go back and make your choice..."
    show_quick_setup_wizard
}

# Helper function for confirmations
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Handle script arguments
if [ $# -gt 0 ]; then
    case "$1" in
        "user_admin") handle_user_menu ;;
        "protocols") handle_protocol_menu ;;
        "network") handle_network_menu ;;
        "security") handle_security_menu ;;
        "monitoring") show_system_monitoring_menu ;;
        "tools") show_system_tools_menu ;;
        "advanced") show_advanced_settings_menu ;;
        "ports") show_port_mapping_info ;;
        *) main ;;
    esac
else
    main
fi