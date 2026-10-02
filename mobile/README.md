# AutoIntel — Mobile (Flutter)

AI-powered vehicle diagnostics app. Connects to an ELM327 OBD-II adapter over
Bluetooth, reads fault codes and live sensor data, and explains them in plain
English.

## Quick demo (no hardware, no Firebase)

`flutter run` works out of the box. When no Firebase project is configured,
`main.dart` falls back to an in-memory mock auth service and seeds a demo
vehicle, so the whole app is demoable end to end:

```bash
cd mobile
flutter pub get
flutter run
```

Then, in the app:

1. Tap **Use demo account** on the login screen.
2. Tap the seeded **My Corolla** vehicle.
3. Watch it connect to the mock adapter, run the AT init sequence
   (`ATZ` → `ATE0` → `ATSP0`), read two stored fault codes (`P0133`, `P0301`),
   generate AI explanations with severity ratings, and stream live sensor data
   (RPM, speed, coolant temp, engine load).

Use the Bluetooth icon (top-right) to see the raw AT-command log.

### Auth-free OBD demo

For a direct view of just the OBD + AI pipeline, skipping auth entirely:

```bash
flutter run -t lib/main_demo.dart
```

## Full app (Firebase + backend)

```bash
cd mobile
flutter pub get
flutterfire configure     # links the app to your Firebase project
flutter run
```

With Firebase configured, `main.dart` uses the real `FirebaseAuthService`
instead of the mock. Update the `baseUrl` in `lib/services/api_service.dart`
to point at your backend (`10.0.2.2:8000` for the Android emulator).

## Tests

```bash
flutter test
```

The suite covers the ELM327 client (init sequence, echo stripping, timeouts),
DTC/PID decoding, the diagnostics service against the mock adapter, and the
login + diagnostics + demo-home screens end to end.
