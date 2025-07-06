#!/bin/bash

# Mastermind VPS Toolkit - TCP BBR Management
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Show BBR management menu
show_bbr_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             TCP BBR MANAGEMENT                               ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Check current BBR status
    local current_cc=$(sysctl net.ipv4.tcp_congestion_control | cut -d' ' -f3)
    local bbr_available=$(sysctl net.ipv4.tcp_available_congestion_control | grep -o bbr || echo "not available")
    
    echo -e "${YELLOW}Current Status:${NC}"
    echo -e "  Congestion Control: ${GREEN}$current_cc${NC}"
    echo -e "  BBR Available: ${GREEN}$bbr_available${NC}"
    
    # Check if BBR is enabled
    if [ "$current_cc" = "bbr" ]; then
        echo -e "  BBR Status: ${GREEN}ENABLED${NC}"
    else
        echo -e "  BBR Status: ${RED}DISABLED${NC}"
    fi
    
    echo
    echo -e "${YELLOW}Kernel Information:${NC}"
    echo -e "  Kernel Version: $(uname -r)"
    echo -e "  BBR Support: $(check_bbr_support)"
    
    echo
    echo -e "${YELLOW}  [1] Enable TCP BBR${NC}"
    echo -e "${YELLOW}  [2] Disable TCP BBR${NC}"
    echo -e "${YELLOW}  [3] BBR Performance Test${NC}"
    echo -e "${YELLOW}  [4] View BBR Statistics${NC}"
    echo -e "${YELLOW}  [5] BBR Configuration${NC}"
    echo -e "${YELLOW}  [6] Install BBR (if needed)${NC}"
    echo -e "${YELLOW}  [7] BBR Troubleshooting${NC}"
    echo -e "${YELLOW}  [0] Back to Network Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Check BBR support
check_bbr_support() {
    local kernel_version=$(uname -r | cut -d. -f1-2)
    local major=$(echo $kernel_version | cut -d. -f1)
    local minor=$(echo $kernel_version | cut -d. -f2)
    
    if [ "$major" -gt 4 ] || ([ "$major" -eq 4 ] && [ "$minor" -ge 9 ]); then
        echo -e "${GREEN}Supported${NC}"
    else
        echo -e "${RED}Not Supported (Kernel 4.9+ required)${NC}"
    fi
}

# Enable TCP BBR
enable_bbr() {
    log_info "Enabling TCP BBR..."
    
    # Check if BBR is available
    if ! sysctl net.ipv4.tcp_available_congestion_control | grep -q bbr; then
        log_error "BBR is not available in this kernel"
        if confirm "Would you like to install a BBR-compatible kernel?"; then
            install_bbr_kernel
            return
        else
            wait_for_key
            return
        fi
    fi
    
    # Backup current configuration
    backup_file /etc/sysctl.conf
    
    # Enable BBR
    cat >> /etc/sysctl.conf << EOF

# TCP BBR Configuration
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
    
    # Apply settings
    sysctl -p
    
    # Verify BBR is enabled
    local new_cc=$(sysctl net.ipv4.tcp_congestion_control | cut -d' ' -f3)
    
    if [ "$new_cc" = "bbr" ]; then
        log_info "TCP BBR enabled successfully"
        
        # Update configuration
        sed -i "s/ENABLE_BBR=.*/ENABLE_BBR=true/" /opt/mastermind/core/config.cfg
        
        echo
        echo -e "${GREEN}✓ TCP BBR is now active${NC}"
        echo -e "${GREEN}✓ Default qdisc set to fq${NC}"
        echo -e "${GREEN}✓ Configuration saved${NC}"
    else
        log_error "Failed to enable TCP BBR"
    fi
    
    wait_for_key
}

# Disable TCP BBR
disable_bbr() {
    log_info "Disabling TCP BBR..."
    
    if confirm "Are you sure you want to disable TCP BBR?"; then
        # Remove BBR configuration
        sed -i '/# TCP BBR Configuration/,+2d' /etc/sysctl.conf
        
        # Set to default congestion control
        sysctl net.ipv4.tcp_congestion_control=cubic
        sysctl net.core.default_qdisc=pfifo_fast
        
        # Update configuration
        sed -i "s/ENABLE_BBR=.*/ENABLE_BBR=false/" /opt/mastermind/core/config.cfg
        
        log_info "TCP BBR disabled. Using cubic congestion control."
    fi
    
    wait_for_key
}

# BBR performance test
bbr_performance_test() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             BBR PERFORMANCE TEST                              ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Running BBR performance test..."
    echo
    
    # Test 1: Check current settings
    echo -e "${YELLOW}1. Current Configuration:${NC}"
    echo -e "   Congestion Control: $(sysctl net.ipv4.tcp_congestion_control | cut -d' ' -f3)"
    echo -e "   Default QDisc: $(sysctl net.core.default_qdisc | cut -d' ' -f3)"
    echo
    
    # Test 2: Network performance metrics
    echo -e "${YELLOW}2. Network Performance Metrics:${NC}"
    echo -e "   Network interfaces:"
    ip -s link show | grep -E "(eth|ens|enp)" -A1
    echo
    
    # Test 3: Connection statistics
    echo -e "${YELLOW}3. TCP Connection Statistics:${NC}"
    ss -s
    echo
    
    # Test 4: Bandwidth test (if available)
    echo -e "${YELLOW}4. Bandwidth Test:${NC}"
    if command_exists iperf3; then
        echo -e "   Running iperf3 test..."
        timeout 10 iperf3 -c speedtest.selectel.ru -p 5201 -t 5 2>/dev/null || echo "   iperf3 test failed or unavailable"
    else
        echo -e "   iperf3 not available, using curl test..."
        echo -e "   Testing download speed..."
        curl -o /dev/null -s -w "   Download speed: %{speed_download} bytes/sec\n" http://speedtest.tele2.net/10MB.zip
    fi
    echo
    
    # Test 5: BBR specific metrics
    if [ "$(sysctl net.ipv4.tcp_congestion_control | cut -d' ' -f3)" = "bbr" ]; then
        echo -e "${YELLOW}5. BBR Specific Metrics:${NC}"
        echo -e "   BBR is active and monitoring connections"
        
        # Show active connections using BBR
        local bbr_connections=$(ss -i | grep bbr | wc -l)
        echo -e "   Active BBR connections: $bbr_connections"
    else
        echo -e "${YELLOW}5. BBR Status:${NC}"
        echo -e "   BBR is not currently active"
    fi
    
    echo
    wait_for_key
}

# View BBR statistics
view_bbr_statistics() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             BBR STATISTICS                                   ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}TCP BBR Statistics:${NC}"
    echo
    
    # System information
    echo -e "${YELLOW}System Information:${NC}"
    echo -e "  Kernel: $(uname -r)"
    echo -e "  Uptime: $(uptime -p)"
    echo -e "  Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo
    
    # TCP settings
    echo -e "${YELLOW}TCP Configuration:${NC}"
    echo -e "  Congestion Control: $(sysctl net.ipv4.tcp_congestion_control | cut -d' ' -f3)"
    echo -e "  Available Algorithms: $(sysctl net.ipv4.tcp_available_congestion_control | cut -d' ' -f3-)"
    echo -e "  Default QDisc: $(sysctl net.core.default_qdisc | cut -d' ' -f3)"
    echo
    
    # Network statistics
    echo -e "${YELLOW}Network Statistics:${NC}"
    cat /proc/net/netstat | grep TcpExt | awk '{print "  TCP Extensions: Active"}'
    cat /proc/net/snmp | grep Tcp: | tail -1 | awk '{print "  TCP Segments In: " $11 "\n  TCP Segments Out: " $12}'
    echo
    
    # Connection statistics
    echo -e "${YELLOW}Connection Statistics:${NC}"
    ss -s | grep -E "(TCP|UDP)" | sed 's/^/  /'
    echo
    
    # BBR specific information
    if [ "$(sysctl net.ipv4.tcp_congestion_control | cut -d' ' -f3)" = "bbr" ]; then
        echo -e "${YELLOW}BBR Active Connections:${NC}"
        ss -i | grep bbr | head -5 | sed 's/^/  /'
        
        local total_bbr=$(ss -i | grep bbr | wc -l)
        echo -e "  Total BBR connections: $total_bbr"
    else
        echo -e "${YELLOW}BBR Status: ${RED}Not Active${NC}"
    fi
    
    echo
    wait_for_key
}

# BBR configuration
bbr_configuration() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                             BBR CONFIGURATION                               ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Configure QDisc Settings${NC}"
        echo -e "${YELLOW}  [2] TCP Buffer Tuning${NC}"
        echo -e "${YELLOW}  [3] Advanced BBR Parameters${NC}"
        echo -e "${YELLOW}  [4] Reset to Default${NC}"
        echo -e "${YELLOW}  [5] View Current Settings${NC}"
        echo -e "${YELLOW}  [0] Back to BBR Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) configure_qdisc ;;
            2) configure_tcp_buffers ;;
            3) configure_advanced_bbr ;;
            4) reset_bbr_config ;;
            5) view_current_settings ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Configure QDisc settings
configure_qdisc() {
    echo
    echo -e "${YELLOW}QDisc Configuration${NC}"
    echo
    
    echo -e "${YELLOW}Available QDisc algorithms:${NC}"
    echo -e "  [1] fq (Fair Queue - recommended for BBR)"
    echo -e "  [2] fq_codel (Fair Queue with Controlled Delay)"
    echo -e "  [3] pfifo_fast (Default)"
    echo
    
    read -p "Choose QDisc algorithm [1-3]: " qdisc_choice
    
    case $qdisc_choice in
        1)
            sysctl net.core.default_qdisc=fq
            echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
            log_info "QDisc set to Fair Queue (fq)"
            ;;
        2)
            sysctl net.core.default_qdisc=fq_codel
            echo "net.core.default_qdisc = fq_codel" >> /etc/sysctl.conf
            log_info "QDisc set to Fair Queue CoDel (fq_codel)"
            ;;
        3)
            sysctl net.core.default_qdisc=pfifo_fast
            echo "net.core.default_qdisc = pfifo_fast" >> /etc/sysctl.conf
            log_info "QDisc set to Default (pfifo_fast)"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    wait_for_key
}

# Configure TCP buffers
configure_tcp_buffers() {
    echo
    echo -e "${YELLOW}TCP Buffer Configuration${NC}"
    echo
    
    echo -e "${YELLOW}Current buffer sizes:${NC}"
    echo -e "  TCP Read Buffer: $(sysctl net.ipv4.tcp_rmem | cut -d' ' -f3-)"
    echo -e "  TCP Write Buffer: $(sysctl net.ipv4.tcp_wmem | cut -d' ' -f3-)"
    echo -e "  Core Read Buffer: $(sysctl net.core.rmem_max | cut -d' ' -f3)"
    echo -e "  Core Write Buffer: $(sysctl net.core.wmem_max | cut -d' ' -f3)"
    echo
    
    if confirm "Apply optimized buffer settings for BBR?"; then
        cat >> /etc/sysctl.conf << EOF

# TCP Buffer Optimization for BBR
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
EOF
        
        # Apply settings
        sysctl -p
        
        log_info "TCP buffer settings optimized for BBR"
    fi
    
    wait_for_key
}

# Configure advanced BBR parameters
configure_advanced_bbr() {
    echo
    echo -e "${YELLOW}Advanced BBR Configuration${NC}"
    echo
    
    if confirm "Apply advanced BBR optimization settings?"; then
        cat >> /etc/sysctl.conf << EOF

# Advanced BBR Optimization
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_frto = 2
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
EOF
        
        # Apply settings
        sysctl -p
        
        log_info "Advanced BBR settings applied"
    fi
    
    wait_for_key
}

# Reset BBR configuration
reset_bbr_config() {
    if confirm "Reset BBR configuration to defaults?"; then
        # Remove BBR configuration from sysctl.conf
        sed -i '/# TCP BBR Configuration/,+10d' /etc/sysctl.conf
        sed -i '/# TCP Buffer Optimization for BBR/,+5d' /etc/sysctl.conf
        sed -i '/# Advanced BBR Optimization/,+10d' /etc/sysctl.conf
        
        # Reset to defaults
        sysctl net.ipv4.tcp_congestion_control=cubic
        sysctl net.core.default_qdisc=pfifo_fast
        
        log_info "BBR configuration reset to defaults"
    fi
    
    wait_for_key
}

# View current settings
view_current_settings() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             CURRENT BBR SETTINGS                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Congestion Control:${NC}"
    sysctl net.ipv4.tcp_congestion_control
    sysctl net.ipv4.tcp_available_congestion_control
    echo
    
    echo -e "${YELLOW}QDisc Configuration:${NC}"
    sysctl net.core.default_qdisc
    echo
    
    echo -e "${YELLOW}TCP Buffers:${NC}"
    sysctl net.ipv4.tcp_rmem
    sysctl net.ipv4.tcp_wmem
    sysctl net.core.rmem_max
    sysctl net.core.wmem_max
    echo
    
    echo -e "${YELLOW}Advanced Settings:${NC}"
    sysctl net.ipv4.tcp_slow_start_after_idle
    sysctl net.ipv4.tcp_window_scaling
    sysctl net.ipv4.tcp_timestamps
    echo
    
    wait_for_key
}

# Install BBR kernel
install_bbr_kernel() {
    log_info "Installing BBR-compatible kernel..."
    
    # Check current kernel version
    local current_kernel=$(uname -r)
    echo -e "${YELLOW}Current kernel: $current_kernel${NC}"
    
    # Update package list
    apt update
    
    # Install latest kernel
    apt install -y linux-image-generic linux-headers-generic
    
    # Check if BBR is now available
    if modprobe tcp_bbr 2>/dev/null; then
        log_info "BBR module loaded successfully"
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    else
        log_warn "BBR module not available even after kernel update"
    fi
    
    log_warn "Please reboot the system to use the new kernel"
    
    if confirm "Reboot now?"; then
        reboot
    fi
    
    wait_for_key
}

# BBR troubleshooting
bbr_troubleshooting() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             BBR TROUBLESHOOTING                              ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}BBR Troubleshooting Guide${NC}"
    echo
    
    # Check 1: Kernel version
    echo -e "${YELLOW}1. Kernel Version Check:${NC}"
    local kernel=$(uname -r)
    local major=$(echo $kernel | cut -d. -f1)
    local minor=$(echo $kernel | cut -d. -f2)
    
    echo -e "   Current kernel: $kernel"
    if [ "$major" -gt 4 ] || ([ "$major" -eq 4 ] && [ "$minor" -ge 9 ]); then
        echo -e "   Status: ${GREEN}✓ BBR supported${NC}"
    else
        echo -e "   Status: ${RED}✗ BBR not supported (need 4.9+)${NC}"
        echo -e "   Solution: Update kernel with 'apt install linux-image-generic'"
    fi
    echo
    
    # Check 2: BBR module
    echo -e "${YELLOW}2. BBR Module Check:${NC}"
    if lsmod | grep -q tcp_bbr; then
        echo -e "   Status: ${GREEN}✓ BBR module loaded${NC}"
    else
        echo -e "   Status: ${RED}✗ BBR module not loaded${NC}"
        echo -e "   Solution: Run 'modprobe tcp_bbr'"
    fi
    echo
    
    # Check 3: Available algorithms
    echo -e "${YELLOW}3. Available Algorithms:${NC}"
    local available=$(sysctl net.ipv4.tcp_available_congestion_control | cut -d' ' -f3-)
    echo -e "   Available: $available"
    if echo "$available" | grep -q bbr; then
        echo -e "   Status: ${GREEN}✓ BBR available${NC}"
    else
        echo -e "   Status: ${RED}✗ BBR not available${NC}"
    fi
    echo
    
    # Check 4: Current setting
    echo -e "${YELLOW}4. Current Configuration:${NC}"
    local current=$(sysctl net.ipv4.tcp_congestion_control | cut -d' ' -f3)
    echo -e "   Current: $current"
    if [ "$current" = "bbr" ]; then
        echo -e "   Status: ${GREEN}✓ BBR active${NC}"
    else
        echo -e "   Status: ${RED}✗ BBR not active${NC}"
        echo -e "   Solution: Run 'sysctl net.ipv4.tcp_congestion_control=bbr'"
    fi
    echo
    
    # Check 5: Persistent configuration
    echo -e "${YELLOW}5. Persistent Configuration:${NC}"
    if grep -q "tcp_congestion_control.*bbr" /etc/sysctl.conf; then
        echo -e "   Status: ${GREEN}✓ BBR configured in sysctl.conf${NC}"
    else
        echo -e "   Status: ${RED}✗ BBR not in sysctl.conf${NC}"
        echo -e "   Solution: Add 'net.ipv4.tcp_congestion_control = bbr' to /etc/sysctl.conf"
    fi
    echo
    
    echo -e "${YELLOW}Quick Fix Commands:${NC}"
    echo -e "   modprobe tcp_bbr"
    echo -e "   echo 'tcp_bbr' >> /etc/modules-load.d/modules.conf"
    echo -e "   sysctl net.ipv4.tcp_congestion_control=bbr"
    echo -e "   echo 'net.ipv4.tcp_congestion_control = bbr' >> /etc/sysctl.conf"
    echo
    
    wait_for_key
}

# Main function
main() {
    while true; do
        show_bbr_menu
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) enable_bbr ;;
            2) disable_bbr ;;
            3) bbr_performance_test ;;
            4) view_bbr_statistics ;;
            5) bbr_configuration ;;
            6) install_bbr_kernel ;;
            7) bbr_troubleshooting ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
