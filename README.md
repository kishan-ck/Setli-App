# Setli-App

Cross-platform mobile application for **Setli** built with Capacitor, iOS (Swift), and Android.

---

## 🚀 Environment Setup & Automatic Sync

Whenever you run `npm run local`, `npm run dev`, or `npm run prod`, the active environment is **automatically synced everywhere across all layers in one command**:
- Updates **`server.url`** in `capacitor.config.json`
- Updates Android **`applicationIdSuffix`**, **`versionNameSuffix`**, and **`app_name`** via [`android/app/environment.gradle`](./android/app/environment.gradle) & [`strings.xml`](./android/app/src/main/res/values/strings.xml)
- Updates iOS **`PRODUCT_BUNDLE_IDENTIFIER`** and **`CFBundleDisplayName`** via [`ios/debug.xcconfig`](./ios/debug.xcconfig) & [`ios/release.xcconfig`](./ios/release.xcconfig)
- Updates Google Services / Firebase client identifiers for Android
- Automatically triggers **`npx cap sync`**

### Environments

| Environment | Command | Server URL | Android Package ID | iOS Bundle ID | App Display Name |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Local** | `npm run local` | `https://pants-unshaken-stony.ngrok-free.dev/login` | `com.setli.app.local` | `com.setli.app.local` | Setli LOCAL |
| **Development** | `npm run dev` | `https://dev.setli.com.au/login` | `com.setli.app.dev` | `com.setli.app.dev` | Setli DEV |
| **Production** | `npm run prod` | `https://setli.com.au/login` | `com.setli.app` | `com.setli.app` | Setli |

---

## 💻 Simple Command Cheatsheet

### 1. Switch Environment (Syncs All Native Projects Automatically)
```bash
npm run local    # Switch to Local & sync everywhere
npm run dev      # Switch to Development & sync everywhere
npm run prod     # Switch to Production & sync everywhere
```

### 2. Run Directly from CLI / Terminal
```bash
npm run android         # Builds & runs active environment on Android device/emulator
npm run ios             # Builds & runs active environment on iOS device/simulator
```

### 3. Open in IDEs
```bash
npm run open:android    # Open in Android Studio (standard 'debug' / 'release' automatically use active env!)
npm run open:ios        # Open in Xcode (standard Run automatically uses active env!)
```

### 4. Manual Sync
```bash
npm run sync            # Sync both Android & iOS
npm run sync:android    # Sync Android only
npm run sync:ios        # Sync iOS only
```

---

## 📦 How Dynamic Native Syncing Works

### Android
- [`android/app/environment.gradle`](./android/app/environment.gradle) is dynamically updated when switching environments.
- [`android/app/build.gradle`](./android/app/build.gradle) applies `environment.gradle` directly into `defaultConfig`.
- [`strings.xml`](./android/app/src/main/res/values/strings.xml) is automatically updated with the matching display title.
- In **Android Studio**, there are no conflicting multi-flavor build variants: the standard **`debug`** and **`release`** builds will automatically and immediately run with the active environment's Application ID and App Name.

### iOS
- [`ios/debug.xcconfig`](./ios/debug.xcconfig) and [`ios/release.xcconfig`](./ios/release.xcconfig) include the active `env-*.xcconfig`.
- Sets `SETLI_BUNDLE_ID_SUFFIX` and `SETLI_DISPLAY_NAME` dynamically.
- In **Xcode**, hitting **Run** automatically builds with the active environment's Bundle ID and Display Name.

---

## 📱 Features & Native Modules

- **File Downloads & QR Codes**:
  - Saved to `Documents/Setli` directory (accessible via iOS **Files** app under *On My iPhone > Setli* and Android *Downloads/Setli*).
  - Images and QR codes are simultaneously saved to the system **Photos** gallery.
  - Success and error alerts are presented via a bottom **Snackbar**.