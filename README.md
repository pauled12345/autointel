# AutoIntel — AI-Powered Smart Vehicle Diagnostic and Maintenance Assistant

Mobile app that connects to a car via an ELM327 Bluetooth OBD-II adapter, reads
fault codes and live sensor data, and uses an LLM (OpenAI or Gemini) to explain
what's wrong in plain English — alongside maintenance, fuel, and repair cost tracking.

## Tech Stack
- **Mobile:** Flutter
- **Backend:** FastAPI (Python)
- **Database:** PostgreSQL
- **AI:** OpenAI API or Gemini API (provider-agnostic client)
- **Auth:** Firebase Authentication
- **Notifications:** Firebase Cloud Messaging
- **OBD-II:** ELM327 Bluetooth adapter (Classic SPP or BLE — TBD, see Phase 3)
- **Deployment:** Docker → Railway / Render

## Getting Started — Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env          # fill in DATABASE_URL, Firebase, and LLM keys
```

You'll also need a Firebase service account JSON (Firebase Console → Project
Settings → Service Accounts → Generate new private key) saved at the path
referenced by `FIREBASE_CREDENTIALS_PATH` in `.env`.

Create the database and run migrations:
```bash
createdb autointel
alembic revision --autogenerate -m "initial schema"
alembic upgrade head
```

Run the API:
```bash
uvicorn main:app --reload
```
API docs available at `http://localhost:8000/docs`.

## Getting Started — Mobile

```bash
cd mobile
flutter pub get
flutterfire configure     # links the app to your Firebase project
flutter run
```

Update the `baseUrl` in `lib/services/api_service.dart` to point at your
backend (use `10.0.2.2:8000` for the Android emulator, your machine's LAN IP
for a physical device paired to the ELM327 adapter).

### Demo mode (no hardware, no Firebase)

The app runs out of the box even before Firebase is wired up. If
`Firebase.initializeApp()` fails (no project configured), `main.dart` falls
back to an in-memory mock auth service and seeds a demo vehicle, so you can
walk the full flow — **login → home → vehicle → diagnostics** — with no
backend and no OBD scanner:

```bash
cd mobile
flutter run            # sign in with "Use demo account", tap the demo vehicle
```

For a direct, auth-free view of just the OBD + AI pipeline (the mock ELM327
init sequence, fault codes, AI explanations, live sensor data), use the
standalone demo entry point:

```bash
flutter run -t lib/main_demo.dart
```

See `mobile/README.md` for details.

## Project Structure

```
AutoIntel/
├── backend/
│   ├── api/            # (reserved for versioned API composition, e.g. api/v1)
│   ├── routes/          # FastAPI routers (auth, vehicles, diagnostics, maintenance, fuel)
│   ├── services/        # firebase auth, LLM orchestration
│   ├── ai/              # LLM provider client (OpenAI / Gemini)
│   ├── obd/              # python-obd wrapper — LOCAL DEV/TEST UTILITY ONLY (see Phase 3 note)
│   ├── database/        # SQLAlchemy engine/session setup
│   ├── models/           # SQLAlchemy ORM models
│   ├── schemas/          # Pydantic request/response schemas
│   ├── prompts/          # LLM prompt templates
│   ├── utils/            # settings/config
│   ├── alembic/          # DB migrations
│   └── main.py
│
├── mobile/
│   └── lib/
│       ├── screens/      # UI screens
│       ├── widgets/      # reusable UI components
│       ├── services/     # auth, API client, OBD Bluetooth service
│       ├── models/       # Dart data models
│       └── providers/    # state management (Provider)
│
├── docs/
│   └── architecture.md   # data flow, auth flow, schema rationale
├── database/
│   └── schema.sql        # raw SQL reference matching the SQLAlchemy models
└── README.md
```

## Roadmap & Status

### Phase 1 — Project Foundation ✅ Done
- [x] Backend skeleton (FastAPI + SQLAlchemy models + Pydantic schemas)
- [x] PostgreSQL schema (users, vehicles, diagnostic_sessions, fault_codes,
      sensor_readings, maintenance_logs, fuel_logs)
- [x] Flutter app shell with provider-based state management

### Phase 2 — Authentication ✅ Done
- [x] Firebase Auth verification middleware (`services/firebase_service.py`)
- [x] Auto-provisioning of local `users` row on first authenticated request
- [x] Flutter auth screens: Splash, Login, Register, Forgot Password
- [ ] Wire up `flutterfire configure` with your real Firebase project *(needs your Firebase console — can't be done from here)*
- [ ] End-to-end auth test: register → login → `/auth/me` returns a real profile

### Phase 3 — OBD-II Bluetooth Integration 🚧 In Progress — blocked
- [x] `backend/obd/obd_reader.py` — python-obd wrapper (DTC read, live PIDs, clear codes)
- [x] `mobile/lib/services/obd_service.dart` — BLE scan/connect stub (flutter_blue_plus)
- [ ] **Resolve architecture mismatch:** `python-obd` needs a local serial port, so it
      can't run on a deployed backend (Railway/Render). OBD reading must happen
      on-device in Flutter, then be POSTed to the API. `obd_reader.py` should be
      treated as a local dev/test utility only, not production code path.
- [ ] **Confirm adapter type** (Classic SPP vs BLE) — determines whether
      `flutter_blue_plus` (BLE) or `flutter_bluetooth_serial` (Classic) is the right package
- [ ] Implement real AT-command handshake + PID/DTC parsing in Flutter (`obd_service.dart`
      currently only opens a Bluetooth connection, no OBD protocol logic yet)
- [ ] Test ELM327 pairing + live read against an actual vehicle
- [ ] Wire parsed results into `POST /diagnostics/sessions/{id}/...` endpoints

### Phase 4 — AI Diagnostics ✅ Scaffolded, needs end-to-end testing
- [x] Provider-agnostic LLM client (`ai/llm_client.py`) — OpenAI / Gemini switch via `.env`
- [x] `services/llm_service.explain_fault_code()` — builds prompt, calls LLM, parses JSON response
- [x] Prompt template (`prompts/diagnostic_prompt.py`)
- [x] `fault_codes.ai_explanation` cached per code per session (schema supports it)
- [ ] Test full loop once Phase 3 delivers real fault codes: code in → explanation out → rendered in `diagnostics_screen.dart`
- [ ] Add retry/error handling around LLM calls (malformed JSON fallback exists; no network-failure handling yet)

### Phase 5 — Maintenance & Fuel Tracking 🚧 Backend only
- [x] `maintenance_logs` / `fuel_logs` tables + models + schemas
- [x] `routes/maintenance.py`, `routes/fuel.py` API endpoints
- [ ] Flutter screens for maintenance & fuel entry/history (not yet in `mobile/lib/screens/`)
- [ ] Cost tracking / summary views

### Phase 6 — Notifications ⬜ Not started
- [ ] FCM push setup (maintenance reminders, critical fault alerts)
- [ ] `notifications` service alongside `services/llm_service.py`
- [ ] Notification preferences in user settings

### Phase 7 — Polish & Deployment ⬜ Not started
- [ ] Tighten CORS (`main.py` currently allows `*`)
- [ ] Switch startup from `Base.metadata.create_all()` to Alembic-only migrations
- [ ] Dockerfile(s) for backend
- [ ] Deploy to Railway or Render, connect managed Postgres
- [ ] Environment-specific config (dev/staging/prod)
- [ ] App icons, splash branding, store listing assets
- [ ] Basic test coverage (auth flow, diagnostics endpoint, LLM service parsing)

## Known Issues
- `alembic/versions/` is currently empty — no migration has been generated yet.
  `main.py` falls back to `Base.metadata.create_all()` for local dev, which
  should not be relied on once you're ready to deploy.
- `obd_reader.py`'s OBD connection calls are synchronous/blocking — if ever
  called from an async route directly, they'll block the event loop. Fine for
  a local CLI/test script; needs `run_in_threadpool` if it's ever called from FastAPI.
- No error handling in `obd_reader.py` for a failed/unreachable adapter connection.

See `docs/architecture.md` for how the pieces fit together.
