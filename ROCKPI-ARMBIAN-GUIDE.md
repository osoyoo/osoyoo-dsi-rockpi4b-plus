# OSOYOO DSI Panel Driver for RockPi 4B+ (Armbian)

Complete installation guide for OSOYOO DSI touchscreen panels on RockPi 4B+ running Armbian.

## Supported Hardware

- **Panels**: OSOYOO 7" and 10.1" DSI touchscreen panels
- **Board**: RockPi 4B+ (Rockchip RK3399)
- **OS**: Armbian 26.x and later
- **Tested**: Armbian 26.2.0 trunk.821 trixi

## Hardware Requirements

1. RockPi 4B+ board
2. OSOYOO DSI panel (7" or 10.1")
3. MIPI DSI cable (usually included with panel)
4. Armbian OS installed

## ⚠️ Current Status

**Partially Working** - Driver builds and installs successfully on kernel 6.18+. Device tree overlay support is in progress.

**What Works:**
- ✅ Kernel 6.18+ GPIO API compatibility fixed
- ✅ DKMS driver builds and installs
- ✅ Correct I2C bus identified (I2C1, not I2C4)

**Known Issues:**
- ❌ U-Boot overlay loading not working (investigating)
- ⚠️ Requires manual device tree patching (workaround available)

## Quick Installation (3 Steps)

### Step 1: Install the Driver

```bash
cd ~
git clone https://github.com/osoyoo/osoyoo-dsi-rockpi4b-plus.git
cd osoyoo-dsi-rockpi4b-plus
sudo ./install-rockpi-armbian.sh
```

The installer will automatically:
- Install dependencies (DKMS, device-tree-compiler)
- Install kernel headers for your Armbian kernel
- Build and install the driver module
- Compile and install device tree overlays

### Step 2: Configure Boot Parameters

Edit the Armbian boot configuration:

```bash
sudo nano /boot/armbianEnv.txt
```

Add the appropriate overlay for your panel:

**For 10.1" panel (recommended for most users):**
```ini
user_overlays=osoyoo-panel-dsi-10inch
```

**For 7" panel:**
```ini
user_overlays=osoyoo-panel-dsi-7inch
```

**Optional I2C speed adjustment (if touchscreen is unreliable):**
```ini
param_i2c4_speed=100000
```

Example complete `/boot/armbianEnv.txt`:
```ini
verbosity=1
bootlogo=false
overlay_prefix=rockchip
rootdev=UUID=12345678-1234-1234-1234-123456789abc
rootfstype=ext4
user_overlays=osoyoo-panel-dsi-10inch
param_i2c4_speed=100000
```

Save and exit (Ctrl+X, Y, Enter).

### Step 3: Reboot

```bash
sudo reboot
```

After reboot, your DSI screen should display!

## Verification

Check if the driver loaded successfully:

```bash
# Check loaded modules
lsmod | grep osoyoo
```

You should see:
```
osoyoo_panel_dsi
osoyoo_panel_regulator
```

Check kernel messages:
```bash
dmesg | grep -i osoyoo
```

Check I2C devices:
```bash
sudo apt-get install -y i2c-tools
sudo i2cdetect -y 4
```

You should see devices at addresses `0x45` (display MCU) and `0x5d` (touchscreen).

## Hardware Connection

### Physical Setup

1. **Power off** your RockPi 4B+ completely
2. Connect the OSOYOO DSI panel to the **MIPI DSI port** on RockPi 4B+
3. Ensure the MIPI cable is firmly seated in both connectors
4. Power on the board

### RockPi 4B+ DSI Port Location

The MIPI DSI port on RockPi 4B+ is typically located near the HDMI ports. Refer to your board's documentation for exact location.

## Touchscreen Configuration

The touchscreen uses the Goodix GT9271 controller and should work automatically after driver installation.

### Touchscreen Calibration

If the touchscreen coordinates are inverted or swapped, you can adjust the device tree overlay:

Edit the overlay source:
```bash
sudo nano /usr/src/osoyoo-dsi-panel-1.0/osoyoo-panel-dsi-10inch.dts
```

Uncomment these sections as needed:
- For inverted X: activate `fragment@10`
- For inverted Y: activate `fragment@11`
- For swapped X/Y: modify the `touchscreen-swapped-x-y` property

Then recompile:
```bash
cd /usr/src/osoyoo-dsi-panel-1.0
sudo dtc -I dts -O dtb -o /boot/overlay-user/osoyoo-panel-dsi-10inch.dtbo \
    osoyoo-panel-dsi-10inch.dts
sudo reboot
```

## Troubleshooting

### Screen shows nothing (black screen)

1. **Check physical connection:**
   ```bash
   # Verify DSI is recognized
   dmesg | grep -i dsi
   dmesg | grep -i mipi
   ```

2. **Check overlay is loaded:**
   ```bash
   ls -la /boot/overlay-user/osoyoo*
   cat /boot/armbianEnv.txt | grep overlay
   ```

3. **Check I2C communication:**
   ```bash
   sudo i2cdetect -y 4
   ```
   Should show devices at `0x45` and `0x5d`.

4. **Verify kernel modules:**
   ```bash
   lsmod | grep osoyoo
   lsmod | grep panel
   ```

### Touchscreen not responding

1. **Check touchscreen driver:**
   ```bash
   dmesg | grep gt9271
   dmesg | grep goodix
   ```

2. **Verify input device:**
   ```bash
   ls /dev/input/event*
   cat /proc/bus/input/devices | grep -A 10 Goodix
   ```

3. **Test raw touchscreen input:**
   ```bash
   sudo evtest
   # Select the Goodix device and test touch
   ```

4. **Try slower I2C speed:**
   Edit `/boot/armbianEnv.txt` and set:
   ```ini
   param_i2c4_speed=50000
   ```

### Driver fails to build

1. **Ensure kernel headers are installed:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y linux-headers-$(uname -r)
   ```

   For Armbian, try:
   ```bash
   sudo apt-get install -y linux-headers-current-rockchip64
   ```

2. **Check DKMS status:**
   ```bash
   sudo dkms status
   ```

3. **Manual rebuild:**
   ```bash
   cd /usr/src/osoyoo-dsi-panel-1.0
   sudo dkms remove osoyoo-dsi-panel/1.0 --all
   sudo dkms add osoyoo-dsi-panel/1.0
   sudo dkms build osoyoo-dsi-panel/1.0
   sudo dkms install osoyoo-dsi-panel/1.0
   ```

### After kernel update, screen stops working

When Armbian updates the kernel, reinstall the driver:

```bash
cd ~/osoyoo-dsi-rockpi4b-plus
sudo dkms remove osoyoo-dsi-panel/1.0 --all
sudo ./install-rockpi-armbian.sh
sudo reboot
```

## Technical Details

### Device Tree Overlay Structure

The RockPi device tree overlay configures:

1. **I2C4 Bus**: Display MCU (0x45) and touchscreen (0x5d)
2. **MIPI DSI Controller**: Panel initialization and display modes
3. **GPIO Configuration**: Touch interrupt and reset GPIOs
4. **Touchscreen Parameters**: Resolution (800x1280 for 10.1", 720x1280 for 7")

### Panel Specifications

**10.1" Panel:**
- Resolution: 800x1280
- Interface: 4-lane MIPI DSI
- Touchscreen: Goodix GT9271 (I2C)
- Display MCU: Custom controller at 0x45

**7" Panel:**
- Resolution: 720x1280
- Interface: 2-lane MIPI DSI
- Touchscreen: Goodix GT9271 (I2C)
- Display MCU: Custom controller at 0x45

### RockPi 4B+ vs Raspberry Pi Differences

| Feature | Raspberry Pi | RockPi 4B+ |
|---------|-------------|-----------|
| SoC | BCM2712 (Pi 5) | Rockchip RK3399 |
| DSI Controller | BCM DSI | Rockchip MIPI DSI |
| Overlay Path | `/boot/firmware/overlays/` | `/boot/overlay-user/` |
| Boot Config | `config.txt` | `armbianEnv.txt` |
| I2C Bus | i2c_csi_dsi | i2c4 |

## Panel Settings and Overrides

You can customize panel behavior by modifying the device tree overlay source:

```bash
sudo nano /usr/src/osoyoo-dsi-panel-1.0/osoyoo-panel-dsi-10inch.dts
```

Available parameters:
- `touchscreen-size-x`: Touch resolution X (default: 800)
- `touchscreen-size-y`: Touch resolution Y (default: 1280)
- `touchscreen-inverted-x`: Invert X axis
- `touchscreen-inverted-y`: Invert Y axis
- `touchscreen-swapped-x-y`: Swap X and Y axes

After modification, recompile and reboot:
```bash
cd /usr/src/osoyoo-dsi-panel-1.0
sudo dtc -I dts -O dtb -o /boot/overlay-user/osoyoo-panel-dsi-10inch.dtbo \
    osoyoo-panel-dsi-10inch.dts
sudo reboot
```

## Uninstallation

To remove the driver:

```bash
sudo dkms remove osoyoo-dsi-panel/1.0 --all
sudo rm -rf /usr/src/osoyoo-dsi-panel-1.0
sudo rm /boot/overlay-user/osoyoo-panel-dsi-*.dtbo
```

Edit `/boot/armbianEnv.txt` and remove the `user_overlays` line, then reboot.

## Support

- **Issues**: https://github.com/osoyoo/osoyoo-dsi-rockpi4b-plus/issues
- **Email**: support@osoyoo.info
- **Armbian Forum**: https://forum.armbian.com/

## Known Limitations

1. **Display rotation**: Currently configured for portrait mode (800x1280). Landscape rotation requires DRM/KMS configuration.
2. **Backlight control**: Backlight is controlled by display MCU, manual brightness adjustment may require custom I2C commands.
3. **Multi-display**: Using both HDMI and DSI simultaneously may require additional configuration.

## License

GPL v2 (same as original driver)

## Credits

- **Original Driver**: OSOYOO
- **Raspberry Pi Version**: Community contribution
- **RockPi/Armbian Adaptation**: Community contribution

---

**Note**: This is a community-adapted driver for RockPi 4B+. For Raspberry Pi 5/CM5, use the original repository: https://github.com/osoyoo/osoyoo_dsi_ubuntu
