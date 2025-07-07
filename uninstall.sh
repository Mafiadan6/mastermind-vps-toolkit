#!/bin/bash

# MasterMind VPS Toolkit - Complete Uninstall Script
# Version: 5.1.0
# This script completely removes all traces of the toolkit

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
MASTERMIND_HOME="/opt/mastermind"
LOG_DIR="/var/log/mastermind"
BACKUP_DIR="/opt/mastermind/backups"

echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                    MasterMind VPS Toolkit - UNINSTALL                       ║${NC}"
echo -e "${RED}║                         Complete System Removal                             ║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo

# Confirm uninstallation
echo -e "${YELLOW}⚠️  WARNING: This will completely remove MasterMind VPS Toolkit${NC}"
echo -e "${WHITE}The following will be removed:${NC}"
echo -e "  • All proxy services (SOCKS5, WebSocket, HTTP)"
echo -e "  • Response servers (ports 9000-9003)"
echo -e "  • V2Ray configuration"
echo -e "  • SSH banners and MOTD"
echo -e "  • All user accounts created by the toolkit"
echo -e "  • Firewall rules and fail2ban configurations"
echo -e "  • System service files"
echo -e "  • Log files and backups"
echo -e "  • All toolkit files in /opt/mastermind"
echo

read -p "Are you sure you want to completely uninstall MasterMind VPS Toolkit? (type 'REMOVE' to confirm): " confirmation
if [ "$confirmation" != "REMOVE" ]; then
    echo -e "${GREEN}Uninstallation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}🚀 Starting complete uninstallation...${NC}"
echo

# Function to log actions
log_action() {
    echo -e "${CYAN}[$(date)] $1${NC}"
}

# 1. Stop and disable all services
log_action "Stopping and disabling services..."
services=("python-proxy" "v2ray" "dropbear" "squid" "openvpn" "nginx")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        systemctl stop "$service" 2>/dev/null || true
        echo -e "  ${GREEN}✓ Stopped $service${NC}"
    fi
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        systemctl disable "$service" 2>/dev/null || true
        echo -e "  ${GREEN}✓ Disabled $service${NC}"
    fi
done

# 2. Remove systemd service files
log_action "Removing systemd service files..."
service_files=(
    "/etc/systemd/system/python-proxy.service"
    "/etc/systemd/system/mastermind-proxy.service"
    "/etc/systemd/system/mastermind-v2ray.service"
    "/etc/systemd/system/mastermind-monitor.service"
)
for file in "${service_files[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo -e "  ${GREEN}✓ Removed $file${NC}"
    fi
done
systemctl daemon-reload

# 3. Close all open ports and remove firewall rules
log_action "Closing ports and removing firewall rules..."
ports=(22 80 443 1080 8080 8888 9000 9001 9002 9003 444 445)

# UFW rules
if command -v ufw >/dev/null 2>&1; then
    for port in "${ports[@]}"; do
        ufw --force delete allow "$port" 2>/dev/null || true
    done
    echo -e "  ${GREEN}✓ Removed UFW rules${NC}"
fi

# iptables rules (backup and restore original)
if command -v iptables >/dev/null 2>&1; then
    # Save current rules for safety
    iptables-save > /tmp/iptables-before-mastermind-removal.bak 2>/dev/null || true
    
    # Remove common MasterMind rules
    for port in "${ports[@]}"; do
        iptables -D INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -p udp --dport "$port" -j ACCEPT 2>/dev/null || true
    done
    echo -e "  ${GREEN}✓ Removed iptables rules${NC}"
fi

# 4. Kill any running proxy processes
log_action "Terminating proxy processes..."
processes=("python3.*proxy" "v2ray" "dropbear" "squid" "openvpn")
for process in "${processes[@]}"; do
    pkill -f "$process" 2>/dev/null || true
done

# Kill processes on specific ports
for port in 1080 8080 8888 9000 9001 9002 9003; do
    lsof -ti:$port | xargs kill -9 2>/dev/null || true
done
echo -e "  ${GREEN}✓ Terminated all proxy processes${NC}"

# 5. Remove SSH banners and MOTD
log_action "Removing SSH banners and MOTD..."
files_to_remove=(
    "/etc/ssh/mastermind_banner"
    "/etc/motd.mastermind"
    "/etc/update-motd.d/01-mastermind"
    "/etc/update-motd.d/99-mastermind"
)
for file in "${files_to_remove[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo -e "  ${GREEN}✓ Removed $file${NC}"
    fi
done

# Restore original SSH config
if [ -f "/etc/ssh/sshd_config" ]; then
    # Remove MasterMind banner lines
    sed -i '/Banner.*mastermind/d' /etc/ssh/sshd_config 2>/dev/null || true
    # Restart SSH if changes were made
    if systemctl is-active --quiet ssh 2>/dev/null; then
        systemctl restart ssh
        echo -e "  ${GREEN}✓ Restored SSH configuration${NC}"
    fi
fi

# 6. Remove user accounts created by MasterMind
log_action "Removing MasterMind user accounts..."
if [ -f "$MASTERMIND_HOME/users/.created_users" ]; then
    while read -r username; do
        if [ -n "$username" ] && id "$username" >/dev/null 2>&1; then
            userdel -r "$username" 2>/dev/null || true
            echo -e "  ${GREEN}✓ Removed user: $username${NC}"
        fi
    done < "$MASTERMIND_HOME/users/.created_users"
fi

# Remove the mastermind system user if it exists
if id "mastermind" >/dev/null 2>&1; then
    userdel -r mastermind 2>/dev/null || true
    echo -e "  ${GREEN}✓ Removed mastermind system user${NC}"
fi

# 7. Remove cron jobs
log_action "Removing cron jobs..."
crontab -l 2>/dev/null | grep -v "mastermind\|MASTERMIND" | crontab - 2>/dev/null || true
echo -e "  ${GREEN}✓ Removed cron jobs${NC}"

# 8. Remove fail2ban configurations
log_action "Removing fail2ban configurations..."
fail2ban_files=(
    "/etc/fail2ban/jail.d/mastermind.conf"
    "/etc/fail2ban/filter.d/mastermind.conf"
    "/etc/fail2ban/action.d/mastermind.conf"
)
for file in "${fail2ban_files[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo -e "  ${GREEN}✓ Removed $file${NC}"
    fi
done

if systemctl is-active --quiet fail2ban 2>/dev/null; then
    systemctl restart fail2ban 2>/dev/null || true
    echo -e "  ${GREEN}✓ Restarted fail2ban${NC}"
fi

# 9. Remove nginx/apache configurations
log_action "Removing web server configurations..."
nginx_files=(
    "/etc/nginx/sites-available/mastermind"
    "/etc/nginx/sites-enabled/mastermind"
    "/etc/nginx/conf.d/mastermind.conf"
)
for file in "${nginx_files[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo -e "  ${GREEN}✓ Removed $file${NC}"
    fi
done

if systemctl is-active --quiet nginx 2>/dev/null; then
    nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null || true
fi

# 10. Remove SSL certificates
log_action "Removing SSL certificates..."
cert_dirs=(
    "/etc/letsencrypt/live/mastermind*"
    "/etc/ssl/mastermind"
    "/opt/mastermind/ssl"
)
for dir in "${cert_dirs[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo -e "  ${GREEN}✓ Removed SSL certificates in $dir${NC}"
    fi
done

# 11. Remove Python packages and dependencies
log_action "Removing Python packages..."
python_packages=("websockets" "qrcode" "pillow" "cryptography")
for package in "${python_packages[@]}"; do
    pip3 uninstall -y "$package" 2>/dev/null || true
done
echo -e "  ${GREEN}✓ Removed Python packages${NC}"

# 12. Remove log files and backups
log_action "Removing log files and backups..."
dirs_to_remove=(
    "$LOG_DIR"
    "$BACKUP_DIR"
    "/var/backups/mastermind"
    "/tmp/mastermind*"
)
for dir in "${dirs_to_remove[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo -e "  ${GREEN}✓ Removed $dir${NC}"
    fi
done

# Remove log entries from syslog
if [ -f "/var/log/syslog" ]; then
    sed -i '/mastermind\|MASTERMIND/d' /var/log/syslog 2>/dev/null || true
fi

# 13. Remove main installation directory
log_action "Removing main installation directory..."
if [ -d "$MASTERMIND_HOME" ]; then
    rm -rf "$MASTERMIND_HOME"
    echo -e "  ${GREEN}✓ Removed $MASTERMIND_HOME${NC}"
fi

# 14. Remove environment variables
log_action "Removing environment variables..."
env_files=(
    "/etc/environment"
    "/etc/profile.d/mastermind.sh"
    "/root/.bashrc"
    "/home/*/.bashrc"
)
for file in ${env_files[@]}; do
    if [ -f "$file" ]; then
        sed -i '/MASTERMIND\|mastermind/d' "$file" 2>/dev/null || true
    fi
done
echo -e "  ${GREEN}✓ Removed environment variables${NC}"

# 15. Clean package cache
log_action "Cleaning package cache..."
if command -v apt >/dev/null 2>&1; then
    apt autoremove -y 2>/dev/null || true
    apt autoclean 2>/dev/null || true
fi
echo -e "  ${GREEN}✓ Cleaned package cache${NC}"

# 16. Reset network configuration
log_action "Resetting network configuration..."
# Remove any custom network configurations
if [ -f "/etc/sysctl.d/99-mastermind.conf" ]; then
    rm -f "/etc/sysctl.d/99-mastermind.conf"
    sysctl --system 2>/dev/null || true
    echo -e "  ${GREEN}✓ Reset network configuration${NC}"
fi

# 17. Final cleanup and verification
log_action "Performing final cleanup..."

# Remove any remaining files with mastermind in the name
find /etc /var /opt /usr -name "*mastermind*" -type f -delete 2>/dev/null || true
find /etc /var /opt /usr -name "*MASTERMIND*" -type f -delete 2>/dev/null || true

# Remove empty directories
find /etc /var /opt /usr -name "*mastermind*" -type d -empty -delete 2>/dev/null || true

echo -e "  ${GREEN}✓ Final cleanup completed${NC}"

# 18. Verification
echo
log_action "Verifying removal..."
verification_passed=true

# Check for remaining processes
if pgrep -f "mastermind\|python.*proxy" >/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠ Warning: Some processes may still be running${NC}"
    verification_passed=false
fi

# Check for remaining open ports
for port in 1080 8080 8888 9000 9001 9002 9003; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "  ${YELLOW}⚠ Warning: Port $port is still open${NC}"
        verification_passed=false
    fi
done

# Check for remaining files
if [ -d "$MASTERMIND_HOME" ] || [ -d "$LOG_DIR" ]; then
    echo -e "  ${YELLOW}⚠ Warning: Some directories may still exist${NC}"
    verification_passed=false
fi

if [ "$verification_passed" = true ]; then
    echo -e "  ${GREEN}✓ All components successfully removed${NC}"
else
    echo -e "  ${YELLOW}⚠ Some components may require manual removal${NC}"
fi

echo
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                        UNINSTALLATION COMPLETED                             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${WHITE}MasterMind VPS Toolkit has been completely removed from your system.${NC}"
echo
echo -e "${CYAN}What was removed:${NC}"
echo -e "  ✓ All proxy services and configurations"
echo -e "  ✓ Open ports closed and firewall rules removed"
echo -e "  ✓ SSH banners and MOTD restored"
echo -e "  ✓ User accounts and access removed"
echo -e "  ✓ System services and cron jobs removed"
echo -e "  ✓ Log files and backups deleted"
echo -e "  ✓ SSL certificates and configurations removed"
echo -e "  ✓ All toolkit files and directories deleted"
echo
echo -e "${WHITE}Your system has been restored to its pre-installation state.${NC}"
echo -e "${WHITE}Thank you for using MasterMind VPS Toolkit!${NC}"
echo

# Reboot recommendation
echo -e "${YELLOW}📋 Recommendation: Reboot your system to ensure all changes take effect.${NC}"
read -p "Would you like to reboot now? (y/N): " reboot_choice
if [[ $reboot_choice =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Rebooting system in 10 seconds... Press Ctrl+C to cancel.${NC}"
    sleep 10
    reboot
fi

echo -e "${GREEN}Uninstallation script completed successfully.${NC}"