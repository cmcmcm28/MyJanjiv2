# Flask Backend Integration Guide

This guide explains how to integrate the Flask facial recognition backend with the Flutter app.

## Backend Setup

1. Navigate to the `Face recognition` folder
2. Install dependencies: `pip install -r requirements.txt`
3. Run the backend: `python app.py`
4. The backend will start on `http://0.0.0.0:5000`

See `SETUP_BACKEND.md` in the `Face recognition` folder for detailed setup instructions.

## Backend Setup

1. Ensure your Flask backend is running at `http://10.0.2.2:5000` (Android emulator) or `http://localhost:5000` (iOS simulator)

## Android Permissions

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Camera permission -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- Internet permission for API calls -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- For accessing localhost from emulator -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application>
        <!-- ... your existing configuration ... -->
    </application>
</manifest>
```

## iOS Permissions

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera for face verification</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to upload IC images</string>
```

## Configuration

### Backend URL Configuration

The backend URL is configured in `lib/services/face_auth_service.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:5000';
```

- **Android Emulator**: Use `http://10.0.2.2:5000` (this maps to `localhost:5000` on your host machine)
- **iOS Simulator**: Use `http://localhost:5000`
- **Physical Device**: Use your computer's IP address (e.g., `http://192.168.1.100:5000`)

### Switching Between Mock and Real Backend

The app now uses the real backend by default. The `VerifyFaceView` widget will:
1. Open the live camera
2. Auto-capture frames every 2 seconds
3. Send frames to `/process_frame` endpoint
4. Display verification results

## API Endpoints

### 1. POST /upload_ic
- **Input**: Multipart form-data with `ic_image` file
- **Response**: `{ "status": "success", "redirect": "..." }` or error

### 2. POST /process_frame
- **Input**: JSON `{ "image": "data:image/jpeg;base64,..." }`
- **Response**: 
  - Success: `{ "status": "success", "score": 95, "message": "Identity Verified" }`
  - Fail: `{ "status": "fail", "message": "..." }`

## Usage

### Registration Flow

Use `RegisterFaceView` widget to upload IC images:

```dart
RegisterFaceView(
  onComplete: (bool success, String? message) {
    if (success) {
      // Handle success
    } else {
      // Handle error
    }
  },
)
```

### Verification Flow

Use `VerifyFaceView` widget for live camera verification:

```dart
VerifyFaceView(
  onVerified: (bool success, Map<String, dynamic>? result) {
    if (success) {
      final score = result?['score'];
      final message = result?['message'];
      // Handle success
    } else {
      // Handle failure
    }
  },
)
```

## Error Handling

The service handles:
- Network errors (backend offline)
- HTTP errors (server errors)
- Camera initialization errors
- Image encoding errors

All errors are displayed to the user with appropriate messages.

## Testing

1. Start your Flask backend
2. Run the Flutter app
3. During login, the IC upload and face verification will use the real backend
4. Check console logs for any connection issues

