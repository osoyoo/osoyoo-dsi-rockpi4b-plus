# OSOYOO DSI Panel Driver for RockPi 4B+

Pre-configured driver for OSOYOO DSI touchscreen panels on RockPi 4B+ running Armbian.

![RockPi 4B+ with OSOYOO Panel](https://img.shields.io/badge/Platform-RockPi%204B%2B-blue) ![Armbian](https://img.shields.io/badge/OS-Armbian%2026.x-green) ![License](https://img.shields.io/badge/License-GPL%20v2-orange)

## 🎯 Quick Start

**On your RockPi 4B+ board:**

```bash
# 1. Clone and install
cd ~
git clone https://github.com/osoyoo/osoyoo-dsi-rockpi4b-plus.git
cd osoyoo-dsi-rockpi4b-plus
sudo ./install-rockpi-armbian.sh

# 2. Configure boot overlay
sudo nano /boot/armbianEnv.txt
# Add this line:
user_overlays=osoyoo-panel-dsi-10inch

# 3. Reboot
sudo reboot
```

Your 10.1" touchscreen should now work! 🎉

## 📋 Supported Hardware

- ✅ **Panel**: OSOYOO 10.1" DSI touchscreen (800x1280)
- ✅ **Panel**: OSOYOO 7" DSI touchscreen (720x1280)
- ✅ **Board**: RockPi 4B+ (Rockchip RK3399)
- ✅ **OS**: Armbian 26.x and later
- ✅ **Tested**: Armbian 26.2.0 trunk.821 trixi

## 📖 Documentation

- **[Installation Guide](ROCKPI-ARMBIAN-GUIDE.md)** - Complete step-by-step instructions
- **[Troubleshooting](ROCKPI-ARMBIAN-GUIDE.md#troubleshooting)** - Common issues and solutions
- **[Technical Details](ROCKPI-CHANGES.md)** - Architecture and adaptations

## 🔍 Verification

After installation, run the diagnostic tool:

```bash
sudo ./verify-rockpi.sh
```

This checks:
- Driver modules loaded
- I2C devices detected (0x45, 0x5d)
- Device tree overlay status
- Touchscreen input device

## ⚙️ What Gets Installed

- **Kernel modules**: `osoyoo_panel_dsi`, `osoyoo_panel_regulator`
- **Device tree overlays**: For RK3399 MIPI DSI interface
- **Touchscreen driver**: Goodix GT9271 support
- **I2C configuration**: Display MCU and touch controller

## 🛠️ Hardware Setup

1. **Power off** your RockPi 4B+ completely
2. Connect OSOYOO panel to the **MIPI DSI port**
3. Ensure cable is firmly seated
4. Power on and boot

## 🐛 Troubleshooting

**Black screen?**
```bash
# Check I2C devices
sudo i2cdetect -y 4
# Should show 0x45 and 0x5d

# Check kernel messages
dmesg | grep -i osoyoo
```

**Touch not working?**
```bash
# Verify touchscreen device
cat /proc/bus/input/devices | grep Goodix

# Test raw input
sudo evtest
```

**After kernel update?**
```bash
cd ~/osoyoo-dsi-rockpi4b-plus
sudo dkms remove osoyoo-dsi-panel/1.0 --all
sudo ./install-rockpi-armbian.sh
sudo reboot
```

## 🔧 Technical Specs

### 10.1" Panel
- Resolution: 800×1280 (portrait)
- Interface: 4-lane MIPI DSI
- Touch: Goodix GT9271 (I2C)
- Pixel Clock: 74.673 MHz

### 7" Panel
- Resolution: 720×1280 (portrait)
- Interface: 2-lane MIPI DSI
- Touch: Goodix GT9271 (I2C)
- Pixel Clock: 51.2 MHz

## 🆚 RockPi vs Raspberry Pi

| Feature | Raspberry Pi 5 | RockPi 4B+ |
|---------|---------------|-----------|
| **SoC** | BCM2712 | Rockchip RK3399 |
| **Boot Config** | `/boot/firmware/config.txt` | `/boot/armbianEnv.txt` |
| **Overlay Path** | `/boot/firmware/overlays/` | `/boot/overlay-user/` |
| **DSI Node** | `&dsi0` / `&dsi1` | `&mipi_dsi` |
| **I2C Bus** | i2c_csi_dsi | i2c4 |

## 📦 Repository Contents

```
osoyoo-dsi-rockpi4b-plus/
├── install-rockpi-armbian.sh   # Installation script
├── verify-rockpi.sh            # Diagnostic tool
├── ROCKPI-ARMBIAN-GUIDE.md     # Complete guide
├── ROCKPI-CHANGES.md           # Technical details
├── src/rockpi/                 # RK3399 device tree overlays
│   ├── osoyoo-panel-dsi-10inch.dts
│   └── osoyoo-panel-dsi-7inch.dts
├── osoyoo-panel-dsi.c          # Panel driver
├── osoyoo-panel-regulator.c    # Regulator driver
├── Makefile                    # Build configuration
└── dkms.conf                   # DKMS configuration
```

## 🤝 Support

- **GitHub Issues**: [Report a bug](https://github.com/osoyoo/osoyoo-dsi-rockpi4b-plus/issues)
- **Email**: support@osoyoo.info
- **Armbian Forum**: https://forum.armbian.com/

## 📄 License

GPL v2 (same as Linux kernel and original driver)

## 🙏 Credits

- **Original Driver**: OSOYOO
- **Raspberry Pi Port**: Community
- **RockPi Adaptation**: Community contribution
- **Testing**: RockPi 4B+ + Armbian users

---

**Related Projects**:
- [Raspberry Pi 5 Version](https://github.com/osoyoo/osoyoo_dsi_ubuntu) - For Ubuntu on Pi 5/CM5
- [Original Driver](https://github.com/osoyoo/osoyoo-dsi-panel) - For Raspberry Pi OS

---

Made with ❤️ for the RockPi community
