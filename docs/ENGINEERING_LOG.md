# Engineering Log

A record of the significant decisions made and obstacles overcome while building
AI Connect Africa, with pointers to where each change landed. This is the "why" behind
the commit history — useful for the next engineer and for an enterprise review.

Entries are newest-first.

---

## Toolchain & environment

| Item | Detail |
|---|---|
| Flutter SDK | `D:\flutter\bin` (installed directly, not winget) |
| JDK | Temurin JDK 17 (`Eclipse Adoptium`) — Microsoft.OpenJDK winget manifest had a hash mismatch |
| Android SDK | `D:\Android` (moved off C: because C: is chronically near-full) |
| Android build-tools | 34.0.0; platforms android-35 + android-36 |
| Release keystore | `C:\Users\LENOVO\otic-release.jks`, alias `otic`; password file alongside it. **Both must be backed up** — losing them means losing the app's update identity. |
| Build temp | Redirected `TEMP`/`TMP` to `D:\temp` during builds to survive low C: space |

---

## Obstacles faced and how they were resolved

### 0. Experimental llama.cpp path on Android without replacing Gemma
**Problem:** the app already had Google's MediaPipe/LiteRT-LM path through
`flutter_gemma`, but needed a second on-device LLM route for Llama 3.2 1B GGUF
testing without disturbing production tutor inference.
**Resolution:** added an isolated `fllama` path:
- `lib/ai_core/llama/llama_model_manager.dart` downloads and verifies the GGUF
  in app documents storage, with a `.part` file and install marker.
- `lib/ai_core/llama/fllama_engine.dart` wraps fllama context loading and
  completion calls.
- `lib/features/llama/llama_test_screen.dart` exposes `/llama-test` for manual
  download, prompt, response, and error testing.

The existing `ModelManager`, `LiteRtLmEngine`, and `engineLoadedProvider` remain
the production Gemma/MediaPipe path. `fllama` documents Android min SDK 23 and
support for `arm64-v8a`, `armeabi-v7a`, and `x86_64`.

**Verification note:** this change still needs `flutter pub get` and
`flutter build apk --debug` on a machine with Flutter installed. The edit
environment used here did not have `flutter` or `dart` on PATH.

### 1. C: drive runs out of space mid-build
**Problem:** The C: drive repeatedly dropped to ~0 bytes during `flutter build`,
breaking compilation. Gradle and Dart write large intermediate files to temp.
**Resolution:**
- Redirect `TEMP`/`TMP` to `D:\temp` for every build command.
- Moved the Android SDK to `D:\Android`.
- Delete the regenerable `build/` folder (~1 GB) after copying release artifacts.

**Still open:** the Gradle cache (~4 GB) is sitting at `C:\Users\LENOVO\.gradle`
despite an intended `GRADLE_USER_HOME=D:\gradle-cache`; the env var isn't taking
effect for builds. Relocating it would reclaim ~4 GB. Windows user-temp cleanup
must be done via Settings → Storage → Temporary files.

### 2. Fonts silently fetched over the network
**Problem:** `google_fonts` downloads font files at runtime on first use — a
hard violation of the offline-first constraint. The app *looked* fine in dev
(where there was internet) but would render wrong fonts on a disconnected device.
**Resolution:** removed `google_fonts`, bundled the Plus Jakarta Sans `.ttf`
files as assets, and declared them in `pubspec.yaml`.
**Landed in:** commit `4ed9b23`.

### 3. Model file is ~1 GB and can't ship in the app or over the internet
**Problem:** The Gemma model is too large to bundle in the APK and must never be
downloaded. Students receive it by USB or school server, so the app must accept a
model file from arbitrary local storage and verify it.
**Resolution:** built the **Install from file…** flow — pick the file, validate
it (minimum-size guard rejects truncated copies), copy it into app storage with a
progress bar, then activate the real engine. The app runs on a `MockEngine` until
a valid model is present, so no screen is dead without it.
**Landed in:** commit `73d635c`; see [model_manager.dart](../lib/ai_core/model/model_manager.dart)
and [model_not_installed_screen.dart](../lib/features/model_setup/model_not_installed_screen.dart).

### 4. file_picker version churn
**Problem:** Newer `file_picker` releases changed APIs and pulled in transitive
breakage. **Resolution:** pinned `file_picker` to exactly `8.3.7`, which has the
stable `saveFile`/`pickFiles` surface the model installer and HTML export rely on.

### 5. Android release build failures (native AI libs)
**Problem:** Release builds with R8/ProGuard stripped classes needed by
MediaPipe/LiteRT-LM, and `compileSdk` had to advance for the plugins.
**Resolution:** added ProGuard keep rules for MediaPipe/LiteRT-LM (`46be448`) and
set `compileSdk` to 36 with a plugin override (`4ed9b23`).

### 6. Publishing releases — GitHub token access
**Problem:** `gh` (GitHub CLI) is not authenticated in the automation
environment, and reading the stored credential to authenticate it is blocked by
security policy (credential-store scraping). `git push` works because it uses the
credential helper internally, but `gh release create` cannot borrow that.
**Resolution / workflow:** a human runs `gh auth login` once on the machine;
afterwards releases can be published. The exact steps are in
[RELEASING.md](RELEASING.md). Code and tags still push normally over `git`.

### 7. Voice learning dropped from scope
**Decision:** offline STT/TTS (Vosk/Piper) was planned but removed. It added
significant model weight and integration surface for marginal early value. The
roadmap jumps from text learning straight to the later phases. Recorded so the
absence reads as intentional, not missing.

---

## Notable design decisions

### Single InferenceEngine interface across platforms
One interface, three implementations (LiteRT-LM, llama.cpp, Mock). UI and the
tutor pipeline never branch on platform — they depend only on the interface, so
the desktop/Android split and the no-model fallback are invisible above the AI
core. See [ARCHITECTURE.md](ARCHITECTURE.md#2-the-ai-core).

### Compressed summaries, never raw logs
Student privacy and tiny on-device storage drove the choice to persist only 2–3
sentence summaries per session. There is no table that can hold a full transcript.

### Additive-only DB migrations
Every schema bump (now at v4) only adds tables/columns. App updates therefore
never wipe a student's history — important when updates arrive by USB and can't be
easily rolled back.

### Centralized HTML sanitization in the Website Builder
The exporter is the single place student input becomes a file, so all escaping and
link/color sanitization lives in `html_generator.dart` and is unit-tested, rather
than being scattered across the UI.

### Mock engine as a first-class fallback
Because the model ships separately, a device may run the app for a while before the
model arrives. The `MockEngine` keeps every screen functional for demos and
training, and makes UI development possible without a 1 GB model loaded.

---

## Testing posture

- `flutter analyze` is kept clean (zero issues) before every release.
- Tests cover the parts where correctness is non-obvious: the emotional-safety
  classifier ([test/emotional_safety_test.dart](../test/emotional_safety_test.dart))
  and the Website Builder block model + HTML generator, including the security
  cases ([test/website_builder_test.dart](../test/website_builder_test.dart)).
- Real end-to-end inference with the 1 GB model on physical devices is a manual
  validation step (the harness can't host the model); it is the last gate before
  putting a build in front of a school.
