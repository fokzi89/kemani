# POS Admin Dashboard

Flutter-based point-of-sale administration dashboard for managing products, inventory, sales, and analytics.

## Features

- Product management
- Inventory tracking
- Sales processing
- Analytics dashboard
- Multi-tenant support
- Offline-first capability (planned)
- Cross-platform (Web, Windows, Android, iOS)

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

# Run on Windows
flutter run -d windows

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
├── main.dart                   # App entry point
├── screens/
│   ├── dashboard_screen.dart   # Main dashboard
│   ├── login_screen.dart       # Authentication
│   ├── products_screen.dart    # Product management (TBD)
│   ├── inventory_screen.dart   # Inventory tracking (TBD)
│   ├── sales_screen.dart       # Sales processing (TBD)
│   └── analytics_screen.dart   # Analytics (TBD)
├── widgets/                    # Reusable widgets
├── services/
│   └── supabase_service.dart   # Supabase integration
├── models/                     # Data models
└── utils/                      # Utilities
```

## Database Tables

This app connects to the following Supabase tables:

- `tenants` - Business/tenant information
- `users` - User accounts with tenant association
- `products` - Products with tenant isolation
- `inventory` - Stock management
- `sales` - Transaction records
- `receipts` - Sale receipts
- `staff` - Staff members per tenant

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

## Authentication

The app uses Supabase Auth with email/password authentication. Users must have an account in the Supabase users table with appropriate tenant association.

## Multi-Tenant Support

All data operations are scoped to the authenticated user's tenant via Supabase Row-Level Security (RLS) policies.

## Roadmap

- [ ] Complete products screen implementation
- [ ] Complete inventory screen implementation
- [ ] Complete sales screen implementation
- [ ] Complete analytics screen implementation
- [ ] Implement offline-first with local database
- [ ] Add barcode scanning support
- [ ] Add receipt printing
- [ ] Add real-time sync indicators
- [ ] Add bulk import/export
- [ ] Add advanced filtering and search

## License

[Add your license here]
