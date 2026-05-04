#!/bin/bash
# Armbian installation script for RockPi 4B+
# This script installs the OSOYOO DSI panel driver for Rockchip RK3399
# Run this ON your RockPi 4B+ running Armbian

set -e

PACKAGE_NAME="osoyoo-dsi-panel"
PACKAGE_VERSION="1.0"
SRC_BASE="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"

echo "=========================================="
echo "OSOYOO DSI Panel Driver Installation"
echo "For RockPi 4B+ / Armbian"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Hardware detection function
detect_hardware() {
    local board_model="unknown"
    local os_distro="unknown"
    local kernel_version=$(uname -r)
    local arch=$(uname -m)

    # Detect Board Model
    if [ -f /proc/device-tree/model ]; then
        local device_model=$(cat /proc/device-tree/model | tr -d '\0')

        case "$device_model" in
            *"ROCK Pi 4"*|*"Radxa ROCK Pi 4"*)
                board_model="rockpi4"
                ;;
            *"RK3399"*)
                board_model="rockpi4"
                ;;
            *)
                # Fallback to /proc/cpuinfo
                if grep -q "RK3399" /proc/cpuinfo 2>/dev/null || grep -q "RK3399" /proc/device-tree/compatible 2>/dev/null; then
                    board_model="rockpi4"
                fi
                ;;
        esac
    fi

    # Detect OS Distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            debian|armbian) os_distro="armbian" ;;
            ubuntu) os_distro="ubuntu" ;;
            *) os_distro="$ID" ;;
        esac
    fi

    echo "$board_model|$os_distro|$kernel_version|$arch"
}

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y dkms device-tree-compiler

# Install kernel headers
KERNEL_VERSION=$(uname -r)
echo "Installing kernel headers for ${KERNEL_VERSION}..."
if apt-cache search linux-headers-${KERNEL_VERSION} | grep -q linux-headers-${KERNEL_VERSION}; then
    apt-get install -y linux-headers-${KERNEL_VERSION}
else
    echo "WARNING: Could not find exact kernel headers."
    echo "         Attempting to install current kernel headers..."
    apt-get install -y linux-headers-current-rockchip64 || \
    apt-get install -y linux-headers-edge-rockchip64 || \
    apt-get install -y linux-headers-legacy-rockchip64 || \
    apt-get install -y linux-headers-$(uname -r) || true
fi

echo "✓ Dependencies installed"
echo ""

# Detect hardware
echo "Detecting hardware..."
HARDWARE_INFO=$(detect_hardware)
BOARD_MODEL=$(echo "$HARDWARE_INFO" | cut -d'|' -f1)
OS_DISTRO=$(echo "$HARDWARE_INFO" | cut -d'|' -f2)
KERNEL_VERSION=$(echo "$HARDWARE_INFO" | cut -d'|' -f3)
ARCH=$(echo "$HARDWARE_INFO" | cut -d'|' -f4)

echo "  Board Model: $BOARD_MODEL"
echo "  OS Distribution: $OS_DISTRO"
echo "  Kernel Version: $KERNEL_VERSION"
echo "  Architecture: $ARCH"
echo ""

if [ "$BOARD_MODEL" != "rockpi4" ]; then
    echo "WARNING: This script is designed for RockPi 4B+."
    echo "         Your board: $BOARD_MODEL"
    echo "         Proceed with caution!"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if RockPi sources exist
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/src/rockpi"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: RockPi driver sources not found at $SOURCE_DIR"
    exit 1
fi

echo "Using RockPi driver: $SOURCE_DIR"
echo ""

# Remove old installation if exists
if dkms status -m ${PACKAGE_NAME} -v ${PACKAGE_VERSION} 2>/dev/null | grep -q "installed"; then
    echo "Removing previous installation..."
    dkms remove -m ${PACKAGE_NAME} -v ${PACKAGE_VERSION} --all || true
fi

# Create source directory
echo "Creating source directory..."
rm -rf "${SRC_BASE}"
mkdir -p "${SRC_BASE}"

# Copy files
echo "Copying source files..."
cp "${SCRIPT_DIR}/Makefile" "${SRC_BASE}/"
cp "${SCRIPT_DIR}/dkms.conf" "${SRC_BASE}/"
cp "${SCRIPT_DIR}/osoyoo-panel-dsi.c" "${SRC_BASE}/"
cp "${SCRIPT_DIR}/osoyoo-panel-regulator.c" "${SRC_BASE}/"
cp "$SOURCE_DIR/osoyoo-panel-dsi-7inch.dts" "${SRC_BASE}/"
cp "$SOURCE_DIR/osoyoo-panel-dsi-10inch.dts" "${SRC_BASE}/"

echo "✓ Files copied"
echo ""

# Add to DKMS
echo "Adding module to DKMS..."
dkms add -m ${PACKAGE_NAME} -v ${PACKAGE_VERSION}

# Build
echo "Building driver for kernel $KERNEL_VERSION..."
if dkms build -m ${PACKAGE_NAME} -v ${PACKAGE_VERSION}; then
    echo "✓ Build successful!"
else
    echo "ERROR: Build failed."
    echo "Make sure kernel headers are installed:"
    echo "  sudo apt-get install linux-headers-\$(uname -r)"
    exit 1
fi
echo ""

# Install
echo "Installing driver module..."
if dkms install -m ${PACKAGE_NAME} -v ${PACKAGE_VERSION}; then
    echo "✓ Installation successful!"
else
    echo "ERROR: Installation failed."
    exit 1
fi
echo ""

# Install device tree overlays
echo "Installing device tree overlays..."

# Armbian typically uses /boot/dtb/rockchip/overlay/ or /boot/overlay-user/
OVERLAY_DIR="/boot/overlay-user"
mkdir -p "$OVERLAY_DIR"

if [ -f "${SRC_BASE}/osoyoo-panel-dsi-7inch.dts" ]; then
    echo "  Compiling 7-inch panel overlay..."
    dtc -I dts -O dtb -o "$OVERLAY_DIR/osoyoo-panel-dsi-7inch.dtbo" \
        "${SRC_BASE}/osoyoo-panel-dsi-7inch.dts" 2>/dev/null
    echo "  ✓ 7-inch panel overlay installed"
fi

if [ -f "${SRC_BASE}/osoyoo-panel-dsi-10inch.dts" ]; then
    echo "  Compiling 10-inch panel overlay..."
    dtc -I dts -O dtb -o "$OVERLAY_DIR/osoyoo-panel-dsi-10inch.dtbo" \
        "${SRC_BASE}/osoyoo-panel-dsi-10inch.dts" 2>/dev/null
    echo "  ✓ 10-inch panel overlay installed"
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Hardware Configuration:"
echo "  Board: $BOARD_MODEL"
echo "  Kernel: $KERNEL_VERSION"
echo ""
echo "Next Steps:"
echo ""
echo "1. Enable the device tree overlay:"
echo "   sudo nano /boot/armbianEnv.txt"
echo ""
echo "2. Add ONE of the following lines:"
echo ""
echo "   For 7\" panel:"
echo "     user_overlays=osoyoo-panel-dsi-7inch"
echo ""
echo "   For 10.1\" panel (4-lane DSI):"
echo "     user_overlays=osoyoo-panel-dsi-10inch"
echo ""
echo "3. (Optional) If you need to adjust I2C settings, add:"
echo "     param_i2c4_speed=100000"
echo ""
echo "4. Save the file and reboot:"
echo "   sudo reboot"
echo ""
echo "5. After reboot, verify the driver loaded:"
echo "   lsmod | grep osoyoo"
echo "   dmesg | grep -i osoyoo"
echo ""
echo "Troubleshooting:"
echo "  - Check kernel messages: dmesg | grep -i dsi"
echo "  - Verify I2C devices: i2cdetect -y 4"
echo "  - Check overlay status: ls -la $OVERLAY_DIR/"
echo ""
echo "=========================================="
