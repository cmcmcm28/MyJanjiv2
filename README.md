# MyJanji V2 - Demo Prototype

A high-fidelity Flutter UI/UX prototype showcasing the MyJanji app with 4 connected screens.

## Features

- **Screen 1: Security Gateway** - Landing page with pulsing animation and identity verification
- **Screen 2: Dashboard** - Home screen with Digital MyKad card, summary tabs, and contract list
- **Screen 3: Create Contract** - Form to create new contracts
- **Screen 4: NFC Simulation** - Handshake screen with radar scanning animation

## Design System

- **Material Design 3** compliant
- **Primary Color**: Deep Royal Blue (#1E3A8A)
- **Secondary Color**: Golden Yellow (#FFD700)
- **Font**: Poppins (Google Fonts)

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
  └── main.dart    # All 4 screens in a single file
```

## Navigation Flow

1. **Security Gateway** → Tap circle → Navigate to Dashboard
2. **Dashboard** → Tap "+ New Janji" FAB → Navigate to Create Contract
3. **Create Contract** → Tap "Tap ID to Sign & Create" → Navigate to NFC Simulation
4. **NFC Simulation** → Tap radar → Show success animation

## Notes

- Ready for immediate demo recording
- Smooth animations and transitions throughout

