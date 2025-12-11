# Device Setup Guide for MyJanji App

## Quick Solutions

### Option 1: Start an Android Emulator (Recommended for Windows)

1. **Open Android Studio**
   - Launch Android Studio
   - Click on "More Actions" → "Virtual Device Manager" (or Tools → Device Manager)

2. **Create/Start an Emulator**
   - If you don't have one, click "Create Device"
   - Select a device (e.g., Pixel 5, Pixel 6)
   - Choose a system image (API 33 or 34 recommended)
   - Click "Finish" and then click the ▶️ play button to start the emulator

3. **Wait for Emulator to Boot**
   - Wait until the Android home screen appears (may take 1-2 minutes)

4. **Run Flutter App**
   ```bash
   flutter run
   ```

### Option 2: Connect a Physical Android Device

1. **Enable Developer Options on Your Phone**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings → Developer Options
   - Enable "USB Debugging"

2. **Connect via USB**
   - Connect your phone to your computer via USB cable
   - Allow USB debugging when prompted on your phone

3. **Verify Connection**
   ```bash
   flutter devices
   ```
   You should see your device listed

4. **Run Flutter App**
   ```bash
   flutter run
   ```

### Option 3: Use Chrome (Web - Quick Testing)

If you just want to see the UI quickly:

```bash
flutter run -d chrome
```

## Troubleshooting

### Check Available Devices
```bash
flutter devices
```

### If No Devices Show Up

**For Android:**
- Make sure Android SDK is installed
- Check that `adb` (Android Debug Bridge) is working:
  ```bash
   adb devices
   ```
- Restart ADB if needed:
  ```bash
   adb kill-server
   adb start-server
   ```

**For iOS (Mac only):**
- Open Xcode
- Go to Window → Devices and Simulators
- Start a simulator from there

### Common Issues

1. **"No supported devices"**
   - Make sure emulator is fully booted (not just starting)
   - For physical devices, check USB debugging is enabled

2. **"Waiting for another flutter command"**
   - Close other Flutter processes or restart your IDE

3. **Emulator too slow**
   - Try a smaller device profile (Pixel 4 instead of Pixel 6)
   - Enable hardware acceleration in Android Studio

## Recommended Setup for Demo Recording

For the best demo experience:
- Use **Android Emulator** (Pixel 5 or 6) - smooth and reliable
- Screen resolution: 1080x1920 or higher
- API Level: 33 or 34

## Quick Start Commands

```bash
# List all available devices
flutter devices

# Run on specific device (replace device-id)
flutter run -d <device-id>

# Run on Chrome (web)
flutter run -d chrome

# Run on first available device
flutter run
```

