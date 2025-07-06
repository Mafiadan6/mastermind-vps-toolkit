#!/bin/bash

# Mastermind VPS Toolkit - Fail2ban Setup
# Version: 1.0.0

source /opt/mastermind/core/helpers.sh
source /opt/mastermind/core/config.cfg

# Configure fail2ban for all services
configure_fail2ban() {
    log_info "Configuring Fail2ban..."
    
    # Create SSH jail
    cat > /etc/fail2ban/jail.d/sshd.conf << EOF
[sshd]
enabled = true
port = $SSH_PORT,$DROPBEAR_PORT,$DROPBEAR_PORT2
filter = sshd
logpath = /var/log/auth.log
maxretry = $MAX_LOGIN_ATTEMPTS
bantime = $BAN_TIME
findtime = $FIND_TIME
EOF

    # Create HTTP jail for nginx
    cat > /etc/fail2ban/jail.d/nginx.conf << EOF
[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5
bantime = 3600

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 10
bantime = 3600
EOF

    # Create V2Ray jail
    cat > /etc/fail2ban/jail.d/v2ray.conf << EOF
[v2ray]
enabled = true
port = $V2RAY_PORT
filter = v2ray
logpath = /var/log/v2ray/error.log
maxretry = 3
bantime = 7200
findtime = 600
EOF

    # Restart fail2ban
    systemctl restart fail2ban
    systemctl enable fail2ban
    
    log_success "Fail2ban configured successfully"
}

# Show fail2ban status
show_fail2ban_status() {
    echo "Fail2ban Status:"
    fail2ban-client status
    echo
    echo "Active Jails:"
    fail2ban-client status | grep "Jail list:" | sed 's/.*:\s*//' | tr ',' '\n' | while read jail; do
        if [ -n "$jail" ]; then
            echo "  $jail: $(fail2ban-client status $jail | grep "Currently banned" | awk '{print $4}')"
        fi
    done
}

# Main execution
if [ "$1" = "configure" ]; then
    configure_fail2ban
elif [ "$1" = "status" ]; then
    show_fail2ban_status
else
    configure_fail2ban
fi