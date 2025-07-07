#!/bin/bash

# MasterMind VPS Toolkit - Complete Reinstall Script
# Version: 5.1.0
# This script performs a clean reinstallation

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

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                    MasterMind VPS Toolkit - REINSTALL                       ║${NC}"
echo -e "${PURPLE}║                        Complete System Reinstall                            ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${YELLOW}🔄 This script will completely reinstall MasterMind VPS Toolkit${NC}"
echo -e "${WHITE}The process includes:${NC}"
echo -e "  • Complete removal of existing installation"
echo -e "  • Fresh download of latest version"
echo -e "  • Clean installation with updated components"
echo -e "  • Restoration of proxy services"
echo -e "  • Configuration of all features"
echo

read -p "Do you want to proceed with the reinstallation? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Reinstallation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}🚀 Starting reinstallation process...${NC}"
echo

# Function to log actions
log_action() {
    echo -e "${CYAN}[$(date)] $1${NC}"
}

# 1. Backup current configuration if it exists
log_action "Backing up current configuration..."
BACKUP_DIR="/tmp/mastermind-backup-$(date +%Y%m%d-%H%M%S)"
MASTERMIND_HOME="/opt/mastermind"

if [ -d "$MASTERMIND_HOME" ]; then
    mkdir -p "$BACKUP_DIR"
    
    # Backup configuration files
    if [ -f "$MASTERMIND_HOME/core/config.cfg" ]; then
        cp "$MASTERMIND_HOME/core/config.cfg" "$BACKUP_DIR/" 2>/dev/null || true
        echo -e "  ${GREEN}✓ Backed up config.cfg${NC}"
    fi
    
    # Backup user data
    if [ -d "$MASTERMIND_HOME/users" ]; then
        cp -r "$MASTERMIND_HOME/users" "$BACKUP_DIR/" 2>/dev/null || true
        echo -e "  ${GREEN}✓ Backed up user data${NC}"
    fi
    
    # Backup SSL certificates
    if [ -d "$MASTERMIND_HOME/ssl" ]; then
        cp -r "$MASTERMIND_HOME/ssl" "$BACKUP_DIR/" 2>/dev/null || true
        echo -e "  ${GREEN}✓ Backed up SSL certificates${NC}"
    fi
    
    echo -e "  ${GREEN}✓ Configuration backed up to $BACKUP_DIR${NC}"
else
    echo -e "  ${YELLOW}No existing installation found${NC}"
fi

# 2. Run uninstall script if it exists
log_action "Removing existing installation..."
if [ -f "./uninstall.sh" ]; then
    chmod +x ./uninstall.sh
    echo "REMOVE" | ./uninstall.sh
elif [ -f "$MASTERMIND_HOME/uninstall.sh" ]; then
    chmod +x "$MASTERMIND_HOME/uninstall.sh"
    echo "REMOVE" | "$MASTERMIND_HOME/uninstall.sh"
else
    # Manual cleanup if uninstall script doesn't exist
    log_action "Manual cleanup of existing installation..."
    
    # Stop services
    services=("python-proxy" "v2ray" "dropbear" "squid" "openvpn")
    for service in "${services[@]}"; do
        systemctl stop "$service" 2>/dev/null || true
        systemctl disable "$service" 2>/dev/null || true
    done
    
    # Remove directories
    rm -rf /opt/mastermind /var/log/mastermind 2>/dev/null || true
    
    # Remove service files
    rm -f /etc/systemd/system/python-proxy.service 2>/dev/null || true
    systemctl daemon-reload
    
    echo -e "  ${GREEN}✓ Manual cleanup completed${NC}"
fi

# 3. Update system
log_action "Updating system packages..."
if command -v apt >/dev/null 2>&1; then
    apt update && apt upgrade -y
elif command -v yum >/dev/null 2>&1; then
    yum update -y
elif command -v dnf >/dev/null 2>&1; then
    dnf update -y
fi
echo -e "  ${GREEN}✓ System updated${NC}"

# 4. Download latest version
log_action "Downloading latest MasterMind VPS Toolkit..."
cd /tmp
rm -rf mastermind-vps-toolkit* 2>/dev/null || true

# Try multiple download methods
if command -v curl >/dev/null 2>&1; then
    curl -sSL https://github.com/Mafiadan6/mastermind-vps-toolkit/archive/main.zip -o mastermind-latest.zip
elif command -v wget >/dev/null 2>&1; then
    wget -q https://github.com/Mafiadan6/mastermind-vps-toolkit/archive/main.zip -O mastermind-latest.zip
else
    echo -e "${RED}Error: Neither curl nor wget is available${NC}"
    exit 1
fi

# Extract the archive
if command -v unzip >/dev/null 2>&1; then
    unzip -q mastermind-latest.zip
    cd mastermind-vps-toolkit-main
elif command -v python3 >/dev/null 2>&1; then
    python3 -m zipfile -e mastermind-latest.zip .
    cd mastermind-vps-toolkit-main
else
    echo -e "${RED}Error: Cannot extract zip file${NC}"
    exit 1
fi

echo -e "  ${GREEN}✓ Latest version downloaded${NC}"

# 5. Run fresh installation
log_action "Running fresh installation..."
chmod +x install.sh
./install.sh

echo -e "  ${GREEN}✓ Fresh installation completed${NC}"

# 6. Restore backed up configuration
if [ -d "$BACKUP_DIR" ]; then
    log_action "Restoring backed up configuration..."
    
    # Restore config.cfg
    if [ -f "$BACKUP_DIR/config.cfg" ]; then
        cp "$BACKUP_DIR/config.cfg" "/opt/mastermind/core/" 2>/dev/null || true
        echo -e "  ${GREEN}✓ Restored config.cfg${NC}"
    fi
    
    # Restore user data
    if [ -d "$BACKUP_DIR/users" ]; then
        cp -r "$BACKUP_DIR/users"/* "/opt/mastermind/users/" 2>/dev/null || true
        echo -e "  ${GREEN}✓ Restored user data${NC}"
    fi
    
    # Restore SSL certificates
    if [ -d "$BACKUP_DIR/ssl" ]; then
        cp -r "$BACKUP_DIR/ssl"/* "/opt/mastermind/ssl/" 2>/dev/null || true
        echo -e "  ${GREEN}✓ Restored SSL certificates${NC}"
    fi
    
    echo -e "  ${GREEN}✓ Configuration restored from backup${NC}"
fi

# 7. Start services
log_action "Starting services..."
systemctl daemon-reload
systemctl enable python-proxy 2>/dev/null || true
systemctl start python-proxy 2>/dev/null || true

if systemctl is-active --quiet python-proxy; then
    echo -e "  ${GREEN}✓ Proxy services started successfully${NC}"
else
    echo -e "  ${YELLOW}⚠ Warning: Proxy services may need manual configuration${NC}"
fi

# 8. Verification
log_action "Verifying installation..."
verification_passed=true

# Check if main directory exists
if [ ! -d "/opt/mastermind" ]; then
    echo -e "  ${RED}✗ Installation directory not found${NC}"
    verification_passed=false
else
    echo -e "  ${GREEN}✓ Installation directory created${NC}"
fi

# Check if main script exists
if [ ! -f "/opt/mastermind/core/menu.sh" ]; then
    echo -e "  ${RED}✗ Main menu script not found${NC}"
    verification_passed=false
else
    echo -e "  ${GREEN}✓ Main menu script available${NC}"
fi

# Check service status
if systemctl is-active --quiet python-proxy; then
    echo -e "  ${GREEN}✓ Proxy service is running${NC}"
else
    echo -e "  ${YELLOW}⚠ Proxy service needs attention${NC}"
    verification_passed=false
fi

# 9. Cleanup
log_action "Cleaning up temporary files..."
cd /
rm -rf /tmp/mastermind-latest.zip /tmp/mastermind-vps-toolkit-main 2>/dev/null || true
echo -e "  ${GREEN}✓ Temporary files cleaned${NC}"

# 10. Final status
echo
if [ "$verification_passed" = true ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                      REINSTALLATION SUCCESSFUL                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${WHITE}MasterMind VPS Toolkit has been successfully reinstalled!${NC}"
    echo
    echo -e "${CYAN}What's new in this installation:${NC}"
    echo -e "  ✓ Latest version with all recent improvements"
    echo -e "  ✓ Enhanced proxy suite with user-friendly descriptions"
    echo -e "  ✓ Quick Setup Wizard for easy configuration"
    echo -e "  ✓ Live port monitoring and service status indicators"
    echo -e "  ✓ Improved mobile app support (NPV Tunnel, HTTP Injector)"
    echo -e "  ✓ Fixed SSH user management and path resolution"
    echo -e "  ✓ Enhanced MasterMind branding across all services"
    echo
    echo -e "${YELLOW}🚀 Quick Start:${NC}"
    echo -e "${WHITE}sudo /opt/mastermind/core/menu.sh${NC}"
    echo
    echo -e "${CYAN}Configuration backup location: ${WHITE}$BACKUP_DIR${NC}"
    
else
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                  REINSTALLATION COMPLETED WITH WARNINGS                     ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${WHITE}MasterMind VPS Toolkit has been reinstalled but may need attention.${NC}"
    echo -e "${YELLOW}Please check the warnings above and run the menu to configure services.${NC}"
fi

echo
echo -e "${WHITE}Access the main menu: ${CYAN}sudo /opt/mastermind/core/menu.sh${NC}"
echo -e "${WHITE}Quick Setup Wizard: Choose option 9 from the main menu${NC}"
echo
echo -e "${GREEN}Reinstallation process completed!${NC}"