# Android & iOS Permissions Setup

## Android Permissions

When you create your Android project or if you haven't yet, add these permissions to:

**File:** `android/app/src/main/AndroidManifest.xml`

Add inside the `<manifest>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera permission -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- Internet permission for API calls -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- For accessing localhost from emulator -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Read external storage for image picker -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32" />
    
    <application
        android:label="myjanji_v2"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... existing configuration ... -->
        
        <!-- Allow cleartext traffic for localhost (development only) -->
        <uses-library android:name="org.apache.http.legacy" android:required="false"/>
    </application>
</manifest>
```

**Also add to** `android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
<application>
    <!-- ... existing code ... -->
    
    <!-- Allow HTTP traffic for localhost (development only) -->
    <uses-library android:name="org.apache.http.legacy" android:required="false"/>
    
    <!-- For Android 9+ cleartext traffic -->
    <meta-data 
        android:name="io.flutter.networkPolicy" 
        android:value="@xml/network_security_config" />
</application>
```

Create **File:** `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

## iOS Permissions

**File:** `ios/Runner/Info.plist`

Add these keys inside the `<dict>` tag:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera for face verification</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to upload IC images</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to save photos</string>
```

## Testing Permissions

After adding permissions:

1. **Android**: Rebuild the app (`flutter clean && flutter pub get && flutter run`)
2. **iOS**: Rebuild the app (permissions are read at build time)

The app will automatically request permissions when needed (camera for verification, photo library for IC upload).

