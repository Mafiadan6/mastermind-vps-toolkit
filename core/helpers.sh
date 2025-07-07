#!/bin/bash

# Mastermind VPS Toolkit - Helper Functions
# Version: 2.0.0

# Set default log directory
LOG_DIR="${LOG_DIR:-/var/log/mastermind}"

# Ensure log directory exists
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

# Enhanced logging functions
log_info() {
    echo -e "\033[0;36m[INFO]\033[0m $1" | tee -a "$LOG_DIR/mastermind.log"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1" | tee -a "$LOG_DIR/mastermind.log"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" | tee -a "$LOG_DIR/mastermind.log" >&2
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1" | tee -a "$LOG_DIR/mastermind.log"
}

# System utilities
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Command '$cmd' not found. Please install it first."
        return 1
    fi
    return 0
}

ensure_directory() {
    local dir="$1"
    if [ -z "$dir" ]; then
        log_error "Directory path cannot be empty"
        return 1
    fi
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    fi
}

# Service management helpers
service_start() {
    local service="$1"
    if systemctl start "$service" 2>/dev/null; then
        log_success "Started service: $service"
        return 0
    else
        log_error "Failed to start service: $service"
        return 1
    fi
}

# Get service status with proper formatting
get_service_status() {
    local service="$1"
    if systemctl is-active "$service" >/dev/null 2>&1; then
        echo -e "${GREEN}● Running${NC}"
    elif systemctl is-enabled "$service" >/dev/null 2>&1; then
        echo -e "${YELLOW}● Stopped${NC}"
    else
        echo -e "${RED}○ Not Configured${NC}"
    fi
}

# Get port status
get_port_status() {
    local port="$1"
    if netstat -tuln | grep -q ":$port "; then
        echo -e "${GREEN}Open${NC}"
    else
        echo -e "${RED}Closed${NC}"
    fi
}

# Color definitions for helpers
if [ -z "$RED" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
fi

# Wait for key press
wait_for_key() {
    echo
    read -p "Press any key to continue..." -n 1
    echo
}

service_stop() {
    local service="$1"
    if systemctl stop "$service" 2>/dev/null; then
        log_success "Stopped service: $service"
        return 0
    else
        log_error "Failed to stop service: $service"
        return 1
    fi
}

service_restart() {
    local service="$1"
    if systemctl restart "$service" 2>/dev/null; then
        log_success "Restarted service: $service"
        return 0
    else
        log_error "Failed to restart service: $service"
        return 1
    fi
}

service_enable() {
    local service="$1"
    if systemctl enable "$service" 2>/dev/null; then
        log_success "Enabled service: $service"
        return 0
    else
        log_error "Failed to enable service: $service"
        return 1
    fi
}

# User input validation
validate_username() {
    local username="$1"
    if [[ ! "$username" =~ ^[a-zA-Z][a-zA-Z0-9_-]{2,31}$ ]]; then
        log_error "Invalid username format. Must start with letter, 3-32 chars, alphanumeric/underscore/dash only."
        return 1
    fi
    return 0
}

validate_port() {
    local port="$1"
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "Invalid port number. Must be between 1-65535."
        return 1
    fi
    return 0
}

validate_ip() {
    local ip="$1"
    if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        log_error "Invalid IP address format."
        return 1
    fi
    
    IFS='.' read -ra ADDR <<< "$ip"
    for i in "${ADDR[@]}"; do
        if [ "$i" -gt 255 ]; then
            log_error "Invalid IP address: octet out of range."
            return 1
        fi
    done
    return 0
}

# Network utilities
check_port_available() {
    local port="$1"
    if ss -tuln | grep -q ":$port "; then
        log_warn "Port $port is already in use"
        return 1
    fi
    return 0
}

get_external_ip() {
    local ip
    ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null) || \
    ip=$(curl -s --max-time 5 icanhazip.com 2>/dev/null) || \
    ip=$(curl -s --max-time 5 ipecho.net/plain 2>/dev/null) || \
    ip="Unknown"
    echo "$ip"
}

# File operations
backup_file() {
    local file="$1"
    local backup_dir="$2"
    
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        return 1
    fi
    
    ensure_directory "$backup_dir"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$backup_dir/$(basename "$file").backup.$timestamp"
    
    if cp "$file" "$backup_path"; then
        log_success "Backed up $file to $backup_path"
        echo "$backup_path"
        return 0
    else
        log_error "Failed to backup $file"
        return 1
    fi
}

# Configuration management
read_config() {
    local config_file="$1"
    local key="$2"
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    grep "^$key=" "$config_file" | cut -d'=' -f2- | tr -d '"'
}

write_config() {
    local config_file="$1"
    local key="$2"
    local value="$3"
    
    if [ ! -f "$config_file" ]; then
        touch "$config_file"
    fi
    
    # Remove existing key
    sed -i "/^$key=/d" "$config_file"
    # Add new key=value
    echo "$key=\"$value\"" >> "$config_file"
}

# Progress display
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# SSH key management
generate_ssh_key() {
    local username="$1"
    local key_type="$2"
    local key_comment="$3"
    
    local user_home="/home/$username"
    if [ "$username" = "root" ]; then
        user_home="/root"
    fi
    
    local ssh_dir="$user_home/.ssh"
    ensure_directory "$ssh_dir"
    
    local key_file="$ssh_dir/id_$key_type"
    
    if [ -f "$key_file" ]; then
        log_warn "SSH key already exists for $username"
        return 1
    fi
    
    ssh-keygen -t "$key_type" -f "$key_file" -C "$key_comment" -N ""
    chown -R "$username:$username" "$ssh_dir"
    chmod 700 "$ssh_dir"
    chmod 600 "$key_file"
    chmod 644 "$key_file.pub"
    
    log_success "Generated SSH key for $username"
    echo "$key_file.pub"
}

# System optimization
optimize_system_limits() {
    local limits_file="/etc/security/limits.conf"
    
    # Backup current limits
    backup_file "$limits_file" "/opt/mastermind/backups"
    
    # Add optimized limits
    cat >> "$limits_file" << 'EOF'

# Mastermind VPS Toolkit - Optimized Limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
root soft nofile 65536
root hard nofile 65536
EOF

    log_success "Applied system limit optimizations"
}

# Monitoring functions
get_cpu_cores() {
    nproc
}

get_total_memory() {
    free -h | awk '/^Mem:/ {print $2}'
}

get_disk_space() {
    df -h / | awk 'NR==2{print $2}'
}

get_network_interface() {
    ip route | grep default | awk '{print $5}' | head -1
}

# QR Code generation helper
generate_qr_text() {
    local text="$1"
    local size="${2:-medium}"
    
    if ! check_command qrencode; then
        log_error "QR code generation requires qrencode package"
        return 1
    fi
    
    case "$size" in
        small) qrencode -t ansiutf8 -s 1 "$text" ;;
        medium) qrencode -t ansiutf8 -s 2 "$text" ;;
        large) qrencode -t ansiutf8 -s 3 "$text" ;;
        *) qrencode -t ansiutf8 -s 2 "$text" ;;
    esac
}

# Firewall helpers
ufw_allow_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    local comment="$3"
    
    if [ -n "$comment" ]; then
        ufw allow "$port/$protocol" comment "$comment"
    else
        ufw allow "$port/$protocol"
    fi
    
    log_success "Allowed port $port/$protocol in firewall"
}

ufw_deny_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    
    ufw deny "$port/$protocol"
    log_success "Denied port $port/$protocol in firewall"
}

# Error handling
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    log_error "An error occurred on line $line_number (exit code: $exit_code)"
    exit $exit_code
}

# Set error trap
trap 'handle_error ${LINENO}' ERR

# Cleanup functions
cleanup_temp_files() {
    local temp_dir="/tmp/mastermind"
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
        log_info "Cleaned up temporary files"
    fi
}

cleanup_old_logs() {
    local log_dir="$1"
    local days="${2:-7}"
    
    if [ -d "$log_dir" ]; then
        find "$log_dir" -name "*.log" -mtime +$days -delete
        log_info "Cleaned up logs older than $days days"
    fi
}

# Service dependency checking
check_service_dependencies() {
    local service="$1"
    
    case "$service" in
        "python-proxy")
            check_command python3 || return 1
            check_command pip3 || return 1
            ;;
        "v2ray")
            check_command curl || return 1
            ;;
        "nginx")
            check_command nginx || return 1
            ;;
        *)
            log_warn "No dependency check defined for service: $service"
            ;;
    esac
    
    return 0
}

# Auto-completion helpers
get_available_users() {
    cut -d: -f1 /etc/passwd | grep -v -E '^(root|daemon|bin|sys|sync|games|man|lp|mail|news|uucp|proxy|www-data|backup|list|irc|gnats|nobody|_apt)$'
}

get_available_services() {
    systemctl list-unit-files --type=service | awk '{print $1}' | grep -E '^(python-proxy|tcp-bypass|v2ray|nginx|fail2ban|ufw)'
}

# Time and date helpers
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

get_date_filename() {
    date '+%Y%m%d_%H%M%S'
}

# Version checking
check_version() {
    local component="$1"
    
    case "$component" in
        "mastermind")
            echo "2.0.0"
            ;;
        "python")
            python3 --version 2>/dev/null | cut -d' ' -f2
            ;;
        "kernel")
            uname -r
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Initialize helper environment
init_helpers() {
    # Ensure log directory exists
    ensure_directory "$LOG_DIR"
    
    # Set proper permissions
    chmod 755 "$LOG_DIR"
    
    # Initialize log file
    touch "$LOG_DIR/mastermind.log"
    chmod 644 "$LOG_DIR/mastermind.log"
    
    log_info "Helper functions initialized"
}

# Additional functions for V2Ray and other protocols
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_service_status() {
    local service="$1"
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "\033[32mRunning\033[0m"
    elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
        echo -e "\033[33mStopped\033[0m"
    else
        echo -e "\033[31mDisabled\033[0m"
    fi
}

get_port_status() {
    local port="$1"
    if ss -tuln | grep -q ":${port} "; then
        echo -e "\033[32mOpen\033[0m"
    else
        echo -e "\033[31mClosed\033[0m"
    fi
}

is_service_running() {
    local service="$1"
    systemctl is-active --quiet "$service" 2>/dev/null
}

get_public_ip() {
    curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "Unknown"
}

wait_for_key() {
    echo
    read -p "Press Enter to continue..." -r
}

get_input() {
    local prompt="$1"
    local validator="$2"
    local default="$3"
    local input=""
    
    while true; do
        if [ -n "$default" ]; then
            read -p "$prompt [$default]: " input
            input="${input:-$default}"
        else
            read -p "$prompt: " input
        fi
        
        if [ -z "$validator" ] || "$validator" "$input"; then
            echo "$input"
            return 0
        fi
    done
}

validate_number() {
    local input="$1"
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        return 0
    else
        log_error "Invalid number format"
        return 1
    fi
}

confirm() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$prompt [y/N]: " response
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]|"") return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

validate_config() {
    local config_file="${1:-$V2RAY_CONFIG_FILE}"
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Check if it's valid JSON
    if command_exists jq; then
        jq empty "$config_file" 2>/dev/null
        return $?
    else
        # Basic JSON validation
        python3 -m json.tool "$config_file" >/dev/null 2>&1
        return $?
    fi
}

# Auto-initialize when sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    init_helpers
fi