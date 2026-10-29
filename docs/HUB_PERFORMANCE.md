# Hub response speed - 29 October 2026

Hub answers now stream into the chat while the model generates them. The final
answer retains source credits, media, lesson plans and follow-up suggestions.
The JSON endpoint remains available for older apps/servers. Content misses still
allow internet lookup; interrupted streams clear partial output before fallback.

## Measurements on this PC

| Question/mode | First visible text | Complete response |
| --- | --- | --- |
| Convection, buffered baseline | 19.5 s | 19.5 s |
| What is convection?, streamed | 1.1 s | 12.8 s |
| What is density?, streamed | 6.4 s | 22.0 s |

These are individual local measurements, not latency guarantees. Prompt-cache
warmth, answer length, available memory and other activity affect completion
time. Streaming primarily reduces the blank wait; it does not make the model's
individual token calculations faster. No model downgrade or answer-length cap
was introduced by this change.

## Validation

- 894 Flutter tests and 74 backend tests pass.
- Focused analysis of the app streaming implementation is clean.
- Tests cover early text delivery, split UTF-8 chunks, older-server fallback,
  content misses, stream interruption, reasoning suppression and final sources.
- Local benchmark records: build/speed-baseline-today.json and
  build/speed-streaming-after.json (gitignored).

Start the presentation package using the desktop AI Connect Africa Hub shortcut
so the model and tutor are ready before the app opens.
