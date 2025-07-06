#!/bin/bash

# Mastermind VPS Toolkit - Helper Functions
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

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [ "$DEBUG" = "true" ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Get public IP address
get_public_ip() {
    local ip=$(curl -s ifconfig.me 2>/dev/null)
    if [ -z "$ip" ]; then
        ip=$(curl -s ipinfo.io/ip 2>/dev/null)
    fi
    if [ -z "$ip" ]; then
        ip=$(curl -s icanhazip.com 2>/dev/null)
    fi
    if [ -z "$ip" ]; then
        ip="Unknown"
    fi
    echo "$ip"
}

# Check if service is running
is_service_running() {
    local service_name=$1
    systemctl is-active --quiet "$service_name"
}

# Get service status
get_service_status() {
    local service_name=$1
    if is_service_running "$service_name"; then
        echo -e "${GREEN}RUNNING${NC}"
    else
        echo -e "${RED}STOPPED${NC}"
    fi
}

# Check if port is open
is_port_open() {
    local port=$1
    netstat -tuln | grep -q ":$port "
}

# Get port status
get_port_status() {
    local port=$1
    if is_port_open "$port"; then
        echo -e "${GREEN}OPEN${NC}"
    else
        echo -e "${RED}CLOSED${NC}"
    fi
}

# Generate random password
generate_password() {
    local length=${1:-16}
    tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c "$length"
}

# Generate random username
generate_username() {
    local prefix=${1:-"user"}
    local suffix=$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)
    echo "${prefix}${suffix}"
}

# Validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate domain name
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate port number
validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

# Check if user exists
user_exists() {
    local username=$1
    id "$username" &>/dev/null
}

# Check if command exists
command_exists() {
    local cmd=$1
    command -v "$cmd" &>/dev/null
}

# Get system information
get_system_info() {
    echo -e "${CYAN}System Information:${NC}"
    echo -e "  OS: $(lsb_release -d | cut -f2-)"
    echo -e "  Kernel: $(uname -r)"
    echo -e "  Architecture: $(uname -m)"
    echo -e "  CPU: $(nproc) cores"
    echo -e "  Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
    echo -e "  Disk: $(df -h / | tail -1 | awk '{print $2}')"
    echo -e "  Load: $(uptime | awk -F'load average:' '{print $2}')"
}

# Get network information
get_network_info() {
    echo -e "${CYAN}Network Information:${NC}"
    echo -e "  Public IP: $(get_public_ip)"
    echo -e "  Hostname: $(hostname)"
    echo -e "  DNS: $(cat /etc/resolv.conf | grep nameserver | head -1 | awk '{print $2}')"
    echo -e "  Default Gateway: $(ip route | grep default | awk '{print $3}')"
}

# Progress bar function
show_progress() {
    local duration=$1
    local message=$2
    local bar_length=40
    
    for ((i=0; i<=duration; i++)); do
        local progress=$((i * bar_length / duration))
        local bar=""
        
        for ((j=0; j<bar_length; j++)); do
            if [ $j -lt $progress ]; then
                bar+="█"
            else
                bar+="░"
            fi
        done
        
        local percentage=$((i * 100 / duration))
        printf "\r${message} [${GREEN}%s${NC}] %d%%" "$bar" "$percentage"
        sleep 1
    done
    
    echo
}

# Spinner function
show_spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='|/-\'
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c] %s" "$spinstr" "$message"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
        for ((i=0; i<${#message}; i++)); do
            printf "\b"
        done
    done
    printf "    \b\b\b\b"
}

# Confirmation prompt
confirm() {
    local message=$1
    local default=${2:-"n"}
    
    if [ "$default" = "y" ]; then
        local prompt="${message} [Y/n]: "
    else
        local prompt="${message} [y/N]: "
    fi
    
    read -p "$prompt" response
    
    if [ -z "$response" ]; then
        response=$default
    fi
    
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Input validation
get_input() {
    local prompt=$1
    local validator=$2
    local default=$3
    local value
    
    while true; do
        if [ -n "$default" ]; then
            read -p "$prompt [$default]: " value
            if [ -z "$value" ]; then
                value=$default
            fi
        else
            read -p "$prompt: " value
        fi
        
        if [ -n "$validator" ]; then
            if $validator "$value"; then
                echo "$value"
                return 0
            else
                log_error "Invalid input. Please try again."
            fi
        else
            echo "$value"
            return 0
        fi
    done
}

# File backup function
backup_file() {
    local file=$1
    local backup_dir=${2:-"/opt/mastermind/backup"}
    
    if [ -f "$file" ]; then
        local filename=$(basename "$file")
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_path="$backup_dir/${filename}.${timestamp}.bak"
        
        mkdir -p "$backup_dir"
        cp "$file" "$backup_path"
        log_info "Backed up $file to $backup_path"
    fi
}

# Service management functions
start_service() {
    local service_name=$1
    log_info "Starting $service_name service..."
    systemctl start "$service_name"
    if is_service_running "$service_name"; then
        log_info "$service_name service started successfully"
    else
        log_error "Failed to start $service_name service"
        return 1
    fi
}

stop_service() {
    local service_name=$1
    log_info "Stopping $service_name service..."
    systemctl stop "$service_name"
    if ! is_service_running "$service_name"; then
        log_info "$service_name service stopped successfully"
    else
        log_error "Failed to stop $service_name service"
        return 1
    fi
}

restart_service() {
    local service_name=$1
    log_info "Restarting $service_name service..."
    systemctl restart "$service_name"
    if is_service_running "$service_name"; then
        log_info "$service_name service restarted successfully"
    else
        log_error "Failed to restart $service_name service"
        return 1
    fi
}

enable_service() {
    local service_name=$1
    log_info "Enabling $service_name service..."
    systemctl enable "$service_name"
    log_info "$service_name service enabled for auto-start"
}

disable_service() {
    local service_name=$1
    log_info "Disabling $service_name service..."
    systemctl disable "$service_name"
    log_info "$service_name service disabled from auto-start"
}

# Wait for keypress
wait_for_key() {
    local message=${1:-"Press any key to continue..."}
    read -n 1 -s -r -p "$message"
    echo
}

# Clean up temporary files
cleanup() {
    local temp_dir="/tmp/mastermind"
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
        log_debug "Cleaned up temporary directory: $temp_dir"
    fi
}

# Trap cleanup on exit
trap cleanup EXIT
