#!/bin/bash

# Mastermind VPS Toolkit - Advanced Admin Dashboard
# Version: 2.0.0 - Complete Rewrite

set -e

# Enhanced Color Palette
declare -A COLORS=(
    ["RESET"]='\033[0m'
    ["BOLD"]='\033[1m'
    ["DIM"]='\033[2m'
    ["RED"]='\033[0;31m'
    ["GREEN"]='\033[0;32m'
    ["YELLOW"]='\033[1;33m'
    ["BLUE"]='\033[0;34m'
    ["PURPLE"]='\033[0;35m'
    ["CYAN"]='\033[0;36m'
    ["WHITE"]='\033[1;37m'
    ["GRAY"]='\033[0;37m'
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

# Load helper functions
if [ -f "$MASTERMIND_HOME/core/helpers.sh" ]; then
    source "$MASTERMIND_HOME/core/helpers.sh"
fi

# System Information Functions
get_system_info() {
    local info_type="$1"
    
    case "$info_type" in
        "cpu_usage")
            top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}'
            ;;
        "memory_usage")
            free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}'
            ;;
        "disk_usage")
            df -h / | awk 'NR==2{print $5}' | sed 's/%//'
            ;;
        "load_average")
            uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//'
            ;;
        "uptime")
            uptime -p | sed 's/up //'
            ;;
        "kernel")
            uname -r
            ;;
        "os")
            lsb_release -d 2>/dev/null | cut -f2 | head -1 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2
            ;;
        "hostname")
            hostname
            ;;
        "ip_internal")
            hostname -I | awk '{print $1}'
            ;;
        "ip_external")
            curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "Unknown"
            ;;
        "ssh_users")
            who | wc -l
            ;;
        "total_processes")
            ps aux | wc -l
            ;;
        "network_connections")
            ss -tuln | grep LISTEN | wc -l
            ;;
    esac
}

# Get service status with color coding
get_service_status() {
    local service="$1"
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${COLORS[GREEN]}●${COLORS[RESET]} Running"
    elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
        echo -e "${COLORS[YELLOW]}●${COLORS[RESET]} Stopped"
    else
        echo -e "${COLORS[RED]}●${COLORS[RESET]} Disabled"
    fi
}

# Real-time system monitoring
show_system_dashboard() {
    local cpu_usage=$(get_system_info "cpu_usage")
    local memory_usage=$(get_system_info "memory_usage")
    local disk_usage=$(get_system_info "disk_usage")
    local load_avg=$(get_system_info "load_average")
    local uptime=$(get_system_info "uptime")
    local ssh_users=$(get_system_info "ssh_users")
    local processes=$(get_system_info "total_processes")
    local connections=$(get_system_info "network_connections")
    
    # CPU Usage Bar
    local cpu_bar=$(create_progress_bar "$cpu_usage" 100)
    local mem_bar=$(create_progress_bar "$memory_usage" 100)
    local disk_bar=$(create_progress_bar "$disk_usage" 100)
    
    cat << EOF
╔════════════════════════════════════════════════════════════════════════════════╗
║                           ${COLORS[BOLD]}${COLORS[CYAN]}SYSTEM PERFORMANCE MONITOR${COLORS[RESET]}                          ║
╠════════════════════════════════════════════════════════════════════════════════╣
║ ${COLORS[YELLOW]}CPU Usage:${COLORS[RESET]}     $cpu_bar ${cpu_usage}%                                    ║
║ ${COLORS[YELLOW]}Memory:${COLORS[RESET]}        $mem_bar ${memory_usage}%                                    ║
║ ${COLORS[YELLOW]}Disk /:${COLORS[RESET]}        $disk_bar ${disk_usage}%                                    ║
║                                                                                ║
║ ${COLORS[CYAN]}Load Average:${COLORS[RESET]}   $load_avg                                              ║
║ ${COLORS[CYAN]}Uptime:${COLORS[RESET]}         $uptime                                              ║
║ ${COLORS[CYAN]}SSH Users:${COLORS[RESET]}      ${ssh_users} active sessions                                           ║
║ ${COLORS[CYAN]}Processes:${COLORS[RESET]}      ${processes} total                                                 ║
║ ${COLORS[CYAN]}Connections:${COLORS[RESET]}    ${connections} listening ports                                       ║
╚════════════════════════════════════════════════════════════════════════════════╝
EOF
}

# Create progress bar
create_progress_bar() {
    local value="$1"
    local max="$2"
    local width=20
    local filled=$(( (value * width) / max ))
    local empty=$((width - filled))
    
    local color
    if (( $(echo "$value > 80" | bc -l) )); then
        color="${COLORS[RED]}"
    elif (( $(echo "$value > 60" | bc -l) )); then
        color="${COLORS[YELLOW]}"
    else
        color="${COLORS[GREEN]}"
    fi
    
    printf "${color}["
    printf "%*s" "$filled" | tr ' ' '█'
    printf "%*s" "$empty" | tr ' ' '░'
    printf "]${COLORS[RESET]}"
}

# Service status dashboard
show_service_status() {
    local services=("python-proxy" "tcp-bypass" "ssh" "nginx" "fail2ban" "ufw")
    
    cat << EOF
╔════════════════════════════════════════════════════════════════════════════════╗
║                              ${COLORS[BOLD]}${COLORS[PURPLE]}SERVICE STATUS${COLORS[RESET]}                                ║
╠════════════════════════════════════════════════════════════════════════════════╣
EOF

    for service in "${services[@]}"; do
        local status=$(get_service_status "$service")
        printf "║ %-20s %s                                                    ║\n" "$service" "$status"
    done
    
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
}

# Network monitoring
show_network_info() {
    local internal_ip=$(get_system_info "ip_internal")
    local external_ip=$(get_system_info "ip_external")
    
    cat << EOF
╔════════════════════════════════════════════════════════════════════════════════╗
║                              ${COLORS[BOLD]}${COLORS[BLUE]}NETWORK INFORMATION${COLORS[RESET]}                            ║
╠════════════════════════════════════════════════════════════════════════════════╣
║ ${COLORS[YELLOW]}Internal IP:${COLORS[RESET]}    $internal_ip                                               ║
║ ${COLORS[YELLOW]}External IP:${COLORS[RESET]}    $external_ip                                               ║
║                                                                                ║
║ ${COLORS[CYAN]}Active Ports:${COLORS[RESET]}                                                              ║
EOF

    # Show active listening ports
    ss -tuln | grep LISTEN | awk '{print $5}' | cut -d: -f2 | sort -n | uniq | head -8 | while read port; do
        local service_name=$(ss -tuln | grep ":$port " | head -1 | awk '{print $1}')
        printf "║   ${COLORS[GREEN]}%-6s${COLORS[RESET]} %s                                                          ║\n" "$port" "$service_name"
    done
    
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
}

# User management dashboard
show_user_info() {
    local total_users=$(cat /etc/passwd | grep -E "/home|/root" | wc -l)
    local sudo_users=$(getent group sudo | cut -d: -f4 | tr ',' '\n' | wc -l)
    
    cat << EOF
╔════════════════════════════════════════════════════════════════════════════════╗
║                               ${COLORS[BOLD]}${COLORS[GREEN]}USER MANAGEMENT${COLORS[RESET]}                               ║
╠════════════════════════════════════════════════════════════════════════════════╣
║ ${COLORS[YELLOW]}Total Users:${COLORS[RESET]}    $total_users                                                   ║
║ ${COLORS[YELLOW]}Sudo Users:${COLORS[RESET]}     $sudo_users                                                    ║
║                                                                                ║
║ ${COLORS[CYAN]}Currently Logged In:${COLORS[RESET]}                                                       ║
EOF

    # Show logged in users
    who | while IFS= read -r line; do
        local user=$(echo "$line" | awk '{print $1}')
        local terminal=$(echo "$line" | awk '{print $2}')
        local time=$(echo "$line" | awk '{print $3, $4}')
        printf "║   ${COLORS[GREEN]}%-10s${COLORS[RESET]} %-8s %s                                    ║\n" "$user" "$terminal" "$time"
    done
    
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
}

# Main header with branding
show_header() {
    clear
    local hostname=$(get_system_info "hostname")
    local os=$(get_system_info "os")
    local kernel=$(get_system_info "kernel")
    
    cat << EOF
${COLORS[CYAN]}
████████████████████████████████████████████████████████████████████████████████
█                                                                              █
█    ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ███╗   ███╗██╗███╗   █
█    ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  █
█    ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ █
█    ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗█
█    ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚███
█    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚══
█                                                                              █
█              ${COLORS[WHITE]}VPS ADMINISTRATION DASHBOARD v2.0${COLORS[CYAN]}                          █
█                                                                              █
████████████████████████████████████████████████████████████████████████████████
${COLORS[RESET]}

${COLORS[BOLD]}${COLORS[WHITE]}Server:${COLORS[RESET]} $hostname  ${COLORS[BOLD]}${COLORS[WHITE]}OS:${COLORS[RESET]} $os  ${COLORS[BOLD]}${COLORS[WHITE]}Kernel:${COLORS[RESET]} $kernel

EOF
}

# Main navigation menu
show_main_menu() {
    cat << EOF
${COLORS[BOLD]}${COLORS[YELLOW]}╔══════════════════════════════════════════════════════════════════════════════╗
║                               MAIN NAVIGATION                                ║
╠══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}
║                                                                              ║
║  ${COLORS[CYAN]}[1]${COLORS[RESET]} ${COLORS[WHITE]}🚀 Protocol Management${COLORS[RESET]}      ${COLORS[CYAN]}[2]${COLORS[RESET]} ${COLORS[WHITE]}⚡ Network Optimization${COLORS[RESET]}    ║
║      SOCKS5, V2Ray, SSH Suite           BBR, Kernel Tuning, UDP       ║
║                                                                              ║
║  ${COLORS[CYAN]}[3]${COLORS[RESET]} ${COLORS[WHITE]}👥 User Administration${COLORS[RESET]}      ${COLORS[CYAN]}[4]${COLORS[RESET]} ${COLORS[WHITE]}🔒 Security Center${COLORS[RESET]}        ║
║      Add/Remove Users, SSH Keys          Firewall, Fail2ban, Audit     ║
║                                                                              ║
║  ${COLORS[CYAN]}[5]${COLORS[RESET]} ${COLORS[WHITE]}📊 System Monitoring${COLORS[RESET]}        ${COLORS[CYAN]}[6]${COLORS[RESET]} ${COLORS[WHITE]}🎨 Branding & QR Codes${COLORS[RESET]}   ║
║      Logs, Performance, Alerts          Custom Banners, QR Generator   ║
║                                                                              ║
║  ${COLORS[CYAN]}[7]${COLORS[RESET]} ${COLORS[WHITE]}🌐 Domain & SSL${COLORS[RESET]}             ${COLORS[CYAN]}[8]${COLORS[RESET]} ${COLORS[WHITE]}⚙️  System Tools${COLORS[RESET]}          ║
║      Certificates, Auto-renewal          Backup, Updates, Utilities     ║
║                                                                              ║
║  ${COLORS[CYAN]}[0]${COLORS[RESET]} ${COLORS[RED]}Exit Dashboard${COLORS[RESET]}                ${COLORS[CYAN]}[R]${COLORS[RESET]} ${COLORS[YELLOW]}Refresh Display${COLORS[RESET]}         ║
║                                                                              ║
${COLORS[BOLD]}${COLORS[YELLOW]}╚══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}

${COLORS[BOLD]}${COLORS[WHITE]}Enter your choice:${COLORS[RESET]} 
EOF
}

# Protocol Management Menu
protocol_management_menu() {
    while true; do
        show_header
        show_system_dashboard
        echo
        cat << EOF
${COLORS[BOLD]}${COLORS[PURPLE]}╔══════════════════════════════════════════════════════════════════════════════╗
║                             PROTOCOL MANAGEMENT                              ║
╠══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}
║                                                                              ║
║  ${COLORS[CYAN]}[1]${COLORS[RESET]} Python Proxy Suite        $(get_service_status "python-proxy")                     ║
║      SOCKS5, HTTP, WebSocket proxy with custom responses                    ║
║                                                                              ║
║  ${COLORS[CYAN]}[2]${COLORS[RESET]} V2Ray Manager             ${COLORS[GRAY]}○ Not Configured${COLORS[RESET]}                        ║
║      VLESS, VMESS, Trojan protocols with TLS                                ║
║                                                                              ║
║  ${COLORS[CYAN]}[3]${COLORS[RESET]} SSH Ecosystem             $(get_service_status "ssh")                           ║
║      SSH, Dropbear, SSH-UDP tunneling                                       ║
║                                                                              ║
║  ${COLORS[CYAN]}[4]${COLORS[RESET]} TCP Bypass Proxy          $(get_service_status "tcp-bypass")                     ║
║      High-performance TCP proxy and bypass                                  ║
║                                                                              ║
║  ${COLORS[CYAN]}[5]${COLORS[RESET]} BadVPN Integration        ${COLORS[GRAY]}○ Not Configured${COLORS[RESET]}                        ║
║      UDP over TCP tunneling solution                                        ║
║                                                                              ║
║  ${COLORS[CYAN]}[6]${COLORS[RESET]} Squid Proxy Setup         ${COLORS[GRAY]}○ Not Configured${COLORS[RESET]}                        ║
║      HTTP/HTTPS caching proxy server                                        ║
║                                                                              ║
║  ${COLORS[CYAN]}[0]${COLORS[RESET]} Back to Main Menu                                                       ║
║                                                                              ║
${COLORS[BOLD]}${COLORS[PURPLE]}╚══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}

${COLORS[BOLD]}${COLORS[WHITE]}Enter your choice:${COLORS[RESET]} 
EOF
        read -r choice
        case "$choice" in
            1) manage_python_proxy ;;
            2) manage_v2ray ;;
            3) manage_ssh_ecosystem ;;
            4) manage_tcp_bypass ;;
            5) manage_badvpn ;;
            6) manage_squid_proxy ;;
            0) return ;;
            *) echo -e "${COLORS[RED]}Invalid option. Please try again.${COLORS[RESET]}" ; sleep 2 ;;
        esac
    done
}

# User Administration Menu
user_management_menu() {
    while true; do
        show_header
        show_user_info
        echo
        cat << EOF
${COLORS[BOLD]}${COLORS[GREEN]}╔══════════════════════════════════════════════════════════════════════════════╗
║                              USER ADMINISTRATION                             ║
╠══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}
║                                                                              ║
║  ${COLORS[CYAN]}[1]${COLORS[RESET]} Add New SSH User           Create user with SSH access and keys       ║
║  ${COLORS[CYAN]}[2]${COLORS[RESET]} Remove User                Delete user account and home directory     ║
║  ${COLORS[CYAN]}[3]${COLORS[RESET]} Manage SSH Keys            Add, remove, list SSH public keys         ║
║  ${COLORS[CYAN]}[4]${COLORS[RESET]} Set User Limits            Configure resource limits and quotas      ║
║  ${COLORS[CYAN]}[5]${COLORS[RESET]} View Active Sessions       Show current SSH and login sessions       ║
║  ${COLORS[CYAN]}[6]${COLORS[RESET]} User Password Policy       Configure password requirements           ║
║  ${COLORS[CYAN]}[7]${COLORS[RESET]} Sudo Privileges            Manage sudo access and permissions        ║
║  ${COLORS[CYAN]}[8]${COLORS[RESET]} Bulk User Operations       Import/export users from CSV              ║
║                                                                              ║
║  ${COLORS[CYAN]}[0]${COLORS[RESET]} Back to Main Menu                                                     ║
║                                                                              ║
${COLORS[BOLD]}${COLORS[GREEN]}╚══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}

${COLORS[BOLD]}${COLORS[WHITE]}Enter your choice:${COLORS[RESET]} 
EOF
        read -r choice
        case "$choice" in
            1) add_ssh_user ;;
            2) remove_user ;;
            3) manage_ssh_keys ;;
            4) set_user_limits ;;
            5) view_active_sessions ;;
            6) user_password_policy ;;
            7) manage_sudo_privileges ;;
            8) bulk_user_operations ;;
            0) return ;;
            *) echo -e "${COLORS[RED]}Invalid option. Please try again.${COLORS[RESET]}" ; sleep 2 ;;
        esac
    done
}

# System Monitoring Menu
monitoring_menu() {
    while true; do
        show_header
        show_system_dashboard
        show_service_status
        show_network_info
        echo
        cat << EOF
${COLORS[BOLD]}${COLORS[BLUE]}╔══════════════════════════════════════════════════════════════════════════════╗
║                              SYSTEM MONITORING                               ║
╠══════════════════════════════════════════════════════════════════════════════╣${COLORS[RESET]}
║                                                                              ║
║  ${COLORS[CYAN]}[1]${COLORS[RESET]} Real-time Performance      Live CPU, memory, disk monitoring         ║
║  ${COLORS[CYAN]}[2]${COLORS[RESET]} Service Logs               View logs for all services                ║
║  ${COLORS[CYAN]}[3]${COLORS[RESET]} Network Analysis           Connection monitoring and statistics      ║
║  ${COLORS[CYAN]}[4]${COLORS[RESET]} Security Audit             Run comprehensive security scan          ║
║  ${COLORS[CYAN]}[5]${COLORS[RESET]} Resource Alerts            Configure monitoring alerts              ║
║  ${COLORS[CYAN]}[6]${COLORS[RESET]} Performance History        View historical performance data         ║
║  ${COLORS[CYAN]}[7]${COLORS[RESET]} Log Analysis               Advanced log parsing and filtering       ║
║                                                                              ║
║  ${COLORS[CYAN]}[R]${COLORS[RESET]} Auto-refresh (30s)         Enable automatic dashboard refresh       ║
║  ${COLORS[CYAN]}[0]${COLORS[RESET]} Back to Main Menu                                                    ║
║                                                                              ║
${COLORS[BOLD]}${COLORS[BLUE]}╚══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}

${COLORS[BOLD]}${COLORS[WHITE]}Enter your choice:${COLORS[RESET]} 
EOF
        read -r choice
        case "$choice" in
            1) real_time_performance ;;
            2) view_service_logs ;;
            3) network_analysis ;;
            4) security_audit ;;
            5) resource_alerts ;;
            6) performance_history ;;
            7) log_analysis ;;
            [Rr]) auto_refresh_mode ;;
            0) return ;;
            *) echo -e "${COLORS[RED]}Invalid option. Please try again.${COLORS[RESET]}" ; sleep 2 ;;
        esac
    done
}

# Enhanced function implementations
manage_python_proxy() {
    clear
    echo -e "${COLORS[BOLD]}${COLORS[PURPLE]}Python Proxy Suite Management${COLORS[RESET]}"
    echo "════════════════════════════════════════"
    echo
    
    local status=$(systemctl is-active python-proxy 2>/dev/null || echo "inactive")
    echo -e "Current Status: $(get_service_status "python-proxy")"
    echo
    
    if [ "$status" = "active" ]; then
        echo "Proxy is running. Available actions:"
        echo "  [1] Stop service"
        echo "  [2] Restart service"
        echo "  [3] View logs"
        echo "  [4] View connections"
        echo "  [0] Back"
        echo
        read -p "Choice: " action
        case "$action" in
            1) systemctl stop python-proxy && echo "Service stopped" ;;
            2) systemctl restart python-proxy && echo "Service restarted" ;;
            3) journalctl -u python-proxy -f ;;
            4) ss -tuln | grep -E ":8080|:8888|:8443" ;;
        esac
    else
        echo "Proxy is not running. Available actions:"
        echo "  [1] Start service"
        echo "  [2] Enable auto-start"
        echo "  [3] Check configuration"
        echo "  [0] Back"
        echo
        read -p "Choice: " action
        case "$action" in
            1) systemctl start python-proxy && echo "Service started" ;;
            2) systemctl enable python-proxy && echo "Auto-start enabled" ;;
            3) python3 -m py_compile "$MASTERMIND_HOME/protocols/python_proxy.py" && echo "Configuration OK" ;;
        esac
    fi
    
    read -p "Press Enter to continue..."
}

add_ssh_user() {
    clear
    echo -e "${COLORS[BOLD]}${COLORS[GREEN]}Add New SSH User${COLORS[RESET]}"
    echo "══════════════════════"
    echo
    
    read -p "Username: " username
    if [ -z "$username" ]; then
        echo "Username cannot be empty"
        return
    fi
    
    if id "$username" &>/dev/null; then
        echo "User already exists"
        return
    fi
    
    read -p "Create with sudo privileges? (y/N): " sudo_access
    read -p "Set password? (Y/n): " set_password
    
    # Create user
    if [[ "$sudo_access" =~ ^[Yy]$ ]]; then
        useradd -m -s /bin/bash -G sudo "$username"
        echo "User $username created with sudo access"
    else
        useradd -m -s /bin/bash "$username"
        echo "User $username created"
    fi
    
    # Set password
    if [[ ! "$set_password" =~ ^[Nn]$ ]]; then
        passwd "$username"
    fi
    
    # SSH key setup
    read -p "Add SSH public key? (y/N): " add_key
    if [[ "$add_key" =~ ^[Yy]$ ]]; then
        echo "Paste the SSH public key:"
        read -r ssh_key
        
        user_home="/home/$username"
        mkdir -p "$user_home/.ssh"
        echo "$ssh_key" >> "$user_home/.ssh/authorized_keys"
        chmod 700 "$user_home/.ssh"
        chmod 600 "$user_home/.ssh/authorized_keys"
        chown -R "$username:$username" "$user_home/.ssh"
        
        echo "SSH key added successfully"
    fi
    
    echo "User setup completed!"
    read -p "Press Enter to continue..."
}

view_active_sessions() {
    clear
    echo -e "${COLORS[BOLD]}${COLORS[BLUE]}Active Sessions${COLORS[RESET]}"
    echo "═══════════════════"
    echo
    
    echo "Current SSH Sessions:"
    echo "─────────────────────"
    who -u | while IFS= read -r line; do
        echo "  $line"
    done
    echo
    
    echo "Last 10 Login Attempts:"
    echo "───────────────────────"
    last -n 10 | head -10
    echo
    
    echo "Failed Login Attempts (Last 24h):"
    echo "──────────────────────────────────"
    grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | tail -5 || echo "  No failed attempts found"
    
    read -p "Press Enter to continue..."
}

real_time_performance() {
    clear
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}Real-time Performance Monitor${COLORS[RESET]}"
    echo "Press Ctrl+C to exit"
    echo
    
    while true; do
        clear
        show_header
        show_system_dashboard
        echo
        echo "Top Processes by CPU:"
        echo "─────────────────────"
        ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "  %-10s %5s%% %5s%% %s\n", $1, $3, $4, $11}'
        echo
        echo "Top Processes by Memory:"
        echo "────────────────────────"
        ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "  %-10s %5s%% %5s%% %s\n", $1, $3, $4, $11}'
        echo
        echo "Network Connections:"
        echo "───────────────────"
        ss -tuln | grep LISTEN | wc -l | xargs echo "  Listening ports:"
        
        sleep 3
    done
}

auto_refresh_mode() {
    clear
    echo -e "${COLORS[BOLD]}${COLORS[YELLOW]}Auto-refresh Mode Enabled${COLORS[RESET]}"
    echo "Dashboard will refresh every 30 seconds"
    echo "Press Ctrl+C to exit auto-refresh"
    echo
    
    while true; do
        show_header
        show_system_dashboard
        show_service_status
        show_network_info
        show_user_info
        echo
        echo -e "${COLORS[DIM]}Auto-refreshing in 30 seconds... (Ctrl+C to stop)${COLORS[RESET]}"
        
        sleep 30
    done
}

# Main application loop
main() {
    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ]; then
        echo -e "${COLORS[RED]}This script requires root privileges. Please run with sudo.${COLORS[RESET]}"
        exit 1
    fi
    
    # Ensure required commands are available
    for cmd in systemctl ss who ps top free df; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${COLORS[RED]}Required command '$cmd' not found.${COLORS[RESET]}"
            exit 1
        fi
    done
    
    # Main menu loop
    while true; do
        show_header
        show_system_dashboard
        show_service_status
        echo
        show_main_menu
        
        read -r choice
        case "$choice" in
            1) protocol_management_menu ;;
            2) echo "Network Optimization - Coming soon!" ; sleep 2 ;;
            3) user_management_menu ;;
            4) echo "Security Center - Coming soon!" ; sleep 2 ;;
            5) monitoring_menu ;;
            6) echo "Branding & QR Codes - Coming soon!" ; sleep 2 ;;
            7) echo "Domain & SSL - Coming soon!" ; sleep 2 ;;
            8) echo "System Tools - Coming soon!" ; sleep 2 ;;
            [Rr]) continue ;;
            0) 
                clear
                echo -e "${COLORS[CYAN]}Thank you for using Mastermind VPS Toolkit!${COLORS[RESET]}"
                echo -e "${COLORS[YELLOW]}Stay secure, stay connected.${COLORS[RESET]}"
                exit 0
                ;;
            *) 
                echo -e "${COLORS[RED]}Invalid option. Please try again.${COLORS[RESET]}"
                sleep 2
                ;;
        esac
    done
}

# Error handling
trap 'echo -e "\n${COLORS[RED]}Script interrupted.${COLORS[RESET]}" ; exit 1' INT

# Start the application
main "$@"