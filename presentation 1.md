# AutoIntel — Technical Review (Today)

**AI-Powered Smart Vehicle Diagnostic & Maintenance Assistant**

---

## 1. Title + One-liner

AutoIntel: turns the "check engine" light into a plain-English answer and keeps the
car's maintenance/fuel history in the owner's pocket.

---

## 2. The Problem (what a review panel should hear first)

A check-engine light gives three bad options today:

- **Ignore it** — it won't go away.
- **Pay a shop** just to read the code and tell you what it means.
- **Cheap scanners** that show `P0301` and nothing else.

None of them answer the real question: *what's actually wrong, and what do I do about it?*

---

## 3. What AutoIntel Is

One app, three jobs:

1. **Diagnose** — read fault codes and live sensor data over Bluetooth OBD-II.
2. **Explain** — the AI turns a code like `P0301` into "cylinder 1 is misfiring — here's
   what that means and here's what to do next" (severity + actionable advice).
3. **Track** — maintenance and fuel logs, so the car's history lives in your pocket.

From *light on* to *here's the problem and the fix* in a few taps.

---

## 4. Architecture (verified today)

| Layer      | Tech                                                                 |
|------------|----------------------------------------------------------------------|
| Mobile     | Flutter (Dart) — screens: dashboard, diagnostics, garage, maintenance, fuel, login, chat, notifications, profile, shell |
| Backend    | FastAPI (Python), `backend/main.py`, routers: auth, vehicles, diagnostics, maintenance, fuel, chat |
| Database   | SQLAlchemy/SQLite locally (`backend/autointel.db`, `database/schema.sql`); PostgreSQL noted as the production target |
| AI         | Provider-agnostic — OpenAI **or** Gemini, swappable via config (`ai/llm_client.py`, `services/llm_service.explain_fault_code`) |
| Auth       | Firebase (mock auth in demo mode today)                              |
| OBD-II     | ELM327 adapter over Bluetooth Classic (SPP) (`services/obd/bluetooth_classic_transport.dart`, `backend/obd/obd_reader.py`) |

Key endpoints: `POST/GET /vehicles`, `/diagnostics` (sessions, fault codes, sensor
readings), plus auth/fuel/maintenance/chat routers — all under `backend/routes/`.

Checks I ran before today: backend `compileall` passed, `import main` OK, git shows the
usual in-progress state (recent commit: "Connect mobile app to backend, add full UI and
OBD diagnostics").

---

## 5. Live Demo Walkthrough (approx. 6 min)

1. Start the backend (terminal in `backend/`):
   `venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 8000` — leave running.
2. Open the app, tap **Use demo account** → Dashboard (Garage lists the added vehicles).
3. Diagnostic screen — connect the (mock) adapter, run a scan → fault codes appear.
4. **Watch this:** raw code becomes plain English with severity + recommended action.
5. **Live data:** RPM, coolant temperature streaming from the car.
6. **Maintenance & fuel tabs:** the "system" part — spend and service history.

---

## 6. Working vs. In Progress

**Working today**
- Full backend API (vehicles, diagnostics, maintenance, fuel).
- Complete Flutter UI — every screen wired up.
- OBD protocol layer (read codes, live data).
- AI explanation pipeline (provider-agnostic).
- Demo mode — runs with no car and no Firebase.

**In progress**
- Real Firebase login (demo uses mock auth).
- Production database migrations.
- Live testing against an actual vehicle.

We demo with a simulated adapter today, but the pipeline — code in, explanation out — is real.

---

## 7. Next Steps (after this review)

- Validate against a real vehicle.
- Finish production deployment.
- Push notifications for maintenance reminders.

**Questions welcome.**
