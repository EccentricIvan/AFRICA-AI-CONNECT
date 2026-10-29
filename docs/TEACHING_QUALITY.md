# Teaching quality and depth - 29 October 2026

## Answer structure

Broad concept questions now request a full school-level explanation: meaning and
background, main ideas/types, mechanisms, connected examples, importance, common
misconceptions, key takeaways and one unanswered check question. Sections are
selected for relevance, rather than forcing unrelated material into every answer.

Example requests remain focused: brief context, a worked example, why it fits,
a common confusion, a takeaway and a check question. Explicit requests for a
short/simple answer still receive a simpler explanation. Course steps retain
their current subtopic and expand its explanation instead of jumping ahead.

Generation and retrieval budgets adapt to the request. The hub receives more of
the actual relevant lesson, reducing the chance that important definitions,
classifications or examples are missing from its prompt. Text still streams;
longer lessons take longer to finish. Offline generation also has more room for
broad topic explanations. No smaller model was substituted.

## Context and accuracy

The screenshot showed a herbivore incorrectly described as an autotroph. The broad nutrition lesson and its worked example now use structured curriculum teaching notes, including generic expansion follow-ups. Topic
accuracy notes now distinguish nutrition modes from animal diets and nutrient
classes. Conversation history can contain mistakes and no longer overrides
relevant source definitions. A native nutrition diagram and caption reinforce
the distinction. Source references used for checking these basic concepts:

- [OpenStax Biology 2e: Overview of Photosynthesis](https://openstax.org/books/biology-2e/pages/8-1-overview-of-photosynthesis)
- [OpenStax Biology 2e: Digestive Systems](https://openstax.org/books/biology-2e/pages/34-1-digestive-systems)

Expansion requests such as "Tell me more" preserve the last substantive topic.
Instruction words such as "example", "detail" and "briefly" are excluded from
subject matching so they do not pull unrelated lesson material into the answer.
Ordinary replies now offer an "Explain in detail" follow-up button.

## Validation and limits

- 904 Flutter tests and 84 backend tests pass.
- Live generated nutrition-example and photosynthesis replies were reviewed. A later nutrition overview exposed misleading wording, so that identified lesson and its worked example now bypass model generation and use the structured teaching note. Final live checks verify the deployed note. Evaluations are saved locally
  in build/teaching-live-evaluation.json and build/teaching-full-nutrition-evaluation.json.
- Tests cover relevant source selection, multi-turn expansion, adaptive response
  budgets, nutrition accuracy notes and the offline nutrition diagram.
- These checks do not establish that every generated statement is correct.
  Broader curriculum/content-pack teacher review remains a rollout requirement.
## Source and picture relevance correction

The first-aid screenshot exposed two retrieval errors: the app discarded the
three-letter word "aid", and the hub accepted "first" and "aid" appearing
separately in a camera article. A taxation article also matched "foreign aid".

Local matching now preserves short words and requires evidence for the named
multiword topic. Scattered words and a passing mention of a first-aid kit are
insufficient. The hub applies the same restriction to expansion follow-ups.
Pictures and follow-up actions must come from entries about the requested topic;
a general lesson mentioning a narrower topic cannot supply unrelated pictures.

Validation: 905 app tests and 89 backend tests pass. Against the internal hub's
593 entries, "What is first aid?" finds no qualifying lesson, while photosynthesis
and food chains still find the expected lessons. A content miss lets the app use
its existing credited internet explanation fallback. JSON, streamed answers,
and the hub picture endpoint have regression coverage for unrelated media.
These lexical relevance checks reduce false matches; they do not independently
verify the contents of every image or model-generated explanation.
