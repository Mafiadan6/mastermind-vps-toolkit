#!/bin/bash

# Mastermind VPS Toolkit - UDP Optimization
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Show UDP optimization menu
show_udp_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             UDP OPTIMIZATION                                 ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Current UDP Configuration:${NC}"
    echo -e "  UDP Read Buffer Min: $(sysctl net.ipv4.udp_rmem_min | cut -d' ' -f3)"
    echo -e "  UDP Write Buffer Min: $(sysctl net.ipv4.udp_wmem_min | cut -d' ' -f3)"
    echo -e "  Core Read Buffer Max: $(sysctl net.core.rmem_max | cut -d' ' -f3)"
    echo -e "  Core Write Buffer Max: $(sysctl net.core.wmem_max | cut -d' ' -f3)"
    echo -e "  Receive Buffer Default: $(sysctl net.core.rmem_default | cut -d' ' -f3)"
    
    echo
    echo -e "${YELLOW}UDP Statistics:${NC}"
    local udp_stats=$(cat /proc/net/snmp | grep Udp: | tail -1)
    if [ -n "$udp_stats" ]; then
        local in_datagrams=$(echo $udp_stats | awk '{print $2}')
        local out_datagrams=$(echo $udp_stats | awk '{print $5}')
        echo -e "  Incoming Datagrams: $in_datagrams"
        echo -e "  Outgoing Datagrams: $out_datagrams"
    fi
    
    echo
    echo -e "${YELLOW}  [1] Apply UDP Optimizations${NC}"
    echo -e "${YELLOW}  [2] Gaming/Real-time Optimization${NC}"
    echo -e "${YELLOW}  [3] Streaming Optimization${NC}"
    echo -e "${YELLOW}  [4] VPN/Tunnel Optimization${NC}"
    echo -e "${YELLOW}  [5] Custom UDP Configuration${NC}"
    echo -e "${YELLOW}  [6] UDP Performance Test${NC}"
    echo -e "${YELLOW}  [7] View Detailed Statistics${NC}"
    echo -e "${YELLOW}  [8] Reset UDP Settings${NC}"
    echo -e "${YELLOW}  [0] Back to Network Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Apply general UDP optimizations
apply_udp_optimizations() {
    log_info "Applying general UDP optimizations..."
    
    # Backup current configuration
    backup_file /etc/sysctl.conf
    
    cat >> /etc/sysctl.conf << 'EOF'

# UDP Optimization - Mastermind VPS Toolkit
# UDP Buffer Settings
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.core.rmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_default = 262144
net.core.wmem_max = 67108864

# Network Device Settings
net.core.netdev_max_backlog = 5000
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 8000

# Socket Settings
net.core.optmem_max = 65536
net.core.busy_read = 50
net.core.busy_poll = 50

# IP Settings for UDP
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.ip_no_pmtu_disc = 0

# Multicast Settings
net.ipv4.igmp_max_memberships = 20
net.ipv4.igmp_max_msf = 10

# Fragment Handling
net.ipv4.ipfrag_high_thresh = 4194304
net.ipv4.ipfrag_low_thresh = 3145728
net.ipv4.ipfrag_time = 30
net.ipv4.ipfrag_max_dist = 64
EOF
    
    # Apply settings
    sysctl -p
    
    log_info "UDP optimizations applied successfully"
    
    echo
    echo -e "${GREEN}UDP optimizations applied:${NC}"
    echo -e "  ✓ UDP buffer sizes increased"
    echo -e "  ✓ Network device settings optimized"
    echo -e "  ✓ Socket performance enhanced"
    echo -e "  ✓ Fragment handling improved"
    echo -e "  ✓ Port range optimized"
    
    wait_for_key
}

# Gaming/Real-time optimization
gaming_optimization() {
    log_info "Applying gaming/real-time UDP optimizations..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# Gaming/Real-time UDP Optimization - Mastermind VPS Toolkit
# Low Latency Settings
net.core.rmem_default = 131072
net.core.rmem_max = 134217728
net.core.wmem_default = 131072
net.core.wmem_max = 134217728

# Minimize UDP buffer delays
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# Network device priority
net.core.netdev_max_backlog = 10000
net.core.netdev_budget = 300
net.core.netdev_budget_usecs = 4000

# Reduce processing delays
net.core.busy_read = 50
net.core.busy_poll = 50

# Optimize for small packets
net.ipv4.ipfrag_high_thresh = 8388608
net.ipv4.ipfrag_low_thresh = 6291456

# CPU scheduling for network
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 0
EOF
    
    # Apply settings
    sysctl -p
    
    # Set network interface optimizations
    for interface in $(ip link show | grep -E "^[0-9]+:" | grep -v lo | cut -d: -f2 | tr -d ' '); do
        if [ -d "/sys/class/net/$interface" ]; then
            # Optimize interrupt coalescence
            ethtool -C "$interface" rx-usecs 1 tx-usecs 1 2>/dev/null || true
            # Optimize ring buffer
            ethtool -G "$interface" rx 4096 tx 4096 2>/dev/null || true
            echo -e "  ✓ Optimized interface: $interface"
        fi
    done
    
    log_info "Gaming/real-time optimizations applied"
    
    echo
    echo -e "${GREEN}Gaming optimizations applied:${NC}"
    echo -e "  ✓ Low latency settings configured"
    echo -e "  ✓ Buffer delays minimized"
    echo -e "  ✓ Processing delays reduced"
    echo -e "  ✓ Network interfaces optimized"
    echo -e "  ✓ CPU scheduling optimized"
    
    wait_for_key
}

# Streaming optimization
streaming_optimization() {
    log_info "Applying streaming UDP optimizations..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# Streaming UDP Optimization - Mastermind VPS Toolkit
# Large Buffer Settings for Streaming
net.core.rmem_default = 524288
net.core.rmem_max = 268435456
net.core.wmem_default = 524288
net.core.wmem_max = 268435456

# UDP Streaming Buffers
net.ipv4.udp_rmem_min = 32768
net.ipv4.udp_wmem_min = 32768

# High throughput settings
net.core.netdev_max_backlog = 30000
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 8000

# Multicast optimization for streaming
net.ipv4.igmp_max_memberships = 100
net.ipv4.igmp_max_msf = 64

# Fragment handling for large packets
net.ipv4.ipfrag_high_thresh = 16777216
net.ipv4.ipfrag_low_thresh = 12582912
net.ipv4.ipfrag_time = 60

# Memory pressure handling
vm.min_free_kbytes = 131072
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
EOF
    
    # Apply settings
    sysctl -p
    
    # Optimize network interfaces for high throughput
    for interface in $(ip link show | grep -E "^[0-9]+:" | grep -v lo | cut -d: -f2 | tr -d ' '); do
        if [ -d "/sys/class/net/$interface" ]; then
            # Increase ring buffer for high throughput
            ethtool -G "$interface" rx 8192 tx 8192 2>/dev/null || true
            # Optimize interrupt settings
            ethtool -C "$interface" rx-usecs 50 tx-usecs 50 2>/dev/null || true
            echo -e "  ✓ Optimized interface for streaming: $interface"
        fi
    done
    
    log_info "Streaming optimizations applied"
    
    echo
    echo -e "${GREEN}Streaming optimizations applied:${NC}"
    echo -e "  ✓ Large buffers configured"
    echo -e "  ✓ High throughput settings applied"
    echo -e "  ✓ Multicast optimized"
    echo -e "  ✓ Fragment handling improved"
    echo -e "  ✓ Memory pressure handling optimized"
    
    wait_for_key
}

# VPN/Tunnel optimization
vpn_optimization() {
    log_info "Applying VPN/tunnel UDP optimizations..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# VPN/Tunnel UDP Optimization - Mastermind VPS Toolkit
# Tunnel Buffer Settings
net.core.rmem_default = 262144
net.core.rmem_max = 134217728
net.core.wmem_default = 262144
net.core.wmem_max = 134217728

# UDP Tunnel Specific
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# MTU Discovery for tunnels
net.ipv4.ip_no_pmtu_disc = 0
net.ipv4.tcp_mtu_probing = 1

# Fragment handling for encapsulation
net.ipv4.ipfrag_high_thresh = 8388608
net.ipv4.ipfrag_low_thresh = 6291456
net.ipv4.ipfrag_time = 30

# Network namespace optimization
net.core.netdev_max_backlog = 5000
net.core.netdev_budget = 300

# Routing table optimization
net.ipv4.route.max_size = 2097152
net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh3 = 8192

# TUN/TAP optimization
net.core.optmem_max = 131072
EOF
    
    # Apply settings
    sysctl -p
    
    # Load TUN module if not loaded
    modprobe tun 2>/dev/null || true
    echo "tun" >> /etc/modules-load.d/modules.conf 2>/dev/null || true
    
    log_info "VPN/tunnel optimizations applied"
    
    echo
    echo -e "${GREEN}VPN/tunnel optimizations applied:${NC}"
    echo -e "  ✓ Tunnel buffers optimized"
    echo -e "  ✓ MTU discovery enabled"
    echo -e "  ✓ Fragment handling improved"
    echo -e "  ✓ Routing optimization applied"
    echo -e "  ✓ TUN/TAP module loaded"
    
    wait_for_key
}

# Custom UDP configuration
custom_udp_configuration() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           CUSTOM UDP CONFIGURATION                          ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Configure UDP Buffer Sizes${NC}"
        echo -e "${YELLOW}  [2] Configure Network Device Settings${NC}"
        echo -e "${YELLOW}  [3] Configure Fragment Handling${NC}"
        echo -e "${YELLOW}  [4] Configure Multicast Settings${NC}"
        echo -e "${YELLOW}  [5] Configure Socket Options${NC}"
        echo -e "${YELLOW}  [0] Back to UDP Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) configure_udp_buffers ;;
            2) configure_network_device ;;
            3) configure_fragment_handling ;;
            4) configure_multicast ;;
            5) configure_socket_options ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Configure UDP buffers
configure_udp_buffers() {
    echo
    echo -e "${YELLOW}UDP Buffer Configuration${NC}"
    echo
    
    echo -e "${YELLOW}Current buffer sizes:${NC}"
    echo -e "  UDP Read Min: $(sysctl net.ipv4.udp_rmem_min | cut -d' ' -f3)"
    echo -e "  UDP Write Min: $(sysctl net.ipv4.udp_wmem_min | cut -d' ' -f3)"
    echo -e "  Core Read Max: $(sysctl net.core.rmem_max | cut -d' ' -f3)"
    echo -e "  Core Write Max: $(sysctl net.core.wmem_max | cut -d' ' -f3)"
    echo
    
    local udp_rmem_min
    udp_rmem_min=$(get_input "UDP minimum read buffer size" "validate_number" "8192")
    
    local udp_wmem_min
    udp_wmem_min=$(get_input "UDP minimum write buffer size" "validate_number" "8192")
    
    local rmem_max
    rmem_max=$(get_input "Core maximum read buffer size" "validate_number" "67108864")
    
    local wmem_max
    wmem_max=$(get_input "Core maximum write buffer size" "validate_number" "67108864")
    
    # Apply settings
    sysctl net.ipv4.udp_rmem_min=$udp_rmem_min
    sysctl net.ipv4.udp_wmem_min=$udp_wmem_min
    sysctl net.core.rmem_max=$rmem_max
    sysctl net.core.wmem_max=$wmem_max
    
    # Save to configuration
    cat >> /etc/sysctl.conf << EOF

# Custom UDP Buffer Configuration
net.ipv4.udp_rmem_min = $udp_rmem_min
net.ipv4.udp_wmem_min = $udp_wmem_min
net.core.rmem_max = $rmem_max
net.core.wmem_max = $wmem_max
EOF
    
    log_info "UDP buffer configuration updated"
    wait_for_key
}

# Configure network device settings
configure_network_device() {
    echo
    echo -e "${YELLOW}Network Device Configuration${NC}"
    echo
    
    local netdev_backlog
    netdev_backlog=$(get_input "Network device max backlog" "validate_number" "5000")
    
    local netdev_budget
    netdev_budget=$(get_input "Network device budget" "validate_number" "600")
    
    local netdev_budget_usecs
    netdev_budget_usecs=$(get_input "Network device budget usecs" "validate_number" "8000")
    
    # Apply settings
    sysctl net.core.netdev_max_backlog=$netdev_backlog
    sysctl net.core.netdev_budget=$netdev_budget
    sysctl net.core.netdev_budget_usecs=$netdev_budget_usecs
    
    # Save to configuration
    cat >> /etc/sysctl.conf << EOF

# Custom Network Device Configuration
net.core.netdev_max_backlog = $netdev_backlog
net.core.netdev_budget = $netdev_budget
net.core.netdev_budget_usecs = $netdev_budget_usecs
EOF
    
    log_info "Network device configuration updated"
    wait_for_key
}

# Configure fragment handling
configure_fragment_handling() {
    echo
    echo -e "${YELLOW}Fragment Handling Configuration${NC}"
    echo
    
    local frag_high_thresh
    frag_high_thresh=$(get_input "Fragment high threshold" "validate_number" "4194304")
    
    local frag_low_thresh
    frag_low_thresh=$(get_input "Fragment low threshold" "validate_number" "3145728")
    
    local frag_time
    frag_time=$(get_input "Fragment timeout (seconds)" "validate_number" "30")
    
    # Apply settings
    sysctl net.ipv4.ipfrag_high_thresh=$frag_high_thresh
    sysctl net.ipv4.ipfrag_low_thresh=$frag_low_thresh
    sysctl net.ipv4.ipfrag_time=$frag_time
    
    # Save to configuration
    cat >> /etc/sysctl.conf << EOF

# Custom Fragment Handling Configuration
net.ipv4.ipfrag_high_thresh = $frag_high_thresh
net.ipv4.ipfrag_low_thresh = $frag_low_thresh
net.ipv4.ipfrag_time = $frag_time
EOF
    
    log_info "Fragment handling configuration updated"
    wait_for_key
}

# Configure multicast settings
configure_multicast() {
    echo
    echo -e "${YELLOW}Multicast Configuration${NC}"
    echo
    
    local igmp_memberships
    igmp_memberships=$(get_input "IGMP max memberships" "validate_number" "20")
    
    local igmp_msf
    igmp_msf=$(get_input "IGMP max source filter" "validate_number" "10")
    
    # Apply settings
    sysctl net.ipv4.igmp_max_memberships=$igmp_memberships
    sysctl net.ipv4.igmp_max_msf=$igmp_msf
    
    # Save to configuration
    cat >> /etc/sysctl.conf << EOF

# Custom Multicast Configuration
net.ipv4.igmp_max_memberships = $igmp_memberships
net.ipv4.igmp_max_msf = $igmp_msf
EOF
    
    log_info "Multicast configuration updated"
    wait_for_key
}

# Configure socket options
configure_socket_options() {
    echo
    echo -e "${YELLOW}Socket Options Configuration${NC}"
    echo
    
    local optmem_max
    optmem_max=$(get_input "Socket option memory max" "validate_number" "65536")
    
    local busy_read
    busy_read=$(get_input "Busy read microseconds" "validate_number" "50")
    
    local busy_poll
    busy_poll=$(get_input "Busy poll microseconds" "validate_number" "50")
    
    # Apply settings
    sysctl net.core.optmem_max=$optmem_max
    sysctl net.core.busy_read=$busy_read
    sysctl net.core.busy_poll=$busy_poll
    
    # Save to configuration
    cat >> /etc/sysctl.conf << EOF

# Custom Socket Options Configuration
net.core.optmem_max = $optmem_max
net.core.busy_read = $busy_read
net.core.busy_poll = $busy_poll
EOF
    
    log_info "Socket options configuration updated"
    wait_for_key
}

# UDP performance test
udp_performance_test() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             UDP PERFORMANCE TEST                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Running UDP performance tests..."
    echo
    
    # Test 1: Buffer size verification
    echo -e "${YELLOW}1. Buffer Size Verification:${NC}"
    echo -e "   UDP Read Min: $(sysctl net.ipv4.udp_rmem_min | cut -d' ' -f3) bytes"
    echo -e "   UDP Write Min: $(sysctl net.ipv4.udp_wmem_min | cut -d' ' -f3) bytes"
    echo -e "   Core Read Max: $(sysctl net.core.rmem_max | cut -d' ' -f3) bytes"
    echo -e "   Core Write Max: $(sysctl net.core.wmem_max | cut -d' ' -f3) bytes"
    echo
    
    # Test 2: Network interface statistics
    echo -e "${YELLOW}2. Network Interface Statistics:${NC}"
    for interface in $(ip link show | grep -E "^[0-9]+:" | grep -v lo | cut -d: -f2 | tr -d ' '); do
        if [ -d "/sys/class/net/$interface" ]; then
            local rx_packets=$(cat /sys/class/net/$interface/statistics/rx_packets)
            local tx_packets=$(cat /sys/class/net/$interface/statistics/tx_packets)
            local rx_errors=$(cat /sys/class/net/$interface/statistics/rx_errors)
            local tx_errors=$(cat /sys/class/net/$interface/statistics/tx_errors)
            
            echo -e "   Interface: $interface"
            echo -e "     RX Packets: $rx_packets, Errors: $rx_errors"
            echo -e "     TX Packets: $tx_packets, Errors: $tx_errors"
        fi
    done
    echo
    
    # Test 3: UDP statistics
    echo -e "${YELLOW}3. UDP Protocol Statistics:${NC}"
    local udp_stats=$(cat /proc/net/snmp | grep Udp: | tail -1)
    if [ -n "$udp_stats" ]; then
        local in_datagrams=$(echo $udp_stats | awk '{print $2}')
        local no_ports=$(echo $udp_stats | awk '{print $3}')
        local in_errors=$(echo $udp_stats | awk '{print $4}')
        local out_datagrams=$(echo $udp_stats | awk '{print $5}')
        
        echo -e "   Incoming Datagrams: $in_datagrams"
        echo -e "   No Port Errors: $no_ports"
        echo -e "   Input Errors: $in_errors"
        echo -e "   Outgoing Datagrams: $out_datagrams"
    fi
    echo
    
    # Test 4: Fragment statistics
    echo -e "${YELLOW}4. Fragment Statistics:${NC}"
    if [ -f /proc/net/netstat ]; then
        local frag_stats=$(grep IpExt /proc/net/netstat | tail -1)
        if [ -n "$frag_stats" ]; then
            echo -e "   Fragment statistics available in /proc/net/netstat"
        fi
    fi
    echo
    
    # Test 5: Simple UDP test (if netcat is available)
    echo -e "${YELLOW}5. UDP Connectivity Test:${NC}"
    if command_exists nc; then
        echo -e "   Testing UDP echo on localhost..."
        # Start a simple UDP echo server in background
        timeout 5 nc -u -l 12345 < /dev/null &
        sleep 1
        # Test connectivity
        if echo "test" | timeout 2 nc -u localhost 12345 >/dev/null 2>&1; then
            echo -e "   ${GREEN}✓ UDP connectivity test passed${NC}"
        else
            echo -e "   ${YELLOW}? UDP connectivity test inconclusive${NC}"
        fi
    else
        echo -e "   netcat not available for connectivity test"
    fi
    echo
    
    wait_for_key
}

# View detailed statistics
view_detailed_statistics() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           DETAILED UDP STATISTICS                           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}UDP Configuration Summary:${NC}"
    echo -e "  UDP Read Buffer Min: $(sysctl net.ipv4.udp_rmem_min | cut -d' ' -f3)"
    echo -e "  UDP Write Buffer Min: $(sysctl net.ipv4.udp_wmem_min | cut -d' ' -f3)"
    echo -e "  Core Read Buffer Max: $(sysctl net.core.rmem_max | cut -d' ' -f3)"
    echo -e "  Core Write Buffer Max: $(sysctl net.core.wmem_max | cut -d' ' -f3)"
    echo -e "  Network Device Backlog: $(sysctl net.core.netdev_max_backlog | cut -d' ' -f3)"
    echo -e "  Network Device Budget: $(sysctl net.core.netdev_budget | cut -d' ' -f3)"
    echo
    
    echo -e "${YELLOW}Fragment Handling:${NC}"
    echo -e "  Fragment High Threshold: $(sysctl net.ipv4.ipfrag_high_thresh | cut -d' ' -f3)"
    echo -e "  Fragment Low Threshold: $(sysctl net.ipv4.ipfrag_low_thresh | cut -d' ' -f3)"
    echo -e "  Fragment Timeout: $(sysctl net.ipv4.ipfrag_time | cut -d' ' -f3) seconds"
    echo
    
    echo -e "${YELLOW}Socket Statistics:${NC}"
    if [ -f /proc/net/sockstat ]; then
        grep UDP /proc/net/sockstat | sed 's/^/  /'
    fi
    echo
    
    echo -e "${YELLOW}UDP Protocol Statistics:${NC}"
    if [ -f /proc/net/snmp ]; then
        echo -e "  Raw UDP Statistics:"
        grep Udp: /proc/net/snmp | sed 's/^/    /'
    fi
    echo
    
    echo -e "${YELLOW}Network Interface Details:${NC}"
    for interface in $(ip link show | grep -E "^[0-9]+:" | grep -v lo | cut -d: -f2 | tr -d ' '); do
        if [ -d "/sys/class/net/$interface" ]; then
            echo -e "  Interface: $interface"
            echo -e "    State: $(cat /sys/class/net/$interface/operstate)"
            echo -e "    MTU: $(cat /sys/class/net/$interface/mtu)"
            if [ -f "/sys/class/net/$interface/statistics/rx_packets" ]; then
                echo -e "    RX Packets: $(cat /sys/class/net/$interface/statistics/rx_packets)"
                echo -e "    TX Packets: $(cat /sys/class/net/$interface/statistics/tx_packets)"
                echo -e "    RX Bytes: $(cat /sys/class/net/$interface/statistics/rx_bytes)"
                echo -e "    TX Bytes: $(cat /sys/class/net/$interface/statistics/tx_bytes)"
            fi
        fi
    done
    echo
    
    echo -e "${YELLOW}Memory Statistics:${NC}"
    if [ -f /proc/meminfo ]; then
        grep -E "(MemTotal|MemFree|Buffers|Cached)" /proc/meminfo | sed 's/^/  /'
    fi
    echo
    
    wait_for_key
}

# Reset UDP settings
reset_udp_settings() {
    if confirm "Reset all UDP settings to system defaults?"; then
        log_info "Resetting UDP settings to defaults..."
        
        # Remove custom UDP configurations
        sed -i '/# UDP Optimization - Mastermind VPS Toolkit/,/^$/d' /etc/sysctl.conf
        sed -i '/# Gaming\/Real-time UDP Optimization - Mastermind VPS Toolkit/,/^$/d' /etc/sysctl.conf
        sed -i '/# Streaming UDP Optimization - Mastermind VPS Toolkit/,/^$/d' /etc/sysctl.conf
        sed -i '/# VPN\/Tunnel UDP Optimization - Mastermind VPS Toolkit/,/^$/d' /etc/sysctl.conf
        sed -i '/# Custom UDP.*Configuration/,/^$/d' /etc/sysctl.conf
        
        # Reset to default values
        sysctl net.ipv4.udp_rmem_min=4096
        sysctl net.ipv4.udp_wmem_min=4096
        sysctl net.core.rmem_default=212992
        sysctl net.core.wmem_default=212992
        sysctl net.core.rmem_max=212992
        sysctl net.core.wmem_max=212992
        sysctl net.core.netdev_max_backlog=1000
        sysctl net.core.netdev_budget=300
        
        log_info "UDP settings reset to defaults"
        
        if confirm "Reboot to ensure all settings are applied?"; then
            reboot
        fi
    fi
    
    wait_for_key
}

# Validate number
validate_number() {
    local number=$1
    if [[ $number =~ ^[0-9]+$ ]] && [ "$number" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Main function
main() {
    while true; do
        show_udp_menu
        read -p "Enter your choice [0-8]: " choice
        
        case $choice in
            1) apply_udp_optimizations ;;
            2) gaming_optimization ;;
            3) streaming_optimization ;;
            4) vpn_optimization ;;
            5) custom_udp_configuration ;;
            6) udp_performance_test ;;
            7) view_detailed_statistics ;;
            8) reset_udp_settings ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
