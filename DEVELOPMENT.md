# Loyalty App Development Guide

This document provides instructions for setting up and running the Loyalty App during development.

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (included with Flutter)
- Android Studio or Visual Studio Code with Flutter/Dart plugins
- A mobile device or emulator

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/loyalty-app.git
   cd loyalty-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

The app follows a Clean Architecture approach with BLoC pattern for state management:

```
lib/
  core/                      # Core functionality
    app/                     # App-wide services
    common/                  # Shared widgets
    constants/               # Constants and configuration
    di/                      # Dependency injection
    l10n/                    # Localization
    theme/                   # Design system
    utils/                   # Helper functions
  
  features/                  # Feature modules
    loyalty/                 # Loyalty feature
      api/                   # API contracts
      data/                  # Data implementation
      domain/                # Business logic
      ui/                    # Presentation
    auth/                    # Authentication feature
      api/                   # API contracts
      data/                  # Data implementation
      domain/                # Business logic
      ui/                    # Presentation
```

## UI Implementation Details

### Frosted Glass Effect

The app uses a custom `GlassCard` widget to create the frosted glass effect seen in the design. This widget uses `BackdropFilter` with `ImageFilter.blur` to create the effect.

### Dark Theme with Gradients

The app implements a dark theme with gradient backgrounds. The `GradientBackground` and `GradientContainer` widgets are used to create consistent gradient backgrounds throughout the app.

### Loyalty Features

- Loyalty Level Display: Shows the current loyalty level and benefits
- Cashback Section: Displays current cashback balance and rates
- Transaction History: Lists recent transactions with details
- Achievement Tracking: Shows progress towards loyalty goals

## Development Notes

- The app currently uses mock data for demonstration purposes
- Firebase integration requires setup of Firebase project and configuration files
- WooCommerce integration requires a working WooCommerce site with the appropriate API endpoints

## Testing

Run tests using:
```bash
flutter test
```

## Building for Production

```bash
flutter build apk --release  # For Android
flutter build ios --release  # For iOS
``` 