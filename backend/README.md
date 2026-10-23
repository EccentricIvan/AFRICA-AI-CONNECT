# School cloud (optional)

The server for the app's optional school cloud: a backup and recovery copy
of each school's assignments, answers, grades and note PDFs. The app never
needs it — every feature works offline and over the local network. The
contract is `docs/CLOUD_API.md`; the security model is `docs/SECURITY.md`.

Each school gets its own database and file folder; a request reaches a
school only through the device key that signed it.

## Run locally (Windows)

```powershell
cd backend
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
.venv\Scripts\python -m pytest            # the isolation and security tests
$env:OTIC_DATA_DIR = "$PWD\otic-data"
$env:OTIC_ALLOW_HTTP = "1"                 # local testing only
.venv\Scripts\python -m uvicorn otic_cloud.main:app --host 0.0.0.0 --port 8443
```

On Linux use `.venv/bin/python` and `export`.

## Online AI tutor (Claude)

A separate service in the same package: it answers learners' questions with
Claude when a device can reach it. It holds no school records. The API key
stays here, never in the app.

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."     # from console.anthropic.com
$env:OTIC_TUTOR_TOKEN = "choose-a-secret"  # optional; enter the same in the app
.venv\Scripts\python -m uvicorn otic_cloud.tutor:app --host 127.0.0.1 --port 8787
```

Check it with `GET /v1/tutor/health` (`"configured": true` once the key is
set). Without a key it answers 503 and the app answers on the device. In the
app: Teachers → Online AI tutor → on, and set Tutor server to this address
(`http://127.0.0.1:8787` on the same computer; for other devices, the
computer's address on the school network, `--host 0.0.0.0`, and a token).
The guardrails are the system prompt in `otic_cloud/tutor.py`.

## Onboard a school

1. The school registers (`POST /v1/schools/register`), or the operator
   does it for them.
2. The operator approves it on the server:

   ```powershell
   .venv\Scripts\python -m otic_cloud.admin pending
   .venv\Scripts\python -m otic_cloud.admin approve reg_...
   ```

   This creates the school's database and folder, checks isolation, and
   prints the first Admin enrollment code (one use, 7 days).
3. The school's Admin enters the server address and that code in the app
   (Admin → School cloud). From there the Admin issues codes for teacher
   and learner devices, and recovery codes for replacement devices.

## Production — needs a person with cloud access

Not done here, and not claimed:

- **HTTPS**: run behind a TLS-terminating proxy that sets
  `X-Forwarded-Proto: https`; never set `OTIC_ALLOW_HTTP` in production.
- **Databases**: set `OTIC_SCHOOL_DB_URL`, e.g.
  `postgresql+psycopg://otic_{school_id}:...@db/{school_id}`, and create
  one database and one role per school in your provisioning pipeline (the
  role must have rights on its own database only). Add the driver to
  `requirements.txt`.
- **Encryption at rest**: disk or database encryption from the host; one
  key per school if the provider supports it.
- **Backups**: per school folder / database, restored only into the same
  school id.
- **Monitoring and rate limits** beyond enrollment, at the proxy.
- **Data protection**: see `docs/PRIVACY_UGANDA.md` before any school's
  data is stored.
