# AutoIntel Architecture Overview

## Data flow (fault code diagnosis)
1. Flutter app connects to ELM327 adapter over Bluetooth (`mobile/lib/services/obd_service.dart`).
2. Raw DTCs / live PIDs are sent to the backend, OR read directly on-device by
   `backend/obd/obd_reader.py` if the phone tethers to the adapter and runs a
   local bridge — either topology is supported by the same API contract.
3. Backend stores the raw fault code in `fault_codes` and calls
   `services/llm_service.explain_fault_code()`, which builds a prompt
   (`prompts/diagnostic_prompt.py`) and calls whichever provider is configured
   in `.env` (`ai/llm_client.py`).
4. The LLM's structured JSON response (plain-English explanation, severity,
   recommended action) is cached directly on the `fault_codes` row so it's
   only generated once per code per session.
5. Flutter fetches `/diagnostics/sessions/{id}/fault-codes` and renders it.

## Auth flow
- Flutter signs the user in via `firebase_auth`.
- Every backend request attaches the Firebase ID token as a Bearer header
  (`mobile/lib/services/api_service.dart`).
- FastAPI verifies the token server-side using the Firebase Admin SDK
  (`backend/services/firebase_service.py`) and lazily creates a matching
  `users` row on first request.

## Why UUID primary keys
Firebase UIDs and offline-first mobile writes don't play well with
auto-incrementing integer keys (collision risk when the app creates local
records before syncing). UUIDs sidestep that entirely.

## Extension points for later phases
- `sensor_readings` is a time-series table — plan to partition or downsample
  once volume grows past a few thousand rows per vehicle.
- `ai/llm_client.py` is provider-agnostic by design — switching
  `LLM_PROVIDER` in `.env` from `openai` to `gemini` requires no route changes.
- FCM push (maintenance reminders, critical fault alerts) isn't wired yet —
  add a `notifications` service alongside `services/llm_service.py` once
  Phase 5 starts.
