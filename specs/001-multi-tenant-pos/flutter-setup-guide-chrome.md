# Flutter Setup Guide - Chrome Development

**Target Platform**: Web (Chrome)
**Flutter Version**: 3.38.9
**Dart Version**: 3.10.8
**Purpose**: Quick-start guide for Flutter development using Chrome only (no Android Studio)

---

## Prerequisites

✅ Flutter SDK 3.38.9 installed at `C:\Users\AFOKE\Documents\flutter`
✅ Chrome browser installed
✅ VS Code installed (recommended)
✅ Windows 10/11

---

## 1. Environment Setup

### 1.1 Add Flutter to PATH

**Why**: Access `flutter` and `dart` commands from any terminal

**Steps:**

1. Open Windows Settings → Search "Environment Variables"
2. Click "Environment Variables" button
3. Under "User variables", select "Path" → Click "Edit"
4. Click "New" and add: `C:\Users\AFOKE\Documents\flutter\bin`
5. Click "OK" on all dialogs
6. **Restart VS Code** (or any open terminals)

**Verify:**
```bash
flutter --version
dart --version
```

Expected output:
```
Flutter 3.38.9 • channel stable
Dart 3.10.8
```

### 1.2 Enable Web Support

```bash
flutter config --enable-web
```

**Verify:**
```bash
flutter devices
```

Expected output should include:
```
Chrome (web) • chrome • web-javascript • Google Chrome
```

---

## 2. VS Code Setup

### 2.1 Install Extensions

**Required:**
1. **Flutter** (Dart-Code.flutter)
2. **Dart** (Dart-Code.dart-code)

**Recommended:**
3. **Awesome Flutter Snippets** (Nash.awesome-flutter-snippets)
4. **Pubspec Assist** (jeroen-meijer.pubspec-assist)
5. **Error Lens** (usernamehw.errorlens)

**Install via command palette** (Ctrl+Shift+P):
```
ext install Dart-Code.flutter
ext install Dart-Code.dart-code
```

### 2.2 Configure VS Code Settings

Create `.vscode/settings.json` in your workspace:

```json
{
  "dart.flutterSdkPath": "C:\\Users\\AFOKE\\Documents\\flutter",
  "dart.lineLength": 100,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.formatOnType": true,
    "editor.rulers": [100],
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": "off"
  },
  "dart.openDevTools": "flutter",
  "dart.debugExternalPackageLibraries": false,
  "dart.debugSdkLibraries": false
}
```

---

## 3. Create Your First Flutter Project

### 3.1 Create POS Flutter App

Navigate to your workspace:

```bash
cd C:\Users\AFOKE\kemani
mkdir apps
cd apps
flutter create pos_flutter
```

**What this creates:**
```
pos_flutter/
├── lib/
│   └── main.dart          # Entry point
├── web/
│   ├── index.html         # Web entry
│   └── manifest.json      # PWA manifest
├── test/
│   └── widget_test.dart   # Tests
├── pubspec.yaml           # Dependencies
├── analysis_options.yaml  # Linting
└── README.md
```

### 3.2 Test the App

```bash
cd pos_flutter
flutter run -d chrome
```

**What happens:**
1. Flutter builds the app
2. Chrome opens automatically
3. You'll see the default Flutter counter app
4. Hot reload enabled (press `r` in terminal)

**Expected output:**
```
Launching lib\main.dart on Chrome in debug mode...
Waiting for connection from debug service on Chrome...
This app is linked to the debug service: ws://127.0.0.1:53963/...
Debug service listening on ws://127.0.0.1:53963/...

🔥 To hot reload changes while running, press "r" or "R".
For a more detailed help message, press "h". To quit, press "q".

An Observatory debugger and profiler on Chrome is available at: http://127.0.0.1:53963/...
The Flutter DevTools debugger and profiler on Chrome is available at: http://127.0.0.1:9100/...
```

---

## 4. VS Code Development Workflow

### 4.1 Launch Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter Web (Chrome)",
      "request": "launch",
      "type": "dart",
      "deviceId": "chrome",
      "args": [
        "--web-renderer",
        "html"
      ]
    },
    {
      "name": "Flutter Web (CanvasKit)",
      "request": "launch",
      "type": "dart",
      "deviceId": "chrome",
      "args": [
        "--web-renderer",
        "canvaskit"
      ]
    }
  ]
}
```

**Usage:**
- Press `F5` to start debugging
- Select "Flutter Web (Chrome)" or "Flutter Web (CanvasKit)"

**Renderers:**
- **HTML**: Smaller bundle, better performance, recommended for POS
- **CanvasKit**: Better fidelity, heavier bundle, use for complex graphics

### 4.2 Hot Reload

**In VS Code:**
- Save file (`Ctrl+S`) → Auto hot reload
- Or click thunderbolt icon in debug toolbar

**In Terminal:**
- Press `r` for hot reload
- Press `R` for hot restart (full app restart)
- Press `q` to quit

### 4.3 DevTools

**Access Flutter DevTools:**
1. Run app with `flutter run -d chrome`
2. Click the DevTools URL in terminal
3. Or press `Shift+Ctrl+P` → "Dart: Open DevTools"

**DevTools features:**
- **Inspector**: Widget tree, layout explorer
- **Performance**: Frame rendering, CPU profiling
- **Memory**: Memory usage, heap snapshots
- **Network**: HTTP requests
- **Logging**: Console output

---

## 5. Project Structure Best Practices

### 5.1 Recommended Folder Structure

```
pos_flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # Root app widget
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   ├── providers/
│   │   │   └── models/
│   │   ├── pos/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   ├── providers/
│   │   │   └── models/
│   │   └── admin/
│   ├── services/
│   │   ├── supabase_service.dart
│   │   ├── powersync_service.dart
│   │   └── auth_service.dart
│   ├── providers/
│   │   └── (global providers)
│   ├── models/
│   │   └── (shared models)
│   ├── widgets/
│   │   └── (shared widgets)
│   └── router/
│       └── app_router.dart
├── web/
├── test/
└── pubspec.yaml
```

### 5.2 Create Initial Structure

```bash
cd lib

# Create core folders
mkdir core core\constants core\theme core\utils

# Create feature folders
mkdir features features\auth features\pos features\admin

# Within each feature
mkdir features\auth\screens features\auth\widgets features\auth\providers features\auth\models
mkdir features\pos\screens features\pos\widgets features\pos\providers features\pos\models
mkdir features\admin\screens features\admin\widgets features\admin\providers features\admin\models

# Create service folders
mkdir services models widgets router
```

---

## 6. Install Dependencies

### 6.1 Essential Packages

Edit `pubspec.yaml`:

```yaml
name: pos_flutter
description: Multi-Tenant POS Application
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.10.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.0.0

  # Backend
  supabase_flutter: ^2.5.0
  powersync: ^1.6.0

  # Database
  sqflite: ^2.3.0
  path: ^1.8.3
  path_provider: ^2.1.0

  # Models (Code Generation)
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

  # UI
  flutter_svg: ^2.0.10
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  intl: ^0.19.0

  # Charts (for analytics)
  fl_chart: ^0.69.0

  # Utils
  uuid: ^4.3.3
  dio: ^5.4.0
  shared_preferences: ^2.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

  # Code Generation
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.11
  freezed: ^2.4.7
  json_serializable: ^6.7.1

flutter:
  uses-material-design: true
```

### 6.2 Install Packages

```bash
flutter pub get
```

**What this does:**
- Downloads all dependencies
- Resolves version conflicts
- Creates `pubspec.lock` file

### 6.3 Run Code Generation (later)

When you create models with Freezed/Riverpod:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or watch mode (auto-generate on file changes):

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## 7. Configure Environment Variables

### 7.1 Create `.env` File

**Note**: Flutter doesn't have native .env support. Use `--dart-define` or create a config file.

**Option 1: Using dart-define (Recommended for web)**

Create `env.json`:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key",
  "POWERSYNC_URL": "https://your-powersync.com"
}
```

Run with env variables:

```bash
flutter run -d chrome --dart-define-from-file=env.json
```

**Option 2: Config Dart file (Simpler for development)**

Create `lib/core/config/env.dart`:

```dart
class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  static const String powersyncUrl = String.fromEnvironment(
    'POWERSYNC_URL',
    defaultValue: 'https://your-powersync.com',
  );
}
```

Usage:

```dart
import 'package:pos_flutter/core/config/env.dart';

final supabase = Supabase.instance.client;
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
);
```

### 7.2 Git Ignore

Add to `.gitignore`:

```
# Environment
env.json
.env

# Build outputs
/build/
.dart_tool/
```

---

## 8. Setup Supabase

### 8.1 Initialize Supabase

Create `lib/core/config/supabase_config.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
```

### 8.2 Initialize in main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('POS App - Coming Soon'),
        ),
      ),
    );
  }
}
```

---

## 9. Development Commands Cheat Sheet

### Running the App

```bash
# Run in Chrome
flutter run -d chrome

# Run with HTML renderer (faster)
flutter run -d chrome --web-renderer html

# Run with CanvasKit (better graphics)
flutter run -d chrome --web-renderer canvaskit

# Run in release mode
flutter run -d chrome --release
```

### Building for Production

```bash
# Build web (production)
flutter build web

# Build with HTML renderer
flutter build web --web-renderer html

# Build with CanvasKit
flutter build web --web-renderer canvaskit

# Output: build/web/
```

### Code Generation

```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-generate)
flutter pub run build_runner watch
```

### Cleaning

```bash
# Clean build cache
flutter clean

# Re-download dependencies
flutter pub get
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Code Analysis

```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .

# Fix auto-fixable issues
dart fix --apply
```

---

## 10. Debugging in Chrome

### 10.1 Chrome DevTools

**Access:**
1. Run app: `flutter run -d chrome`
2. Open Chrome DevTools: `F12` or `Ctrl+Shift+I`
3. Navigate to **Console**, **Network**, **Performance** tabs

**Useful Chrome DevTools Features:**
- **Console**: Dart print() statements appear here
- **Network**: Monitor HTTP requests (Supabase API calls)
- **Application > Local Storage**: Check offline data
- **Application > IndexedDB**: PowerSync local database

### 10.2 Flutter DevTools

**Access:**
1. Run app
2. Click DevTools URL in terminal
3. Or in VS Code: `Ctrl+Shift+P` → "Dart: Open DevTools"

**Key Tools:**
- **Widget Inspector**: Visualize widget tree, debug layout
- **Performance**: FPS, frame rendering times
- **Memory**: Track memory leaks
- **Network**: HTTP requests with payloads
- **Logging**: Structured logging

### 10.3 Hot Reload Best Practices

**Works with Hot Reload:**
- ✅ UI changes (widgets)
- ✅ Method implementations
- ✅ Function logic
- ✅ String constants

**Requires Hot Restart:**
- ⚠️ Main() changes
- ⚠️ Global variables initialization
- ⚠️ Enum changes
- ⚠️ Class constructors

**Hot Reload Shortcuts:**
- `r` in terminal
- `Ctrl+S` in VS Code (auto hot reload)
- `Shift+F5` in VS Code (hot restart)

---

## 11. Common Issues & Fixes

### Issue 1: "flutter: command not found"

**Cause**: Flutter not in PATH

**Fix:**
1. Add `C:\Users\AFOKE\Documents\flutter\bin` to PATH (see Section 1.1)
2. Restart terminal
3. Verify: `flutter --version`

### Issue 2: "No devices found"

**Cause**: Web support not enabled

**Fix:**
```bash
flutter config --enable-web
flutter devices
```

### Issue 3: "Chrome not found"

**Cause**: Chrome not in default location

**Fix:**
```bash
# Set Chrome executable path
flutter config --chrome-executable="C:\Program Files\Google\Chrome\Application\chrome.exe"
```

### Issue 4: Hot Reload Not Working

**Cause**: Syntax errors or missing save

**Fix:**
1. Check for compilation errors in terminal
2. Save file (`Ctrl+S`)
3. Try hot restart (`Shift+F5`)

### Issue 5: "Waiting for connection from debug service..."

**Cause**: Port conflict or firewall

**Fix:**
1. Close Chrome
2. Run: `flutter clean`
3. Run: `flutter run -d chrome`
4. Check Windows Firewall settings

### Issue 6: Slow Initial Load

**Cause**: CanvasKit renderer (large download)

**Fix:**
```bash
# Use HTML renderer instead
flutter run -d chrome --web-renderer html
```

### Issue 7: "Error: Cannot run with sound null safety"

**Cause**: Package compatibility issues

**Fix:**
```bash
# Run in no-sound-null-safety mode
flutter run --no-sound-null-safety
```

Or update packages:
```bash
flutter pub upgrade
```

---

## 12. Performance Tips for Web

### 12.1 Choose the Right Renderer

**HTML Renderer:**
- ✅ Smaller bundle size (~1MB)
- ✅ Faster initial load
- ✅ Better text rendering
- ❌ Less graphic fidelity

**Recommended for**: POS app (text-heavy, fast load critical)

```bash
flutter build web --web-renderer html
```

**CanvasKit Renderer:**
- ✅ Better graphics rendering
- ✅ Native-like animations
- ❌ Larger bundle (~2-3MB)
- ❌ Slower initial load

**Recommended for**: Apps with complex graphics

### 12.2 Optimize Assets

**Images:**
- Use SVG for icons (flutter_svg package)
- Use WebP for photos
- Use cached_network_image for remote images

**Fonts:**
- Limit custom fonts
- Subset fonts if possible

### 12.3 Code Splitting

Flutter web automatically splits code by route. Enable deferred loading:

```dart
// Instead of:
import 'package:pos_flutter/features/admin/screens/analytics.dart';

// Use:
import 'package:pos_flutter/features/admin/screens/analytics.dart' deferred as analytics;

// Load when needed:
await analytics.loadLibrary();
```

### 12.4 Lazy Loading

Use `ListView.builder` instead of `ListView`:

```dart
// ✅ Good (lazy loads)
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) => ProductTile(products[index]),
)

// ❌ Bad (loads all at once)
ListView(
  children: products.map((p) => ProductTile(p)).toList(),
)
```

---

## 13. Next Steps

### Immediate (Today)

1. ✅ Verify Flutter installation: `flutter doctor`
2. ✅ Add Flutter to PATH
3. ✅ Install VS Code extensions
4. ✅ Create test project: `flutter create test_app`
5. ✅ Run test app: `flutter run -d chrome`

### Short-term (This Week)

1. [ ] Set up POS project structure
2. [ ] Install dependencies (Supabase, Riverpod, GoRouter)
3. [ ] Configure environment variables
4. [ ] Build first screen (Login)
5. [ ] Set up routing

### Medium-term (Next 2 Weeks)

1. [ ] Implement authentication flow
2. [ ] Set up Supabase integration
3. [ ] Create design system (theme, colors, typography)
4. [ ] Build core POS screens (Inventory, Sales)
5. [ ] Integrate PowerSync for offline sync

---

## 14. Learning Resources

### Official Documentation

- **Flutter Docs**: https://docs.flutter.dev
- **Dart Language Tour**: https://dart.dev/guides/language/language-tour
- **Riverpod Docs**: https://riverpod.dev
- **GoRouter**: https://pub.dev/packages/go_router
- **Supabase Flutter**: https://supabase.com/docs/guides/getting-started/tutorials/with-flutter

### Video Tutorials

- **Flutter Official YouTube**: https://www.youtube.com/c/flutterdev
- **The Flutter Way**: https://www.youtube.com/@TheFlutterWay
- **Riverpod Tutorial**: https://codewithandrea.com/articles/flutter-state-management-riverpod/

### Code Examples

- **Flutter Samples**: https://github.com/flutter/samples
- **Riverpod Examples**: https://github.com/rrousselGit/riverpod/tree/master/examples
- **Supabase Flutter Examples**: https://github.com/supabase/supabase-flutter/tree/main/example

### Community

- **Flutter Discord**: https://discord.gg/flutter
- **r/FlutterDev**: https://www.reddit.com/r/FlutterDev
- **Stack Overflow**: Tag `flutter`

---

## 15. VS Code Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| **Run app** | `F5` |
| **Stop debugging** | `Shift+F5` |
| **Hot reload** | `Ctrl+S` (auto on save) |
| **Hot restart** | `Shift+F5` (stop) then `F5` (start) |
| **Open command palette** | `Ctrl+Shift+P` |
| **Go to definition** | `F12` |
| **Find references** | `Shift+F12` |
| **Rename symbol** | `F2` |
| **Format document** | `Shift+Alt+F` |
| **Quick fix** | `Ctrl+.` |
| **Toggle sidebar** | `Ctrl+B` |
| **Open terminal** | `` Ctrl+` `` |
| **Search files** | `Ctrl+P` |
| **Search in files** | `Ctrl+Shift+F` |

---

## 16. Sample Workflow

### Day 1: Hello World

```bash
# 1. Create project
flutter create hello_pos
cd hello_pos

# 2. Run in Chrome
flutter run -d chrome

# 3. Make a change in lib/main.dart
# Change 'Flutter Demo Home Page' to 'POS System'

# 4. Save (Ctrl+S) → Hot reload happens automatically

# 5. See the change in Chrome!
```

### Day 2: Add Riverpod

```bash
# 1. Add dependency
# Edit pubspec.yaml, add flutter_riverpod: ^2.5.1

# 2. Get packages
flutter pub get

# 3. Create a simple counter provider
```

`lib/providers/counter_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final counterProvider = StateProvider<int>((ref) => 0);
```

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/counter_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS',
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('POS')),
      body: Center(
        child: Text('Count: $counter', style: TextStyle(fontSize: 24)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(counterProvider.notifier).state++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

```bash
# 4. Run
flutter run -d chrome

# 5. Click the + button → counter increments!
```

---

## 17. Troubleshooting Checklist

Before asking for help, check:

- [ ] `flutter doctor` shows no critical issues
- [ ] Flutter is in PATH (`flutter --version` works)
- [ ] Web support enabled (`flutter devices` shows Chrome)
- [ ] Latest packages (`flutter pub get`)
- [ ] No syntax errors (`flutter analyze`)
- [ ] Clean build (`flutter clean` then `flutter run`)
- [ ] Chrome is running and not blocked by firewall
- [ ] Checked terminal for error messages
- [ ] Tried hot restart (`Shift+F5`)

---

## 18. Summary

**What You Have:**
- ✅ Flutter 3.38.9 installed
- ✅ Chrome browser ready
- ✅ Web development capability

**What You Can Do:**
- ✅ Create Flutter projects
- ✅ Run apps in Chrome
- ✅ Use hot reload for rapid development
- ✅ Debug with DevTools
- ✅ Build production web apps

**What's Next:**
1. Follow migration plan (`flutter-migration-plan.md`)
2. Build first screen (Login)
3. Integrate Supabase
4. Implement offline sync
5. Gradually migrate features from Next.js

**Estimated Time to Productive:**
- Basic Flutter: 1-2 days
- Comfortable with Dart: 1 week
- First working screen: 2 weeks
- Full POS migration: 5-6 months

---

**Document Version**: 1.0
**Last Updated**: 2026-02-11
**Status**: Ready for Use
**Next Action**: Create your first Flutter project!

---

## Quick Start Commands

```bash
# Navigate to workspace
cd C:\Users\AFOKE\kemani\apps

# Create Flutter project
flutter create pos_flutter
cd pos_flutter

# Install dependencies
flutter pub get

# Run in Chrome
flutter run -d chrome
```

**You're ready to build! 🚀**
