# GEMINI.md - Project Context: awksalat

## Project Overview
`awksalat` is a Flutter-based mobile application designed to provide daily Islamic prayer times (Salat) and Hijri calendar dates. The application uses a minimalist dark UI and features integration with Android home screen widgets for quick access to prayer information.

### Core Technologies
- **Flutter (SDK ^3.11.0)**: Main framework for cross-platform development.
- **adhan**: Library for calculating prayer times (currently present in `pubspec.yaml`, though times are currently loaded from CSV).
- **hijri**: For Hijri calendar calculations and formatting.
- **home_widget**: For managing Android and iOS home screen widgets.
- **intl**: For date and time formatting.

### Architecture & Data Flow
- **Data Source**: Prayer times are currently loaded and parsed from a local CSV asset (`assets/horaires.csv`).
- **UI Structure**: 
  - `SalatApp`: Main application entry point.
  - `PrayerScreen`: The primary screen displaying the Hijri date and a table of the six prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha).
- **Widget Integration**: The app is configured to update an Android widget defined in `android/app/src/main/res/layout/prayer_widget.xml` using `HomeWidgetProvider`.

---

## Building and Running

### Prerequisites
- Flutter SDK installed and configured.
- Android/iOS development environment.

### Key Commands
- **Install Dependencies**: `flutter pub get`
- **Run Application**: `flutter run`
- **Run Tests**: `flutter test`
- **Linting**: `flutter analyze`
- **Build Android APK**: `flutter build apk`
- **Build iOS (on macOS)**: `flutter build ios`

---

## Development Conventions

### Coding Style
- Follows standard Flutter/Dart linting rules as defined in `analysis_options.yaml` (using `package:flutter_lints/flutter.yaml`).
- **RTL Support**: The application explicitly uses `TextDirection.rtl` as it is primarily targeted at Arabic-speaking users.
- **Formatting**: Use `dart format .` for consistent code formatting.

### Localization & Dates
- **Language**: UI elements and dates are primarily in Arabic.
- **Hijri Date Format**: Custom formatting is used (e.g., "الجمعة، 6 رمضان 1447") with Latin-to-Arabic numeral conversion helpers.

### Home Widget Implementation
- Updates to the home widget should be performed via `HomeWidget.saveWidgetData` and `HomeWidget.updateWidget`.
- Ensure the `androidName` in Flutter matches the `receiver` name in `AndroidManifest.xml`.
- Widget layouts are managed natively on the Android side (`res/layout/prayer_widget.xml`).

### Testing
- Widget tests are located in the `test/` directory.
- Use `flutter test` to verify UI components and basic logic.
