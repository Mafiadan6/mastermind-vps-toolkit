#!/bin/bash

# Mastermind VPS Toolkit - Main Menu
# Version: 1.0.0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Load configuration
source /opt/mastermind/core/config.cfg
source /opt/mastermind/core/helpers.sh

# Main menu display
show_main_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           MASTERMIND VPS TOOLKIT                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}  [1] Protocol Management${NC}"
    echo -e "    ${CYAN}[1a]${NC} V2Ray (VLESS/VMESS)"
    echo -e "    ${CYAN}[1b]${NC} SSH Ecosystem (Dropbear/SSH-UDP)"
    echo -e "    ${CYAN}[1c]${NC} Python Proxy Suite ${GREEN}★${NC}"
    echo -e "    ${CYAN}[1d]${NC} TCP Bypass Proxy ${GREEN}★${NC}"
    echo -e "    ${CYAN}[1e]${NC} BadVPN Setup"
    echo
    echo -e "${YELLOW}  [2] Network Optimization${NC}"
    echo -e "    ${CYAN}[2a]${NC} Enable/Disable TCP BBR"
    echo -e "    ${CYAN}[2b]${NC} Kernel Tuning"
    echo -e "    ${CYAN}[2c]${NC} UDP Optimization"
    echo
    echo -e "${YELLOW}  [3] User Administration${NC}"
    echo -e "    ${CYAN}[3a]${NC} Add SSH User"
    echo -e "    ${CYAN}[3b]${NC} Remove User"
    echo -e "    ${CYAN}[3c]${NC} Manage Access"
    echo
    echo -e "${YELLOW}  [4] Domain & Certificates${NC}"
    echo -e "    ${CYAN}[4a]${NC} Domain Setup"
    echo -e "    ${CYAN}[4b]${NC} SSL Certificates"
    echo -e "    ${CYAN}[4c]${NC} Auto-Renewal"
    echo
    echo -e "${YELLOW}  [5] Security Center${NC}"
    echo -e "    ${CYAN}[5a]${NC} Firewall Config"
    echo -e "    ${CYAN}[5b]${NC} Fail2Ban Setup"
    echo -e "    ${CYAN}[5c]${NC} Security Audit"
    echo
    echo -e "${YELLOW}  [6] Service Controls${NC}"
    echo -e "    ${CYAN}[6a]${NC} Start/Stop Services"
    echo -e "    ${CYAN}[6b]${NC} Service Status"
    echo -e "    ${CYAN}[6c]${NC} Log Viewer"
    echo
    echo -e "${YELLOW}  [7] Custom Branding${NC}"
    echo -e "    ${CYAN}[7a]${NC} SSH Connection Banner ${GREEN}★${NC}"
    echo -e "    ${CYAN}[7b]${NC} HTTP Response Messages"
    echo -e "    ${CYAN}[7c]${NC} QR Code Generator"
    echo
    echo -e "${YELLOW}  [8] Backup & Restore${NC}"
    echo -e "    ${CYAN}[8a]${NC} Create Backup"
    echo -e "    ${CYAN}[8b]${NC} Restore Config"
    echo -e "    ${CYAN}[8c]${NC} System Snapshots"
    echo
    echo -e "${YELLOW}  [9] Monitoring Dashboard${NC}"
    echo -e "    ${CYAN}[9a]${NC} Connection Stats"
    echo -e "    ${CYAN}[9b]${NC} Bandwidth Usage"
    echo -e "    ${CYAN}[9c]${NC} Service Health"
    echo
    echo -e "${YELLOW}  [0] Exit System${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}Server: ${GREEN}$(hostname)${NC} | IP: ${GREEN}$(get_public_ip)${NC} | Uptime: ${GREEN}$(uptime -p)${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Protocol Management Menu
protocol_menu() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           PROTOCOL MANAGEMENT                               ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] V2Ray Management${NC}"
        echo -e "${YELLOW}  [2] SSH Ecosystem${NC}"
        echo -e "${YELLOW}  [3] Python Proxy Suite${NC}"
        echo -e "${YELLOW}  [4] TCP Bypass Proxy${NC}"
        echo -e "${YELLOW}  [5] BadVPN Setup${NC}"
        echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) /opt/mastermind/protocols/v2ray_manager.sh ;;
            2) /opt/mastermind/protocols/ssh_suite.sh ;;
            3) /opt/mastermind/protocols/proxy_manager.sh ;;
            4) /opt/mastermind/protocols/tcp_bypass.sh ;;
            5) /opt/mastermind/protocols/badvpn_setup.sh ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Network Optimization Menu
network_menu() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           NETWORK OPTIMIZATION                              ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] TCP BBR Management${NC}"
        echo -e "${YELLOW}  [2] Kernel Tuning${NC}"
        echo -e "${YELLOW}  [3] UDP Optimization${NC}"
        echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-3]: " choice
        
        case $choice in
            1) /opt/mastermind/network/bbr.sh ;;
            2) /opt/mastermind/network/kernel_tuning.sh ;;
            3) /opt/mastermind/network/udp_optimizer.sh ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# User Administration Menu
user_menu() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           USER ADMINISTRATION                               ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] Add SSH User${NC}"
        echo -e "${YELLOW}  [2] Remove User${NC}"
        echo -e "${YELLOW}  [3] Manage Access${NC}"
        echo -e "${YELLOW}  [4] Quota Management${NC}"
        echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-4]: " choice
        
        case $choice in
            1) /opt/mastermind/users/user_manager.sh add ;;
            2) /opt/mastermind/users/user_manager.sh remove ;;
            3) /opt/mastermind/users/access_controls.sh ;;
            4) /opt/mastermind/users/quota_manager.sh ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Security Center Menu
security_menu() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             SECURITY CENTER                                 ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] Firewall Configuration${NC}"
        echo -e "${YELLOW}  [2] Fail2Ban Setup${NC}"
        echo -e "${YELLOW}  [3] Security Audit${NC}"
        echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-3]: " choice
        
        case $choice in
            1) /opt/mastermind/security/firewall_manager.sh ;;
            2) /opt/mastermind/security/fail2ban_setup.sh ;;
            3) /opt/mastermind/security/audit_tool.sh ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Service Controls Menu
service_menu() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             SERVICE CONTROLS                                ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] Start/Stop Services${NC}"
        echo -e "${YELLOW}  [2] Service Status${NC}"
        echo -e "${YELLOW}  [3] Log Viewer${NC}"
        echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-3]: " choice
        
        case $choice in
            1) /opt/mastermind/core/service_ctl.sh ;;
            2) /opt/mastermind/core/service_ctl.sh status ;;
            3) /opt/mastermind/monitoring/dashboard.sh logs ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Custom Branding Menu
branding_menu() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             CUSTOM BRANDING                                 ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] SSH Connection Banner${NC}"
        echo -e "${YELLOW}  [2] HTTP Response Messages${NC}"
        echo -e "${YELLOW}  [3] QR Code Generator${NC}"
        echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-3]: " choice
        
        case $choice in
            1) /opt/mastermind/branding/banner_generator.sh ;;
            2) /opt/mastermind/branding/response_servers.py ;;
            3) /opt/mastermind/branding/qr_generator.py ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Monitoring Dashboard Menu
monitoring_menu() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           MONITORING DASHBOARD                              ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] Connection Stats${NC}"
        echo -e "${YELLOW}  [2] Bandwidth Usage${NC}"
        echo -e "${YELLOW}  [3] Service Health${NC}"
        echo -e "${YELLOW}  [4] Real-time Monitor${NC}"
        echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-4]: " choice
        
        case $choice in
            1) /opt/mastermind/monitoring/dashboard.sh connections ;;
            2) /opt/mastermind/monitoring/bandwidth_logger.sh ;;
            3) /opt/mastermind/monitoring/dashboard.sh health ;;
            4) /opt/mastermind/monitoring/connection_monitor.py ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Backup & Restore Menu
backup_menu() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             BACKUP & RESTORE                                ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}  [1] Create Backup${NC}"
        echo -e "${YELLOW}  [2] Restore Configuration${NC}"
        echo -e "${YELLOW}  [3] System Snapshots${NC}"
        echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-3]: " choice
        
        case $choice in
            1) /opt/mastermind/backup/backup_system.sh ;;
            2) /opt/mastermind/backup/restore_tool.sh ;;
            3) /opt/mastermind/backup/snapshot_manager.sh ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Main menu loop
main_menu() {
    while true; do
        show_main_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) protocol_menu ;;
            2) network_menu ;;
            3) user_menu ;;
            4) echo -e "${YELLOW}Domain & Certificates feature coming soon...${NC}" ; sleep 2 ;;
            5) security_menu ;;
            6) service_menu ;;
            7) branding_menu ;;
            8) backup_menu ;;
            9) monitoring_menu ;;
            0) 
                echo -e "${GREEN}Thank you for using Mastermind VPS Toolkit!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Start the main menu
main_menu
