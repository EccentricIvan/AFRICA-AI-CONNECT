# AI Connect Africa

> **Current project status (26 October 2026):** source version 1.4.0+5,
> database schema 37. This document contains historical descriptions that may
> predate school sync, roles, current models, and optional connected services.
> Start with [the current status and rollout checklist](docs/PROJECT_STATUS.md).


**Offline AI-Powered Learning Operating System**

[![Release](https://img.shields.io/badge/release-v1.1.0-4F46E5)](https://github.com/EccentricIvan/AI-CONNECT-AFRICA/releases/latest)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows-informational)](#downloads)
[![Offline](https://img.shields.io/badge/network-100%25%20offline-10B981)](#core-constraint-offline-first)
[![Built with Flutter](https://img.shields.io/badge/built%20with-Flutter-02569B)](https://flutter.dev)

> **Maintainers / new team:** start with **[HANDOVER.md](HANDOVER.md)** — it lists everything needed to build, change, release, and maintain the app, including the signing keystore and AI model that are not in the repo.

AI Connect Africa is a fully offline AI tutor and learning platform for students in schools with no reliable internet. Every feature — AI responses, curriculum generation, exercises, certificates, badges, even a website builder — runs entirely on-device. **No internet, no cloud, no external APIs, no accounts. Ever.**

The AI model (Gemma 3 1B) is bundled and runs locally: LiteRT-LM on Android, llama.cpp on desktop. Updates ship by USB drive or local school LAN, never the internet.

---

## Downloads

Get the latest build from the [**Releases page**](https://github.com/EccentricIvan/AI-CONNECT-AFRICA/releases/latest).

### Android — one APK with everything (recommended)

Build and publish the **with-models** APK so schools get a single download:

```powershell
# 1. Put models here (gitignored):
#    dist\models\chat-model.litertlm
#    dist\models\translate-afrislm.gguf

.\tools\build_release_with_models.ps1 -Version 1.2.0
.\tools\publish_release.ps1 -Version 1.2.0 -WithModels
```

After publish, the direct link is:

`https://github.com/<owner>/<repo>/releases/download/v1.2.0/AI%20Connect%20Africa%20v1.2.0-with-models.apk`

(`publish_release.ps1` prints the exact URL for your repo.)

Install that APK → first launch unpacks the bundled chat + translation models → app works offline. No separate USB model step.

Rolling CI builds on `latest-build` stay **slim** by default. To publish a fat rolling APK, run the **Build Release Artifacts** workflow with **bundle_models** after uploading a one-time [`model-pack`](https://github.com/EccentricIvan/AI-CONNECT-AFRICA/releases) release that contains `chat-model.litertlm` and `translate-afrislm.gguf`. Then use:

[**Download Android APK (with models)**](https://github.com/EccentricIvan/AI-CONNECT-AFRICA/releases/download/latest-build/ai-connect-africa-latest-with-models.apk)

| Download | Platform | How to install |
|---|---|---|
| `AI Connect Africa vX.Y.Z-with-models.apk` | **Android** (4 GB+ RAM) | Install APK; first launch unpacks models (~1 GB free space) |
| `AI Connect Africa vX.Y.Z.apk` | Android (slim) | Install APK, then **Install from file…** for models |
| `AI Connect Africa Windows vX.Y.Z.zip` | **Windows** (8 GB RAM) | Extract; `models/` next to the exe is used automatically |

Both can also be shared offline by USB, Bluetooth, or a local server. Release APKs built with `tools\build_release_with_models.ps1` are signed with the official certificate (`CN=AI Connect Africa, OU=Engineering, O=AI Connect Africa, L=Kampala, ST=Central, C=UG`); Android rejects updates not signed with the same key.

> **Rolling CI builds are debug-signed.** The workflow has no keystore, so `build.gradle.kts` falls back to the debug key. APKs from the `latest-build` release therefore cannot be upgraded in place to an official release — uninstall first, or hand out only the artifacts built locally by the release script.

---

## Features

| Area | What it does |
|---|---|
| **Learn** | Type `Ask Otic anything...`; the AI mentors through Answer → Clarify → Practice → Apply → Create → Reflect |
| **Practice** | AI-generated multiple-choice exercises with feedback and scoring |
| **Apply** | Real-world scenario challenges with open-ended AI evaluation |
| **Create** | Build projects (essay, business plan, experiment, story, code plan) guided step by step |
| **Teach** | Explain a topic back to OTIC and get a mastery score |
| **Website Builder** 🆕 | Drag-and-drop page builder; AI writes block content; exports a standalone offline `.html` file |
| **Learning Paths** | AI generates a multi-unit curriculum for any topic, with lesson tracking |
| **Certificates** | Offline PDF certificates on path completion |
| **Achievements** | Badges, points, and streaks earned automatically |
| **Projects** | Per-student tracker for saved Create-mode work and websites |
| **Teacher dashboard** | Per-student progress, mastery, and session history |
| **Admin** | Device info, model status, student profile management |
| **Collaboration** | Discover classmates on the same LAN — no server, no internet |
| **Emotional safety** | Detects frustration/distress offline; crisis messages bypass the model with a supportive response |
| **Offline updates** | New versions install from USB or school LAN via the update bundle tool |

> **Not included:** Voice learning (STT/TTS) was intentionally dropped from scope. A standalone simulation engine was not built as a separate module — domain scenarios are delivered through Apply mode.

---

## Core Constraint: Offline-First

| What is NOT used | What IS used |
|---|---|
| OpenAI / Anthropic / any hosted LLM | Qwen3-0.6B running on-device |
| Firebase / Supabase / cloud sync | SQLite via Drift (local, per device) |
| `google_fonts` (fetches over network) | Font files bundled in the APK |
| Cloud certificate services | `pdf` package — generated locally |
| Internet-based updates | USB flash drive or local school server |

---

## AI Inference

| Role | Platform | Runtime | Model | Size |
|---|---|---|---|---|
| Chat/tutor | Android, Windows, Linux (4 GB+ RAM) | LiteRT-LM (Google, GPU/NPU) via `flutter_gemma`/`flutter_gemma_litertlm` | Qwen3-0.6B `.litertlm` | ~330–590 MB |
| Translation | Android, Windows, Linux | llama.cpp in-process (`llm_llamacpp`) | TranslatePsy-AfriSLM 0.8B `.gguf` | ~0.5–1 GB |

All engines implement the same `InferenceEngine` interface ([lib/ai_core/inference/](lib/ai_core/inference/)). The app detects each model at startup; when absent it falls back to a `MockEngine` so every screen still works for demonstration, and translation degrades to English-only chat.

---

## Technology Stack

- **Flutter 3.44+ / Dart** — single codebase for Android and Desktop
- **flutter_gemma + flutter_gemma_litertlm** — LiteRT-LM on-device chat inference (Qwen3-0.6B), one engine for Android/Windows/Linux
- **Drift 2.20 + drift_flutter** — SQLite ORM for student data
- **flutter_riverpod** — state management
- **go_router** — navigation with async onboarding redirect
- **file_picker 8.3.7** — model install + HTML export file dialogs
- **pdf** — offline certificate generation

---

## Project Structure

```
lib/
  ai_core/
    inference/        InferenceEngine + LiteRT-LM, Ollama, Mock engines
    translate/        AfriSlmModelManager, TranslationPipeline, supported languages
    model/            ModelManager: detect, validate, install chat model file
    tutor/            TutorPipeline (Answer→Clarify→Practice→Apply→Create→Reflect)
    providers/        Riverpod engine, chat, and model-status providers
  db/
    tables/           Drift tables (7 — see Database Schema)
    daos/             Student, Session, Path, Badge, Project, Website DAOs
    providers/        dbProvider, activeStudentProvider, feature providers
  features/
    home/ learn/ practice/ create/ teach/        learning surfaces
    website/          Website Builder (block model, HTML gen, canvas)  🆕
    projects/ achievements/ certificates/         student output
    teacher/ admin/ collaborate/ settings/        roles & ops
    llama/            Standalone Llama 3.2 GGUF test screen
    onboarding/ model_setup/                       first-run flows
  gamification/       Badge definitions + award service
  certificates/       Offline PDF certificate generator
  collaboration/      LAN peer discovery
  safety/             Emotional safety engine
  core/               Theme + router
  shared/widgets/     AppShell, responsive helpers, common cards
tools/
  make_update_package.ps1   Builds the USB/LAN offline update bundle
test/                 Widget, emotional-safety, and website-builder tests
docs/                 Architecture, engineering log, release process
```

---

## Database Schema

Single SQLite file per device (`otic_student_db`), never synced. Current `schemaVersion`: **4**.

| Table | Purpose | Added |
|---|---|---|
| `students` | Profile: name, age, interests, style, strengths, streaks, points | v1 |
| `session_summaries` | Compressed 2–3 sentence summaries per topic (never full logs) | v1 |
| `topic_progress` | Mastery level (0–100) per student per topic | v1 |
| `learning_paths` | AI-generated curriculum + lesson completion state | v2 |
| `earned_badges` | Badges a student has earned | v3 |
| `student_projects` | Saved Create-mode projects | v3 |
| `website_projects` | Saved drag-and-drop websites (blocks as JSON) | v4 |

Schema upgrades are handled by an additive migration in [lib/db/otic_database.dart](lib/db/otic_database.dart) — existing student data survives every app update.

---

## Development

```powershell
flutter pub get                                   # dependencies
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift code after table changes
flutter run -d windows                            # run desktop
flutter run -d android                            # run on device
flutter analyze                                   # lint
flutter test                                      # tests
flutter build apk --release                       # signed Android build
flutter build windows --release                   # desktop build
```

Toolchain specifics (paths, signing, build quirks, disk-space notes) are documented in [docs/ENGINEERING_LOG.md](docs/ENGINEERING_LOG.md). Release build + publish steps are in [docs/RELEASING.md](docs/RELEASING.md).

---

## Documentation

| Doc | Contents |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design, the tutor pipeline, the offline AI layer, data flow |
| [docs/ENGINEERING_LOG.md](docs/ENGINEERING_LOG.md) | Decisions made and obstacles overcome, with where each change landed |
| [docs/RELEASING.md](docs/RELEASING.md) | How to build, sign, and publish a release; offline update bundles |
| [CHANGELOG.md](CHANGELOG.md) | Versioned history of what shipped and when |

---

## Roadmap (next ideas)

- Real image embedding in the Website Builder (currently styled placeholders)
- Multi-page websites with internal links
- Teacher-assigned learning paths and group quizzes
- Peer-to-peer content sync over LAN (inspired by Kolibri's model)

---

## Design Principles

- **Ground answers, don't invent** — Otic builds on what the student already knows from prior sessions.
- **Never store audio or full logs** — only compressed text summaries persist.
- **Fail visibly** — a missing, corrupt, or truncated model shows a clear actionable screen, never a silent crash.
- **Offline is non-negotiable** — every dependency is verified to work with zero connectivity before it ships.
