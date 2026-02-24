# Healthcare Medic Interface

Flutter-based healthcare provider/medic interface for managing consultations and patients.

## Features

- Patient management
- Consultation scheduling
- Session notes
- Appointment tracking
- Provider profile management
- Real-time updates
- Cross-platform (Web, mobile, desktop)

## Tech Stack

- Flutter 3.0+
- Supabase Flutter SDK
- Provider (state management)
- Material Design 3

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK
- Supabase account

### Installation

```bash
# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on mobile
flutter run

# Run with environment variables
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-key
```

### Environment Setup

You can configure Supabase credentials in two ways:

**Option 1: Command-line arguments**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

**Option 2: Edit lib/main.dart**
Replace the default values in the `Supabase.initialize()` call.

## Project Structure

```
lib/
├── main.dart                       # App entry point
├── screens/
│   ├── consultations_screen.dart   # Consultations list
│   ├── login_screen.dart           # Authentication
│   ├── patients_screen.dart        # Patient management (TBD)
│   ├── schedule_screen.dart        # Schedule view (TBD)
│   └── profile_screen.dart         # Provider profile (TBD)
├── widgets/                        # Reusable widgets
├── services/
│   └── supabase_service.dart       # Supabase integration
├── models/                         # Data models
└── utils/                          # Utilities
```

## Database Tables

This app connects to the following Supabase tables:

- `healthcare_providers` - Medical professional profiles
- `patients` - Patient records
- `consultations` - Consultation sessions
- `consultation_notes` - Session notes
- `appointments` - Scheduled appointments

## Authentication

The app uses Supabase Auth with email/password authentication. Healthcare providers must have:
1. A user account in Supabase
2. An entry in the `healthcare_providers` table

## Building for Production

### Web
```bash
flutter build web --release
```
Deploy the `build/web/` directory to any static hosting service.

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

## Development

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

## Roadmap

- [ ] Complete patients screen implementation
- [ ] Complete schedule screen implementation
- [ ] Complete profile screen implementation
- [ ] Add consultation notes editor
- [ ] Add appointment booking
- [ ] Add real-time notifications
- [ ] Add video consultation support
- [ ] Add prescription management
- [ ] Add patient health records
- [ ] Add analytics and reporting

## Privacy & Security

This application handles sensitive health information. Ensure:
- All communication uses HTTPS
- Data is encrypted in transit and at rest
- Row-Level Security (RLS) policies are properly configured
- Comply with HIPAA and local healthcare privacy regulations
- Regular security audits

## License

[Add your license here]
