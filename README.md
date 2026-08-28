# Africa AI Connect

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

## AI Chat

AI Chat is fully offline — there is no LLM/SLM call and no backend
dependency. Replies come from a local knowledge base: a small curated set
of question/answer intents, backstopped by a ~25k-sentence lookup drawn
from Sunbird AI's SALT dataset for Luganda, Acholi, Ateso, and Runyankole.
See [CLAUDE.md](CLAUDE.md) for how the matching works.

`api/index.py` and `AI_BACKEND/` still exist in this repo as an earlier,
unintegrated experiment with a hosted Groq-backed chat API — nothing in the
Flutter app calls them.

See [CLAUDE.md](CLAUDE.md) for architecture, the design system, and
navigation structure.
