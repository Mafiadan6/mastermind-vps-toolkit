#!/bin/bash

# Mastermind VPS Toolkit - Demo Version for Replit
# This demonstrates the menu system without requiring root access

set -e

# Enhanced Color Palette
declare -A COLORS=(
    ["RESET"]='\033[0m'
    ["BOLD"]='\033[1m'
    ["GREEN"]='\033[0;92m'
    ["BRIGHT_BLUE"]='\033[0;94m'
    ["BRIGHT_CYAN"]='\033[0;96m'
    ["BRIGHT_YELLOW"]='\033[0;93m'
    ["BRIGHT_RED"]='\033[0;91m'
    ["BRIGHT_WHITE"]='\033[0;97m'
    ["CYAN"]='\033[0;36m'
    ["YELLOW"]='\033[0;33m'
    ["RED"]='\033[0;31m'
    ["PURPLE"]='\033[0;35m'
)

# Configuration for demo
DEMO_MODE=true
MASTERMIND_HOME="$(pwd)"

# Helper functions
log_info() {
    echo -e "${COLORS[BRIGHT_CYAN]}[INFO]${COLORS[RESET]} $1"
}

log_success() {
    echo -e "${COLORS[GREEN]}[SUCCESS]${COLORS[RESET]} $1"
}

log_warning() {
    echo -e "${COLORS[BRIGHT_YELLOW]}[WARNING]${COLORS[RESET]} $1"
}

log_error() {
    echo -e "${COLORS[BRIGHT_RED]}[ERROR]${COLORS[RESET]} $1"
}

wait_for_key() {
    echo
    echo -e "${COLORS[BRIGHT_WHITE]}Press any key to continue...${COLORS[RESET]}"
    read -n 1 -s
}

# Banner function
show_banner() {
    clear
    echo -e "${COLORS[BRIGHT_CYAN]}"
    cat << "EOF"
    ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██████╗ 
    ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗
    ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║  ██║
    ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║  ██║
    ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██████╔╝
    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝ 
EOF
    echo -e "${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_WHITE]}                              VPS TOOLKIT v3.0.0 - DEMO MODE${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_YELLOW]}                           Advanced VPS Management Suite${COLORS[RESET]}"
    echo
}

# System info for demo
show_system_info() {
    local cpu_usage="$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}' || echo "N/A")"
    local memory_info="$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}' || echo "N/A")"
    local disk_usage="$(df -h / | awk 'NR==2{printf "%s", $5}' || echo "N/A")"
    local uptime_info="$(uptime | awk -F',' '{print $1}' | awk '{print $3,$4}' || echo "N/A")"
    
    echo -e "${COLORS[BRIGHT_CYAN]}╔══════════════════════════════════════════════════════════════════════════════╗${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[BRIGHT_WHITE]}                              SYSTEM STATUS                                ║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_CYAN]}╚══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
    echo
    echo -e "   ${COLORS[BRIGHT_YELLOW]}🖥️  CPU Usage:${COLORS[RESET]}     ${cpu_usage}%"
    echo -e "   ${COLORS[BRIGHT_YELLOW]}💾 Memory Usage:${COLORS[RESET]}   ${memory_info}%"
    echo -e "   ${COLORS[BRIGHT_YELLOW]}💿 Disk Usage:${COLORS[RESET]}     ${disk_usage}"
    echo -e "   ${COLORS[BRIGHT_YELLOW]}⏰ Uptime:${COLORS[RESET]}         ${uptime_info}"
    echo -e "   ${COLORS[BRIGHT_YELLOW]}🌐 Public IP:${COLORS[RESET]}      $(curl -s ifconfig.me 2>/dev/null || echo "Demo Mode")"
    echo
}

# Main menu
show_main_menu() {
    show_banner
    show_system_info
    
    echo -e "${COLORS[BRIGHT_CYAN]}╔══════════════════════════════════════════════════════════════════════════════╗${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[BRIGHT_WHITE]}                               MAIN MENU                                  ║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_CYAN]}╚══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
    echo
    echo -e "   ${COLORS[BRIGHT_GREEN]}[1]${COLORS[RESET]} 🔧 ${COLORS[BRIGHT_WHITE]}System Management${COLORS[RESET]}     - Core system administration"
    echo -e "   ${COLORS[BRIGHT_GREEN]}[2]${COLORS[RESET]} 🌐 ${COLORS[BRIGHT_WHITE]}Network Tools${COLORS[RESET]}         - Network optimization & monitoring"
    echo -e "   ${COLORS[BRIGHT_GREEN]}[3]${COLORS[RESET]} 🔒 ${COLORS[BRIGHT_WHITE]}Security Suite${COLORS[RESET]}        - Security auditing & hardening"
    echo -e "   ${COLORS[BRIGHT_GREEN]}[4]${COLORS[RESET]} 👥 ${COLORS[BRIGHT_WHITE]}User Management${COLORS[RESET]}       - Account & permission management"
    echo -e "   ${COLORS[BRIGHT_GREEN]}[5]${COLORS[RESET]} 🚀 ${COLORS[BRIGHT_WHITE]}Protocol Manager${COLORS[RESET]}      - Proxy & VPN configurations"
    echo -e "   ${COLORS[BRIGHT_GREEN]}[6]${COLORS[RESET]} 📱 ${COLORS[BRIGHT_WHITE]}QR Code Generator${COLORS[RESET]}     - Generate connection QR codes"
    echo -e "   ${COLORS[BRIGHT_GREEN]}[7]${COLORS[RESET]} 🎨 ${COLORS[BRIGHT_WHITE]}Branding & Banners${COLORS[RESET]}    - Customize system appearance"
    echo -e "   ${COLORS[BRIGHT_GREEN]}[8]${COLORS[RESET]} 📊 ${COLORS[BRIGHT_WHITE]}System Monitor${COLORS[RESET]}        - Real-time system monitoring"
    echo -e "   ${COLORS[BRIGHT_GREEN]}[9]${COLORS[RESET]} ⚙️  ${COLORS[BRIGHT_WHITE]}Configuration${COLORS[RESET]}        - Toolkit settings & preferences"
    echo
    echo -e "   ${COLORS[BRIGHT_YELLOW]}[0]${COLORS[RESET]} 🚪 ${COLORS[BRIGHT_WHITE]}Exit Toolkit${COLORS[RESET]}"
    echo
    echo -e "${COLORS[BRIGHT_CYAN]}══════════════════════════════════════════════════════════════════════════════${COLORS[RESET]}"
}

# Demo functions
demo_system_management() {
    clear
    echo -e "${COLORS[BRIGHT_CYAN]}╔══════════════════════════════════════════════════════════════════════════════╗${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[BRIGHT_WHITE]}                            SYSTEM MANAGEMENT                             ║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_CYAN]}╚══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
    echo
    
    log_info "Demonstrating system management features..."
    echo
    echo -e "   ${COLORS[BRIGHT_GREEN]}✓${COLORS[RESET]} System update check"
    echo -e "   ${COLORS[BRIGHT_GREEN]}✓${COLORS[RESET]} Service status monitoring"
    echo -e "   ${COLORS[BRIGHT_GREEN]}✓${COLORS[RESET]} Log file analysis"
    echo -e "   ${COLORS[BRIGHT_GREEN]}✓${COLORS[RESET]} Performance optimization"
    echo
    log_success "System management features ready"
    wait_for_key
}

demo_network_tools() {
    clear
    echo -e "${COLORS[BRIGHT_CYAN]}╔══════════════════════════════════════════════════════════════════════════════╗${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[BRIGHT_WHITE]}                              NETWORK TOOLS                               ║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_CYAN]}╚══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
    echo
    
    log_info "Demonstrating network optimization features..."
    echo
    echo -e "   ${COLORS[BRIGHT_GREEN]}✓${COLORS[RESET]} BBR congestion control"
    echo -e "   ${COLORS[BRIGHT_GREEN]}✓${COLORS[RESET]} Kernel parameter tuning"
    echo -e "   ${COLORS[BRIGHT_GREEN]}✓${COLORS[RESET]} UDP optimization"
    echo -e "   ${COLORS[BRIGHT_GREEN]}✓${COLORS[RESET]} Network speed testing"
    echo
    log_success "Network tools initialized"
    wait_for_key
}

demo_qr_generator() {
    clear
    echo -e "${COLORS[BRIGHT_CYAN]}╔══════════════════════════════════════════════════════════════════════════════╗${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_CYAN]}║${COLORS[BRIGHT_WHITE]}                             QR CODE GENERATOR                            ║${COLORS[RESET]}"
    echo -e "${COLORS[BRIGHT_CYAN]}╚══════════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
    echo
    
    log_info "Generating demo QR code..."
    echo
    
    # Create a simple QR code
    echo "Demo VPS Configuration: ssh://demo@example.com:22" | qrencode -t UTF8 2>/dev/null || {
        echo -e "   ${COLORS[BRIGHT_YELLOW]}█████████████████████████${COLORS[RESET]}"
        echo -e "   ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}       ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}   ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}       ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}"
        echo -e "   ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█████${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█████${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}"
        echo -e "   ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}   ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}   ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}"
        echo -e "   ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█████${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█████${COLORS[RESET]} ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}"
        echo -e "   ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}       ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}   ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}       ${COLORS[BRIGHT_YELLOW]}█${COLORS[RESET]}"
        echo -e "   ${COLORS[BRIGHT_YELLOW]}█████████████████████████${COLORS[RESET]}"
        echo
        echo -e "   ${COLORS[BRIGHT_WHITE]}Demo QR Code: SSH Connection${COLORS[RESET]}"
    }
    
    echo
    log_success "QR code generated successfully"
    wait_for_key
}

# Main program loop
main() {
    while true; do
        show_main_menu
        echo -n -e "${COLORS[BRIGHT_WHITE]}Choose option [0-9]: ${COLORS[RESET]}"
        read -r choice
        
        case $choice in
            1)
                demo_system_management
                ;;
            2)
                demo_network_tools
                ;;
            3)
                clear
                log_info "Security suite demo - Firewall, fail2ban, audit tools"
                wait_for_key
                ;;
            4)
                clear
                log_info "User management demo - Account creation, permissions"
                wait_for_key
                ;;
            5)
                clear
                log_info "Protocol manager demo - SOCKS5, V2Ray, SSH tunnels"
                wait_for_key
                ;;
            6)
                demo_qr_generator
                ;;
            7)
                clear
                log_info "Branding & banners demo - Custom SSH banners, themes"
                wait_for_key
                ;;
            8)
                clear
                log_info "System monitor demo - Real-time resource monitoring"
                wait_for_key
                ;;
            9)
                clear
                log_info "Configuration demo - Toolkit settings and preferences"
                wait_for_key
                ;;
            0)
                clear
                log_success "Thank you for using Mastermind VPS Toolkit!"
                echo
                echo -e "${COLORS[BRIGHT_CYAN]}For full functionality, install on Ubuntu/Debian VPS:${COLORS[RESET]}"
                echo -e "${COLORS[BRIGHT_WHITE]}curl -sSL https://raw.githubusercontent.com/mafiadan6/mastermind-vps-toolkit/main/install.sh | sudo bash${COLORS[RESET]}"
                echo
                exit 0
                ;;
            *)
                clear
                log_error "Invalid option. Please choose 0-9."
                sleep 2
                ;;
        esac
    done
}

# Start the demo
main