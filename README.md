# lazychef

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Use Genymotion Emulator

```
flutter run --dart-define=API_URL=http://10.0.3.2:3000/api
```

## Connecting a Physical Device to Local Backend

If you are testing the app on a physical Android device and running the Node.js backend locally on your computer, your phone will not be able to reach your computer using `localhost` or `10.0.2.2`.

The easiest way to fix this is by using **ADB Reverse Port Forwarding**:

1. Make sure your Android phone is connected to your computer (via USB or Wi-Fi debugging).
2. Run this command to forward your phone's port 3000 directly to your computer's port 3000:
   ```bash
   adb reverse tcp:3000 tcp:3000
   ```
3. Start the Flutter app and override the API URL so it points to localhost:
   ```bash
   flutter run --dart-define=API_URL=http://127.0.0.1:3000/api
   ```

*(Note: You will need to re-run the `adb reverse` command if you disconnect and reconnect your phone).*

**Using the Emulator:**
When you switch back to using the Android Emulator, you can just run `flutter run` normally. The app will automatically default to `http://10.0.2.2:3000/api` which points to your computer.
