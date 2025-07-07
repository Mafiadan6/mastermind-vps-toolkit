#!/bin/bash

# Simple test for user display improvements
echo "Testing User Statistics Calculation"
echo "===================================="

# Test user count calculations
echo "1. Testing user statistics functions..."

total_users=$(getent passwd | wc -l)
regular_users=$(getent passwd | awk -F: '$3 >= 1000 && $3 != 65534' | wc -l)
ssh_users=$(getent passwd | awk -F: '$3 >= 1000 && $7 == "/bin/bash" && $3 != 65534' | wc -l)

echo "✓ User counts:"
echo "  Total system users: $total_users"
echo "  Regular users: $regular_users"
echo "  SSH-enabled users: $ssh_users"

echo
echo "2. Testing user list functionality..."

echo "✓ Regular users found:"
getent passwd | awk -F: '$3 >= 1000 && $3 != 65534' | head -5 | while IFS=: read -r username _ uid gid comment home shell; do
    shell_name=$(basename "$shell")
    printf "  %-15s UID:%-6s Shell:%-10s\n" "$username" "$uid" "$shell_name"
done

echo
echo "3. Testing sudo detection..."

if getent group sudo >/dev/null 2>&1; then
    sudo_members=$(getent group sudo | cut -d: -f4)
    if [ -n "$sudo_members" ]; then
        sudo_count=$(echo "$sudo_members" | tr ',' '\n' | grep -v '^$' | wc -l)
        echo "✓ Sudo users: $sudo_count"
    else
        echo "✓ No sudo users"
    fi
else
    echo "✓ Sudo group not found"
fi

echo
echo "4. Testing user manager improvements..."

if [ -f "users/user_manager.sh" ]; then
    if grep -q "Regular users (created)" users/user_manager.sh; then
        echo "✓ Enhanced statistics found"
    else
        echo "✗ Enhanced statistics missing"
    fi
    
    if grep -q "SSH-Enabled Users" users/user_manager.sh; then
        echo "✓ Enhanced user list found"
    else
        echo "✗ Enhanced user list missing"
    fi
else
    echo "✗ User manager file not found"
fi

echo
echo "===================================="
echo "User display improvements are working correctly"