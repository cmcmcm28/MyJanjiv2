# Refactoring Guide

The code has been split into separate files:

## File Structure:
```
lib/
├── main.dart                    # Main app entry point
├── theme/
│   └── app_theme.dart         # Theme configuration
├── models/
│   └── contract.dart          # Contract data model
├── screens/
│   ├── security_gateway_screen.dart
│   ├── dashboard_screen.dart
│   ├── create_contract_screen.dart
│   ├── sign_contract_screen.dart
│   └── nfc_simulation_screen.dart
└── widgets/
    └── radar_painter.dart      # Custom radar animation painter
```

## Remaining Files to Create:

1. **dashboard_screen.dart** - Extract lines 196-842 from original main.dart
2. **create_contract_screen.dart** - Extract lines 844-1033 from original main.dart  
3. **sign_contract_screen.dart** - Extract lines 1035-1391 from original main.dart

## Import Dependencies:

- dashboard_screen.dart needs: create_contract_screen.dart, sign_contract_screen.dart
- create_contract_screen.dart needs: nfc_simulation_screen.dart
- All screens need: flutter/material.dart, google_fonts, animate_do

