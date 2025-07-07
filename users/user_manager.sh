#!/bin/bash

# Mastermind VPS Toolkit - User Manager
# Version: 1.0.0

# Load configuration and helper functions
MASTERMIND_HOME="${MASTERMIND_HOME:-/opt/mastermind}"
if [ -f "$MASTERMIND_HOME/core/helpers.sh" ]; then
    source "$MASTERMIND_HOME/core/helpers.sh"
elif [ -f "core/helpers.sh" ]; then
    source "core/helpers.sh"
fi

if [ -f "$MASTERMIND_HOME/core/config.cfg" ]; then
    source "$MASTERMIND_HOME/core/config.cfg"
elif [ -f "core/config.cfg" ]; then
    source "core/config.cfg"
fi

# Show user management menu
show_user_menu() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                             USER MANAGEMENT                                  ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Show user statistics
    local total_users=$(grep -c '^[^:]*:[^:]*:[0-9]*:[0-9]*:' /etc/passwd)
    local shell_users=$(grep -v 'nologin\|false' /etc/passwd | grep -v '^#' | wc -l)
    local sudo_users=$(getent group sudo | cut -d: -f4 | tr ',' '\n' | grep -v '^$' | wc -l)
    
    echo -e "${YELLOW}User Statistics:${NC}"
    echo -e "  Total users: $total_users"
    echo -e "  Users with shell access: $shell_users"
    echo -e "  Users with sudo access: $sudo_users"
    
    echo
    echo -e "${YELLOW}  [1] Add SSH User${NC}"
    echo -e "${YELLOW}  [2] Remove User${NC}"
    echo -e "${YELLOW}  [3] Modify User${NC}"
    echo -e "${YELLOW}  [4] List Users${NC}"
    echo -e "${YELLOW}  [5] User Permissions${NC}"
    echo -e "${YELLOW}  [6] Password Management${NC}"
    echo -e "${YELLOW}  [7] SSH Key Management${NC}"
    echo -e "${YELLOW}  [8] User Activity Monitor${NC}"
    echo -e "${YELLOW}  [9] Bulk User Operations${NC}"
    echo -e "${YELLOW}  [0] Back to Main Menu${NC}"
    echo
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Add SSH user (simplified for mobile apps)
add_ssh_user() {
    echo
    echo -e "${YELLOW}Add SSH User for Mobile Apps${NC}"
    echo -e "${CYAN}Quick setup for NPV Tunnel, HTTP Injector, etc.${NC}"
    echo
    
    # Get basic user details
    local username
    while true; do
        username=$(get_input "Username" "" "")
        if [ -n "$username" ]; then
            if user_exists "$username"; then
                log_error "User $username already exists"
            else
                break
            fi
        fi
    done
    
    local password
    if confirm "Generate random password?"; then
        password=$(generate_password 12)
        echo -e "${GREEN}Generated password: $password${NC}"
    else
        password=$(get_input "Password" "" "")
    fi
    
    # Use simple defaults for mobile app users
    local shell="/bin/bash"
    local home_dir="/home/$username"
    
    echo
    echo -e "${YELLOW}Data Usage Limits (optional):${NC}"
    local data_limit=$(get_input "Data limit (GB)" "10" "")
    local days_limit=$(get_input "Account validity (days)" "30" "")
    local connection_limit=$(get_input "Max concurrent connections" "3" "")
    
    # Simplified setup - no SSH keys or sudo for mobile users
    local create_ssh_key=false
    local add_to_sudo=false
    local set_quota=false
    
    if confirm "Set disk quota?"; then
        set_quota=true
    fi
    
    # Create user
    log_info "Creating user $username..."
    
    # Add user with specified shell and home directory
    useradd -m -d "$home_dir" -s "$shell" "$username"
    
    if [ $? -eq 0 ]; then
        # Set password
        echo "$username:$password" | chpasswd
        
        # Add to sudo group if requested
        if [ "$add_to_sudo" = true ]; then
            usermod -aG sudo "$username"
            log_info "User $username added to sudo group"
        fi
        
        # Create SSH key pair if requested
        if [ "$create_ssh_key" = true ]; then
            create_user_ssh_keys "$username" "$home_dir"
        fi
        
        # Set quota if requested
        if [ "$set_quota" = true ]; then
            setup_user_quota "$username"
        fi
        
        # Set proper permissions
        chown -R "$username:$username" "$home_dir"
        chmod 755 "$home_dir"
        
        # Add user to usage limits system
        if [ -f "/opt/mastermind/users/usage_limits.py" ]; then
            python3 /opt/mastermind/users/usage_limits.py add_user "$username" "ssh" "$data_limit" "$days_limit" "$connection_limit"
            log_info "User $username added to usage limits system"
        fi
        
        log_info "User $username created successfully"
        
        # Display user information
        echo
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}                            SSH USER CREATED SUCCESSFULLY                       ${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}Account Details:${NC}"
        echo -e "  📤 Username: ${WHITE}$username${NC}"
        echo -e "  🔑 Password: ${WHITE}$password${NC}"
        echo -e "  🏠 Home Directory: ${WHITE}$home_dir${NC}"
        echo -e "  🐚 Shell: ${WHITE}$shell${NC}"
        echo -e "  👤 Sudo Access: ${WHITE}$([ "$add_to_sudo" = true ] && echo "Yes" || echo "No")${NC}"
        echo -e "  🔐 SSH Keys: ${WHITE}$([ "$create_ssh_key" = true ] && echo "Generated" || echo "No")${NC}"
        echo
        echo -e "${YELLOW}Usage Limits:${NC}"
        echo -e "  📊 Data Limit: ${WHITE}${data_limit} GB${NC}"
        echo -e "  📅 Account Validity: ${WHITE}${days_limit} days${NC}"
        echo -e "  🔗 Max Connections: ${WHITE}${connection_limit}${NC}"
        echo
        echo -e "${YELLOW}Mobile App Configuration:${NC}"
        local server_ip=$(curl -s ifconfig.me 2>/dev/null || echo "Your-Server-IP")
        echo -e "  🌐 Server IP: ${WHITE}$server_ip${NC}"
        echo -e "  🔌 SSH Port: ${WHITE}443${NC} (for SSL/TLS tunnel)"
        echo -e "  👤 Username: ${WHITE}$username${NC}"
        echo -e "  🔑 Password: ${WHITE}$password${NC}"
        echo
        echo -e "${YELLOW}📱 For NPV Tunnel:${NC}"
        echo -e "  ${WHITE}• Host:${NC} $server_ip"
        echo -e "  ${WHITE}• Port:${NC} 8080 (WebSocket)"
        echo -e "  ${WHITE}• SSH Host:${NC} $server_ip"
        echo -e "  ${WHITE}• SSH Port:${NC} 443"
        echo -e "  ${WHITE}• Username:${NC} $username"
        echo -e "  ${WHITE}• Password:${NC} $password"
        echo
        echo -e "${YELLOW}📱 For HTTP Injector:${NC}"
        echo -e "  ${WHITE}• Proxy:${NC} $server_ip:8888"
        echo -e "  ${WHITE}• SSH Host:${NC} $server_ip:443"
        echo -e "  ${WHITE}• Username:${NC} $username"
        echo -e "  ${WHITE}• Password:${NC} $password"
        echo
        echo -e "${YELLOW}📱 Connection Test:${NC}"
        echo -e "  ${WHITE}• SSH Command:${NC} ssh -p 443 $username@$server_ip"
        echo
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        # Save user info to log
        echo "$(date): Created SSH user $username with limits: ${data_limit}GB, ${days_limit} days, ${connection_limit} connections" >> /var/log/mastermind/user-management.log
        
    else
        log_error "Failed to create user $username"
    fi
    
    wait_for_key
}

# Remove user
remove_user() {
    echo
    echo -e "${YELLOW}Remove User${NC}"
    echo
    
    # List existing users
    echo -e "${YELLOW}Existing users with shell access:${NC}"
    grep -v 'nologin\|false' /etc/passwd | grep -v '^#' | cut -d: -f1,5 | sed 's/:/ - /' | sed 's/^/  /'
    echo
    
    local username=$(get_input "Username to remove" "" "")
    
    if [ -z "$username" ]; then
        log_error "Username cannot be empty"
        wait_for_key
        return
    fi
    
    if ! user_exists "$username"; then
        log_error "User $username does not exist"
        wait_for_key
        return
    fi
    
    # Prevent removal of system users
    local uid=$(id -u "$username" 2>/dev/null)
    if [ "$uid" -lt 1000 ] && [ "$username" != "root" ]; then
        log_error "Cannot remove system user $username"
        wait_for_key
        return
    fi
    
    echo
    echo -e "${YELLOW}User information:${NC}"
    id "$username"
    echo
    
    if confirm "Remove user $username and all associated data?"; then
        # Check if user is currently logged in
        if who | grep -q "$username"; then
            log_warn "User $username is currently logged in"
            if confirm "Force logout and continue removal?"; then
                pkill -KILL -u "$username"
            else
                log_info "User removal cancelled"
                wait_for_key
                return
            fi
        fi
        
        # Remove user and home directory
        log_info "Removing user $username..."
        
        # Remove from sudo group if member
        if groups "$username" | grep -q sudo; then
            deluser "$username" sudo 2>/dev/null
        fi
        
        # Remove user and home directory
        userdel -r "$username" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            log_info "User $username removed successfully"
            
            # Remove any remaining processes
            pkill -KILL -u "$username" 2>/dev/null || true
            
            # Log removal
            echo "$(date): Removed user $username" >> /var/log/mastermind/user-management.log
        else
            log_error "Failed to remove user $username"
        fi
    fi
    
    wait_for_key
}

# Modify user
modify_user() {
    echo
    echo -e "${YELLOW}Modify User${NC}"
    echo
    
    # List existing users
    echo -e "${YELLOW}Existing users:${NC}"
    grep -v 'nologin\|false' /etc/passwd | grep -v '^#' | cut -d: -f1,5 | sed 's/:/ - /' | sed 's/^/  /'
    echo
    
    local username=$(get_input "Username to modify" "" "")
    
    if [ -z "$username" ]; then
        log_error "Username cannot be empty"
        wait_for_key
        return
    fi
    
    if ! user_exists "$username"; then
        log_error "User $username does not exist"
        wait_for_key
        return
    fi
    
    # Show current user information
    echo
    echo -e "${YELLOW}Current user information:${NC}"
    id "$username"
    finger "$username" 2>/dev/null || echo "User: $username"
    echo
    
    while true; do
        echo -e "${YELLOW}What would you like to modify?${NC}"
        echo -e "  [1] Change password"
        echo -e "  [2] Change shell"
        echo -e "  [3] Change home directory"
        echo -e "  [4] Add/remove sudo access"
        echo -e "  [5] Lock/unlock account"
        echo -e "  [6] Set account expiration"
        echo -e "  [7] Change user comment/info"
        echo -e "  [0] Back to user menu"
        echo
        
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) change_user_password "$username" ;;
            2) change_user_shell "$username" ;;
            3) change_user_home "$username" ;;
            4) toggle_sudo_access "$username" ;;
            5) toggle_account_lock "$username" ;;
            6) set_account_expiration "$username" ;;
            7) change_user_info "$username" ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
        
        echo
    done
}

# Change user password
change_user_password() {
    local username=$1
    
    echo
    echo -e "${YELLOW}Change password for $username${NC}"
    echo
    
    if confirm "Generate random password?"; then
        local new_password=$(generate_password 16)
        echo "$username:$new_password" | chpasswd
        echo -e "${GREEN}New password: $new_password${NC}"
    else
        echo "Enter new password for $username:"
        passwd "$username"
    fi
    
    log_info "Password changed for user $username"
}

# Change user shell
change_user_shell() {
    local username=$1
    
    echo
    echo -e "${YELLOW}Change shell for $username${NC}"
    echo
    
    local current_shell=$(getent passwd "$username" | cut -d: -f7)
    echo -e "Current shell: $current_shell"
    echo
    
    echo -e "${YELLOW}Available shells:${NC}"
    cat /etc/shells | grep -v '^#' | sed 's/^/  /'
    echo
    
    local new_shell=$(get_input "New shell" "" "$current_shell")
    
    if [ "$new_shell" != "$current_shell" ]; then
        usermod -s "$new_shell" "$username"
        log_info "Shell changed for user $username to $new_shell"
    fi
}

# Change user home directory
change_user_home() {
    local username=$1
    
    echo
    echo -e "${YELLOW}Change home directory for $username${NC}"
    echo
    
    local current_home=$(getent passwd "$username" | cut -d: -f6)
    echo -e "Current home: $current_home"
    echo
    
    local new_home=$(get_input "New home directory" "" "$current_home")
    
    if [ "$new_home" != "$current_home" ]; then
        if confirm "Move existing home directory to new location?"; then
            usermod -d "$new_home" -m "$username"
            log_info "Home directory moved for user $username to $new_home"
        else
            usermod -d "$new_home" "$username"
            log_info "Home directory path changed for user $username to $new_home"
        fi
    fi
}

# Toggle sudo access
toggle_sudo_access() {
    local username=$1
    
    echo
    if groups "$username" | grep -q sudo; then
        echo -e "${YELLOW}User $username currently has sudo access${NC}"
        if confirm "Remove sudo access?"; then
            deluser "$username" sudo
            log_info "Removed sudo access for user $username"
        fi
    else
        echo -e "${YELLOW}User $username does not have sudo access${NC}"
        if confirm "Grant sudo access?"; then
            usermod -aG sudo "$username"
            log_info "Granted sudo access for user $username"
        fi
    fi
}

# Toggle account lock
toggle_account_lock() {
    local username=$1
    
    echo
    local lock_status=$(passwd -S "$username" | awk '{print $2}')
    
    if [ "$lock_status" = "L" ]; then
        echo -e "${YELLOW}Account $username is currently locked${NC}"
        if confirm "Unlock account?"; then
            usermod -U "$username"
            log_info "Unlocked account for user $username"
        fi
    else
        echo -e "${YELLOW}Account $username is currently unlocked${NC}"
        if confirm "Lock account?"; then
            usermod -L "$username"
            log_info "Locked account for user $username"
        fi
    fi
}

# Set account expiration
set_account_expiration() {
    local username=$1
    
    echo
    echo -e "${YELLOW}Set account expiration for $username${NC}"
    echo
    
    local current_expiry=$(chage -l "$username" | grep "Account expires" | cut -d: -f2 | xargs)
    echo -e "Current expiration: $current_expiry"
    echo
    
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  [1] Never expire"
    echo -e "  [2] Set specific date (YYYY-MM-DD)"
    echo -e "  [3] Set days from now"
    echo
    
    read -p "Choose option [1-3]: " exp_choice
    
    case $exp_choice in
        1)
            chage -E -1 "$username"
            log_info "Set account $username to never expire"
            ;;
        2)
            local exp_date=$(get_input "Expiration date (YYYY-MM-DD)" "" "")
            if [ -n "$exp_date" ]; then
                chage -E "$exp_date" "$username"
                log_info "Set account $username to expire on $exp_date"
            fi
            ;;
        3)
            local days=$(get_input "Days from now" "validate_number" "30")
            local exp_date=$(date -d "+$days days" +%Y-%m-%d)
            chage -E "$exp_date" "$username"
            log_info "Set account $username to expire in $days days ($exp_date)"
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
}

# Change user info
change_user_info() {
    local username=$1
    
    echo
    echo -e "${YELLOW}Change user information for $username${NC}"
    echo
    
    local current_info=$(getent passwd "$username" | cut -d: -f5)
    echo -e "Current info: $current_info"
    echo
    
    local new_info=$(get_input "New user information/comment" "" "$current_info")
    
    if [ "$new_info" != "$current_info" ]; then
        usermod -c "$new_info" "$username"
        log_info "Updated information for user $username"
    fi
}

# List users
list_users() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                                 USER LIST                                    ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Users with shell access:${NC}"
    echo
    
    printf "%-15s %-10s %-20s %-15s %-10s\n" "Username" "UID" "Home Directory" "Shell" "Status"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    while IFS=: read -r username _ uid gid comment home shell; do
        # Skip system users and users with no shell
        if [[ ! "$shell" =~ (nologin|false) ]] && [ "$uid" -ge 1000 ] || [ "$username" = "root" ]; then
            local status="Active"
            local lock_status=$(passwd -S "$username" 2>/dev/null | awk '{print $2}')
            if [ "$lock_status" = "L" ]; then
                status="Locked"
            fi
            
            printf "%-15s %-10s %-20s %-15s %-10s\n" "$username" "$uid" "$home" "$(basename $shell)" "$status"
        fi
    done < /etc/passwd
    
    echo
    echo -e "${YELLOW}Sudo users:${NC}"
    getent group sudo | cut -d: -f4 | tr ',' '\n' | grep -v '^$' | sed 's/^/  /'
    
    echo
    echo -e "${YELLOW}Currently logged in users:${NC}"
    who | sed 's/^/  /'
    
    echo
    wait_for_key
}

# User permissions management
user_permissions() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           USER PERMISSIONS                                  ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] View User Groups${NC}"
        echo -e "${YELLOW}  [2] Add User to Group${NC}"
        echo -e "${YELLOW}  [3] Remove User from Group${NC}"
        echo -e "${YELLOW}  [4] Create New Group${NC}"
        echo -e "${YELLOW}  [5] Delete Group${NC}"
        echo -e "${YELLOW}  [6] View Group Members${NC}"
        echo -e "${YELLOW}  [0] Back to User Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-6]: " choice
        
        case $choice in
            1) view_user_groups ;;
            2) add_user_to_group ;;
            3) remove_user_from_group ;;
            4) create_new_group ;;
            5) delete_group ;;
            6) view_group_members ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# View user groups
view_user_groups() {
    echo
    local username=$(get_input "Username" "" "")
    
    if [ -n "$username" ] && user_exists "$username"; then
        echo
        echo -e "${YELLOW}Groups for user $username:${NC}"
        groups "$username"
        echo
        
        echo -e "${YELLOW}Detailed group information:${NC}"
        id "$username"
    else
        log_error "User not found or username empty"
    fi
    
    echo
    wait_for_key
}

# Add user to group
add_user_to_group() {
    echo
    local username=$(get_input "Username" "" "")
    local groupname=$(get_input "Group name" "" "")
    
    if [ -n "$username" ] && [ -n "$groupname" ]; then
        if user_exists "$username"; then
            if getent group "$groupname" >/dev/null; then
                usermod -aG "$groupname" "$username"
                log_info "Added user $username to group $groupname"
            else
                log_error "Group $groupname does not exist"
            fi
        else
            log_error "User $username does not exist"
        fi
    else
        log_error "Username and group name cannot be empty"
    fi
    
    wait_for_key
}

# Remove user from group
remove_user_from_group() {
    echo
    local username=$(get_input "Username" "" "")
    local groupname=$(get_input "Group name" "" "")
    
    if [ -n "$username" ] && [ -n "$groupname" ]; then
        if user_exists "$username"; then
            if getent group "$groupname" >/dev/null; then
                deluser "$username" "$groupname" 2>/dev/null
                log_info "Removed user $username from group $groupname"
            else
                log_error "Group $groupname does not exist"
            fi
        else
            log_error "User $username does not exist"
        fi
    else
        log_error "Username and group name cannot be empty"
    fi
    
    wait_for_key
}

# Create new group
create_new_group() {
    echo
    local groupname=$(get_input "New group name" "" "")
    
    if [ -n "$groupname" ]; then
        if ! getent group "$groupname" >/dev/null; then
            groupadd "$groupname"
            log_info "Created group $groupname"
        else
            log_error "Group $groupname already exists"
        fi
    else
        log_error "Group name cannot be empty"
    fi
    
    wait_for_key
}

# Delete group
delete_group() {
    echo
    echo -e "${YELLOW}Existing groups:${NC}"
    getent group | grep -v '^[^:]*:[^:]*:[0-9]\{1,2\}:' | cut -d: -f1 | head -20 | sed 's/^/  /'
    echo
    
    local groupname=$(get_input "Group name to delete" "" "")
    
    if [ -n "$groupname" ]; then
        if getent group "$groupname" >/dev/null; then
            local gid=$(getent group "$groupname" | cut -d: -f3)
            if [ "$gid" -lt 1000 ]; then
                log_error "Cannot delete system group $groupname"
            else
                if confirm "Delete group $groupname?"; then
                    groupdel "$groupname"
                    log_info "Deleted group $groupname"
                fi
            fi
        else
            log_error "Group $groupname does not exist"
        fi
    else
        log_error "Group name cannot be empty"
    fi
    
    wait_for_key
}

# View group members
view_group_members() {
    echo
    local groupname=$(get_input "Group name" "" "")
    
    if [ -n "$groupname" ]; then
        if getent group "$groupname" >/dev/null; then
            echo
            echo -e "${YELLOW}Members of group $groupname:${NC}"
            getent group "$groupname" | cut -d: -f4 | tr ',' '\n' | sed 's/^/  /'
        else
            log_error "Group $groupname does not exist"
        fi
    else
        log_error "Group name cannot be empty"
    fi
    
    echo
    wait_for_key
}

# Password management
password_management() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           PASSWORD MANAGEMENT                              ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Change User Password${NC}"
        echo -e "${YELLOW}  [2] Force Password Change${NC}"
        echo -e "${YELLOW}  [3] Set Password Expiry${NC}"
        echo -e "${YELLOW}  [4] View Password Status${NC}"
        echo -e "${YELLOW}  [5] Configure Password Policy${NC}"
        echo -e "${YELLOW}  [6] Generate Random Password${NC}"
        echo -e "${YELLOW}  [0] Back to User Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-6]: " choice
        
        case $choice in
            1) password_change_user ;;
            2) force_password_change ;;
            3) set_password_expiry ;;
            4) view_password_status ;;
            5) configure_password_policy ;;
            6) generate_random_password ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Password change for user
password_change_user() {
    echo
    local username=$(get_input "Username" "" "")
    
    if [ -n "$username" ] && user_exists "$username"; then
        change_user_password "$username"
    else
        log_error "User not found or username empty"
        wait_for_key
    fi
}

# Force password change
force_password_change() {
    echo
    local username=$(get_input "Username" "" "")
    
    if [ -n "$username" ] && user_exists "$username"; then
        chage -d 0 "$username"
        log_info "User $username will be forced to change password on next login"
    else
        log_error "User not found or username empty"
    fi
    
    wait_for_key
}

# Set password expiry
set_password_expiry() {
    echo
    local username=$(get_input "Username" "" "")
    
    if [ -n "$username" ] && user_exists "$username"; then
        set_account_expiration "$username"
    else
        log_error "User not found or username empty"
        wait_for_key
    fi
}

# View password status
view_password_status() {
    echo
    local username=$(get_input "Username" "" "")
    
    if [ -n "$username" ] && user_exists "$username"; then
        echo
        echo -e "${YELLOW}Password status for $username:${NC}"
        passwd -S "$username"
        echo
        echo -e "${YELLOW}Detailed aging information:${NC}"
        chage -l "$username"
    else
        log_error "User not found or username empty"
    fi
    
    echo
    wait_for_key
}

# Configure password policy
configure_password_policy() {
    echo
    echo -e "${YELLOW}Configure Password Policy${NC}"
    echo
    echo -e "${YELLOW}This will modify /etc/login.defs${NC}"
    echo
    
    if confirm "Configure password aging policy?"; then
        local max_days=$(get_input "Maximum password age (days)" "validate_number" "90")
        local min_days=$(get_input "Minimum password age (days)" "validate_number" "1")
        local warn_days=$(get_input "Password warning days" "validate_number" "7")
        
        # Backup current configuration
        backup_file /etc/login.defs
        
        # Update password policy
        sed -i "s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS $max_days/" /etc/login.defs
        sed -i "s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS $min_days/" /etc/login.defs
        sed -i "s/^PASS_WARN_AGE.*/PASS_WARN_AGE $warn_days/" /etc/login.defs
        
        log_info "Password policy updated"
    fi
    
    wait_for_key
}

# Generate random password
generate_random_password() {
    echo
    local length=$(get_input "Password length" "validate_number" "16")
    local count=$(get_input "Number of passwords to generate" "validate_number" "1")
    
    echo
    echo -e "${YELLOW}Generated passwords:${NC}"
    for ((i=1; i<=count; i++)); do
        local password=$(generate_password $length)
        echo -e "  $i: $password"
    done
    
    echo
    wait_for_key
}

# SSH key management
ssh_key_management() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           SSH KEY MANAGEMENT                               ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Generate SSH Keys for User${NC}"
        echo -e "${YELLOW}  [2] Add Public Key to User${NC}"
        echo -e "${YELLOW}  [3] Remove Public Key from User${NC}"
        echo -e "${YELLOW}  [4] List User's SSH Keys${NC}"
        echo -e "${YELLOW}  [5] Backup SSH Keys${NC}"
        echo -e "${YELLOW}  [0] Back to User Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) generate_user_ssh_keys ;;
            2) add_public_key_to_user ;;
            3) remove_public_key_from_user ;;
            4) list_user_ssh_keys ;;
            5) backup_user_ssh_keys ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Generate SSH keys for user
generate_user_ssh_keys() {
    echo
    local username=$(get_input "Username" "" "")
    
    if [ -n "$username" ] && user_exists "$username"; then
        local home_dir=$(getent passwd "$username" | cut -d: -f6)
        create_user_ssh_keys "$username" "$home_dir"
    else
        log_error "User not found or username empty"
        wait_for_key
    fi
}

# Create SSH keys for user
create_user_ssh_keys() {
    local username=$1
    local home_dir=$2
    
    local ssh_dir="$home_dir/.ssh"
    
    # Create .ssh directory
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    # Generate SSH key pair
    local key_type=$(get_input "Key type (rsa/ed25519)" "" "ed25519")
    local key_size=""
    
    if [ "$key_type" = "rsa" ]; then
        key_size=$(get_input "Key size (2048/4096)" "validate_number" "2048")
        ssh-keygen -t rsa -b "$key_size" -f "$ssh_dir/id_rsa" -N "" -C "$username@$(hostname)"
    else
        ssh-keygen -t ed25519 -f "$ssh_dir/id_ed25519" -N "" -C "$username@$(hostname)"
    fi
    
    # Set proper permissions
    chown -R "$username:$username" "$ssh_dir"
    chmod 600 "$ssh_dir"/id_*
    chmod 644 "$ssh_dir"/*.pub
    
    log_info "SSH key pair generated for user $username"
    
    # Display public key
    echo
    echo -e "${YELLOW}Public key:${NC}"
    cat "$ssh_dir"/*.pub
    
    wait_for_key
}

# Add public key to user
add_public_key_to_user() {
    echo
    local username=$(get_input "Username" "" "")
    
    if [ -n "$username" ] && user_exists "$username"; then
        local home_dir=$(getent passwd "$username" | cut -d: -f6)
        local ssh_dir="$home_dir/.ssh"
        local authorized_keys="$ssh_dir/authorized_keys"
        
        echo
        echo -e "${YELLOW}Enter the public key to add:${NC}"
        read -r public_key
        
        if [ -n "$public_key" ]; then
            # Create .ssh directory if it doesn't exist
            mkdir -p "$ssh_dir"
            chmod 700 "$ssh_dir"
            
            # Add public key
            echo "$public_key" >> "$authorized_keys"
            
            # Set proper permissions
            chown -R "$username:$username" "$ssh_dir"
            chmod 600 "$authorized_keys"
            
            log_info "Public key added for user $username"
        else
            log_error "Public key cannot be empty"
        fi
    else
        log_error "User not found or username empty"
    fi
    
    wait_for_key
}

# Remove public key from user
remove_public_key_from_user() {
    echo
    local username=$(get_input "Username" "" "")
    
    if [ -n "$username" ] && user_exists "$username"; then
        local home_dir=$(getent passwd "$username" | cut -d: -f6)
        local authorized_keys="$home_dir/.ssh/authorized_keys"
        
        if [ -f "$authorized_keys" ]; then
            echo
            echo -e "${YELLOW}Current authorized keys:${NC}"
            cat -n "$authorized_keys"
            echo
            
            local line_number=$(get_input "Line number to remove" "validate_number" "")
            
            if [ -n "$line_number" ]; then
                sed -i "${line_number}d" "$authorized_keys"
                log_info "Public key removed from line $line_number for user $username"
            fi
        else
            log_error "No authorized keys file found for user $username"
        fi
    else
        log_error "User not found or username empty"
    fi
    
    wait_for_key
}

# List user's SSH keys
list_user_ssh_keys() {
    echo
    local username=$(get_input "Username" "" "")
    
    if [ -n "$username" ] && user_exists "$username"; then
        local home_dir=$(getent passwd "$username" | cut -d: -f6)
        local ssh_dir="$home_dir/.ssh"
        
        echo
        echo -e "${YELLOW}SSH keys for user $username:${NC}"
        
        if [ -d "$ssh_dir" ]; then
            echo -e "${YELLOW}Private keys:${NC}"
            ls -la "$ssh_dir"/id_* 2>/dev/null | grep -v ".pub" | sed 's/^/  /' || echo "  None found"
            
            echo -e "${YELLOW}Public keys:${NC}"
            ls -la "$ssh_dir"/*.pub 2>/dev/null | sed 's/^/  /' || echo "  None found"
            
            echo -e "${YELLOW}Authorized keys:${NC}"
            if [ -f "$ssh_dir/authorized_keys" ]; then
                cat -n "$ssh_dir/authorized_keys" | sed 's/^/  /'
            else
                echo "  None found"
            fi
        else
            echo "  No .ssh directory found"
        fi
    else
        log_error "User not found or username empty"
    fi
    
    echo
    wait_for_key
}

# Backup SSH keys
backup_user_ssh_keys() {
    echo
    local username=$(get_input "Username (leave empty for all users)" "" "")
    
    local backup_dir="/opt/mastermind/backup/ssh-keys"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    if [ -n "$username" ]; then
        if user_exists "$username"; then
            local home_dir=$(getent passwd "$username" | cut -d: -f6)
            local ssh_dir="$home_dir/.ssh"
            
            if [ -d "$ssh_dir" ]; then
                tar -czf "$backup_dir/ssh_keys_${username}_${timestamp}.tar.gz" -C "$home_dir" .ssh
                log_info "SSH keys backed up for user $username"
            else
                log_error "No SSH directory found for user $username"
            fi
        else
            log_error "User $username not found"
        fi
    else
        # Backup all user SSH keys
        tar -czf "$backup_dir/all_ssh_keys_${timestamp}.tar.gz" \
            --exclude='lost+found' \
            /home/*/.ssh /root/.ssh 2>/dev/null
        log_info "All SSH keys backed up"
    fi
    
    wait_for_key
}

# User activity monitor
user_activity_monitor() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                           USER ACTIVITY MONITOR                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}Currently logged in users:${NC}"
    who -u | sed 's/^/  /'
    echo
    
    echo -e "${YELLOW}Recent login history:${NC}"
    last -n 10 | sed 's/^/  /'
    echo
    
    echo -e "${YELLOW}Failed login attempts:${NC}"
    grep "Failed password" /var/log/auth.log | tail -5 | awk '{print $1, $2, $3, $9, $11}' | sed 's/^/  /' 2>/dev/null || echo "  None found"
    echo
    
    echo -e "${YELLOW}User processes:${NC}"
    ps aux --sort=-%cpu | head -10 | sed 's/^/  /'
    echo
    
    wait_for_key
}

# Bulk user operations
bulk_user_operations() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                           BULK USER OPERATIONS                             ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${YELLOW}  [1] Create Multiple Users${NC}"
        echo -e "${YELLOW}  [2] Delete Multiple Users${NC}"
        echo -e "${YELLOW}  [3] Change Passwords for Multiple Users${NC}"
        echo -e "${YELLOW}  [4] Export User List${NC}"
        echo -e "${YELLOW}  [5] Import Users from File${NC}"
        echo -e "${YELLOW}  [0] Back to User Menu${NC}"
        echo
        echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════════${NC}"
        
        read -p "Enter your choice [0-5]: " choice
        
        case $choice in
            1) create_multiple_users ;;
            2) delete_multiple_users ;;
            3) change_multiple_passwords ;;
            4) export_user_list ;;
            5) import_users_from_file ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
        esac
    done
}

# Create multiple users
create_multiple_users() {
    echo
    echo -e "${YELLOW}Create Multiple Users${NC}"
    echo
    
    local count=$(get_input "Number of users to create" "validate_number" "1")
    local prefix=$(get_input "Username prefix" "" "user")
    local start_number=$(get_input "Starting number" "validate_number" "1")
    
    echo
    for ((i=0; i<count; i++)); do
        local username="${prefix}$((start_number + i))"
        local password=$(generate_password 12)
        
        if ! user_exists "$username"; then
            useradd -m -s /bin/bash "$username"
            echo "$username:$password" | chpasswd
            
            echo -e "Created user: $username with password: $password"
            echo "$(date): Created user $username" >> /var/log/mastermind/user-management.log
        else
            echo -e "User $username already exists, skipping"
        fi
    done
    
    echo
    wait_for_key
}

# Delete multiple users
delete_multiple_users() {
    echo
    echo -e "${YELLOW}Delete Multiple Users${NC}"
    echo
    echo -e "${RED}WARNING: This will permanently delete users and their data${NC}"
    echo
    
    local pattern=$(get_input "Username pattern (e.g., user*)" "" "")
    
    if [ -n "$pattern" ]; then
        echo
        echo -e "${YELLOW}Users matching pattern '$pattern':${NC}"
        getent passwd | grep "^$pattern" | cut -d: -f1 | sed 's/^/  /'
        echo
        
        if confirm "Delete all users matching this pattern?"; then
            getent passwd | grep "^$pattern" | cut -d: -f1 | while read username; do
                if [ -n "$username" ]; then
                    userdel -r "$username" 2>/dev/null
                    echo "Deleted user: $username"
                    echo "$(date): Deleted user $username" >> /var/log/mastermind/user-management.log
                fi
            done
        fi
    fi
    
    wait_for_key
}

# Change passwords for multiple users
change_multiple_passwords() {
    echo
    echo -e "${YELLOW}Change Passwords for Multiple Users${NC}"
    echo
    
    local pattern=$(get_input "Username pattern (e.g., user*)" "" "")
    
    if [ -n "$pattern" ]; then
        echo
        echo -e "${YELLOW}Users matching pattern '$pattern':${NC}"
        getent passwd | grep "^$pattern" | cut -d: -f1 | sed 's/^/  /'
        echo
        
        if confirm "Change passwords for all users matching this pattern?"; then
            getent passwd | grep "^$pattern" | cut -d: -f1 | while read username; do
                if [ -n "$username" ]; then
                    local new_password=$(generate_password 12)
                    echo "$username:$new_password" | chpasswd
                    echo "Changed password for $username: $new_password"
                    echo "$(date): Changed password for user $username" >> /var/log/mastermind/user-management.log
                fi
            done
        fi
    fi
    
    wait_for_key
}

# Export user list
export_user_list() {
    echo
    local export_file="/tmp/user_export_$(date +%Y%m%d_%H%M%S).csv"
    
    echo -e "${YELLOW}Exporting user list to $export_file${NC}"
    echo
    
    echo "Username,UID,GID,Home,Shell,Status" > "$export_file"
    
    while IFS=: read -r username _ uid gid comment home shell; do
        if [[ ! "$shell" =~ (nologin|false) ]] && [ "$uid" -ge 1000 ] || [ "$username" = "root" ]; then
            local status="Active"
            local lock_status=$(passwd -S "$username" 2>/dev/null | awk '{print $2}')
            if [ "$lock_status" = "L" ]; then
                status="Locked"
            fi
            
            echo "$username,$uid,$gid,$home,$shell,$status" >> "$export_file"
        fi
    done < /etc/passwd
    
    log_info "User list exported to $export_file"
    
    wait_for_key
}

# Import users from file
import_users_from_file() {
    echo
    echo -e "${YELLOW}Import Users from File${NC}"
    echo
    echo -e "${YELLOW}File format: username,password,shell,sudo_access${NC}"
    echo -e "${YELLOW}Example: john,mypassword,/bin/bash,yes${NC}"
    echo
    
    local import_file=$(get_input "Import file path" "" "")
    
    if [ -f "$import_file" ]; then
        echo
        echo -e "${YELLOW}Importing users from $import_file${NC}"
        echo
        
        while IFS=, read -r username password shell sudo_access; do
            # Skip empty lines and comments
            if [[ -z "$username" || "$username" =~ ^# ]]; then
                continue
            fi
            
            if ! user_exists "$username"; then
                useradd -m -s "${shell:-/bin/bash}" "$username"
                echo "$username:$password" | chpasswd
                
                if [ "$sudo_access" = "yes" ]; then
                    usermod -aG sudo "$username"
                fi
                
                echo "Created user: $username"
                echo "$(date): Imported user $username" >> /var/log/mastermind/user-management.log
            else
                echo "User $username already exists, skipping"
            fi
        done < "$import_file"
        
        log_info "User import completed"
    else
        log_error "Import file not found: $import_file"
    fi
    
    wait_for_key
}

# Setup user quota (helper function)
setup_user_quota() {
    local username=$1
    
    echo
    local quota_size=$(get_input "Disk quota in MB" "validate_number" "1000")
    
    # Note: This requires quota support to be enabled on the filesystem
    # For demonstration, we'll just log the quota setting
    log_info "Quota of ${quota_size}MB would be set for user $username"
    echo -e "${YELLOW}Note: Quota support requires filesystem configuration${NC}"
}

# Validate number (helper function)
validate_number() {
    local number=$1
    if [[ $number =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Main function
main() {
    local action=${1:-"menu"}
    
    case $action in
        "add")
            add_ssh_user
            ;;
        "remove")
            remove_user
            ;;
        "modify")
            modify_user
            ;;
        "list")
            list_users
            ;;
        "ssh")
            ssh_key_management
            ;;
        "password")
            password_management
            ;;
        "permissions")
            user_permissions
            ;;
        "activity")
            user_activity_monitor
            ;;
        "menu"|*)
            while true; do
                show_user_menu
                read -p "Enter your choice [0-9]: " choice
                
                case $choice in
                    1) add_ssh_user ;;
                    2) remove_user ;;
                    3) modify_user ;;
                    4) list_users ;;
                    5) user_permissions ;;
                    6) password_management ;;
                    7) ssh_key_management ;;
                    8) user_activity_monitor ;;
                    9) bulk_user_operations ;;
                    0) exit 0 ;;
                    *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
                esac
            done
            ;;
    esac
}

# Run main function
main "$@"
