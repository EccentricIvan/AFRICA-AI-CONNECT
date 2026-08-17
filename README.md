# AI Connect Africa

An offline-first, AI-powered digital empowerment app for women in
Sub-Saharan Africa, built with Flutter. Runs on Android, Windows, and Web.

## Pillars
- **Learn** — courses, digital skills, financial literacy
- **Earn** — marketplace, financial hub, business tools
- **Grow** — mentorship, jobs, skills training
- **Thrive** — health, community, wellbeing

## Getting started

```
flutter pub get
flutter run -d windows   # or: -d android, -d chrome
```

To build a release APK:

```
flutter build apk --release --split-per-abi
```

## Vercel backend deployment

The lightweight FastAPI entrypoint in `api/index.py` is deployed independently
from the APK by `.github/workflows/build-android-apk.yml`. Configure these
GitHub repository secrets before running the workflow:

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

Configure `GROQ_API_KEY` (and optionally `GROQ_MODEL`) in the Vercel project's
Production environment. The APK defaults to the stable production backend at
`https://otic-connect-api.vercel.app`; the GitHub repository variable
`AI_BACKEND_URL` can override it without a trailing slash.

For all six local languages, the hosted chat path translates the conversation
to English with Sunbird, reasons with Groq, and translates the answer back with
Sunbird. Configure `SUNBIRD_API_TOKEN` in Vercel; `AUTH_TOKEN` remains accepted
for compatibility with the existing deployment.

The APK uses Vercel only when `AI_BACKEND_URL` is present at build time. If
Vercel fails, it falls back to the existing direct Groq client. With no device
network, chat uses the bundled offline knowledge base. Backend deployment and
APK compilation are separate jobs, so a Vercel failure cannot prevent the APK
artifact from being produced.

See [CLAUDE.md](CLAUDE.md) for architecture, the design system, and
navigation structure.
