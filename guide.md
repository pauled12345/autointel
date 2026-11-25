# AutoIntel — Project Proposal & Guide

**AI-Powered Smart Vehicle Diagnostic and Maintenance Assistant**

> A mobile app that connects to a car via an ELM327 Bluetooth OBD-II adapter,
> reads fault codes and live sensor data, and uses an LLM (OpenAI or Gemini) to
> explain what's wrong in plain English — alongside maintenance, fuel, and
> repair-cost tracking.

---

## 1. Problem Statement

Most drivers have no idea what a "check engine" light means. When it comes on,
they face three bad choices:

- **Ignore it** and risk a small issue becoming an expensive failure.
- **Pay a diagnostic fee** at a shop just to be told the code and what it means.
- **Buy a generic OBD scanner** that shows raw codes like `P0301` with no
  explanation, no history, and no follow-up.

There is no consumer tool that connects the *raw data from the car* with an
*explanation a normal person can act on* — and keeps a *long-term record* of
maintenance, fuel, and repair costs in one place.

**AutoIntel closes that gap.** It reads the car directly, translates the data
into plain English using an AI model, and keeps a running history of the
vehicle's health and running costs.

---

## 2. Solution Overview

AutoIntel is a mobile + backend system with three core jobs:

1. **Diagnose** — read fault codes and live sensor data from the vehicle over
   Bluetooth OBD-II.
2. **Explain** — use a provider-agnostic LLM to turn raw codes into
   plain-English explanations with severity and recommended actions.
3. **Track** — record maintenance and fuel logs, and surface running costs and
   reminders over time.

The design goal is that a user can go from "check engine light on" to "here's
what's wrong, what it means, and what to do about it" in a few taps — with no
technical knowledge.

---

## 3. Goals & Objectives

- Provide **plain-English diagnostics** for OBD-II fault codes.
- Read **live sensor data** (RPM, coolant temperature, etc.) in real time.
- Keep a **per-vehicle history** of faults, maintenance, and fuel.
- Work with **either OpenAI or Gemini** via a single, swappable provider client.
- Support a **fully offline demo mode** so the product can be shown without
  hardware or a Firebase project.
- Be **deployable** (Docker → Railway/Render) with a production database.

---

## 4. Target Users

- Everyday car owners who want to understand and track their vehicle.
- DIY / home mechanics who do their own maintenance.
- Fleet or multi-car households managing several vehicles.
- Workshops as a lightweight customer-facing readout (future scope).

---

## 5. Features

### 5.1 Authentication & Accounts
- Firebase Authentication (email/password).
- Server-side ID-token verification on every backend request.
- Auto-provisioning of a local `users` row on first authenticated request.
- A development bypass (`auth_disabled`) and an in-memory mock auth service so
  the app runs with **no Firebase project configured**.

### 5.2 Vehicle Garage
- Add, list, and view multiple vehicles.
- Fields: make, model, year, VIN (optional), nickname (optional).

### 5.3 OBD-II Diagnostics
- Connect to an ELM327 adapter over **Bluetooth Classic (SPP)**.
- Run the ELM327 AT init sequence (`ATZ` → `ATE0` → `ATSP0`).
- **Mode 03** — read stored diagnostic trouble codes (DTCs), parsed into
  human-readable codes.
- **Mode 01** — read live PIDs (RPM, coolant temperature, speed, and more).
- **Mode 04** — clear stored codes and the malfunction indicator lamp (MIL).
- A **mock transport** that simulates the adapter so the full pipeline runs with
  no car present.

### 5.4 AI Explanations
- Provider-agnostic LLM client (OpenAI / Gemini, switch via `.env`).
- `explain_fault_code()` builds a prompt, calls the model, and parses a
  structured JSON response (plain explanation, severity, recommended action).
- Results are **cached** on the fault-code row, so each code is explained once
  per session.

### 5.5 Maintenance Tracking
- Log maintenance events per vehicle (oil change, tire rotation, etc.).
- Fields: type, cost, odometer, notes, date.

### 5.6 Fuel Tracking
- Log fuel fills per vehicle.
- Fields: liters/gallons, cost, odometer, date.
- Foundation for cost-per-mile / fuel-economy summaries.

### 5.7 Demo Mode
- `main.dart` falls back to a mock auth service and seeds a demo vehicle when no
  backend/Firebase is available.
- `main_demo.dart` provides a standalone, auth-free view of the OBD + AI pipeline
  (init sequence, fault codes, AI explanations, live data).

---

## 6. Tech Stack

| Layer      | Technology                                             |
|------------|--------------------------------------------------------|
| Mobile     | Flutter (Dart), Provider state management              |
| Backend    | FastAPI (Python)                                       |
| Database   | PostgreSQL (SQLite for local dev)                      |
| ORM        | SQLAlchemy 2.x + Alembic migrations                    |
| AI         | OpenAI API or Google Gemini (provider-agnostic client) |
| Auth       | Firebase Authentication (Admin SDK on the backend)     |
| OBD-II     | ELM327 adapter, Bluetooth Classic (SPP)                |
| Deployment | Docker → Railway / Render                              |

---

## 7. Architecture

```
┌─────────────┐   Bluetooth   ┌────────────────┐   HTTPS   ┌──────────────┐
│  Flutter app │ ────────────► │  ELM327 adapter │           │  FastAPI API  │
│  (mobile)    │               └────────────────┘           │  (backend)    │
│              │ ────────────────────────────────────────► │               │
│              │        REST + Firebase ID token            │  ┌─────────┐  │
│              │ ◄──────────────────────────────────────── │  │ LLM     │  │
└─────────────┘                                             │  │ OpenAI/ │  │
                                                            │  │ Gemini  │  │
                                                            │  └─────────┘  │
                                                            └──────┬───────┘
                                                                   │
                                                            ┌──────▼───────┐
                                                            │  Database    │
                                                            └──────────────┘
```

### Data flow (diagnosis)
1. Flutter connects to the ELM327 adapter over Bluetooth.
2. Raw DTCs / live PIDs are read on-device and POSTed to the backend.
3. The backend stores the fault code and calls the LLM to generate an
   explanation + severity.
4. The explanation is cached on the `fault_codes` row.
5. Flutter fetches and renders the result.

### Auth flow
1. Flutter signs the user in via `firebase_auth`.
2. Every request attaches the Firebase ID token as a Bearer header.
3. FastAPI verifies the token with the Firebase Admin SDK and lazily creates a
   matching `users` row on first request.

---

## 8. Data Model

| Entity               | Purpose                                    | Key Fields                              |
|----------------------|--------------------------------------------|-----------------------------------------|
| `users`              | Account (mirrors Firebase UID)             | firebase_uid, email, display_name       |
| `vehicles`           | A user's vehicle                           | user_id, make, model, year, vin, nickname |
| `diagnostic_sessions`| One diagnostic scan session                | vehicle_id, started_at, ended_at        |
| `fault_codes`        | A code found during a session              | session_id, code, raw_description, ai_explanation, severity, status |
| `sensor_readings`    | Live PID samples (time-series)             | session_id, pid, value, unit, recorded_at |
| `maintenance_logs`   | A maintenance event                        | vehicle_id, type, cost, odometer, notes, performed_at |
| `fuel_logs`          | A fuel fill                                | vehicle_id, liters_or_gallons, cost, odometer, recorded_at |

All primary keys are **UUIDs** to avoid collision risk with offline-first mobile
writes and Firebase UIDs.

---

## 9. API Surface

| Method | Path                                        | Purpose                          |
|--------|---------------------------------------------|----------------------------------|
| GET    | `/health`                                   | Health check                     |
| POST   | `/vehicles/`                                | Create a vehicle                 |
| GET    | `/vehicles/`                                | List current user's vehicles     |
| GET    | `/vehicles/{vehicle_id}`                    | Get a vehicle                    |
| POST   | `/diagnostics/sessions`                     | Start a diagnostic session       |
| POST   | `/diagnostics/sessions/{id}/end`            | End a session                    |
| POST   | `/diagnostics/fault-codes`                  | Store a fault code + AI explain  |
| GET    | `/diagnostics/sessions/{id}/fault-codes`    | List a session's fault codes     |
| POST   | `/diagnostics/sensor-readings`              | Store a sensor reading           |
| POST   | `/maintenance/`                             | Create a maintenance log         |
| GET    | `/maintenance/vehicle/{id}`                 | List a vehicle's maintenance     |
| POST   | `/fuel/`                                    | Create a fuel log                |
| GET    | `/fuel/vehicle/{id}`                        | List a vehicle's fuel logs       |

---

## 10. Roadmap — Everything That Was to Be Included

### Phase 1 — Project Foundation ✅
- Backend skeleton (FastAPI + SQLAlchemy + Pydantic).
- PostgreSQL schema (all 7 tables).
- Flutter app shell with provider-based state management.

### Phase 2 — Authentication ✅ (partially)
- Firebase verification middleware and user auto-provisioning.
- Flutter auth screens (Splash, Login, Register, Forgot Password).
- ⏳ Real Firebase wiring (`flutterfire configure`) and end-to-end `/auth/me`
  test — **pending**.

### Phase 3 — OBD-II Bluetooth Integration 🚧
- `obd_reader.py` (backend, local/test utility only) and `obd_service.dart`
  (Flutter BLE/Bluetooth connect).
- ⏳ Real AT-command handshake + PID/DTC parsing on-device — **in progress**.
- ⏳ Test against an actual ELM327 + vehicle — **pending**.
- ⏳ Wire parsed results into the diagnostics endpoints — **pending**.

### Phase 4 — AI Diagnostics ✅ (scaffolded)
- Provider-agnostic LLM client, `explain_fault_code()`, prompt template, cached
  explanations.
- ⏳ End-to-end test (code → explanation → rendered) and retry/error handling —
  **pending**.

### Phase 5 — Maintenance & Fuel Tracking 🚧
- Tables, models, schemas, and API endpoints — **done**.
- Flutter maintenance/fuel screens — **done**.
- ⏳ Cost-tracking / summary views — **pending**.

### Phase 6 — Notifications ⬜ Not started
- FCM push (maintenance reminders, critical fault alerts).
- Notification preferences in user settings.

### Phase 7 — Polish & Deployment ⬜ Not started
- Tighten CORS (currently `*`).
- Switch from `Base.metadata.create_all()` to Alembic-only migrations.
- Dockerfile(s), deploy to Railway/Render, managed Postgres.
- Environment-specific config, app icons/splash/store assets.
- Test coverage (auth, diagnostics, LLM parsing).

---

## 11. Non-Functional Requirements

- **Security** — server-side Firebase token verification; restrict CORS before
  production.
- **Provider agnosticism** — switching LLMs must not require code changes.
- **Offline-first** — app must degrade gracefully to bundled demo data.
- **Persistence** — vehicle/maintenance/fuel/diagnostic data survives restarts.
- **Extensibility** — time-series `sensor_readings` is partition-ready; FCM is
  an additive service, not a rewrite.

---

## 12. Known Issues & Risks

- **No generated Alembic migrations** — startup uses `create_all()`, which is
  not production-safe.
- **SQLite in local dev** — fine for demo, not for deployment.
- **OBD reader is blocking** — the backend `obd_reader.py` is synchronous and
  must never be called from an async route without `run_in_threadpool`.
- **No error handling** for an unreachable adapter connection.
- **No test coverage** yet.
- **Real Firebase + real-vehicle OBD** remain untested end-to-end.

---

## 13. Future Scope

- Push notifications and maintenance reminders.
- Cost-per-mile / fuel-economy analytics and summary dashboards.
- Multi-language explanations.
- Workshop/mechanic-facing readout and customer report export.
- Sensor time-series downsampling/partitioning as data volume grows.
