# Deploying AutoIntel: Render + Neon

Stable HTTPS URL for the backend, with Neon as the Postgres database.

## 1. Neon (database)

1. Create a project at https://console.neon.tech.
2. Open **Connect** and copy the connection string. It looks like:
   `postgresql://user:password@ep-xxxx.region.aws.neon.tech/neondb?sslmode=require`
3. Keep it for step 2 — this becomes `DATABASE_URL` on Render.

Tables are created automatically on backend startup (`Base.metadata.create_all`),
so no manual migration is needed for the demo.

## 2. Render (backend)

Option A — Blueprint (recommended):
1. Push `render.yaml` (repo root) to GitHub.
2. Render Dashboard → **New** → **Blueprint** → pick the AutoIntel repo.
3. When prompted, set `DATABASE_URL` to the Neon string and `OPENAI_API_KEY`.
4. Deploy. The URL will be `https://autointel-api.onrender.com` (or similar).

Option B — Manual web service:
1. Render Dashboard → **New** → **Web Service** → connect the repo.
2. Root Directory: `backend`
3. Runtime: Python 3.12
4. Build Command: `pip install -r requirements.txt`
5. Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
6. Env vars: `DATABASE_URL`, `OPENAI_API_KEY`, `JWT_SECRET` (any long secret),
   `LLM_PROVIDER=openai`.

## 3. Point the app at Render

Build with the URL passed as a build flag (no hard-coded IP):

```powershell
cd C:\Users\paul\OneDrive\Desktop\AutoIntel\mobile
flutter build apk --dart-define=API_BASE_URL=https://autointel-api.onrender.com
adb install -r C:\autointel-build\app\outputs\flutter-apk\app-release.apk
```

Note: this project redirects Gradle output to `C:\autointel-build` (see
`mobile/android/build.gradle`) to avoid OneDrive corruption, so install the APK
from that path with `adb install` — `flutter run` may report it "couldn't find"
the APK even though the build succeeded.

## Notes

- **Free tier sleeps**: Render's free web service sleeps after ~15 min idle; the
  first request after that takes ~50s. Warm it up before a demo by opening
  `https://<service>.onrender.com/health`.
- `/health` should return `{"status":"ok"}`.
- CORS is currently `allow_origins=["*"]` — fine for the demo, tighten later.
