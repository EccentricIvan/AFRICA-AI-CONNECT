# SALT dataset attribution

`salt_corpus.json` is derived from the Sunbird AI SALT (Sunbird African
Language Translation) dataset:

- Source: https://github.com/SunbirdAI/salt-data-archive (v1.2, `train` +
  `dev` + `test` splits combined)
- License: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
- Citation: Sunbird AI, in collaboration with the Makerere AI Lab and the
  Makerere University Institute of Languages.

Only the `en`, `lg`, `ach`, `teo`, `nyn` columns are kept (this app's
locale codes) — SALT's `lgg` (Lugbara) column is dropped since this app has
no such locale, and rows missing any of the five required columns are
excluded. Duplicate English sentences are deduplicated, keeping the first
occurrence. See `lib/services/offline_chat_service.dart` for how it's used
(a translation-lookup fallback tier, tried only when the curated
`offline_chat.json` knowledge base has no match).
