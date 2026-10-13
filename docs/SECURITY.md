# Security: threat model and checklist

AI Connect Africa runs on shared school devices, mostly offline. Its
security has to work without a server, so most controls live on the
device and in the P2P protocol; the optional school cloud (`backend/`,
`docs/CLOUD_API.md`) adds a backup and recovery copy with its own
isolation.

What this document does **not** claim: that an offline app can tell
whether a learner used another phone or tool, that files already copied
to a device which never reconnects can be revoked, or that a device in
an attacker's hands with its OS unlocked can keep its data.

## Assets

| Asset | Where | Who may see it |
|---|---|---|
| Learners' answers, grades, quiz results, progress | learner device, teacher device, school cloud | that learner, teachers of their class/subject, the Admin |
| Teacher notes and PDFs | teacher device, class devices, school cloud | the classes they are shared with |
| Class keys, device keys, teacher signing seed | each device's database | that device only (seed also in the failover ledger, passphrase-sealed) |
| School records (teachers, classes, enrolments) | Admin device, devices it syncs to | that school |
| PINs | each device, salted PBKDF2 hashes | nobody (only verified) |

## Data flow

```
Admin device ──signed Admin records──▶ teacher / learner devices (P2P, one way)
Teacher device ──signed, encrypted class channels──▶ learner devices (P2P)
Learner device ──encrypted progress report + answers──▶ teacher device (P2P)
Teacher device ──grades, receipts, extra help (reply)──▶ that learner device
Any enrolled device ──signed records (outbox)──▶ its school's cloud (optional)
Replacement device ◀──recovery (recovery code)── school cloud
```

Every P2P request is MAC'd with the class key and signed by the device
key; replies are AES-GCM sealed to the request nonce and teacher-signed.
See CLAUDE.md → Class sync for the full rules.

## Threats and controls

| # | Threat | Control | Status |
|---|---|---|---|
| T1 | Another school's device joins a class | school id pinned at first join; join needs a typed code plus the sharer's Accept | verified (`class_sync_e2e_test`) |
| T2 | Cross-school cloud access (changed ids, URLs, params) | school resolved from the signed device key; one database per school; bare 404 | see `backend/tests/test_isolation.py` |
| T3 | Lost or stolen device | per-class and school-wide revocation (P2P and cloud); PINs; database encryption at rest | revocation verified; encryption at rest: see checklist |
| T4 | Copied APK / installer | no secret is bundled; joining needs a one-time code and Accept | verified by design (no embedded key) |
| T5 | Malicious P2P peer | MAC + device signature on every request; teacher-signed manifests with versions that only go up; classmates relay verbatim only | verified (`class_sync_e2e_test`, `class_crypto_test`) |
| T6 | Forged or edited learning packages | Ed25519 manifests over digest + version; PDFs checked against the signed SHA-256 | verified |
| T7 | Replayed sync messages | replies bound to the request nonce; cloud nonce cache (48 h) | P2P verified; cloud see backend tests |
| T8 | Storage permission mistakes | app-private storage on Android; `NotePdfStore` names files by hash only; cloud file names must be 64 hex | partly: Windows app data is readable by the same OS user |
| T9 | Credential theft (codes, PINs) | codes single-use, expiring, hashed, rate-limited; PINs PBKDF2 | verified |
| T10 | Unauthorized export / backup restore | failover ledger sealed under a ≥12-char passphrase (PBKDF2 600k); cloud restore scoped to the device's school | verified for ledger; cloud see backend tests |
| T11 | Network interception | P2P: AES-GCM per reply, signatures; cloud: HTTPS required in production | P2P verified; cloud HTTPS is a deployment step |
| T12 | Cloud or backend compromise | the cloud holds a copy, not the only copy; per-school databases limit a query bug to one school; per-school encryption keys are a deployment option | partly (see checklist) |
| T13 | A teacher reaching another class | `Policy` + teaching assignments on every action | verified (`policy_test`) |
| T14 | A learner on a shared device seeing another's work | active learner switch resets chat, memory, KV; per-learner PIN | verified; PIN is a deterrent only |

## Security checklist

Legend: **verified** (implemented and tested here) · **incomplete**
(partly done, gap named) · **blocked** (needs something outside this
repo).

| Control | Status |
|---|---|
| No universal secret in the app | verified |
| Device identity (Ed25519 + X25519) and revocation, P2P | verified |
| School isolation in P2P (school id pinned, scoped channels) | verified |
| Role-based permissions in one place (`Policy`) | verified |
| PBKDF2 PINs, upgraded on next entry | verified |
| Model files checked against SHA-256 manifests | verified |
| Cloud: per-school database, school from device key | see stage notes below |
| Cloud: request signing, nonce replay cache | see stage notes below |
| Cloud: HTTPS | blocked — needs a certificate and host (deployment) |
| Cloud: per-school encryption keys at rest | blocked — needs a managed key service in the chosen cloud |
| Database encryption at rest on devices | see stage notes below |
| Note PDFs, session recall files, project folders encrypted at rest | incomplete — not encrypted (project folders must open in Explorer) |
| Signed audit log on devices | see stage notes below |
| Teacher recovery (per-teacher key + passphrase) | see stage notes below |
| Rate limiting and monitoring of the cloud | incomplete — enrollment rate limit only; monitoring is a deployment step |
| Real-device tests (Android + Windows, internet off) | blocked — must be done by hand |

## Stage notes

Updated as each stage of the 2026-10-13 architecture work lands.
