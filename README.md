# Setli-App

Cross-platform mobile application for **Setli** built with Capacitor, iOS (Swift), and Android.

---

## 🚀 Environment Setup & Switching

All environments are managed directly inside the single main **[`capacitor.config.json`](file:///Users/macbook/Workspace/Setli-App/capacitor.config.json)** file. Switching environments automatically updates the active URL in `capacitor.config.json` and syncs native configuration files across both **Android** and **iOS**.

### Environments & URLs

| Environment | Command | Active Server URL |
| :--- | :--- | :--- |
| **Local** | `npm run local` | `https://pants-unshaken-stony.ngrok-free.dev/login` |
| **Development** | `npm run dev` | `https://dev.setli.com.au/login` |
| **Production** | `npm run prod` | `https://setli.com.au/login` |

---

## 💻 Simple Command Cheatsheet

### 1. Environment Switching & Sync
```bash
npm run dev      # Switch to Development & sync all platforms
npm run local    # Switch to Local & sync all platforms
npm run prod     # Switch to Production & sync all platforms
```

### 2. Syncing Native Projects
```bash
npm run sync            # Sync both Android & iOS
npm run sync android    # Sync Android only
npm run sync ios        # Sync iOS only
```

### 3. Open Projects in IDE (Xcode / Android Studio)
```bash
npm run open android    # Open Android project in Android Studio
npm run open ios        # Open iOS project in Xcode
```

### 4. Run on Device / Emulator / Simulator
```bash
npm run android         # Run Android app (or: npm run run android)
npm run ios             # Run iOS app (or: npm run run ios)
```

---

## 📱 Platform Specifics

- **iOS Project**: `ios/App/`
- **Android Project**: `android/`
- **Downloaded Files & QR Codes**:
  - Saved to the app's `Documents/Setli` directory (visible in the Apple **Files** app under *On My iPhone > Setli* and Android *Downloads / Setli*).
  - Images and QR codes are also saved to the system **Photos** library.
  - Notifications are shown via a sleek bottom snackbar.