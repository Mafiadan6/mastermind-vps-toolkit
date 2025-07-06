#!/bin/bash

# Mastermind VPS Toolkit - Kernel Tuning
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Show kernel tuning menu
show_kernel_tuning_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             KERNEL TUNING                                    ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Current System Information:${NC}"
    echo -e "  Kernel: $(uname -r)"
    echo -e "  Architecture: $(uname -m)"
    echo -e "  CPU Cores: $(nproc)"
    echo -e "  Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
    echo -e "  Uptime: $(uptime -p)"
    
    echo
    echo -e "${YELLOW}  [1] Network Performance Tuning${NC}"
    echo -e "${YELLOW}  [2] Memory Management Tuning${NC}"
    echo -e "${YELLOW}  [3] File System Tuning${NC}"
    echo -e "${YELLOW}  [4] Security Hardening${NC}"
    echo -e "${YELLOW}  [5] I/O Scheduler Optimization${NC}"
    echo -e "${YELLOW}  [6] Apply All Optimizations${NC}"
    echo -e "${YELLOW}  [7] View Current Settings${NC}"
    echo -e "${YELLOW}  [8] Reset to Defaults${NC}"
    echo -e "${YELLOW}  [0] Back to Network Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Network performance tuning
network_performance_tuning() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           NETWORK PERFORMANCE TUNING                        ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Applying network performance optimizations..."
    
    # Backup current configuration
    backup_file /etc/sysctl.conf
    
    cat >> /etc/sysctl.conf << 'EOF'

# Network Performance Tuning - Mastermind VPS Toolkit
# TCP/IP Stack Optimization
net.core.rmem_default = 262144
net.core.rmem_max = 134217728
net.core.wmem_default = 262144
net.core.wmem_max = 134217728
net.core.netdev_max_backlog = 30000
net.core.netdev_budget = 600

# TCP Buffer Sizes
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_mem = 786432 1048576 26777216

# TCP Optimization
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_reordering = 3
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_syn_retries = 6
net.ipv4.tcp_synack_retries = 5

# TCP Connection Management
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 9
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_orphans = 65536

# TCP Fast Open
net.ipv4.tcp_fastopen = 3

# IP Settings
net.ipv4.ip_forward = 0
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# UDP Optimization
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# Congestion Control
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_mtu_probing = 1

# Socket Settings
net.core.somaxconn = 32768
net.core.optmem_max = 65536
EOF
    
    # Apply settings
    sysctl -p
    
    log_info "Network performance tuning applied"
    
    echo
    echo -e "${GREEN}Network optimizations applied:${NC}"
    echo -e "  ✓ TCP buffer sizes optimized"
    echo -e "  ✓ Connection handling improved"
    echo -e "  ✓ TCP Fast Open enabled"
    echo -e "  ✓ Congestion control optimized"
    echo -e "  ✓ Socket performance enhanced"
    
    wait_for_key
}

# Memory management tuning
memory_management_tuning() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           MEMORY MANAGEMENT TUNING                          ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Applying memory management optimizations..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# Memory Management Tuning - Mastermind VPS Toolkit
# Virtual Memory Settings
vm.swappiness = 10
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
vm.vfs_cache_pressure = 50

# Memory Overcommit
vm.overcommit_memory = 1
vm.overcommit_ratio = 50

# Kernel Memory Management
vm.min_free_kbytes = 65536
vm.zone_reclaim_mode = 0
vm.page_cluster = 3

# Huge Pages (if supported)
vm.nr_hugepages = 0
vm.hugetlb_shm_group = 0

# OOM Killer
vm.panic_on_oom = 0
vm.oom_kill_allocating_task = 0
vm.oom_dump_tasks = 1
EOF
    
    # Apply settings
    sysctl -p
    
    log_info "Memory management tuning applied"
    
    echo
    echo -e "${GREEN}Memory optimizations applied:${NC}"
    echo -e "  ✓ Swap usage minimized"
    echo -e "  ✓ Dirty page handling optimized"
    echo -e "  ✓ Cache pressure balanced"
    echo -e "  ✓ Memory overcommit configured"
    echo -e "  ✓ OOM killer settings optimized"
    
    wait_for_key
}

# File system tuning
filesystem_tuning() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             FILE SYSTEM TUNING                              ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Applying file system optimizations..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# File System Tuning - Mastermind VPS Toolkit
# File Handles
fs.file-max = 2097152
fs.nr_open = 1048576

# Inode and Dentry Cache
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 1024
fs.inotify.max_queued_events = 32768

# AIO Settings
fs.aio-max-nr = 1048576

# Directory Entry Cache
fs.dentry-state = 0

# Pipe Settings
fs.pipe-max-size = 1048576
EOF
    
    # Apply settings
    sysctl -p
    
    # Update limits.conf for file descriptors
    cat >> /etc/security/limits.conf << 'EOF'

# File Descriptor Limits - Mastermind VPS Toolkit
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
root soft nofile 65536
root hard nofile 65536
root soft nproc unlimited
root hard nproc unlimited
EOF
    
    log_info "File system tuning applied"
    
    echo
    echo -e "${GREEN}File system optimizations applied:${NC}"
    echo -e "  ✓ File handle limits increased"
    echo -e "  ✓ Inotify settings optimized"
    echo -e "  ✓ AIO capacity increased"
    echo -e "  ✓ Process limits configured"
    
    wait_for_key
}

# Security hardening
security_hardening() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             SECURITY HARDENING                              ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Applying kernel security hardening..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# Security Hardening - Mastermind VPS Toolkit
# Network Security
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# IPv6 Security
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

# Kernel Security
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.core_uses_pid = 1
kernel.ctrl-alt-del = 0

# Memory Protection
kernel.randomize_va_space = 2
kernel.exec-shield = 1
kernel.kexec_load_disabled = 1

# Process Security
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
EOF
    
    # Apply settings
    sysctl -p
    
    log_info "Security hardening applied"
    
    echo
    echo -e "${GREEN}Security hardening applied:${NC}"
    echo -e "  ✓ Network redirects disabled"
    echo -e "  ✓ Source routing disabled"
    echo -e "  ✓ ICMP protection enabled"
    echo -e "  ✓ Kernel protection enabled"
    echo -e "  ✓ Memory protection enhanced"
    echo -e "  ✓ Process security improved"
    
    wait_for_key
}

# I/O scheduler optimization
io_scheduler_optimization() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           I/O SCHEDULER OPTIMIZATION                        ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    log_info "Optimizing I/O scheduler settings..."
    
    # Detect storage type and set appropriate scheduler
    for disk in /sys/block/*/queue/scheduler; do
        if [ -f "$disk" ]; then
            disk_name=$(echo $disk | cut -d'/' -f4)
            echo -e "${YELLOW}Configuring scheduler for $disk_name...${NC}"
            
            # Check if it's an SSD
            if [ -f "/sys/block/$disk_name/queue/rotational" ]; then
                rotational=$(cat /sys/block/$disk_name/queue/rotational)
                if [ "$rotational" = "0" ]; then
                    # SSD - use none or mq-deadline
                    echo "none" > "$disk" 2>/dev/null || echo "mq-deadline" > "$disk" 2>/dev/null
                    echo -e "  ✓ SSD detected: Set to 'none' or 'mq-deadline'"
                else
                    # HDD - use mq-deadline
                    echo "mq-deadline" > "$disk" 2>/dev/null
                    echo -e "  ✓ HDD detected: Set to 'mq-deadline'"
                fi
            fi
        fi
    done
    
    # I/O related sysctl parameters
    cat >> /etc/sysctl.conf << 'EOF'

# I/O Scheduler Tuning - Mastermind VPS Toolkit
# Block Device Settings
vm.block_dump = 0
vm.laptop_mode = 0

# Read-ahead Settings
# These will be set per device basis
EOF
    
    # Set read-ahead for all block devices
    for device in /dev/sd? /dev/nvme?n? /dev/vd?; do
        if [ -b "$device" ]; then
            blockdev --setra 256 "$device" 2>/dev/null
            echo -e "  ✓ Set read-ahead for $device"
        fi
    done
    
    # Apply settings
    sysctl -p
    
    log_info "I/O scheduler optimization completed"
    
    echo
    echo -e "${GREEN}I/O optimizations applied:${NC}"
    echo -e "  ✓ Scheduler optimized per device type"
    echo -e "  ✓ Read-ahead values set"
    echo -e "  ✓ Block device settings optimized"
    
    wait_for_key
}

# Apply all optimizations
apply_all_optimizations() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           APPLY ALL OPTIMIZATIONS                           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    if confirm "Apply all kernel optimizations? This will modify system settings."; then
        echo
        echo -e "${YELLOW}Applying all optimizations...${NC}"
        echo
        
        # Backup current configuration
        backup_file /etc/sysctl.conf
        backup_file /etc/security/limits.conf
        
        # Apply all optimizations
        show_progress 5 "Network performance tuning"
        network_performance_tuning > /dev/null 2>&1
        
        show_progress 5 "Memory management tuning"
        memory_management_tuning > /dev/null 2>&1
        
        show_progress 5 "File system tuning"
        filesystem_tuning > /dev/null 2>&1
        
        show_progress 5 "Security hardening"
        security_hardening > /dev/null 2>&1
        
        show_progress 5 "I/O scheduler optimization"
        io_scheduler_optimization > /dev/null 2>&1
        
        echo
        echo -e "${GREEN}All optimizations applied successfully!${NC}"
        echo
        echo -e "${YELLOW}Summary:${NC}"
        echo -e "  ✓ Network performance optimized"
        echo -e "  ✓ Memory management tuned"
        echo -e "  ✓ File system optimized"
        echo -e "  ✓ Security hardened"
        echo -e "  ✓ I/O scheduler optimized"
        echo
        echo -e "${YELLOW}Note: Some optimizations require a reboot to take full effect.${NC}"
        
        if confirm "Reboot system now to apply all changes?"; then
            reboot
        fi
    fi
    
    wait_for_key
}

# View current settings
view_current_settings() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             CURRENT KERNEL SETTINGS                         ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Network Settings:${NC}"
    echo -e "  TCP Congestion Control: $(sysctl net.ipv4.tcp_congestion_control | cut -d' ' -f3)"
    echo -e "  TCP Window Scaling: $(sysctl net.ipv4.tcp_window_scaling | cut -d' ' -f3)"
    echo -e "  TCP Fast Open: $(sysctl net.ipv4.tcp_fastopen | cut -d' ' -f3)"
    echo -e "  Max Connections: $(sysctl net.core.somaxconn | cut -d' ' -f3)"
    echo
    
    echo -e "${YELLOW}Memory Settings:${NC}"
    echo -e "  Swappiness: $(sysctl vm.swappiness | cut -d' ' -f3)"
    echo -e "  Dirty Ratio: $(sysctl vm.dirty_ratio | cut -d' ' -f3)"
    echo -e "  VFS Cache Pressure: $(sysctl vm.vfs_cache_pressure | cut -d' ' -f3)"
    echo -e "  Overcommit Memory: $(sysctl vm.overcommit_memory | cut -d' ' -f3)"
    echo
    
    echo -e "${YELLOW}File System Settings:${NC}"
    echo -e "  Max File Handles: $(sysctl fs.file-max | cut -d' ' -f3)"
    echo -e "  Inotify Watches: $(sysctl fs.inotify.max_user_watches | cut -d' ' -f3)"
    echo -e "  AIO Max: $(sysctl fs.aio-max-nr | cut -d' ' -f3)"
    echo
    
    echo -e "${YELLOW}Security Settings:${NC}"
    echo -e "  ASLR: $(sysctl kernel.randomize_va_space | cut -d' ' -f3)"
    echo -e "  Ptrace Scope: $(sysctl kernel.yama.ptrace_scope | cut -d' ' -f3)"
    echo -e "  RP Filter: $(sysctl net.ipv4.conf.all.rp_filter | cut -d' ' -f3)"
    echo
    
    echo -e "${YELLOW}I/O Schedulers:${NC}"
    for disk in /sys/block/*/queue/scheduler; do
        if [ -f "$disk" ]; then
            disk_name=$(echo $disk | cut -d'/' -f4)
            current_scheduler=$(cat $disk | grep -o '\[.*\]' | tr -d '[]')
            echo -e "  $disk_name: $current_scheduler"
        fi
    done
    echo
    
    wait_for_key
}

# Reset to defaults
reset_to_defaults() {
    if confirm "Reset all kernel settings to defaults? This will remove custom optimizations."; then
        log_info "Resetting kernel settings to defaults..."
        
        # Remove custom configurations
        sed -i '/# Network Performance Tuning - Mastermind VPS Toolkit/,/^$/d' /etc/sysctl.conf
        sed -i '/# Memory Management Tuning - Mastermind VPS Toolkit/,/^$/d' /etc/sysctl.conf
        sed -i '/# File System Tuning - Mastermind VPS Toolkit/,/^$/d' /etc/sysctl.conf
        sed -i '/# Security Hardening - Mastermind VPS Toolkit/,/^$/d' /etc/sysctl.conf
        sed -i '/# I/O Scheduler Tuning - Mastermind VPS Toolkit/,/^$/d' /etc/sysctl.conf
        
        # Remove limits configuration
        sed -i '/# File Descriptor Limits - Mastermind VPS Toolkit/,/^$/d' /etc/security/limits.conf
        
        # Reset I/O schedulers to default
        for disk in /sys/block/*/queue/scheduler; do
            if [ -f "$disk" ]; then
                echo "mq-deadline" > "$disk" 2>/dev/null
            fi
        done
        
        log_info "Kernel settings reset to defaults"
        
        if confirm "Reboot to apply default settings?"; then
            reboot
        fi
    fi
    
    wait_for_key
}

# Main function
main() {
    while true; do
        show_kernel_tuning_menu
        read -p "Enter your choice [0-8]: " choice
        
        case $choice in
            1) network_performance_tuning ;;
            2) memory_management_tuning ;;
            3) filesystem_tuning ;;
            4) security_hardening ;;
            5) io_scheduler_optimization ;;
            6) apply_all_optimizations ;;
            7) view_current_settings ;;
            8) reset_to_defaults ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Run main function
main "$@"
