# RockPi 4B+ Support - Changes Summary

This document summarizes the files added to enable OSOYOO DSI panel support on RockPi 4B+ running Armbian.

## Files Added

### Device Tree Overlays

1. **src/rockpi/osoyoo-panel-dsi-10inch.dts**
   - Rockchip RK3399-specific device tree overlay for 10.1" panel
   - Configured for 4-lane MIPI DSI
   - Uses I2C4 for display MCU and touchscreen
   - GPIO configuration for RockPi 4B+ (GPIO1 bank)

2. **src/rockpi/osoyoo-panel-dsi-7inch.dts**
   - Rockchip RK3399-specific device tree overlay for 7" panel
   - Configured for 2-lane MIPI DSI
   - Uses I2C4 for display MCU and touchscreen
   - GPIO configuration for RockPi 4B+ (GPIO1 bank)

### Installation Scripts

3. **install-rockpi-armbian.sh**
   - Armbian-specific installation script
   - Detects RockPi 4B+ hardware
   - Installs kernel headers for Armbian
   - Compiles and installs device tree overlays to `/boot/overlay-user/`
   - Provides Armbian-specific configuration instructions

4. **verify-rockpi.sh**
   - Diagnostic and verification script
   - Checks driver installation status
   - Verifies I2C devices (display MCU and touchscreen)
   - Tests module loading
   - Provides troubleshooting guidance

### Documentation

5. **ROCKPI-ARMBIAN-GUIDE.md**
   - Complete installation guide for RockPi 4B+ users
   - Hardware connection instructions
   - Troubleshooting section
   - Technical details and specifications
   - Comparison with Raspberry Pi implementation

6. **ROCKPI-CHANGES.md** (this file)
   - Summary of changes for RockPi support

### Modified Files

7. **README.md**
   - Updated to include RockPi 4B+ platform support
   - Added platform selection section
   - Links to platform-specific documentation

## Key Technical Adaptations

### Hardware Differences

| Component | Raspberry Pi 5 | RockPi 4B+ |
|-----------|---------------|-----------|
| SoC | Broadcom BCM2712 | Rockchip RK3399 |
| DSI Reference | `&dsi0` / `&dsi1` | `&mipi_dsi` |
| I2C Bus | `&i2c_csi_dsi` | `&i2c4` |
| GPIO | BCM GPIO | Rockchip GPIO1 |
| Compatible String | `brcm,bcm2835` | `rockchip,rk3399` |

### Software Differences

| Aspect | Raspberry Pi (Ubuntu) | RockPi 4B+ (Armbian) |
|--------|----------------------|---------------------|
| Boot Config | `/boot/firmware/config.txt` | `/boot/armbianEnv.txt` |
| Overlay Path | `/boot/firmware/overlays/` | `/boot/overlay-user/` |
| Overlay Syntax | `dtoverlay=name,param1,param2` | `user_overlays=name` |
| Kernel Headers | `raspberrypi-kernel-headers` | `linux-headers-current-rockchip64` |

## Device Tree Overlay Details

### I2C Configuration

Both overlays configure I2C4 with:
- Display MCU at address `0x45`
- Goodix GT9271 touchscreen at address `0x5d`
- Touch interrupt on GPIO1_C4 (GPIO 52)
- Touch reset on GPIO1_D0 (GPIO 56)

### MIPI DSI Configuration

The overlays configure the MIPI DSI controller (`&mipi_dsi`) with:
- 4-lane mode for 10.1" panel
- 2-lane mode for 7" panel
- Standard MIPI DSI panel initialization
- Display modes matching panel specifications

### Panel Specifications

**10.1" Panel:**
```
Resolution: 800x1280
Pixel Clock: 74.673 MHz
MIPI Lanes: 4
Touchscreen: 800x1280
Physical Size: 135mm x 216mm
```

**7" Panel:**
```
Resolution: 720x1280
Pixel Clock: 51.2 MHz
MIPI Lanes: 2
Touchscreen: 720x1280
Physical Size: 90mm x 151mm
```

## Installation Flow

```
User runs: sudo ./install-rockpi-armbian.sh
    ↓
1. Detect RockPi 4B+ hardware
    ↓
2. Install dependencies (DKMS, dtc, kernel headers)
    ↓
3. Copy driver sources to /usr/src/osoyoo-dsi-panel-1.0/
    ↓
4. Build driver with DKMS
    ↓
5. Install driver modules
    ↓
6. Compile device tree overlays (.dts → .dtbo)
    ↓
7. Install overlays to /boot/overlay-user/
    ↓
8. Display configuration instructions
```

## Configuration Flow

```
User edits: /boot/armbianEnv.txt
    ↓
Adds: user_overlays=osoyoo-panel-dsi-10inch
    ↓
(Optional) Adds: param_i2c4_speed=100000
    ↓
User runs: sudo reboot
    ↓
U-Boot loads device tree overlay
    ↓
Kernel initializes:
  - MIPI DSI controller
  - I2C4 with display MCU and touchscreen
  - Panel driver (osoyoo_panel_dsi)
  - Touchscreen driver (goodix)
    ↓
Display shows output
Touch input works
```

## Testing Checklist

After installation, verify:

- [ ] Driver modules loaded: `lsmod | grep osoyoo`
- [ ] DKMS status: `dkms status | grep osoyoo`
- [ ] Overlays installed: `ls /boot/overlay-user/osoyoo*`
- [ ] Boot config: `grep osoyoo /boot/armbianEnv.txt`
- [ ] I2C devices: `sudo i2cdetect -y 4` (should show 0x45 and 0x5d)
- [ ] Kernel messages: `dmesg | grep -i osoyoo`
- [ ] Display output visible
- [ ] Touchscreen responsive: `sudo evtest`

## Future Improvements

Potential enhancements:
1. Auto-detection of panel size (7" vs 10.1")
2. Dynamic I2C bus selection
3. Backlight brightness control via sysfs
4. Display rotation support
5. Multi-display configuration examples
6. DKMS auto-rebuild on kernel updates

## Compatibility Notes

**Tested on:**
- RockPi 4B+ (Model B Plus)
- Armbian 26.2.0 trunk.821 trixi
- Kernel 6.x series
- OSOYOO 10.1" DSI panel

**Should work on:**
- Other RK3399-based boards (with device tree modifications)
- Other Armbian versions (26.x and later)
- Debian-based distributions on RK3399

**Not tested:**
- RockPi 4A/4C variants
- Other Rockchip SoCs (RK3588, RK3566, etc.)
- Android on RockPi

## Maintainer Notes

If adapting for other Rockchip boards:
1. Check I2C bus number (may not be I2C4)
2. Verify GPIO assignments for touch interrupt/reset
3. Check MIPI DSI device tree reference name
4. Adjust compatible string if needed
5. Test and verify all functionality

## License

All added files maintain GPL v2 license compatibility with the original driver.

---

Created: 2026-05-03
Platform: RockPi 4B+ / Armbian
Driver Version: 1.0
