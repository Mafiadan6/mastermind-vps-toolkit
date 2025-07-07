#!/bin/bash

# Mastermind VPS Toolkit - Enhanced Interactive Menu System
# Version: 3.0.0 - Complete UI/UX Redesign
# Author: Mastermind VPS Team

set -e

# Enhanced Color Palette with Modern Design
declare -A COLORS=(
    ["RESET"]='\033[0m'
    ["BOLD"]='\033[1m'
    ["DIM"]='\033[2m'
    ["UNDERLINE"]='\033[4m'
    ["BLINK"]='\033[5m'
    ["REVERSE"]='\033[7m'
    
    # Standard Colors
    ["BLACK"]='\033[0;30m'
    ["RED"]='\033[0;31m'
    ["GREEN"]='\033[0;32m'
    ["YELLOW"]='\033[0;33m'
    ["BLUE"]='\033[0;34m'
    ["PURPLE"]='\033[0;35m'
    ["CYAN"]='\033[0;36m'
    ["WHITE"]='\033[0;37m'
    ["GRAY"]='\033[0;90m'
    
    # Bright Colors
    ["BRIGHT_RED"]='\033[0;91m'
    ["BRIGHT_GREEN"]='\033[0;92m'
    ["BRIGHT_YELLOW"]='\033[0;93m'
    ["BRIGHT_BLUE"]='\033[0;94m'
    ["BRIGHT_PURPLE"]='\033[0;95m'
    ["BRIGHT_CYAN"]='\033[0;96m'
    ["BRIGHT_WHITE"]='\033[0;97m'
    
    # Background Colors
    ["BG_BLACK"]='\033[40m'
    ["BG_RED"]='\033[41m'
    ["BG_GREEN"]='\033[42m'
    ["BG_YELLOW"]='\033[43m'
    ["BG_BLUE"]='\033[44m'
    ["BG_PURPLE"]='\033[45m'
    ["BG_CYAN"]='\033[46m'
    ["BG_WHITE"]='\033[47m'
)

# Configuration
MASTERMIND_HOME="/opt/mastermind"
LOG_DIR="/var/log/mastermind"
CONFIG_FILE="/etc/mastermind.conf"
VERSION="3.0.0"

# Load helper functions
if [ -f "$MASTERMIND_HOME/core/helpers.sh" ]; then
    source "$MASTERMIND_HOME/core/helpers.sh"
fi

# Utility Functions
print_color() {
    local color="$1"
    local text="$2"
    echo -e "${COLORS[$color]}$text${COLORS[RESET]}"
}

print_centered() {
    local text="$1"
    local width="${2:-80}"
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s%*s\n" $padding "" "$text" $padding ""
}

draw_line() {
    local char="${1:-═}"
    local length="${2:-80}"
    printf "%*s\n" $length "" | tr ' ' "$char"
}

# Enhanced System Information Functions
get_cpu_usage() {
    awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) "%"; }' \
        <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat) 2>/dev/null | head -1 | cut -d'%' -f1
}

get_memory_usage() {
    free | awk '/^Mem:/ {printf "%.1f", ($3/$2) * 100.0}'
}

get_disk_usage() {
    df -h / | awk 'NR==2{print $5}' | sed 's/%//'
}

get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//'
}

get_uptime() {
    uptime -p | sed 's/up //'
}

get_system_info() {
    case "$1" in
        "hostname") hostname ;;
        "kernel") uname -r ;;
        "os") lsb_release -d 2>/dev/null | cut -f2 | head -1 || grep PRETTY_NAME /etc/os-release | cut -d'"' -f2 ;;
        "ip_internal") hostname -I | awk '{print $1}' ;;
        "ip_external") curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "Unknown" ;;
        "ssh_users") who | wc -l ;;
        "total_processes") ps aux | wc -l ;;
        "network_connections") ss -tuln | grep LISTEN | wc -l ;;
    esac
}

# Enhanced Progress Bar
create_progress_bar() {
    local value="$1"
    local max="${2:-100}"
    local width=25
    local filled=$(( value * width / max ))
    local empty=$((width - filled))
    
    local color=""
    if [ "$value" -gt 80 ]; then
        color="${COLORS[BRIGHT_RED]}"
    elif [ "$value" -gt 60 ]; then
        color="${COLORS[BRIGHT_YELLOW]}"
    else
        color="${COLORS[BRIGHT_GREEN]}"
    fi
    
    printf "${color}["
    printf "%*s" "$filled" | tr ' ' '█'
    printf "%*s" "$empty" | tr ' ' '░'
    printf "]${COLORS[RESET]}"
}

# Service Status with Enhanced Visual Indicators
get_service_status() {
    local service="$1"
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${COLORS[BRIGHT_GREEN]}●${COLORS[RESET]} ${COLORS[GREEN]}Running${COLORS[RESET]}"
    elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
        echo -e "${COLORS[BRIGHT_YELLOW]}●${COLORS[RESET]} ${COLORS[YELLOW]}Stopped${COLORS[RESET]}"
    else
        echo -e "${COLORS[BRIGHT_RED]}●${COLORS[RESET]} ${COLORS[RED]}Disabled${COLORS[RESET]}"
    fi
}

# Modern Header Design
show_header() {
    clear
    local hostname=$(get_system_info "hostname")
    local os=$(get_system_info "os")
    local kernel=$(get_system_info "kernel")
    local ip_external=$(get_system_info "ip_external")
    
    echo -e "${COLORS[BRIGHT_CYAN]}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║  ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██╗  ║
║  ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██║  ║
║  ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║  ║
║  ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║  ║
║  ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██║  ║
║  ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ║
║                                                                                  ║
EOF
    echo -e "║${COLORS[BRIGHT_WHITE]}                    VPS ADMINISTRATION TOOLKIT ${COLORS[BRIGHT_YELLOW]}v${VERSION}${COLORS[BRIGHT_CYAN]}                      ║"
    echo -e "║                                                                                  ║"
    echo -e "╚══════════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
    echo
    
    # System Information Bar
    echo -e "${COLORS[BOLD]}${COLORS[BLUE]}┌─ Server Info ─────────────────────────────────────────────────────────────────┐${COLORS[RESET]}"
    printf "${COLORS[CYAN]}│${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}Host:${COLORS[RESET]} %-15s ${COLORS[BRIGHT_WHITE]}OS:${COLORS[RESET]} %-25s ${COLORS[BRIGHT_WHITE]}Kernel:${COLORS[RESET]} %-15s ${COLORS[CYAN]}│${COLORS[RESET]}\n" "$hostname" "$os" "$kernel"
    printf "${COLORS[CYAN]}│${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}External IP:${COLORS[RESET]} %-20s ${COLORS[BRIGHT_WHITE]}Time:${COLORS[RESET]} %-30s ${COLORS[CYAN]}│${COLORS[RESET]}\n" "$ip_external" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo -e "${COLORS[BOLD]}${COLORS[BLUE]}└───────────────────────────────────────────────────────────────────────────────┘${COLORS[RESET]}"
    echo
}

# Enhanced System Dashboard
show_system_dashboard() {
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)
    local load_avg=$(get_load_average)
    local uptime=$(get_uptime)
    local ssh_users=$(get_system_info "ssh_users")
    local processes=$(get_system_info "total_processes")
    local connections=$(get_system_info "network_connections")
    
    # Convert to integers for comparison
    cpu_int=$(echo "$cpu_usage" | cut -d'.' -f1)
    mem_int=$(echo "$memory_usage" | cut -d'.' -f1)
    
    local cpu_bar=$(create_progress_bar "$cpu_int")
    local mem_bar=$(create_progress_bar "$mem_int")
    local disk_bar=$(create_progress_bar "$disk_usage")
    
    echo -e "${COLORS[BOLD]}${COLORS[PURPLE]}┌─ System Performance ─────────────────────────────────────────────────────────┐${COLORS[RESET]}"
    printf "${COLORS[PURPLE]}│${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}CPU Usage:${COLORS[RESET]}    %s ${COLORS[BRIGHT_WHITE]}%6.1f%%${COLORS[RESET]}                                  ${COLORS[PURPLE]}│${COLORS[RESET]}\n" "$cpu_bar" "$cpu_usage"
    printf "${COLORS[PURPLE]}│${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}Memory:${COLORS[RESET]}       %s ${COLORS[BRIGHT_WHITE]}%6.1f%%${COLORS[RESET]}                                  ${COLORS[PURPLE]}│${COLORS[RESET]}\n" "$mem_bar" "$memory_usage"
    printf "${COLORS[PURPLE]}│${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}Disk /:${COLORS[RESET]}       %s ${COLORS[BRIGHT_WHITE]}%6s%%${COLORS[RESET]}                                  ${COLORS[PURPLE]}│${COLORS[RESET]}\n" "$disk_bar" "$disk_usage"
    echo -e "${COLORS[PURPLE]}│${COLORS[RESET]}                                                                               ${COLORS[PURPLE]}│${COLORS[RESET]}"
    printf "${COLORS[PURPLE]}│${COLORS[RESET]} ${COLORS[CYAN]}Load Average:${COLORS[RESET]} ${COLORS[WHITE]}%-20s${COLORS[RESET]} ${COLORS[CYAN]}Uptime:${COLORS[RESET]} ${COLORS[WHITE]}%-25s${COLORS[RESET]} ${COLORS[PURPLE]}│${COLORS[RESET]}\n" "$load_avg" "$uptime"
    printf "${COLORS[PURPLE]}│${COLORS[RESET]} ${COLORS[CYAN]}SSH Users:${COLORS[RESET]}    ${COLORS[WHITE]}%-20s${COLORS[RESET]} ${COLORS[CYAN]}Processes:${COLORS[RESET]} ${COLORS[WHITE]}%-20s${COLORS[RESET]} ${COLORS[PURPLE]}│${COLORS[RESET]}\n" "$ssh_users" "$processes"
    printf "${COLORS[PURPLE]}│${COLORS[RESET]} ${COLORS[CYAN]}Open Ports:${COLORS[RESET]}   ${COLORS[WHITE]}%-64s${COLORS[RESET]} ${COLORS[PURPLE]}│${COLORS[RESET]}\n" "$connections"
    echo -e "${COLORS[BOLD]}${COLORS[PURPLE]}└───────────────────────────────────────────────────────────────────────────────┘${COLORS[RESET]}"
    echo
}

# Enhanced Service Status Dashboard
show_service_status() {
    local services=("ssh" "nginx" "fail2ban" "ufw" "python-proxy" "tcp-bypass")
    
    echo -e "${COLORS[BOLD]}${COLORS[GREEN]}┌─ Service Status ─────────────────────────────────────────────────────────────┐${COLORS[RESET]}"
    
    for service in "${services[@]}"; do
        local status=$(get_service_status "$service")
        printf "${COLORS[GREEN]}│${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}%-20s${COLORS[RESET]} %s                                           ${COLORS[GREEN]}│${COLORS[RESET]}\n" "$service" "$status"
    done
    
    echo -e "${COLORS[BOLD]}${COLORS[GREEN]}└───────────────────────────────────────────────────────────────────────────────┘${COLORS[RESET]}"
    echo
}

# Modern Main Menu Design
show_main_menu() {
    echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_YELLOW]}╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo -e "║${COLORS[BRIGHT_WHITE]}                            📋 MAIN NAVIGATION MENU                            ${COLORS[BRIGHT_YELLOW]}║"
    echo -e "╠═══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    
    # Menu items with modern styling
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[1]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🚀 Protocol Management${COLORS[RESET]}     ${COLORS[BRIGHT_CYAN]}[2]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}⚡ Network Optimization${COLORS[RESET]}     ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}      ${COLORS[GRAY]}SOCKS5, V2Ray, SSH Suite${COLORS[RESET]}           ${COLORS[GRAY]}BBR, Kernel Tuning, UDP${COLORS[RESET]}        ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[3]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}👥 User Administration${COLORS[RESET]}     ${COLORS[BRIGHT_CYAN]}[4]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔒 Security Center${COLORS[RESET]}         ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}      ${COLORS[GRAY]}Add/Remove Users, SSH Keys${COLORS[RESET]}         ${COLORS[GRAY]}Firewall, Fail2ban, Audit${COLORS[RESET]}      ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[5]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📊 System Monitoring${COLORS[RESET]}       ${COLORS[BRIGHT_CYAN]}[6]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🎨 Branding & QR Codes${COLORS[RESET]}    ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}      ${COLORS[GRAY]}Logs, Performance, Alerts${COLORS[RESET]}          ${COLORS[GRAY]}Custom Banners, QR Generator${COLORS[RESET]}   ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[7]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🌐 Domain & SSL${COLORS[RESET]}            ${COLORS[BRIGHT_CYAN]}[8]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}⚙️  System Tools${COLORS[RESET]}           ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}      ${COLORS[GRAY]}Certificates, Auto-renewal${COLORS[RESET]}         ${COLORS[GRAY]}Backup, Updates, Utilities${COLORS[RESET]}     ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[9]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📱 Quick Actions${COLORS[RESET]}           ${COLORS[BRIGHT_CYAN]}[A]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔧 Advanced Settings${COLORS[RESET]}       ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}      ${COLORS[GRAY]}Common Tasks, Shortcuts${COLORS[RESET]}            ${COLORS[GRAY]}Expert Configuration${COLORS[RESET]}           ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    
    # Action buttons
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}  ${COLORS[BRIGHT_GREEN]}[R]${COLORS[RESET]} ${COLORS[GREEN]}🔄 Refresh Display${COLORS[RESET]}         ${COLORS[BRIGHT_RED]}[0]${COLORS[RESET]} ${COLORS[RED]}❌ Exit Dashboard${COLORS[RESET]}         ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
    echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_YELLOW]}╚═══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
    echo
    
    echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_WHITE]}💡 Enter your choice (${COLORS[BRIGHT_CYAN]}1-9${COLORS[BRIGHT_WHITE]}, ${COLORS[BRIGHT_CYAN]}A${COLORS[BRIGHT_WHITE]}, ${COLORS[BRIGHT_GREEN]}R${COLORS[BRIGHT_WHITE]}, or ${COLORS[BRIGHT_RED]}0${COLORS[BRIGHT_WHITE]}):${COLORS[RESET]} "
}

# Protocol Management Menu
protocol_management_menu() {
    while true; do
        show_header
        show_system_dashboard
        
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_PURPLE]}╔═══════════════════════════════════════════════════════════════════════════════╗"
        echo -e "║${COLORS[BRIGHT_WHITE]}                         🚀 PROTOCOL MANAGEMENT CENTER                         ${COLORS[BRIGHT_PURPLE]}║"
        echo -e "╠═══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        # Protocol options with live status indicators
        local python_status=$(get_service_status "python-proxy")
        local v2ray_status=$(get_service_status "v2ray")
        local ssh_status=$(get_service_status "ssh")
        local tcp_status=$(get_service_status "tcp-bypass")
        local badvpn_status=$(get_service_status "badvpn")
        local squid_status=$(get_service_status "squid")
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[1]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}Python Proxy Suite${COLORS[RESET]}        Status: $python_status          ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}SOCKS5, HTTP, WebSocket proxies${COLORS[RESET]}                                 ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[2]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}V2Ray Manager${COLORS[RESET]}             Status: $v2ray_status          ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}VLESS, VMESS protocols with TLS${COLORS[RESET]}                                 ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[3]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}SSH Ecosystem${COLORS[RESET]}             Status: $ssh_status             ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}SSH, Dropbear, SSH-UDP tunneling${COLORS[RESET]}                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[4]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}TCP Bypass Proxy${COLORS[RESET]}          Status: $tcp_status             ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}High-performance TCP proxy bypass${COLORS[RESET]}                              ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[5]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}BadVPN Integration${COLORS[RESET]}        Status: $badvpn_status          ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}UDP over TCP tunneling${COLORS[RESET]}                                         ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[6]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}Squid Proxy Setup${COLORS[RESET]}         Status: $squid_status           ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}HTTP/HTTPS caching proxy${COLORS[RESET]}                                        ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_GREEN]}[0]${COLORS[RESET]} ${COLORS[GREEN]}← Back to Main Menu${COLORS[RESET]}                                                ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_PURPLE]}╚═══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
        echo
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_WHITE]}Select protocol [1-6] or [0] to return:${COLORS[RESET]} "
        
        read -r choice
        case "$choice" in
            1) manage_python_proxy ;;
            2) manage_v2ray ;;
            3) manage_ssh_ecosystem ;;
            4) manage_tcp_bypass ;;
            5) manage_badvpn ;;
            6) manage_squid_proxy ;;
            0) return ;;
            *) 
                echo -e "${COLORS[BRIGHT_RED]}❌ Invalid option. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# Quick Actions Menu
quick_actions_menu() {
    while true; do
        show_header
        
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_BLUE]}╔═══════════════════════════════════════════════════════════════════════════════╗"
        echo -e "║${COLORS[BRIGHT_WHITE]}                           📱 QUICK ACTIONS CENTER                            ${COLORS[BRIGHT_BLUE]}║"
        echo -e "╠═══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[1]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔄 Restart All Services${COLORS[RESET]}      ${COLORS[BRIGHT_CYAN]}[2]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📊 System Health Check${COLORS[RESET]}    ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[3]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🧹 Clear System Logs${COLORS[RESET]}        ${COLORS[BRIGHT_CYAN]}[4]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🚀 Performance Boost${COLORS[RESET]}      ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[5]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔐 Generate SSH Keys${COLORS[RESET]}        ${COLORS[BRIGHT_CYAN]}[6]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📋 Show Connection QR${COLORS[RESET]}     ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[7]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🌐 Update System${COLORS[RESET]}            ${COLORS[BRIGHT_CYAN]}[8]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📈 Real-time Monitor${COLORS[RESET]}      ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_GREEN]}[0]${COLORS[RESET]} ${COLORS[GREEN]}← Back to Main Menu${COLORS[RESET]}                                                ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_BLUE]}╚═══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
        echo
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_WHITE]}Select a quick action:${COLORS[RESET]} "
        
        read -r choice
        case "$choice" in
            1) restart_all_services ;;
            2) system_health_check ;;
            3) clear_system_logs ;;
            4) performance_boost ;;
            5) generate_ssh_keys ;;
            6) show_connection_qr ;;
            7) update_system ;;
            8) real_time_monitor ;;
            0) return ;;
            *) 
                echo -e "${COLORS[BRIGHT_RED]}❌ Invalid option. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# Function stubs for menu actions
manage_python_proxy() {
    echo -e "${COLORS[BRIGHT_BLUE]}🔧 Managing Python Proxy Suite...${COLORS[RESET]}"
    if [ -f "$MASTERMIND_HOME/protocols/proxy_manager.sh" ]; then
        bash "$MASTERMIND_HOME/protocols/proxy_manager.sh"
    else
        echo -e "${COLORS[BRIGHT_RED]}❌ Proxy manager script not found${COLORS[RESET]}"
    fi
    read -p "Press Enter to continue..."
}

manage_v2ray() {
    echo -e "${COLORS[BRIGHT_BLUE]}🔧 Managing V2Ray Configuration...${COLORS[RESET]}"
    if [ -f "$MASTERMIND_HOME/protocols/v2ray_manager.sh" ]; then
        bash "$MASTERMIND_HOME/protocols/v2ray_manager.sh"
    else
        echo -e "${COLORS[BRIGHT_RED]}❌ V2Ray manager script not found${COLORS[RESET]}"
    fi
    read -p "Press Enter to continue..."
}

manage_ssh_ecosystem() {
    echo -e "${COLORS[BRIGHT_BLUE]}🔧 Managing SSH Ecosystem...${COLORS[RESET]}"
    if [ -f "$MASTERMIND_HOME/protocols/ssh_suite.sh" ]; then
        bash "$MASTERMIND_HOME/protocols/ssh_suite.sh"
    else
        echo -e "${COLORS[BRIGHT_RED]}❌ SSH suite script not found${COLORS[RESET]}"
    fi
    read -p "Press Enter to continue..."
}

manage_tcp_bypass() {
    echo -e "${COLORS[BRIGHT_BLUE]}🔧 Managing TCP Bypass Proxy...${COLORS[RESET]}"
    if [ -f "$MASTERMIND_HOME/protocols/tcp_bypass.sh" ]; then
        bash "$MASTERMIND_HOME/protocols/tcp_bypass.sh"
    else
        echo -e "${COLORS[BRIGHT_RED]}❌ TCP bypass script not found${COLORS[RESET]}"
    fi
    read -p "Press Enter to continue..."
}

manage_badvpn() {
    echo -e "${COLORS[BRIGHT_BLUE]}🔧 Managing BadVPN Integration...${COLORS[RESET]}"
    if [ -f "$MASTERMIND_HOME/protocols/badvpn_setup.sh" ]; then
        bash "$MASTERMIND_HOME/protocols/badvpn_setup.sh"
    else
        echo -e "${COLORS[BRIGHT_RED]}❌ BadVPN setup script not found${COLORS[RESET]}"
    fi
    read -p "Press Enter to continue..."
}

manage_squid_proxy() {
    echo -e "${COLORS[BRIGHT_BLUE]}🔧 Managing Squid Proxy...${COLORS[RESET]}"
    if [ -f "$MASTERMIND_HOME/protocols/squid_proxy.sh" ]; then
        bash "$MASTERMIND_HOME/protocols/squid_proxy.sh"
    else
        echo -e "${COLORS[BRIGHT_RED]}❌ Squid proxy script not found${COLORS[RESET]}"
    fi
    read -p "Press Enter to continue..."
}

manage_domain_ssl() {
    echo -e "${COLORS[BRIGHT_BLUE]}🌐 Managing Domain & SSL...${COLORS[RESET]}"
    if [ -f "$MASTERMIND_HOME/protocols/domain_manager.sh" ]; then
        bash "$MASTERMIND_HOME/protocols/domain_manager.sh"
    else
        echo -e "${COLORS[BRIGHT_RED]}❌ Domain manager script not found${COLORS[RESET]}"
    fi
    read -p "Press Enter to continue..."
}

restart_all_services() {
    echo -e "${COLORS[BRIGHT_YELLOW]}🔄 Restarting all services...${COLORS[RESET]}"
    local services=("ssh" "nginx" "fail2ban" "ufw")
    for service in "${services[@]}"; do
        echo -e "${COLORS[CYAN]}  Restarting $service...${COLORS[RESET]}"
        systemctl restart "$service" 2>/dev/null && echo -e "${COLORS[BRIGHT_GREEN]}  ✅ $service restarted${COLORS[RESET]}" || echo -e "${COLORS[BRIGHT_RED]}  ❌ Failed to restart $service${COLORS[RESET]}"
    done
    echo -e "${COLORS[BRIGHT_GREEN]}✅ Service restart completed${COLORS[RESET]}"
    read -p "Press Enter to continue..."
}

system_health_check() {
    echo -e "${COLORS[BRIGHT_BLUE]}📊 Running comprehensive system health check...${COLORS[RESET]}"
    echo
    
    echo -e "${COLORS[BRIGHT_YELLOW]}🔍 Checking system resources...${COLORS[RESET]}"
    local cpu=$(get_cpu_usage)
    local mem=$(get_memory_usage)
    local disk=$(get_disk_usage)
    
    echo -e "  CPU Usage: ${COLORS[BRIGHT_WHITE]}${cpu}%${COLORS[RESET]}"
    echo -e "  Memory Usage: ${COLORS[BRIGHT_WHITE]}${mem}%${COLORS[RESET]}"
    echo -e "  Disk Usage: ${COLORS[BRIGHT_WHITE]}${disk}%${COLORS[RESET]}"
    echo
    
    echo -e "${COLORS[BRIGHT_YELLOW]}🔍 Checking critical services...${COLORS[RESET]}"
    local services=("ssh" "nginx" "fail2ban" "ufw")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "  $service: ${COLORS[BRIGHT_GREEN]}✅ Running${COLORS[RESET]}"
        else
            echo -e "  $service: ${COLORS[BRIGHT_RED]}❌ Not running${COLORS[RESET]}"
        fi
    done
    echo
    
    echo -e "${COLORS[BRIGHT_YELLOW]}🔍 Checking network connectivity...${COLORS[RESET]}"
    if ping -c 1 8.8.8.8 &>/dev/null; then
        echo -e "  Internet: ${COLORS[BRIGHT_GREEN]}✅ Connected${COLORS[RESET]}"
    else
        echo -e "  Internet: ${COLORS[BRIGHT_RED]}❌ No connection${COLORS[RESET]}"
    fi
    
    echo -e "${COLORS[BRIGHT_GREEN]}✅ Health check completed${COLORS[RESET]}"
    read -p "Press Enter to continue..."
}

clear_system_logs() {
    echo -e "${COLORS[BRIGHT_YELLOW]}🧹 Clearing system logs...${COLORS[RESET]}"
    
    # Clear journal logs older than 7 days
    journalctl --vacuum-time=7d &>/dev/null
    
    # Clear specific log files
    > /var/log/auth.log
    > /var/log/syslog
    > /var/log/kern.log
    
    # Clear mastermind logs if they exist
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "*.log" -exec truncate -s 0 {} \;
    fi
    
    echo -e "${COLORS[BRIGHT_GREEN]}✅ System logs cleared${COLORS[RESET]}"
    read -p "Press Enter to continue..."
}

performance_boost() {
    echo -e "${COLORS[BRIGHT_YELLOW]}🚀 Applying performance optimizations...${COLORS[RESET]}"
    
    # Apply network optimizations if available
    if [ -f "$MASTERMIND_HOME/network/bbr.sh" ]; then
        echo -e "${COLORS[CYAN]}  Enabling BBR congestion control...${COLORS[RESET]}"
        bash "$MASTERMIND_HOME/network/bbr.sh" enable &>/dev/null
    fi
    
    # Apply kernel tuning if available
    if [ -f "$MASTERMIND_HOME/network/kernel_tuning.sh" ]; then
        echo -e "${COLORS[CYAN]}  Applying kernel optimizations...${COLORS[RESET]}"
        bash "$MASTERMIND_HOME/network/kernel_tuning.sh" &>/dev/null
    fi
    
    echo -e "${COLORS[BRIGHT_GREEN]}✅ Performance optimizations applied${COLORS[RESET]}"
    read -p "Press Enter to continue..."
}

generate_ssh_keys() {
    echo -e "${COLORS[BRIGHT_BLUE]}🔐 Generating SSH key pair...${COLORS[RESET]}"
    
    read -p "Enter username for SSH key: " username
    if [ -n "$username" ]; then
        ssh-keygen -t rsa -b 4096 -f "/home/$username/.ssh/id_rsa" -N "" -C "$username@$(hostname)" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${COLORS[BRIGHT_GREEN]}✅ SSH keys generated for $username${COLORS[RESET]}"
            echo -e "${COLORS[CYAN]}Public key location: /home/$username/.ssh/id_rsa.pub${COLORS[RESET]}"
        else
            echo -e "${COLORS[BRIGHT_RED]}❌ Failed to generate SSH keys${COLORS[RESET]}"
        fi
    else
        echo -e "${COLORS[BRIGHT_RED]}❌ Username cannot be empty${COLORS[RESET]}"
    fi
    
    read -p "Press Enter to continue..."
}

show_connection_qr() {
    echo -e "${COLORS[BRIGHT_BLUE]}📋 Generating connection QR codes...${COLORS[RESET]}"
    
    if [ -f "$MASTERMIND_HOME/branding/qr_generator.py" ]; then
        python3 "$MASTERMIND_HOME/branding/qr_generator.py"
    else
        echo -e "${COLORS[BRIGHT_RED]}❌ QR generator not found${COLORS[RESET]}"
    fi
    
    read -p "Press Enter to continue..."
}

update_system() {
    echo -e "${COLORS[BRIGHT_YELLOW]}🌐 Updating system packages...${COLORS[RESET]}"
    
    apt update &>/dev/null
    echo -e "${COLORS[CYAN]}  Package list updated${COLORS[RESET]}"
    
    apt upgrade -y &>/dev/null
    echo -e "${COLORS[CYAN]}  Packages upgraded${COLORS[RESET]}"
    
    apt autoremove -y &>/dev/null
    echo -e "${COLORS[CYAN]}  Unnecessary packages removed${COLORS[RESET]}"
    
    echo -e "${COLORS[BRIGHT_GREEN]}✅ System update completed${COLORS[RESET]}"
    read -p "Press Enter to continue..."
}

real_time_monitor() {
    echo -e "${COLORS[BRIGHT_BLUE]}📈 Starting real-time system monitor...${COLORS[RESET]}"
    echo -e "${COLORS[YELLOW]}Press Ctrl+C to exit monitor${COLORS[RESET]}"
    echo
    
    while true; do
        clear
        show_header
        show_system_dashboard
        show_service_status
        sleep 2
    done
}

# User Administration Menu
user_administration_menu() {
    while true; do
        show_header
        show_system_dashboard
        
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_PURPLE]}╔═══════════════════════════════════════════════════════════════════════════════╗"
        echo -e "║${COLORS[BRIGHT_WHITE]}                         👥 USER ADMINISTRATION CENTER                         ${COLORS[BRIGHT_PURPLE]}║"
        echo -e "╠═══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[1]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}👤 Add SSH User${COLORS[RESET]}              ${COLORS[BRIGHT_CYAN]}[2]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🗑️  Remove User${COLORS[RESET]}           ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}Create new user accounts${COLORS[RESET]}             ${COLORS[GRAY]}Delete existing users${COLORS[RESET]}       ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[3]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}✏️  Modify User${COLORS[RESET]}              ${COLORS[BRIGHT_CYAN]}[4]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📋 List Users${COLORS[RESET]}             ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}Edit user settings${COLORS[RESET]}                 ${COLORS[GRAY]}View all system users${COLORS[RESET]}      ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[5]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔐 SSH Key Management${COLORS[RESET]}       ${COLORS[BRIGHT_CYAN]}[6]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔑 Password Management${COLORS[RESET]}    ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}SSH keys and auth${COLORS[RESET]}                  ${COLORS[GRAY]}Change passwords${COLORS[RESET]}           ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[7]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}👥 User Permissions${COLORS[RESET]}         ${COLORS[BRIGHT_CYAN]}[8]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📊 User Activity${COLORS[RESET]}          ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}Groups and sudo access${COLORS[RESET]}            ${COLORS[GRAY]}Monitor user actions${COLORS[RESET]}       ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_GREEN]}[0]${COLORS[RESET]} ${COLORS[GREEN]}🔙 Back to Main Menu${COLORS[RESET]}                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_PURPLE]}╚═══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
        echo
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_WHITE]}Enter your choice:${COLORS[RESET]} "
        
        read -r choice
        case "$choice" in
            1) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" add
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ User manager script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" remove
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ User manager script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" modify
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ User manager script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" list
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ User manager script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            5) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" ssh
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ User manager script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            6) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" password
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ User manager script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" permissions
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ User manager script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            8) 
                if [ -f "$MASTERMIND_HOME/users/user_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/users/user_manager.sh" activity
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ User manager script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            0) return ;;
            *) 
                echo -e "${COLORS[BRIGHT_RED]}❌ Invalid option. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# Network Optimization Menu
network_optimization_menu() {
    while true; do
        show_header
        show_system_dashboard
        
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_BLUE]}╔═══════════════════════════════════════════════════════════════════════════════╗"
        echo -e "║${COLORS[BRIGHT_WHITE]}                        ⚡ NETWORK OPTIMIZATION CENTER                         ${COLORS[BRIGHT_BLUE]}║"
        echo -e "╠═══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[1]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🚀 Enable BBR${COLORS[RESET]}                ${COLORS[BRIGHT_CYAN]}[2]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}⚙️  Kernel Tuning${COLORS[RESET]}          ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}      ${COLORS[GRAY]}TCP congestion control${COLORS[RESET]}            ${COLORS[GRAY]}Optimize system parameters${COLORS[RESET]}  ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[3]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📡 UDP Optimization${COLORS[RESET]}          ${COLORS[BRIGHT_CYAN]}[4]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔧 Custom TCP Settings${COLORS[RESET]}     ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}      ${COLORS[GRAY]}Boost UDP performance${COLORS[RESET]}             ${COLORS[GRAY]}Configure TCP manually${COLORS[RESET]}     ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[5]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📊 Network Monitor${COLORS[RESET]}           ${COLORS[BRIGHT_CYAN]}[6]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔄 Reset to Default${COLORS[RESET]}       ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}      ${COLORS[GRAY]}Real-time network stats${COLORS[RESET]}          ${COLORS[GRAY]}Restore original settings${COLORS[RESET]} ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_GREEN]}[0]${COLORS[RESET]} ${COLORS[GREEN]}🔙 Back to Main Menu${COLORS[RESET]}                                               ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_BLUE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_BLUE]}╚═══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
        echo
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_WHITE]}Enter your choice:${COLORS[RESET]} "
        
        read -r choice
        case "$choice" in
            1) 
                if [ -f "$MASTERMIND_HOME/network/bbr.sh" ]; then
                    bash "$MASTERMIND_HOME/network/bbr.sh" enable
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ BBR script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2) 
                if [ -f "$MASTERMIND_HOME/network/kernel_tuning.sh" ]; then
                    bash "$MASTERMIND_HOME/network/kernel_tuning.sh"
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ Kernel tuning script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3) 
                if [ -f "$MASTERMIND_HOME/network/udp_optimizer.sh" ]; then
                    bash "$MASTERMIND_HOME/network/udp_optimizer.sh"
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ UDP optimizer script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4) 
                echo -e "${COLORS[BRIGHT_YELLOW]}🔧 Custom TCP Settings${COLORS[RESET]}"
                echo -e "${COLORS[CYAN]}Current TCP settings:${COLORS[RESET]}"
                sysctl net.core.rmem_max net.core.wmem_max net.ipv4.tcp_rmem net.ipv4.tcp_wmem
                read -p "Press Enter to continue..."
                ;;
            5) 
                echo -e "${COLORS[BRIGHT_BLUE]}📊 Network Monitor${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Network interfaces:${COLORS[RESET]}"
                ip -s link show
                echo -e "${COLORS[YELLOW]}Network connections:${COLORS[RESET]}"
                ss -tuln
                read -p "Press Enter to continue..."
                ;;
            6) 
                echo -e "${COLORS[BRIGHT_YELLOW]}🔄 Reset network settings to default${COLORS[RESET]}"
                if [ -f "$MASTERMIND_HOME/network/bbr.sh" ]; then
                    bash "$MASTERMIND_HOME/network/bbr.sh" disable
                fi
                echo -e "${COLORS[BRIGHT_GREEN]}✅ Network settings reset${COLORS[RESET]}"
                read -p "Press Enter to continue..."
                ;;
            0) return ;;
            *) 
                echo -e "${COLORS[BRIGHT_RED]}❌ Invalid option. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# Security Center Menu
security_center_menu() {
    while true; do
        show_header
        show_system_dashboard
        
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_RED]}╔═══════════════════════════════════════════════════════════════════════════════╗"
        echo -e "║${COLORS[BRIGHT_WHITE]}                           🔒 SECURITY CENTER                                   ${COLORS[BRIGHT_RED]}║"
        echo -e "╠═══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[1]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔥 Firewall Management${COLORS[RESET]}       ${COLORS[BRIGHT_CYAN]}[2]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🛡️  Fail2ban Setup${COLORS[RESET]}        ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}      ${COLORS[GRAY]}Configure UFW rules${COLORS[RESET]}               ${COLORS[GRAY]}Block malicious IPs${COLORS[RESET]}       ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[3]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔐 SSH Hardening${COLORS[RESET]}             ${COLORS[BRIGHT_CYAN]}[4]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔍 Security Audit${COLORS[RESET]}         ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}      ${COLORS[GRAY]}Secure SSH configuration${COLORS[RESET]}         ${COLORS[GRAY]}System security scan${COLORS[RESET]}      ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[5]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📊 Security Logs${COLORS[RESET]}             ${COLORS[BRIGHT_CYAN]}[6]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}⚠️  Intrusion Detection${COLORS[RESET]}   ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}      ${COLORS[GRAY]}View security events${COLORS[RESET]}             ${COLORS[GRAY]}Monitor suspicious activity${COLORS[RESET]} ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}  ${COLORS[BRIGHT_GREEN]}[0]${COLORS[RESET]} ${COLORS[GREEN]}🔙 Back to Main Menu${COLORS[RESET]}                                               ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_RED]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_RED]}║${COLORS[RESET]}"
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_RED]}╚═══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
        echo
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_WHITE]}Enter your choice:${COLORS[RESET]} "
        
        read -r choice
        case "$choice" in
            1) 
                if [ -f "$MASTERMIND_HOME/security/firewall_manager.sh" ]; then
                    bash "$MASTERMIND_HOME/security/firewall_manager.sh"
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ Firewall manager script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2) 
                if [ -f "$MASTERMIND_HOME/security/fail2ban_setup.sh" ]; then
                    bash "$MASTERMIND_HOME/security/fail2ban_setup.sh"
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ Fail2ban setup script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3) 
                echo -e "${COLORS[BRIGHT_YELLOW]}🔐 SSH Hardening${COLORS[RESET]}"
                echo -e "${COLORS[CYAN]}Checking SSH configuration...${COLORS[RESET]}"
                if [ -f /etc/ssh/sshd_config ]; then
                    echo "Port configuration:"
                    grep "^Port\|^#Port" /etc/ssh/sshd_config
                    echo "Authentication settings:"
                    grep "^PasswordAuthentication\|^PubkeyAuthentication\|^PermitRootLogin" /etc/ssh/sshd_config
                fi
                read -p "Press Enter to continue..."
                ;;
            4) 
                if [ -f "$MASTERMIND_HOME/security/audit_tool.sh" ]; then
                    bash "$MASTERMIND_HOME/security/audit_tool.sh"
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ Security audit script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            5) 
                echo -e "${COLORS[BRIGHT_BLUE]}📊 Security Logs${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Recent authentication failures:${COLORS[RESET]}"
                tail -20 /var/log/auth.log | grep "Failed password" 2>/dev/null || echo "No recent failures"
                echo -e "${COLORS[YELLOW]}Recent sudo usage:${COLORS[RESET]}"
                tail -10 /var/log/auth.log | grep "sudo:" 2>/dev/null || echo "No recent sudo activity"
                read -p "Press Enter to continue..."
                ;;
            6) 
                echo -e "${COLORS[BRIGHT_YELLOW]}⚠️ Intrusion Detection${COLORS[RESET]}"
                echo -e "${COLORS[CYAN]}Checking for suspicious activities...${COLORS[RESET]}"
                echo "Active connections:"
                ss -tuln | head -10
                echo "Recent logins:"
                last -n 10
                read -p "Press Enter to continue..."
                ;;
            0) return ;;
            *) 
                echo -e "${COLORS[BRIGHT_RED]}❌ Invalid option. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# System Monitoring Menu
system_monitoring_menu() {
    while true; do
        show_header
        show_system_dashboard
        
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_GREEN]}╔═══════════════════════════════════════════════════════════════════════════════╗"
        echo -e "║${COLORS[BRIGHT_WHITE]}                         📊 SYSTEM MONITORING CENTER                          ${COLORS[BRIGHT_GREEN]}║"
        echo -e "╠═══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[1]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📈 Real-time Monitor${COLORS[RESET]}         ${COLORS[BRIGHT_CYAN]}[2]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📊 Performance Stats${COLORS[RESET]}      ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}      ${COLORS[GRAY]}Live system monitoring${COLORS[RESET]}           ${COLORS[GRAY]}Detailed system metrics${COLORS[RESET]}   ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[3]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📋 System Logs${COLORS[RESET]}              ${COLORS[BRIGHT_CYAN]}[4]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}💽 Disk Usage${COLORS[RESET]}            ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}      ${COLORS[GRAY]}View system logs${COLORS[RESET]}                 ${COLORS[GRAY]}Storage analysis${COLORS[RESET]}          ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[5]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔗 Network Activity${COLORS[RESET]}          ${COLORS[BRIGHT_CYAN]}[6]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}⚡ Process Monitor${COLORS[RESET]}        ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}      ${COLORS[GRAY]}Network connections${COLORS[RESET]}              ${COLORS[GRAY]}Running processes${COLORS[RESET]}         ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}  ${COLORS[BRIGHT_GREEN]}[0]${COLORS[RESET]} ${COLORS[GREEN]}🔙 Back to Main Menu${COLORS[RESET]}                                               ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_GREEN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_GREEN]}╚═══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
        echo
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_WHITE]}Enter your choice:${COLORS[RESET]} "
        
        read -r choice
        case "$choice" in
            1) real_time_monitor ;;
            2) 
                echo -e "${COLORS[BRIGHT_BLUE]}📊 Performance Statistics${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}CPU Information:${COLORS[RESET]}"
                lscpu | grep "Model name\|CPU(s)\|Thread(s)\|Core(s)"
                echo -e "${COLORS[YELLOW]}Memory Information:${COLORS[RESET]}"
                free -h
                echo -e "${COLORS[YELLOW]}Load Average:${COLORS[RESET]}"
                uptime
                read -p "Press Enter to continue..."
                ;;
            3) 
                echo -e "${COLORS[BRIGHT_BLUE]}📋 System Logs${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Recent system messages:${COLORS[RESET]}"
                tail -20 /var/log/syslog 2>/dev/null || journalctl -n 20
                read -p "Press Enter to continue..."
                ;;
            4) 
                echo -e "${COLORS[BRIGHT_BLUE]}💽 Disk Usage Analysis${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Disk space usage:${COLORS[RESET]}"
                df -h
                echo -e "${COLORS[YELLOW]}Largest directories:${COLORS[RESET]}"
                du -sh /* 2>/dev/null | sort -hr | head -10
                read -p "Press Enter to continue..."
                ;;
            5) 
                echo -e "${COLORS[BRIGHT_BLUE]}🔗 Network Activity${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Active connections:${COLORS[RESET]}"
                ss -tuln
                echo -e "${COLORS[YELLOW]}Network interfaces:${COLORS[RESET]}"
                ip addr show
                read -p "Press Enter to continue..."
                ;;
            6) 
                echo -e "${COLORS[BRIGHT_BLUE]}⚡ Process Monitor${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Top processes by CPU:${COLORS[RESET]}"
                ps aux --sort=-%cpu | head -10
                echo -e "${COLORS[YELLOW]}Top processes by Memory:${COLORS[RESET]}"
                ps aux --sort=-%mem | head -10
                read -p "Press Enter to continue..."
                ;;
            0) return ;;
            *) 
                echo -e "${COLORS[BRIGHT_RED]}❌ Invalid option. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# Branding & QR Menu
branding_qr_menu() {
    while true; do
        show_header
        show_system_dashboard
        
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_PURPLE]}╔═══════════════════════════════════════════════════════════════════════════════╗"
        echo -e "║${COLORS[BRIGHT_WHITE]}                        🎨 BRANDING & QR CODE CENTER                          ${COLORS[BRIGHT_PURPLE]}║"
        echo -e "╠═══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[1]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📱 Generate QR Codes${COLORS[RESET]}         ${COLORS[BRIGHT_CYAN]}[2]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🎨 Custom Banner${COLORS[RESET]}          ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}Connection QR codes${COLORS[RESET]}              ${COLORS[GRAY]}Server branding${COLORS[RESET]}           ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[3]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🌐 Response Servers${COLORS[RESET]}          ${COLORS[BRIGHT_CYAN]}[4]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📊 Server Info QR${COLORS[RESET]}        ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}      ${COLORS[GRAY]}Custom HTTP responses${COLORS[RESET]}            ${COLORS[GRAY]}System info QR codes${COLORS[RESET]}     ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}  ${COLORS[BRIGHT_GREEN]}[0]${COLORS[RESET]} ${COLORS[GREEN]}🔙 Back to Main Menu${COLORS[RESET]}                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_PURPLE]}║${COLORS[RESET]}"
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_PURPLE]}╚═══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
        echo
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_WHITE]}Enter your choice:${COLORS[RESET]} "
        
        read -r choice
        case "$choice" in
            1) 
                if [ -f "$MASTERMIND_HOME/branding/qr_generator.py" ]; then
                    python3 "$MASTERMIND_HOME/branding/qr_generator.py"
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ QR generator script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2) 
                if [ -f "$MASTERMIND_HOME/branding/banner_generator.sh" ]; then
                    bash "$MASTERMIND_HOME/branding/banner_generator.sh"
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ Banner generator script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3) 
                if [ -f "$MASTERMIND_HOME/branding/response_servers.py" ]; then
                    python3 "$MASTERMIND_HOME/branding/response_servers.py"
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ Response servers script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4) 
                echo -e "${COLORS[BRIGHT_BLUE]}📊 Generating Server Info QR Code...${COLORS[RESET]}"
                if [ -f "$MASTERMIND_HOME/branding/qr_generator.py" ]; then
                    python3 -c "
import sys
sys.path.append('/opt/mastermind/branding')
from qr_generator import QRGenerator
qr = QRGenerator()
qr.generate_server_info_qr()
"
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ QR generator not available${COLORS[RESET]}"
                fi
                read -p "Press Enter to continue..."
                ;;
            0) return ;;
            *) 
                echo -e "${COLORS[BRIGHT_RED]}❌ Invalid option. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# System Tools Menu
system_tools_menu() {
    while true; do
        show_header
        show_system_dashboard
        
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_YELLOW]}╔═══════════════════════════════════════════════════════════════════════════════╗"
        echo -e "║${COLORS[BRIGHT_WHITE]}                           ⚙️ SYSTEM TOOLS CENTER                              ${COLORS[BRIGHT_YELLOW]}║"
        echo -e "╠═══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[1]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔄 System Update${COLORS[RESET]}             ${COLORS[BRIGHT_CYAN]}[2]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🧹 System Cleanup${COLORS[RESET]}        ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}      ${COLORS[GRAY]}Update all packages${COLORS[RESET]}              ${COLORS[GRAY]}Clean temporary files${COLORS[RESET]}    ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[3]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}💾 System Backup${COLORS[RESET]}            ${COLORS[BRIGHT_CYAN]}[4]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔧 Service Control${COLORS[RESET]}       ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}      ${COLORS[GRAY]}Backup configurations${COLORS[RESET]}           ${COLORS[GRAY]}Start/stop services${COLORS[RESET]}      ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[5]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📦 Package Manager${COLORS[RESET]}           ${COLORS[BRIGHT_CYAN]}[6]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔍 System Information${COLORS[RESET]}    ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}      ${COLORS[GRAY]}Install/remove packages${COLORS[RESET]}         ${COLORS[GRAY]}Detailed system info${COLORS[RESET]}     ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}  ${COLORS[BRIGHT_GREEN]}[0]${COLORS[RESET]} ${COLORS[GREEN]}🔙 Back to Main Menu${COLORS[RESET]}                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_YELLOW]}║${COLORS[RESET]}"
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_YELLOW]}╚═══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
        echo
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_WHITE]}Enter your choice:${COLORS[RESET]} "
        
        read -r choice
        case "$choice" in
            1) update_system ;;
            2) clear_system_logs ;;
            3) 
                echo -e "${COLORS[BRIGHT_BLUE]}💾 System Backup${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Creating backup of important files...${COLORS[RESET]}"
                backup_dir="/opt/mastermind/backups/$(date +%Y%m%d_%H%M%S)"
                mkdir -p "$backup_dir"
                cp -r /etc/ssh "$backup_dir/" 2>/dev/null
                cp -r /opt/mastermind/core "$backup_dir/" 2>/dev/null
                echo -e "${COLORS[BRIGHT_GREEN]}✅ Backup created in $backup_dir${COLORS[RESET]}"
                read -p "Press Enter to continue..."
                ;;
            4) 
                if [ -f "$MASTERMIND_HOME/core/service_ctl.sh" ]; then
                    bash "$MASTERMIND_HOME/core/service_ctl.sh"
                else
                    echo -e "${COLORS[BRIGHT_RED]}❌ Service control script not found${COLORS[RESET]}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            5) 
                echo -e "${COLORS[BRIGHT_BLUE]}📦 Package Manager${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Available options:${COLORS[RESET]}"
                echo "1. Update package list"
                echo "2. List installed packages"
                echo "3. Search for packages"
                read -p "Enter choice: " pkg_choice
                case $pkg_choice in
                    1) apt update ;;
                    2) apt list --installed | head -20 ;;
                    3) read -p "Package name to search: " pkg_name; apt search "$pkg_name" ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            6) 
                echo -e "${COLORS[BRIGHT_BLUE]}🔍 Detailed System Information${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Hardware Information:${COLORS[RESET]}"
                lshw -short 2>/dev/null | head -20
                echo -e "${COLORS[YELLOW]}Network Configuration:${COLORS[RESET]}"
                ip route show
                read -p "Press Enter to continue..."
                ;;
            0) return ;;
            *) 
                echo -e "${COLORS[BRIGHT_RED]}❌ Invalid option. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# Advanced Settings Menu
advanced_settings_menu() {
    while true; do
        show_header
        show_system_dashboard
        
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_CYAN]}╔═══════════════════════════════════════════════════════════════════════════════╗"
        echo -e "║${COLORS[BRIGHT_WHITE]}                          🔧 ADVANCED SETTINGS CENTER                          ${COLORS[BRIGHT_CYAN]}║"
        echo -e "╠═══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[1]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}⚙️  Configuration Editor${COLORS[RESET]}     ${COLORS[BRIGHT_CYAN]}[2]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔄 Service Templates${COLORS[RESET]}      ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}      ${COLORS[GRAY]}Edit system configs${COLORS[RESET]}              ${COLORS[GRAY]}Manage service files${COLORS[RESET]}     ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[3]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🏗️  Custom Scripts${COLORS[RESET]}           ${COLORS[BRIGHT_CYAN]}[4]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}📊 Debug Mode${COLORS[RESET]}            ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}      ${COLORS[GRAY]}Run custom commands${COLORS[RESET]}              ${COLORS[GRAY]}Verbose logging${COLORS[RESET]}          ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}  ${COLORS[BRIGHT_CYAN]}[5]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}🔧 System Variables${COLORS[RESET]}          ${COLORS[BRIGHT_CYAN]}[6]${COLORS[RESET]} ${COLORS[BRIGHT_WHITE]}⚡ Performance Tuning${COLORS[RESET]}    ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}      ${COLORS[GRAY]}Environment settings${COLORS[RESET]}             ${COLORS[GRAY]}Advanced optimization${COLORS[RESET]}    ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}  ${COLORS[BRIGHT_GREEN]}[0]${COLORS[RESET]} ${COLORS[GREEN]}🔙 Back to Main Menu${COLORS[RESET]}                                               ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}                                                                               ${COLORS[BRIGHT_CYAN]}║${COLORS[RESET]}"
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_CYAN]}╚═══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
        echo
        echo -e "${COLORS[BOLD]}${COLORS[BRIGHT_WHITE]}Enter your choice:${COLORS[RESET]} "
        
        read -r choice
        case "$choice" in
            1) 
                echo -e "${COLORS[BRIGHT_BLUE]}⚙️ Configuration Editor${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Available configurations:${COLORS[RESET]}"
                echo "1. Mastermind Config (/opt/mastermind/core/config.cfg)"
                echo "2. SSH Config (/etc/ssh/sshd_config)"
                echo "3. Nginx Config (/etc/nginx/nginx.conf)"
                read -p "Enter choice: " config_choice
                case $config_choice in
                    1) nano /opt/mastermind/core/config.cfg ;;
                    2) nano /etc/ssh/sshd_config ;;
                    3) nano /etc/nginx/nginx.conf ;;
                esac
                ;;
            2) 
                echo -e "${COLORS[BRIGHT_BLUE]}🔄 Service Templates${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}System services:${COLORS[RESET]}"
                systemctl list-unit-files --type=service | grep mastermind
                read -p "Press Enter to continue..."
                ;;
            3) 
                echo -e "${COLORS[BRIGHT_BLUE]}🏗️ Custom Scripts${COLORS[RESET]}"
                read -p "Enter command to execute: " custom_cmd
                if [ -n "$custom_cmd" ]; then
                    echo -e "${COLORS[YELLOW]}Executing: $custom_cmd${COLORS[RESET]}"
                    eval "$custom_cmd"
                fi
                read -p "Press Enter to continue..."
                ;;
            4) 
                echo -e "${COLORS[BRIGHT_BLUE]}📊 Debug Mode${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Current log levels:${COLORS[RESET]}"
                journalctl --level=debug -n 10
                read -p "Press Enter to continue..."
                ;;
            5) 
                echo -e "${COLORS[BRIGHT_BLUE]}🔧 System Variables${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Key environment variables:${COLORS[RESET]}"
                env | grep -E "PATH|HOME|USER|SHELL" | head -10
                read -p "Press Enter to continue..."
                ;;
            6) performance_boost ;;
            0) return ;;
            *) 
                echo -e "${COLORS[BRIGHT_RED]}❌ Invalid option. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# Main execution function
main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${COLORS[BRIGHT_RED]}❌ This script must be run as root${COLORS[RESET]}"
        echo -e "${COLORS[YELLOW]}Please run: sudo $0${COLORS[RESET]}"
        exit 1
    fi
    
    # Main menu loop
    while true; do
        show_header
        show_system_dashboard
        show_service_status
        show_main_menu
        
        read -r choice
        
        case "$choice" in
            1) protocol_management_menu ;;
            2) network_optimization_menu ;;
            3) user_administration_menu ;;
            4) security_center_menu ;;
            5) system_monitoring_menu ;;
            6) branding_qr_menu ;;
            7) manage_domain_ssl ;;
            8) system_tools_menu ;;
            9) quick_actions_menu ;;
            [Aa]) advanced_settings_menu ;;
            [Rr]) continue ;;
            0) 
                echo -e "${COLORS[BRIGHT_GREEN]}👋 Thank you for using Mastermind VPS Toolkit!${COLORS[RESET]}"
                echo -e "${COLORS[CYAN]}Visit us at: https://github.com/mastermind-toolkit${COLORS[RESET]}"
                exit 0
                ;;
            *) 
                echo -e "${COLORS[BRIGHT_RED]}❌ Invalid option '$choice'. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${COLORS[BRIGHT_YELLOW]}👋 Goodbye!${COLORS[RESET]}"; exit 0' INT

# Run main function
main "$@"