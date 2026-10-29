# Architecture

> Historical architecture notes. For the current runtimes, school sync, optional services, and schema, see [PROJECT_STATUS.md](PROJECT_STATUS.md).

This document describes how AI Connect Africa is put together: the offline AI layer,
the tutor pipeline, data storage, and how a student request flows through the app.

> **Guiding constraint:** everything must work with zero network connectivity.
> No dependency, API, or feature is added without verifying it runs fully offline.

---

## 1. High-level shape

AI Connect Africa is a single Flutter codebase targeting Android and Windows/Linux
desktop. It is layered:

```
┌──────────────────────────────────────────────────────────┐
│  UI (features/*)  — Learn, Practice, Create, Website, …   │
├──────────────────────────────────────────────────────────┤
│  State (Riverpod providers)                               │
├──────────────────────────────────────────────────────────┤
│  Domain services                                          │
│   • TutorPipeline        • PathGenerator                  │
│   • EmotionalSafety      • BadgeService                   │
│   • HTML generator       • CertificateGenerator           │
├──────────────────────────────────────────────────────────┤
│  AI core (InferenceEngine)        Storage (Drift/SQLite)  │
│   • LiteRT-LM chat (all platforms) • 7 tables, 1 file      │
│   • Ollama/llama.cpp translation   • per-device, no sync   │
│   • MockEngine (fallback)                                 │
└──────────────────────────────────────────────────────────┘
```

No layer reaches the network. The only "external" inputs are the local model
file and update bundles transferred by USB or LAN.

---

## 2. The AI core

Defined in [lib/ai_core/](../lib/ai_core/).

### InferenceEngine

A single interface ([inference/inference_engine.dart](../lib/ai_core/inference/inference_engine.dart))
that all UI talks to:

```dart
abstract class InferenceEngine {
  Future<void> loadModel(String path);
  Future<String> generate({required String prompt, int maxTokens,
                           double temperature, void Function(String)? onToken});
  void dispose();
}
```

Implementations:

| Engine | Role | Platform | Backing |
|---|---|---|---|
| `LiteRtLmEngineImpl` | Chat/tutor | Android, Windows, Linux | `flutter_gemma`/`flutter_gemma_litertlm` → Google LiteRT-LM, GPU/NPU. Runs Qwen3-0.6B from one `.litertlm` file, identical on every platform. |
| `OllamaEngine` | Translation | Windows, Linux | Local Ollama server, pointed at a specific model tag (`OllamaEngine.modelTag`) — currently the AfriSLM translation model, registered locally via `OllamaModelInstaller` (`ollama create` from a USB-distributed GGUF, never `ollama pull`ed). |
| *(planned)* | Translation | Android | llama.cpp binding loading the AfriSLM GGUF directly — not yet implemented. |
| `MockEngine` | Fallback | any | deterministic canned responses for dev / no-model / no-Ollama |

`TranslationPipeline` ([translate/translation_pipeline.dart](../lib/ai_core/translate/translation_pipeline.dart))
wraps whichever translation engine resolved and exposes `toEnglish`/`fromEnglish`,
called from `ChatNotifier.send()` around the tutor pipeline so the student can
write in any of 19 supported African languages while the tutor itself always
reasons in English.

### Model lifecycle

`ModelManager` ([model/model_manager.dart](../lib/ai_core/model/model_manager.dart))
checks for the model file at startup and validates it (minimum size guard rejects
truncated transfers). The result drives the providers in
[providers/ai_provider.dart](../lib/ai_core/providers/ai_provider.dart):

```
modelInfoProvider → engineLoadedProvider → tutorPipelineProvider
        │                    │
   model present?       picks platform engine, else MockEngine
```

If no valid model exists, the UI routes to the **Model Not Installed** screen,
which offers **Install from file…** (validate → copy with progress → activate).

---

## 3. The tutor pipeline

`TutorPipeline` ([ai_core/tutor/tutor_pipeline.dart](../lib/ai_core/tutor/tutor_pipeline.dart))
enforces the behavior contract — OTIC is a mentor, not a search engine. Every
response advances through six stages, each with its own temperature:

```
Answer (0.5) → Clarify (0.6) → Practice (0.7) → Apply (0.8) → Create (0.9) → Reflect (0.6)
                                    ▲                                            │
                                    └────────────── loops back ─────────────────┘
```

Changing topic resets to Answer. The pipeline returns a `TutorResponse`
(text, stage, topic, follow-up prompt) that the chat layer renders and persists
as a compressed session summary.

---

## 4. Request flow (Learn mode example)

```
Student types a message (any of 19 supported languages, or English)
      │
      ▼
ChatNotifier.send()                       lib/ai_core/providers/ai_provider.dart
      │
      ├─► TranslationPipeline.toEnglish()  if student.language != 'en'
      │     • best-effort — falls back to the original text on failure
      │
      ▼
EmotionalSafetyEngine.check()             lib/safety/emotional_safety.dart
      │     • crisis  → bypass model, return support message, stop
      │     • distress/frustration → attach a tutor note, continue
      │
      ▼
TutorPipeline.respond(onToken: …)         streams tokens to the UI (English)
      │
      ▼
InferenceEngine.generate()                on-device chat model
      │
      ├─► TranslationPipeline.fromEnglish()  translate reply back for display
      │
      ▼
Render response  +  SessionDao.saveSession()   compressed summary → SQLite
```

The same identity of layers (state → safety → pipeline → engine → persist) is
reused by Practice, Apply, Create, Teach, and the Website Builder's "Ask OTIC".

---

## 5. Storage

Local SQLite via Drift ([lib/db/](../lib/db/)), one file per device, never synced.
See the schema table in the [README](../README.md#database-schema). Key rules:

- **Compressed summaries only** — `session_summaries` holds 2–3 sentence
  summaries, never raw conversation logs.
- **Additive migrations** — `migration` in
  [otic_database.dart](../lib/db/otic_database.dart) only adds tables/columns, so
  app updates never destroy student data. Current `schemaVersion` is 4.
- **DAOs** wrap every table (`StudentDao`, `SessionDao`, `PathDao`, `BadgeDao`,
  `ProjectDao`, `WebsiteDao`); generated `.g.dart` files come from `build_runner`.

---

## 6. Website Builder

A self-contained feature in [lib/features/website/](../lib/features/website/) that
demonstrates the "creation tool reusing the AI core" pattern:

- `block_models.dart` — `SiteBlock` (7 types) + `WebsiteDoc`, with JSON
  serialization for storage.
- `html_generator.dart` — pure function `WebsiteDoc → String`. Produces a
  standalone HTML document and is the security boundary: it escapes user text,
  sanitizes link schemes, and validates theme colors.
- `website_provider.dart` — Riverpod state: block CRUD, drag/drop ordering,
  `aiFill()` (calls `engineLoadedProvider`), `save()` (WebsiteDao), `exportHtml()`
  (file dialog).
- `website_builder_screen.dart` — palette, drag-and-drop canvas, inspector.

The generator is the only path that turns student input into a file, which is why
all sanitization is centralized there and covered by tests.

---

## 7. Roles

`Guest → Student → Teacher → Admin`. Guests get demo mode with no saved state;
students get full features and persistence; teachers read student progress; admins
manage device, model, and profiles. Role gating lives in the relevant
`features/teacher` and `features/admin` screens.

---

## 8. Offline updates

There is no auto-update over the internet. [tools/make_update_package.ps1](../tools/make_update_package.ps1)
packages a build into a bundle that is carried by USB or served on the school LAN;
installing over an existing version preserves the SQLite database. See
[RELEASING.md](RELEASING.md).
