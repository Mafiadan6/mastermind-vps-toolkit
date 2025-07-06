#!/bin/bash

# Mastermind VPS Toolkit - Security Audit Tool
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Show security audit menu
show_audit_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             SECURITY AUDIT TOOL                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Security Audit Options:${NC}"
    echo
    echo -e "${YELLOW}  [1] Quick Security Scan${NC}"
    echo -e "${YELLOW}  [2] Comprehensive Audit${NC}"
    echo -e "${YELLOW}  [3] System Vulnerabilities${NC}"
    echo -e "${YELLOW}  [4] Network Security Check${NC}"
    echo -e "${YELLOW}  [5] File System Audit${NC}"
    echo -e "${YELLOW}  [6] User Account Audit${NC}"
    echo -e "${YELLOW}  [7] Service Security Check${NC}"
    echo -e "${YELLOW}  [8] Generate Security Report${NC}"
    echo -e "${YELLOW}  [9] Security Recommendations${NC}"
    echo -e "${YELLOW}  [0] Back to Security Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Quick security scan
quick_security_scan() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             QUICK SECURITY SCAN                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Running quick security scan..."
    echo
    
    # Check 1: Root login
    echo -e "${YELLOW}1. Root Login Check:${NC}"
    if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
        echo -e "   ${GREEN}✓ Root login disabled${NC}"
    else
        echo -e "   ${RED}✗ Root login may be enabled${NC}"
    fi
    
    # Check 2: SSH key authentication
    echo -e "${YELLOW}2. SSH Authentication:${NC}"
    if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
        echo -e "   ${GREEN}✓ Password authentication disabled${NC}"
    else
        echo -e "   ${YELLOW}? Password authentication may be enabled${NC}"
    fi
    
    # Check 3: Firewall status
    echo -e "${YELLOW}3. Firewall Status:${NC}"
    if ufw status | grep -q "Status: active"; then
        echo -e "   ${GREEN}✓ Firewall is active${NC}"
    else
        echo -e "   ${RED}✗ Firewall is not active${NC}"
    fi
    
    # Check 4: Fail2Ban status
    echo -e "${YELLOW}4. Fail2Ban Status:${NC}"
    if systemctl is-active --quiet fail2ban; then
        echo -e "   ${GREEN}✓ Fail2Ban is running${NC}"
    else
        echo -e "   ${RED}✗ Fail2Ban is not running${NC}"
    fi
    
    # Check 5: System updates
    echo -e "${YELLOW}5. System Updates:${NC}"
    local updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    if [ "$updates" -eq 0 ]; then
        echo -e "   ${GREEN}✓ System is up to date${NC}"
    else
        echo -e "   ${YELLOW}? $updates updates available${NC}"
    fi
    
    # Check 6: Open ports
    echo -e "${YELLOW}6. Open Ports:${NC}"
    local open_ports=$(ss -tuln | grep LISTEN | wc -l)
    echo -e "   ${CYAN}$open_ports listening ports detected${NC}"
    
    # Check 7: Running services
    echo -e "${YELLOW}7. Critical Services:${NC}"
    local critical_services=("ssh" "fail2ban" "ufw")
    for service in "${critical_services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "   ${GREEN}✓ $service is running${NC}"
        else
            echo -e "   ${RED}✗ $service is not running${NC}"
        fi
    done
    
    echo
    wait_for_key
}

# Comprehensive audit
comprehensive_audit() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           COMPREHENSIVE SECURITY AUDIT                      ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Running comprehensive security audit..."
    echo
    
    # System information
    echo -e "${YELLOW}=== SYSTEM INFORMATION ===${NC}"
    echo -e "Hostname: $(hostname)"
    echo -e "Kernel: $(uname -r)"
    echo -e "Distribution: $(lsb_release -d | cut -f2-)"
    echo -e "Uptime: $(uptime -p)"
    echo -e "Last boot: $(who -b | awk '{print $3, $4}')"
    echo
    
    # Network configuration
    echo -e "${YELLOW}=== NETWORK CONFIGURATION ===${NC}"
    echo -e "Public IP: $(get_public_ip)"
    echo -e "Network interfaces:"
    ip -4 addr show | grep inet | sed 's/^/  /'
    echo
    
    # SSH configuration
    echo -e "${YELLOW}=== SSH CONFIGURATION ===${NC}"
    audit_ssh_config
    echo
    
    # Firewall status
    echo -e "${YELLOW}=== FIREWALL STATUS ===${NC}"
    audit_firewall
    echo
    
    # User accounts
    echo -e "${YELLOW}=== USER ACCOUNTS ===${NC}"
    audit_user_accounts
    echo
    
    # File permissions
    echo -e "${YELLOW}=== CRITICAL FILE PERMISSIONS ===${NC}"
    audit_file_permissions
    echo
    
    # Running services
    echo -e "${YELLOW}=== RUNNING SERVICES ===${NC}"
    audit_services
    echo
    
    # Network connections
    echo -e "${YELLOW}=== NETWORK CONNECTIONS ===${NC}"
    audit_network_connections
    echo
    
    wait_for_key
}

# SSH configuration audit
audit_ssh_config() {
    local ssh_config="/etc/ssh/sshd_config"
    
    # Port
    local ssh_port=$(grep "^Port" $ssh_config | awk '{print $2}' || echo "22")
    echo -e "SSH Port: $ssh_port"
    
    # Root login
    local root_login=$(grep "^PermitRootLogin" $ssh_config | awk '{print $2}' || echo "default")
    if [ "$root_login" = "no" ]; then
        echo -e "Root Login: ${GREEN}Disabled${NC}"
    else
        echo -e "Root Login: ${RED}$root_login${NC}"
    fi
    
    # Password authentication
    local pass_auth=$(grep "^PasswordAuthentication" $ssh_config | awk '{print $2}' || echo "default")
    if [ "$pass_auth" = "no" ]; then
        echo -e "Password Auth: ${GREEN}Disabled${NC}"
    else
        echo -e "Password Auth: ${YELLOW}$pass_auth${NC}"
    fi
    
    # Protocol version
    local protocol=$(grep "^Protocol" $ssh_config | awk '{print $2}' || echo "2")
    if [ "$protocol" = "2" ]; then
        echo -e "Protocol: ${GREEN}Version 2${NC}"
    else
        echo -e "Protocol: ${RED}Version $protocol${NC}"
    fi
    
    # Max auth tries
    local max_auth=$(grep "^MaxAuthTries" $ssh_config | awk '{print $2}' || echo "6")
    echo -e "Max Auth Tries: $max_auth"
}

# Firewall audit
audit_firewall() {
    # UFW status
    local ufw_status=$(ufw status | head -1 | awk '{print $2}')
    if [ "$ufw_status" = "active" ]; then
        echo -e "UFW Status: ${GREEN}Active${NC}"
        
        # Rules count
        local rules_count=$(ufw status numbered | grep -c "^\[")
        echo -e "Active Rules: $rules_count"
        
        # Default policies
        local default_in=$(ufw status verbose | grep "Default:" | awk '{print $2}')
        local default_out=$(ufw status verbose | grep "Default:" | awk '{print $4}')
        echo -e "Default Incoming: $default_in"
        echo -e "Default Outgoing: $default_out"
    else
        echo -e "UFW Status: ${RED}Inactive${NC}"
    fi
    
    # iptables rules
    local iptables_rules=$(iptables -L | grep -c "^Chain")
    echo -e "iptables Chains: $iptables_rules"
}

# User accounts audit
audit_user_accounts() {
    # Root account
    echo -e "Root account status:"
    passwd -S root | sed 's/^/  /'
    
    # Users with shell access
    echo -e "Users with shell access:"
    grep -v "nologin\|false" /etc/passwd | grep -v "^#" | cut -d: -f1 | sed 's/^/  /'
    
    # Users with sudo access
    echo -e "Users with sudo access:"
    grep -E "^(sudo|admin|wheel)" /etc/group | cut -d: -f4 | tr ',' '\n' | sed 's/^/  /' | sort -u
    
    # Recent logins
    echo -e "Recent login attempts:"
    last -n 5 | sed 's/^/  /'
}

# File permissions audit
audit_file_permissions() {
    local critical_files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/ssh/sshd_config"
        "/root"
        "/etc/sudoers"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -e "$file" ]; then
            local perms=$(ls -ld "$file" | awk '{print $1, $3, $4}')
            echo -e "$file: $perms"
        fi
    done
    
    # SUID files
    echo -e "SUID files in system directories:"
    find /usr /bin /sbin -perm -4000 -type f 2>/dev/null | head -5 | sed 's/^/  /'
}

# Services audit
audit_services() {
    # All running services
    echo -e "Running services:"
    systemctl list-units --type=service --state=running --no-legend | awk '{print $1}' | head -10 | sed 's/^/  /'
    
    # Enabled services
    local enabled_count=$(systemctl list-unit-files --type=service --state=enabled --no-legend | wc -l)
    echo -e "Enabled services: $enabled_count"
    
    # Failed services
    local failed_services=$(systemctl list-units --type=service --state=failed --no-legend | wc -l)
    if [ "$failed_services" -gt 0 ]; then
        echo -e "Failed services: ${RED}$failed_services${NC}"
    else
        echo -e "Failed services: ${GREEN}0${NC}"
    fi
}

# Network connections audit
audit_network_connections() {
    # Listening ports
    echo -e "Listening ports:"
    ss -tuln | grep LISTEN | awk '{print $1, $5}' | head -10 | sed 's/^/  /'
    
    # Established connections
    local established=$(ss -tun | grep ESTAB | wc -l)
    echo -e "Established connections: $established"
    
    # External connections
    echo -e "External connections:"
    ss -tun | grep ESTAB | grep -v "127.0.0.1\|::1" | awk '{print $5}' | head -5 | sed 's/^/  /' || echo "  None"
}

# System vulnerabilities check
system_vulnerabilities() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           SYSTEM VULNERABILITIES CHECK                      ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Checking system vulnerabilities..."
    echo
    
    # Check for available updates
    echo -e "${YELLOW}1. System Updates:${NC}"
    apt update &>/dev/null
    local security_updates=$(apt list --upgradable 2>/dev/null | grep -c "security")
    local total_updates=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
    
    if [ "$security_updates" -gt 0 ]; then
        echo -e "   ${RED}$security_updates security updates available${NC}"
    else
        echo -e "   ${GREEN}No security updates pending${NC}"
    fi
    echo -e "   Total updates available: $total_updates"
    echo
    
    # Check kernel version
    echo -e "${YELLOW}2. Kernel Version:${NC}"
    local current_kernel=$(uname -r)
    local latest_kernel=$(apt-cache policy linux-image-generic | grep Candidate | awk '{print $2}')
    echo -e "   Current: $current_kernel"
    echo -e "   Latest available: $latest_kernel"
    echo
    
    # Check for known vulnerable packages
    echo -e "${YELLOW}3. Package Vulnerability Check:${NC}"
    check_vulnerable_packages
    echo
    
    # Check for weak passwords
    echo -e "${YELLOW}4. Password Policy:${NC}"
    check_password_policy
    echo
    
    # Check for default accounts
    echo -e "${YELLOW}5. Default Accounts:${NC}"
    check_default_accounts
    echo
    
    wait_for_key
}

# Check vulnerable packages
check_vulnerable_packages() {
    local vulnerable_packages=("telnet" "rsh-server" "nis" "tftp" "finger")
    
    for package in "${vulnerable_packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            echo -e "   ${RED}✗ Vulnerable package installed: $package${NC}"
        else
            echo -e "   ${GREEN}✓ $package not installed${NC}"
        fi
    done
}

# Check password policy
check_password_policy() {
    # Check if password complexity is enforced
    if [ -f /etc/pam.d/common-password ]; then
        if grep -q "pam_pwquality.so" /etc/pam.d/common-password; then
            echo -e "   ${GREEN}✓ Password quality enforcement enabled${NC}"
        else
            echo -e "   ${YELLOW}? Password quality enforcement not configured${NC}"
        fi
    fi
    
    # Check password aging
    local max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}' || echo "99999")
    if [ "$max_days" -le 90 ]; then
        echo -e "   ${GREEN}✓ Password aging configured (max $max_days days)${NC}"
    else
        echo -e "   ${YELLOW}? Password aging not optimal (max $max_days days)${NC}"
    fi
}

# Check default accounts
check_default_accounts() {
    local default_accounts=("guest" "nobody" "www-data")
    
    for account in "${default_accounts[@]}"; do
        if grep -q "^$account:" /etc/passwd; then
            local shell=$(grep "^$account:" /etc/passwd | cut -d: -f7)
            if [[ "$shell" =~ (nologin|false) ]]; then
                echo -e "   ${GREEN}✓ $account has no shell access${NC}"
            else
                echo -e "   ${RED}✗ $account has shell access: $shell${NC}"
            fi
        fi
    done
}

# Network security check
network_security_check() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           NETWORK SECURITY CHECK                            ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Performing network security check..."
    echo
    
    # Port scan detection
    echo -e "${YELLOW}1. Open Ports Analysis:${NC}"
    analyze_open_ports
    echo
    
    # Network configuration
    echo -e "${YELLOW}2. Network Configuration:${NC}"
    check_network_config
    echo
    
    # DNS configuration
    echo -e "${YELLOW}3. DNS Configuration:${NC}"
    check_dns_config
    echo
    
    # Network services
    echo -e "${YELLOW}4. Network Services:${NC}"
    check_network_services
    echo
    
    wait_for_key
}

# Analyze open ports
analyze_open_ports() {
    echo -e "   Open TCP ports:"
    ss -tuln | grep LISTEN | grep tcp | awk '{print $5}' | cut -d: -f2 | sort -n | sed 's/^/     /'
    
    echo -e "   Open UDP ports:"
    ss -tuln | grep LISTEN | grep udp | awk '{print $5}' | cut -d: -f2 | sort -n | sed 's/^/     /' || echo "     None"
    
    # Check for dangerous ports
    local dangerous_ports=(21 23 25 53 135 139 445 1433 3306 3389)
    echo -e "   Dangerous port check:"
    for port in "${dangerous_ports[@]}"; do
        if ss -tuln | grep -q ":$port "; then
            echo -e "     ${RED}✗ Port $port is open${NC}"
        fi
    done
}

# Check network configuration
check_network_config() {
    # IP forwarding
    local ip_forward=$(sysctl net.ipv4.ip_forward | cut -d= -f2 | tr -d ' ')
    if [ "$ip_forward" = "0" ]; then
        echo -e "   ${GREEN}✓ IP forwarding disabled${NC}"
    else
        echo -e "   ${YELLOW}? IP forwarding enabled${NC}"
    fi
    
    # ICMP redirects
    local icmp_redirects=$(sysctl net.ipv4.conf.all.accept_redirects | cut -d= -f2 | tr -d ' ')
    if [ "$icmp_redirects" = "0" ]; then
        echo -e "   ${GREEN}✓ ICMP redirects disabled${NC}"
    else
        echo -e "   ${RED}✗ ICMP redirects enabled${NC}"
    fi
    
    # Source routing
    local source_route=$(sysctl net.ipv4.conf.all.accept_source_route | cut -d= -f2 | tr -d ' ')
    if [ "$source_route" = "0" ]; then
        echo -e "   ${GREEN}✓ Source routing disabled${NC}"
    else
        echo -e "   ${RED}✗ Source routing enabled${NC}"
    fi
}

# Check DNS configuration
check_dns_config() {
    echo -e "   DNS servers:"
    grep nameserver /etc/resolv.conf | sed 's/^/     /'
    
    # Check for DNS security
    if grep -q "127.0.0.53" /etc/resolv.conf; then
        echo -e "   ${GREEN}✓ Using systemd-resolved${NC}"
    elif grep -q "127.0.0.1" /etc/resolv.conf; then
        echo -e "   ${GREEN}✓ Using local DNS resolver${NC}"
    else
        echo -e "   ${YELLOW}? Using external DNS servers${NC}"
    fi
}

# Check network services
check_network_services() {
    local network_services=("ssh" "nginx" "apache2" "postfix" "bind9")
    
    for service in "${network_services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "   ${GREEN}✓ $service is running${NC}"
        else
            echo -e "   ${CYAN}- $service is not running${NC}"
        fi
    done
}

# File system audit
filesystem_audit() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             FILE SYSTEM AUDIT                               ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Performing file system audit..."
    echo
    
    # Check mount options
    echo -e "${YELLOW}1. Mount Options:${NC}"
    check_mount_options
    echo
    
    # SUID/SGID files
    echo -e "${YELLOW}2. SUID/SGID Files:${NC}"
    check_suid_files
    echo
    
    # World-writable files
    echo -e "${YELLOW}3. World-writable Files:${NC}"
    check_world_writable
    echo
    
    # File integrity
    echo -e "${YELLOW}4. Critical File Integrity:${NC}"
    check_file_integrity
    echo
    
    wait_for_key
}

# Check mount options
check_mount_options() {
    echo -e "   Mount points with security options:"
    mount | grep -E "(noexec|nosuid|nodev)" | sed 's/^/     /' || echo "     None found"
    
    # Check for dangerous mount options
    if mount | grep -q "rw.*exec.*suid"; then
        echo -e "   ${YELLOW}? Some mounts allow exec and suid${NC}"
    fi
}

# Check SUID files
check_suid_files() {
    echo -e "   SUID files in system directories:"
    find /usr /bin /sbin -perm -4000 -type f 2>/dev/null | head -10 | sed 's/^/     /'
    
    echo -e "   SGID files in system directories:"
    find /usr /bin /sbin -perm -2000 -type f 2>/dev/null | head -5 | sed 's/^/     /'
}

# Check world-writable files
check_world_writable() {
    echo -e "   World-writable files (excluding /tmp and /var/tmp):"
    find / -path /proc -prune -o -path /sys -prune -o -path /tmp -prune -o -path /var/tmp -prune -o -perm -002 -type f -print 2>/dev/null | head -5 | sed 's/^/     /' || echo "     None found"
    
    echo -e "   World-writable directories:"
    find / -path /proc -prune -o -path /sys -prune -o -perm -002 -type d -print 2>/dev/null | head -5 | sed 's/^/     /' || echo "     None found"
}

# Check file integrity
check_file_integrity() {
    local critical_files=("/etc/passwd" "/etc/shadow" "/etc/ssh/sshd_config" "/etc/sudoers")
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            local size=$(stat -c%s "$file")
            local mtime=$(stat -c%Y "$file")
            echo -e "   $file: ${size} bytes, modified $(date -d @$mtime)"
        fi
    done
}

# User account audit
user_account_audit() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             USER ACCOUNT AUDIT                              ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Performing user account audit..."
    echo
    
    # User account analysis
    echo -e "${YELLOW}1. User Account Analysis:${NC}"
    analyze_user_accounts
    echo
    
    # Password security
    echo -e "${YELLOW}2. Password Security:${NC}"
    analyze_password_security
    echo
    
    # Login history
    echo -e "${YELLOW}3. Login History:${NC}"
    analyze_login_history
    echo
    
    # Privilege escalation
    echo -e "${YELLOW}4. Privilege Escalation:${NC}"
    check_privilege_escalation
    echo
    
    wait_for_key
}

# Analyze user accounts
analyze_user_accounts() {
    # Total users
    local total_users=$(grep -c "^[^#]" /etc/passwd)
    echo -e "   Total user accounts: $total_users"
    
    # Users with shell access
    local shell_users=$(grep -v "nologin\|false" /etc/passwd | grep -v "^#" | wc -l)
    echo -e "   Users with shell access: $shell_users"
    
    # Users with UID 0
    local root_users=$(awk -F: '$3 == 0 {print $1}' /etc/passwd | wc -l)
    if [ "$root_users" -eq 1 ]; then
        echo -e "   ${GREEN}✓ Only one root account${NC}"
    else
        echo -e "   ${RED}✗ Multiple accounts with UID 0: $root_users${NC}"
    fi
    
    # Users without password
    local no_pass=$(awk -F: '$2 == "" {print $1}' /etc/shadow | wc -l)
    if [ "$no_pass" -eq 0 ]; then
        echo -e "   ${GREEN}✓ All accounts have passwords${NC}"
    else
        echo -e "   ${RED}✗ Accounts without password: $no_pass${NC}"
    fi
}

# Analyze password security
analyze_password_security() {
    # Password aging
    echo -e "   Password aging settings:"
    grep -E "^PASS_(MAX|MIN|WARN)_DAYS" /etc/login.defs | sed 's/^/     /'
    
    # Locked accounts
    local locked_accounts=$(passwd -S -a | grep -c " L ")
    echo -e "   Locked accounts: $locked_accounts"
    
    # Expired accounts
    local expired_accounts=$(chage -l root 2>/dev/null | grep -c "Account expires.*never" || echo "0")
    echo -e "   Account expiration policies configured"
}

# Analyze login history
analyze_login_history() {
    echo -e "   Recent successful logins:"
    last -n 5 | head -5 | sed 's/^/     /'
    
    echo -e "   Recent failed login attempts:"
    grep "Failed password" /var/log/auth.log | tail -5 | awk '{print $1, $2, $3, $9, $11}' | sed 's/^/     /' 2>/dev/null || echo "     None found"
}

# Check privilege escalation
check_privilege_escalation() {
    # Sudo configuration
    echo -e "   Sudo configuration:"
    if [ -f /etc/sudoers ]; then
        grep -v "^#\|^$" /etc/sudoers | grep -v "Defaults" | head -3 | sed 's/^/     /'
    fi
    
    # SUID binaries
    echo -e "   Critical SUID binaries:"
    find /usr/bin /bin -perm -4000 -name "su\|sudo\|passwd" 2>/dev/null | sed 's/^/     /'
}

# Service security check
service_security_check() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           SERVICE SECURITY CHECK                            ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Performing service security check..."
    echo
    
    # Running services analysis
    echo -e "${YELLOW}1. Running Services Analysis:${NC}"
    analyze_running_services
    echo
    
    # Service configurations
    echo -e "${YELLOW}2. Service Configurations:${NC}"
    check_service_configs
    echo
    
    # Service users
    echo -e "${YELLOW}3. Service Users:${NC}"
    check_service_users
    echo
    
    wait_for_key
}

# Analyze running services
analyze_running_services() {
    echo -e "   Active services:"
    systemctl list-units --type=service --state=running --no-legend | head -10 | awk '{print $1}' | sed 's/^/     /'
    
    # Check for unnecessary services
    local unnecessary_services=("telnet" "ftp" "rsh" "rlogin")
    echo -e "   Unnecessary service check:"
    for service in "${unnecessary_services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "     ${RED}✗ $service is running${NC}"
        else
            echo -e "     ${GREEN}✓ $service is not running${NC}"
        fi
    done
}

# Check service configurations
check_service_configs() {
    # SSH configuration
    echo -e "   SSH service:"
    if systemctl is-active --quiet ssh; then
        local ssh_port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")
        echo -e "     Running on port: $ssh_port"
        
        if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
            echo -e "     ${GREEN}✓ Root login disabled${NC}"
        else
            echo -e "     ${YELLOW}? Root login configuration${NC}"
        fi
    fi
    
    # Web server
    if systemctl is-active --quiet nginx; then
        echo -e "   Nginx: Running"
    elif systemctl is-active --quiet apache2; then
        echo -e "   Apache: Running"
    else
        echo -e "   Web server: Not running"
    fi
}

# Check service users
check_service_users() {
    local service_users=("www-data" "nginx" "mysql" "postgres")
    
    for user in "${service_users[@]}"; do
        if grep -q "^$user:" /etc/passwd; then
            local shell=$(grep "^$user:" /etc/passwd | cut -d: -f7)
            if [[ "$shell" =~ (nologin|false) ]]; then
                echo -e "   ${GREEN}✓ $user has no shell access${NC}"
            else
                echo -e "   ${YELLOW}? $user has shell: $shell${NC}"
            fi
        fi
    done
}

# Generate security report
generate_security_report() {
    local report_file="/opt/mastermind/logs/security_report_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "Generating comprehensive security report..."
    
    {
        echo "MASTERMIND VPS TOOLKIT - SECURITY AUDIT REPORT"
        echo "Generated on: $(date)"
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "Distribution: $(lsb_release -d | cut -f2-)"
        echo "========================================"
        echo
        
        echo "SYSTEM INFORMATION:"
        echo "- Uptime: $(uptime -p)"
        echo "- Load average: $(uptime | awk -F'load average:' '{print $2}')"
        echo "- Memory usage: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
        echo "- Disk usage: $(df / | tail -1 | awk '{print $5}')"
        echo
        
        echo "SECURITY STATUS:"
        # SSH configuration
        if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
            echo "✓ SSH root login disabled"
        else
            echo "✗ SSH root login may be enabled"
        fi
        
        # Firewall status
        if ufw status | grep -q "Status: active"; then
            echo "✓ Firewall is active"
        else
            echo "✗ Firewall is not active"
        fi
        
        # Fail2Ban status
        if systemctl is-active --quiet fail2ban; then
            echo "✓ Fail2Ban is running"
        else
            echo "✗ Fail2Ban is not running"
        fi
        
        echo
        echo "OPEN PORTS:"
        ss -tuln | grep LISTEN | awk '{print $1, $5}'
        
        echo
        echo "RUNNING SERVICES:"
        systemctl list-units --type=service --state=running --no-legend | awk '{print $1}'
        
        echo
        echo "USER ACCOUNTS:"
        echo "- Total accounts: $(grep -c "^[^#]" /etc/passwd)"
        echo "- Shell access: $(grep -v "nologin\|false" /etc/passwd | grep -v "^#" | wc -l)"
        
        echo
        echo "RECOMMENDATIONS:"
        echo "- Regularly update the system"
        echo "- Monitor log files for suspicious activity"
        echo "- Review and minimize running services"
        echo "- Implement strong password policies"
        echo "- Keep firewall rules updated"
        
    } > "$report_file"
    
    log_info "Security report generated: $report_file"
    
    if confirm "View the generated report?"; then
        less "$report_file"
    fi
    
    wait_for_key
}

# Security recommendations
security_recommendations() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           SECURITY RECOMMENDATIONS                          ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}HIGH PRIORITY RECOMMENDATIONS:${NC}"
    echo
    
    # Check and provide recommendations
    provide_high_priority_recommendations
    echo
    
    echo -e "${YELLOW}MEDIUM PRIORITY RECOMMENDATIONS:${NC}"
    echo
    provide_medium_priority_recommendations
    echo
    
    echo -e "${YELLOW}LOW PRIORITY RECOMMENDATIONS:${NC}"
    echo
    provide_low_priority_recommendations
    echo
    
    wait_for_key
}

# High priority recommendations
provide_high_priority_recommendations() {
    # Check firewall
    if ! ufw status | grep -q "Status: active"; then
        echo -e "${RED}1. Enable firewall immediately${NC}"
        echo -e "   Command: ufw enable"
        echo
    fi
    
    # Check Fail2Ban
    if ! systemctl is-active --quiet fail2ban; then
        echo -e "${RED}2. Install and configure Fail2Ban${NC}"
        echo -e "   Command: apt install fail2ban && systemctl enable fail2ban"
        echo
    fi
    
    # Check root login
    if ! grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
        echo -e "${RED}3. Disable SSH root login${NC}"
        echo -e "   Edit /etc/ssh/sshd_config: PermitRootLogin no"
        echo
    fi
    
    # Check for available security updates
    local security_updates=$(apt list --upgradable 2>/dev/null | grep -c "security" || echo "0")
    if [ "$security_updates" -gt 0 ]; then
        echo -e "${RED}4. Install $security_updates security updates${NC}"
        echo -e "   Command: apt update && apt upgrade"
        echo
    fi
}

# Medium priority recommendations
provide_medium_priority_recommendations() {
    echo -e "1. Change default SSH port"
    echo -e "   Edit /etc/ssh/sshd_config: Port 2222"
    echo
    
    echo -e "2. Configure automatic security updates"
    echo -e "   Install: unattended-upgrades"
    echo
    
    echo -e "3. Implement log monitoring"
    echo -e "   Configure: logrotate and log analysis"
    echo
    
    echo -e "4. Harden kernel parameters"
    echo -e "   Configure: /etc/sysctl.conf security settings"
    echo
}

# Low priority recommendations
provide_low_priority_recommendations() {
    echo -e "1. Install intrusion detection system"
    echo -e "   Consider: AIDE or Tripwire"
    echo
    
    echo -e "2. Implement file integrity monitoring"
    echo -e "   Monitor critical system files"
    echo
    
    echo -e "3. Configure centralized logging"
    echo -e "   Setup: rsyslog or journald forwarding"
    echo
    
    echo -e "4. Regular security assessments"
    echo -e "   Schedule: weekly security scans"
    echo
}

# Main function
main() {
    while true; do
        show_audit_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) quick_security_scan ;;
            2) comprehensive_audit ;;
            3) system_vulnerabilities ;;
            4) network_security_check ;;
            5) filesystem_audit ;;
            6) user_account_audit ;;
            7) service_security_check ;;
            8) generate_security_report ;;
            9) security_recommendations ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
