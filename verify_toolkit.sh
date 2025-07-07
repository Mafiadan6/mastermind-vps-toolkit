#!/bin/bash

# Mastermind VPS Toolkit - Verification Script
# Checks that all components are ready for deployment

echo "====================================="
echo "Mastermind VPS Toolkit Verification"
echo "====================================="

# Check essential files
echo "Checking essential files..."
essential_files=(
    "install.sh"
    "core/menu.sh"
    "core/helpers.sh"
    "core/config.cfg"
    "protocols/python_proxy.py"
    "protocols/v2ray_manager.sh"
    "protocols/tcp_bypass.sh"
    "branding/qr_generator.py"
    "security/firewall_manager.sh"
    "network/bbr.sh"
)

missing_files=0
for file in "${essential_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (MISSING)"
        missing_files=$((missing_files + 1))
    fi
done

# Check Python dependencies
echo ""
echo "Checking Python dependencies..."
python3 -c "import qrcode, websockets; print('  ✓ All Python dependencies installed')" 2>/dev/null || echo "  ✗ Missing Python dependencies"

# Check shell script syntax
echo ""
echo "Checking shell script syntax..."
syntax_errors=0
for script in core/*.sh protocols/*.sh security/*.sh network/*.sh; do
    if [ -f "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            echo "  ✓ $script"
        else
            echo "  ✗ $script (SYNTAX ERROR)"
            syntax_errors=$((syntax_errors + 1))
        fi
    fi
done

# Final status
echo ""
echo "====================================="
if [ $missing_files -eq 0 ] && [ $syntax_errors -eq 0 ]; then
    echo "✅ VERIFICATION PASSED"
    echo "Toolkit is ready for GitHub upload and VPS deployment!"
else
    echo "❌ VERIFICATION FAILED"
    echo "Missing files: $missing_files"
    echo "Syntax errors: $syntax_errors"
fi
echo "====================================="