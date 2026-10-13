# School cloud API (v1)

The contract between the app's cloud plug-in (`lib/collaboration/cloud/`)
and the school cloud backend (`backend/`). The backend in this repository
implements it; the hosted Kigali (AOS) backend may differ, and the app's
adapter is the one place to change if it does.

**The cloud is optional.** It is off by default, and no feature needs it:
every device learns, teaches and syncs over the local network (P2P) alone.
The cloud is a school's backup and recovery copy of its records, plus a
second way to move them when devices are far apart.

## Principles

- **Nothing secret ships in the app.** No backend URL, key or school
  secret is bundled. A device joins a school's cloud only by typing a
  one-time code the school's Admin (or, for the first Admin, the platform
  operator) gives it.
- **The school comes from the device, never from the request.** Every
  request is signed by the device's Ed25519 key (the same key P2P sync
  uses). The server looks the key up in its registry; the device's school
  and role come from there. A `school_id` in a URL or body is never used
  to decide access — there is none.
- **One database per school.** The registry holds only schools, devices,
  enrollment codes and operator audit events. Each school's records,
  files and audit log live in its own database and folder, opened through
  its own engine. A request is bound to exactly one school's engine before
  any query runs.
- **Deny by default.** Anything not explicitly allowed for the device's
  role is refused with the same bare `404`, so a probe learns nothing.
- **Idempotent.** Every record has a stable id; sending it again is a
  no-op. Grades and assignments change only with a higher version.

## Request signing

Every request after enrollment carries:

| Header | Value |
|---|---|
| `X-Otic-Device` | the device's Ed25519 public key (base64url, no padding) |
| `X-Otic-Time` | the device's clock, ISO-8601 UTC |
| `X-Otic-Nonce` | 16+ random bytes, base64url |
| `X-Otic-Sig` | Ed25519 signature, base64url |

The signed bytes are UTF-8 of:

```
otic-cloud-req-v1
<METHOD>
<path, including query string>
<X-Otic-Time>
<X-Otic-Nonce>
<lowercase hex SHA-256 of the body>
```

The server refuses (bare `404`):

- an unknown, revoked or pending device, or one whose school is not
  active;
- a bad signature;
- a nonce it has seen from that device in the last 48 hours (replay);
- a time more than 24 hours from the server's. The window is wide on
  purpose: learner devices' clocks are often wrong (see the clock
  warning in Class progress), and the nonce check is what stops replay.

Bodies are JSON, at most 1 MB (files: 40 MB). Transport is HTTPS in
production; the server refuses plain HTTP unless started with
`OTIC_ALLOW_HTTP=1` (development only).

## School registration and provisioning

1. `POST /v1/schools/register` (public, rate-limited):
   `{name, district, contact_name, contact_phone, emis_number?}` →
   `{registration_id, status: "pending"}`. Nothing is provisioned.
2. The platform operator reviews it out of band, then runs
   `python -m otic_cloud.admin approve <registration_id>` on the server
   (operator access is the server's shell, never an API key in the app).
   Provisioning:
   1. generates the permanent school id (`sch_` + 128 random bits);
   2. creates the school's database and file folder;
   3. creates its tables;
   4. runs the isolation self-check (the new engine sees only its own
      file, holds no rows, and another school's id resolves elsewhere);
   5. issues the first Admin enrollment code (one use, 7 days);
   6. marks the school `active` and writes an operator audit event.

   If any step fails the school stays `provisioning` and nothing can
   enroll. The command prints the code once; the operator gives it to
   the school.
3. Offline registration: the app keeps a pending setup record and says
   "Cloud: not set up". It never says provisioning succeeded until the
   server confirmed an enrollment.

## Enrollment

`POST /v1/enroll` (unsigned — the code is the credential):

```json
{"code": "...", "device_key": "...", "box_key": "...",
 "role": "admin|teacher|learner", "label": "S2 tablet 3"}
```

→ `{school: {name}, role, device_status: "active"}`

- The code is stored only as a SHA-256 hash, is single-use, expires, and
  names the role it grants. A learner code can't enroll a teacher device.
- Wrong codes are rate-limited per client address: after 200 failures in
  an hour the address is refused for an hour. The limit is generous
  because a whole school often shares one public address; guessing is
  stopped by the code itself (12 characters from 31, about 59 bits).
- A device key already enrolled in another school is refused.

`POST /v1/enrollment-codes` (signed, Admin only):
`{role, expires_hours (≤ 168), learner_uuids?: [...]}` → `{code}`.
A code with `learner_uuids` is a **recovery code**: the device it enrolls
may read back those learners' records (see Recovery).

`POST /v1/devices/revoke` (signed, Admin only): `{device_key}`. A revoked
device is refused for every later request, in its school only.

`GET /v1/devices` (signed, Admin only): the school's devices.

## Records

`POST /v1/records` (signed): `{records: [{id, kind, payload}]}` (≤ 50)
→ `{accepted: [ids]}`.

| kind | id | who may send | rule |
|---|---|---|---|
| `assignment` | `assignment:<id>` | teacher, admin | publisher-authoritative; replaced only by the same device |
| `submission` | `submission:<uuid>` | learner (own learners), teacher (received ones) | append-only: a repeat is a no-op, never an edit |
| `grade` | `grade:<uuid>:<version>` | teacher, admin | applied only when `version` is higher than held |

`accepted` lists every id the server now holds, including ones it had
already (so the app marks them sent). A record it refuses is left out,
and the app keeps it queued (the outbox counts it as pending).

## Recovery

`GET /v1/records?kind=submission&learner_uuid=<uuid>` (signed): the
learner's synced answers and their latest grades. Allowed for:

- the school's Admin devices;
- a learner device enrolled with a recovery code that names this
  learner.

Not for teacher devices: the server doesn't know teaching assignments,
so it couldn't keep a teacher to their own classes' learners. Teachers
see their learners' answers over P2P, where `Policy` applies.

This is how a learner's work comes back on a replacement device: the
Admin issues a recovery code for that learner, the new device enrolls
with it, then downloads.

## Files

`PUT /v1/files/<sha256>` (signed, teacher/admin): the body must hash to
the name; stored as `<school folder>/files/<sha256>`, written to a temp
file and renamed. `GET /v1/files/<sha256>` (signed, any device of the
school). The name must be 64 lowercase hex characters — nothing else
reaches the file system, so `../` can't.

## Teacher device backups

`PUT /v1/backups/host` (signed, teacher/admin): `{ledger}` — the
device's host backup (classes, keys, shared notes), sealed on the device
under the teacher's standby passphrase (PBKDF2 600k, AES-GCM). Only a
sealed ledger is accepted: its plain header plus nonce, ciphertext and
tag; anything else is refused. The latest 3 per device are kept.

`GET /v1/backups/host` and `GET /v1/backups/host/<id>` (signed,
teacher/admin): list and download. A replacement teacher device takes
over with the passphrase, exactly as a standby does
(`P2PFailoverService.promoteToHostNode`); the server can't open it.

## Audit

Each school database keeps an audit log: enrollments, revocations,
codes issued, refused requests that named a device of that school. The
registry keeps operator actions and refusals with no school (unknown
device). Never logged: codes, signatures, answer text, PINs.

## Status codes

`200` success · `400` malformed body · `404` everything refused (unknown
device, wrong school, no permission, bad signature, replay) · `413` too
large · `429` rate-limited.
