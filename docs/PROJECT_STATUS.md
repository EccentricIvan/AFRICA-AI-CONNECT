# Project status and rollout checklist

Reviewed: 26 October 2026 (Africa/Kampala).

## Source baseline

- Repository: https://github.com/EccentricIvan/AI-CONNECT-AFRICA
- Source version: `1.4.0+5`; Drift database schema: `37`.
- Main: `a813f54` (20 October 2026).
- Latest reviewed feature baseline: `19716cb` (23 October 2026), on
  `feature/full-topic-explanations`, one commit ahead of main at review time.
- Commit dates describe the code history; they are not a complete push-event log.
- Implementation and automated tests do not establish classroom readiness.

## Current system

The Flutter app is offline-first. Student records and core learning work locally.
School devices exchange records and materials over the local network. Optional
cloud backup/recovery, online topic lookup, and an online tutor are exceptions to
older statements that the app never uses a network or external service.

| Area | Current implementation |
| --- | --- |
| Local AI | One reasoning model (Qwen2.5-Coder-1.5B-Instruct) and an AfriSLM translation model. Android uses LiteRT-LM files; Windows/Linux use llama.cpp GGUF files. See `lib/ai_core/model/model_runtime_policy.dart`. |
| Languages | English plus 19 African languages; translation quality requires acceptance checks on target devices. |
| Learning | Curriculum, topic explanations, quizzes, learning paths, conversation memory, notes and school subjects. |
| School roles | Admin, teachers, class teachers, learners; teaching assignments and enrolments scope access. Shared-device learner switching resets chat and sessions. |
| Assessment | PDF-to-quiz, homework, holiday assessments, submissions, grading, and tutor-assistance records. |
| Sync | Admin records, class materials, learner progress, delivery status, device registration/revocation, and student Share/Receive flows. |
| Creation | Website templates/builders, programming labs, projects, achievements and PDF certificates. |
| School cloud | Optional FastAPI backup/recovery service and app adapter; local/P2P workflows remain primary. Production infrastructure is separate work. |
| Latest feature branch | Rich topic explanations and diagrams, optional reference lookup, online tutor, school hub content packs, and guided course teaching. Not on main at the baseline above. |

## Optional tutor and school hub

`backend/otic_cloud/tutor.py` is separate from the school-record service.
The teacher enables and configures it in the app. API credentials belong on the
server. Without a configured/reachable service the app falls back locally.

- Hosted provider mode uses the server's `ANTHROPIC_API_KEY`.
- School hub mode uses `OTIC_HUB_LLM_URL` and `OTIC_PACKS_DIR` for a local
  model server grounded in school content packs.
- `backend/otic_cloud/packs.py` loads packs; `course.py` provides guided teaching.
- See `backend/README.md` for the existing startup commands.
- Real provider access, deployment, and school-hub performance are not proven by
  mocked/unit tests. Confirm the configured provider model is available before deployment.

## Latest development sequence

| Date | Work |
| --- | --- |
| 6-12 October | Admin and teaching assignments, enrolments, school sync, assessments, permission policy, PIN hashing and delivery visibility. |
| 13 October | School cloud, recovery, audit records, class teachers, resumable PDFs and readiness information. |
| 15 October | Admin-provisioned sync fixes and Android model package checks. |
| 20 October | PDF-to-quiz, PIN/language updates, AI-assistance records, student sharing, grouped notes and role/progress access fixes. |
| 23 October | Topic explanations/media, online tutor, school hub packs, guided courses and template improvements. |

## Validation for this review

- Backend: `backend/.venv/Scripts/python.exe -m pytest -q`:
  **64 passed**, with one Starlette/AnyIO deprecation warning.
- Flutter analysis: passed with `--no-fatal-infos`; zero errors/warnings and 46 informational lint suggestions remain.
- Flutter suite: **883 passed** after isolating translation discovery from installed models. The five discovery tests also passed independently.
- Fresh Windows release build: **passed** (`flutter build windows --release --no-pub`). Rebuilt app launched; visual UI validation is unavailable because the computer-use runtime failed to initialize.
- GitHub Actions results: not verified; unauthenticated API returned 404.
- The Windows executable opened before this review was dated 21 October and
  therefore is not evidence of a build containing the 23 October source changes.

## Release gates

- [x] Flutter analysis and app tests pass on the reviewed source (informational lints remain).
- [x] Fresh Windows release builds and launches. Core UI flows still require a visual/manual check.
- [x] Latest teaching feature and validation fix integrated into local main by fast-forward. GitHub main has not been pushed.
- [ ] Android release builds and signatures are verified with the intended signing key.
- [ ] Physical Android and Windows devices run actual reasoning and translation models.
- [ ] Switching learners keeps histories, languages and permissions isolated.
- [ ] Two-device pilot covers enrolment, notes/PDF transfer, offline interruption,
      submissions, grading, progress delivery, reconnect and device revocation.
- [ ] Teachers review topic coverage, factual accuracy, diagrams, quiz quality and translations.
- [ ] Online tutor and hub are exercised against real configured services, including failure fallback.
- [ ] Optional cloud deployment has HTTPS, school isolation, encryption/backups,
      recovery drills, monitoring and privacy review (see backend README and security docs).
- [ ] Release documentation, download links and artifacts match the validated commit.

Do not convert this checklist to a completion percentage: physical-device,
teacher-review and deployment evidence must be recorded separately.

## Local validation changes

The original discovery test searched real user folders and assumed its release
alias fixture would win. A canonical model already installed on this machine won
instead. Translation model discovery now accepts a candidate resolver (the default
production search is unchanged); canonical-name and alias tests use isolated
sparse fixtures and assert the exact selected path. The test no longer attempts
to rewrite the header of an existing model file.

Saved local logs (gitignored): `build/validation-analyze.log`,
`build/validation-tests.log`, `build/validation-windows.log`,
`build/validation-discovery.log`, and `build/validation-doctor.log`.

Android validation is blocked on this machine: `ANDROID_HOME` points to
`D:\dev\android-sdk`, which does not exist. The usual C: SDK locations were
also absent, and no physical Android device is connected. No Android signing
or device-validation result is claimed.

Local integration: validation commit `591a292` and feature commit `19716cb` are on local `main`. The working tree was clean after integration; remote publication remains outstanding.
