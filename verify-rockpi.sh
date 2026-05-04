#!/bin/bash
# Verification and debugging script for RockPi 4B+ OSOYOO DSI Panel
# This script checks the installation and helps diagnose issues

echo "=========================================="
echo "OSOYOO DSI Panel - RockPi 4B+ Diagnostics"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

check_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 1. Check board model
echo "1. Checking board model..."
if [ -f /proc/device-tree/model ]; then
    BOARD_MODEL=$(cat /proc/device-tree/model | tr -d '\0')
    echo "   Board: $BOARD_MODEL"
    if [[ "$BOARD_MODEL" == *"ROCK Pi 4"* ]] || [[ "$BOARD_MODEL" == *"RK3399"* ]]; then
        check_ok "RockPi 4 detected"
    else
        check_warn "Board may not be RockPi 4B+"
    fi
else
    check_fail "Cannot detect board model"
fi
echo ""

# 2. Check kernel version
echo "2. Checking kernel version..."
KERNEL_VERSION=$(uname -r)
echo "   Kernel: $KERNEL_VERSION"
check_ok "Kernel detected"
echo ""

# 3. Check if driver modules are loaded
echo "3. Checking driver modules..."
if lsmod | grep -q osoyoo_panel_dsi; then
    check_ok "osoyoo_panel_dsi module loaded"
else
    check_fail "osoyoo_panel_dsi module NOT loaded"
    echo "   Try: sudo modprobe osoyoo_panel_dsi"
fi

if lsmod | grep -q osoyoo_panel_regulator; then
    check_ok "osoyoo_panel_regulator module loaded"
else
    check_fail "osoyoo_panel_regulator module NOT loaded"
    echo "   Try: sudo modprobe osoyoo_panel_regulator"
fi
echo ""

# 4. Check DKMS installation
echo "4. Checking DKMS installation..."
if dkms status | grep -q "osoyoo-dsi-panel"; then
    check_ok "DKMS module installed"
    dkms status | grep osoyoo-dsi-panel | sed 's/^/   /'
else
    check_fail "DKMS module NOT installed"
    echo "   Run: sudo ./install-rockpi-armbian.sh"
fi
echo ""

# 5. Check device tree overlays
echo "5. Checking device tree overlays..."
if [ -f /boot/overlay-user/osoyoo-panel-dsi-10inch.dtbo ]; then
    check_ok "10-inch panel overlay found"
else
    check_fail "10-inch panel overlay NOT found"
fi

if [ -f /boot/overlay-user/osoyoo-panel-dsi-7inch.dtbo ]; then
    check_ok "7-inch panel overlay found"
else
    check_warn "7-inch panel overlay NOT found (not needed if using 10-inch)"
fi
echo ""

# 6. Check boot configuration
echo "6. Checking boot configuration..."
if [ -f /boot/armbianEnv.txt ]; then
    if grep -q "user_overlays.*osoyoo" /boot/armbianEnv.txt; then
        check_ok "Overlay configured in armbianEnv.txt"
        grep "user_overlays" /boot/armbianEnv.txt | sed 's/^/   /'
    else
        check_fail "Overlay NOT configured in armbianEnv.txt"
        echo "   Add: user_overlays=osoyoo-panel-dsi-10inch"
    fi
else
    check_fail "/boot/armbianEnv.txt not found"
fi
echo ""

# 7. Check I2C
echo "7. Checking I2C devices..."
if command -v i2cdetect &> /dev/null; then
    if [ -e /dev/i2c-4 ]; then
        echo "   Scanning I2C bus 4..."
        i2cdetect -y 4 2>/dev/null | grep -E "45|5d" && {
            check_ok "Display MCU (0x45) or Touchscreen (0x5d) detected"
        } || {
            check_fail "No devices at 0x45 or 0x5d"
            echo "   Expected: Display MCU at 0x45, Touchscreen at 0x5d"
        }
    else
        check_fail "/dev/i2c-4 not found"
        echo "   I2C bus 4 may not be enabled"
    fi
else
    check_warn "i2c-tools not installed"
    echo "   Install: sudo apt-get install i2c-tools"
fi
echo ""

# 8. Check kernel messages
echo "8. Checking kernel messages for OSOYOO..."
if dmesg | grep -i osoyoo | tail -n 5 | grep -q .; then
    check_ok "OSOYOO messages found in kernel log"
    echo "   Recent messages:"
    dmesg | grep -i osoyoo | tail -n 5 | sed 's/^/   /'
else
    check_warn "No OSOYOO messages in kernel log"
    echo "   This may be normal if driver hasn't been loaded yet"
fi
echo ""

# 9. Check DSI/MIPI
echo "9. Checking DSI/MIPI kernel messages..."
if dmesg | grep -iE "dsi|mipi" | tail -n 5 | grep -q .; then
    check_ok "DSI/MIPI messages found"
    echo "   Recent messages:"
    dmesg | grep -iE "dsi|mipi" | tail -n 5 | sed 's/^/   /'
else
    check_warn "No DSI/MIPI messages found"
fi
echo ""

# 10. Check touchscreen input device
echo "10. Checking touchscreen input device..."
if ls /dev/input/event* &> /dev/null; then
    if grep -q "Goodix" /proc/bus/input/devices 2>/dev/null; then
        check_ok "Goodix touchscreen device found"
        grep -A 5 "Goodix" /proc/bus/input/devices | sed 's/^/   /'
    else
        check_fail "Goodix touchscreen NOT found"
        echo "   Touchscreen may not be initialized"
    fi
else
    check_warn "No input devices found"
fi
echo ""

# Summary
echo "=========================================="
echo "Diagnostic Summary"
echo "=========================================="
echo ""
echo "If you see issues above, try these steps:"
echo ""
echo "1. Reinstall the driver:"
echo "   cd ~/osoyoo-dsi-panel"
echo "   sudo ./install-rockpi-armbian.sh"
echo ""
echo "2. Check physical connections:"
echo "   - Ensure DSI cable is firmly connected"
echo "   - Check panel power connection"
echo ""
echo "3. Enable debug messages:"
echo "   dmesg -w | grep -iE 'osoyoo|dsi|mipi|goodix'"
echo ""
echo "4. Test touchscreen manually:"
echo "   sudo evtest"
echo "   (Then select Goodix device and touch the screen)"
echo ""
echo "5. Check detailed logs:"
echo "   journalctl -k | grep -iE 'osoyoo|dsi|mipi'"
echo ""
echo "=========================================="
