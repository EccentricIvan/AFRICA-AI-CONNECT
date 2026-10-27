# Project Handover — AI Connect Africa

> **Current project status (26 October 2026):** source version 1.4.0+5,
> database schema 37. This document contains historical descriptions that may
> predate school sync, roles, current models, and optional connected services.
> Start with [the current status and rollout checklist](docs/PROJECT_STATUS.md).


This document is for the team taking over maintenance of AI Connect Africa. It lists
everything needed to build, change, release, and maintain the app, and points to
the deeper docs for each topic. If you read one file first, read this one.

**Current status:** v1.1.0 is shipped and live. The rolling **AI Connect Africa Latest
Build** release is rebuilt automatically from `main` and publishes the full
Android APK plus the full Windows zip on the
[Releases page](https://github.com/EccentricIvan/AI-CONNECT-AFRICA/releases/tag/latest-build).
The latest branding update changes only logos/icons/splash assets; it does not
change the offline app behavior, student data, AI model flow, or lightweight
runtime design.

---

## 1. What AI Connect Africa is

A **fully offline** AI learning app for students — the Gemma AI model runs on the
device, with no internet, cloud, or accounts. One Flutter codebase targets Android
and Windows/Linux desktop. See [README.md](README.md) for the feature list and
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how it works.

> **The golden rule:** every feature must work with zero network connectivity. Do
> not add any dependency or API that needs the internet at runtime.

---

## 2. Everything the new team needs (checklist)

| Item | Where it is | How to get it |
|---|---|---|
| **Source code** | GitHub: `malinzijeremiah01-lab/Otic-Studio` | Get added as a collaborator (see §3) and `git clone` |
| **Build/run instructions** | [CONTRIBUTING.md](CONTRIBUTING.md) | In the repo |
| **Architecture & decisions** | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/ENGINEERING_LOG.md](docs/ENGINEERING_LOG.md) | In the repo |
| **Release process** | [docs/RELEASING.md](docs/RELEASING.md) | In the repo |
| **Version history** | [CHANGELOG.md](CHANGELOG.md) | In the repo |
| **Product requirements** | `AI Connect Africa PRD.pdf` / `.docx` | In the repo |
| **🔑 Android signing keystore** | NOT in the repo — held by the original developer | Must be transferred **securely** (see §4) |
| **🤖 AI model file (~1 GB)** | NOT in the repo — distributed by USB/server | Obtain from the original developer (see §5) |

The first two rows below the source code are the ones a new team most often forgets
to get and then **cannot recover** — make sure both are physically handed over.

---

## 3. Repository access

The code lives on GitHub and the repo is **public** (it must stay public — the
release download links break if it goes private).

To give the new maintainers control, the current owner does **one** of:

- **Add collaborators** (keeps current owner): repo → **Settings → Collaborators →
  Add people** → enter their GitHub usernames → choose the **Write** (or **Admin**)
  role.
- **Transfer ownership** (hands the repo over entirely): repo → **Settings →
  General → Danger Zone → Transfer ownership**.

After that, maintainers clone and work normally:

```bash
git clone https://github.com/EccentricIvan/AI-CONNECT-AFRICA.git
```

---

## 4. The Android signing keystore (most important handover item)

The keystore is what proves an update is genuinely "AI Connect Africa." It is **not in
the repo** (correctly — it must never be public). It is currently at:

```
C:\Users\LENOVO\otic-release.jks                 (the key)
C:\Users\LENOVO\otic-keystore-password.txt       (its password)
```

**Why it is critical:** Android only accepts an update if it is signed with the
**same** keystore as the installed app. If the new team does not have this exact
file, they can build a new app but **cannot ship an update to anyone who already
installed v1.0.0 / v1.1.0** — those users would have to uninstall and reinstall.
There is no way to recover or reset it. Losing it is permanent.

**How to hand it over — securely, never via the public repo:**

1. Put `otic-release.jks` + the password on an encrypted USB drive (BitLocker), or
2. Send a password-protected 7-Zip archive (`7z a -p -mhe=on backup.7z <files>`) and
   share the archive password through a *separate* channel (phone call, in person),
   or
3. Use a shared password manager vault (Bitwarden/1Password) the new team controls.

Keep **at least two copies in two places**. Once the new team confirms they have a
working copy, they own the responsibility to keep it safe.

After they have the keystore, they wire it up locally by copying
`android/key.properties.example` → `android/key.properties` and filling in the
values (this file is gitignored). Full steps in [CONTRIBUTING.md §6](CONTRIBUTING.md).

---

## 5. The AI model file

The Gemma 3 1B model (~1 GB) is **gitignored and distributed separately** — never
committed, never downloaded over the internet. The app runs without it (showing a
"Model Not Installed" screen and a mock engine), so you can develop the UI without
it, but real AI responses need it.

- Get the model file(s) from the original developer (USB/local server).
- Install in-app via **Model Not Installed → Install from file…**, or place
  manually at `[Documents]/OTIC/chat-model.litertlm` (Android: also checked
  under `[InternalStorage]/OTIC/` and the app's internal `models/` folder).

If the new team wants to source the chat model independently, it is Qwen3-0.6B
in `.litertlm` format (`litert-community/Qwen3-0.6B` on Hugging Face,
Apache-2.0, no license click-through) — the same file works on Android,
Windows, and Linux via LiteRT-LM.

The translation model (TranslatePsy-AfriSLM, GGUF) is separate — see
`lib/ai_core/translate/afrislm_model_manager.dart` — and is installed the
same way via **Settings → Translation → Install from file…**.

---

## 5a. Reference values

Public identifiers — safe to share. Use the certificate fingerprints to **verify**
the keystore you received is the genuine one that signed the published releases.

| Field | Value |
|---|---|
| Application ID / namespace | `com.aiconnectafrica.ai_connect_africa` |
| App label | `AI Connect Africa` |
| Current version | `1.1.0` (versionCode `2`) |
| Signing cert subject | `CN=Otic Studio, OU=Education, O=OTIC, L=Kampala, C=UG` |
| Signing cert SHA-256 | `2f2952030977a45e843c1005e539fec73cc9b51bc26e9fb1c61105eacd53c01e` |
| Signing cert SHA-1 | `6eb623487072e8f1193fabd9f5072ba1b1aed560` |

Verify a keystore/APK matches with:
```powershell
apksigner verify --print-certs <apk>     # compare the printed SHA-256 to the above
```

---

## 6. Build, change, release — quick pointers

- **Set up & run:** [CONTRIBUTING.md](CONTRIBUTING.md) (prerequisites, clone,
  `flutter pub get`, `build_runner`, run commands).
- **Make a change:** edit code, run `flutter analyze` (keep it clean) and
  `flutter test` (keep them passing), commit with a CHANGELOG entry.
- **Database changes:** edit a table/DAO, then run
  `dart run build_runner build --delete-conflicting-outputs`. Migrations are
  additive — never destroy student data ([docs/ARCHITECTURE.md §5](docs/ARCHITECTURE.md)).
- **Latest build release:** push to `main`; GitHub Actions builds the full APK and
  Windows zip, then updates the rolling `latest-build` release.
- **Versioned release:** [docs/RELEASING.md](docs/RELEASING.md) — build, sign,
  verify signature, `gh release create`. Helper: `tools/publish_release.ps1`.
- **Offline update bundles** (USB/LAN for schools): `tools/make_update_package.ps1`.

---

## 7. Known open items / good first tasks

- **Real-device model validation:** the app's switch from mock to real inference
  has been built but should be validated end-to-end on a physical Android phone and
  a Windows PC with the actual chat + translation models installed. This is the
  last gate before classroom use.
- **Android AfriSLM translation engine:** not implemented yet — translation
  currently only works on Windows/Linux via Ollama. Android needs a llama.cpp
  binding wired up before non-English students get translated chat on phones.
- **Website Builder follow-ups:** image blocks are styled placeholders (no real
  image embedding yet); sites are single-page; there is no in-app browser preview.
- **Gradle cache location:** on the original machine the Gradle cache sat on a full
  C: drive despite an intended `GRADLE_USER_HOME=D:`; verify your own setup.
- See [docs/ENGINEERING_LOG.md](docs/ENGINEERING_LOG.md) for the full record of
  decisions and obstacles, so you understand *why* things are the way they are.

---

## 8. Handover sign-off checklist

The handover is complete when the new team has confirmed **all** of:

- [ ] GitHub access (collaborator or owner) and can push.
- [ ] Successfully cloned and ran the app (`flutter run`) — even on the mock engine.
- [ ] Received the **signing keystore + password** and verified a signed release
      build works (`flutter build apk --release`).
- [ ] Received (or sourced) the **AI model file** and confirmed real inference works.
- [ ] Read CONTRIBUTING, ARCHITECTURE, RELEASING, and ENGINEERING_LOG.
- [ ] Made the keystore backups their own responsibility (two copies, two places).
