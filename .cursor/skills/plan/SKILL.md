---
name: plan
description: >-
  Plans and writes AI Connect Africa tutor replies as named pedagogical
  steps (factor, formula, substitute, compute, units) — never fake
  "Sum:" arithmetic. Use when changing tutor prompts, quiz AI answers,
  worked solutions, or when the user says /plan, conversion, or step-by-step method.
disable-model-invocation: true
---

# Plan (worked tutor method)

When planning or implementing an AI tutor reply, **do not** use labelled fake sums. Teach the method with named steps.

## Forbidden (do not look more like this)

```
1. Sum: 250 + 100 = 350
2. Sum: 350 + 100 = 450
Answer: 250 cm is equal to 2.5 metres.
```

Never invent intermediate additions. Never add numbers that are not part of the conversion or formula.

## Required method

Use numbered **named** steps. Each step: a short title, one sentence of why, then only the calculation that belongs there.

For unit conversion (and similar school problems), follow this approach:

Step 1: Identify the conversion factor
Determine the standard metric ratio between centimeters and meters.

1 meter=100 centimeters
Step 2: Set up the division formula
Since centimeters are a smaller unit than meters, divide the quantity by 100 to scale up to meters.

Length in meters= Length in centimeters / 100
Step 3: Substitute the value
Plug 250 cm into the conversion formula:

Length in meters= 250 cm / 100
Step 4: Execute the arithmetic
Divide 250 by 100 (or shift the decimal point two places to the left):

250÷100=2.5
Step 5: Attach the target unit
State the finalized measurement with its correct unit:

250 cm=2.5 m

## Checklist before shipping a tutor prompt or sample reply

- [ ] Steps are named (Identify / Formula / Substitute / Compute / Units) not "Sum"
- [ ] Every arithmetic line is required by the method
- [ ] Units appear on the final line
- [ ] Curriculum notes are the source of truth; no invented formulas
- [ ] Learner can see *why*, not only the answer

## App code

On-device replies are shaped by `lib/ai_core/tutor/tutor_contract.dart` and `assets/prompts/learning_tutor.txt`.

School conversions, percentages, linear equations, arithmetic, and rectangle area/perimeter are **computed in Dart** (`lib/ai_core/tutor/school_math.dart`), then filled into this plan — the small chat model does not do the arithmetic. That is the MathGPT-style split: language model explains other topics; a calculator owns the numbers. After a worked solution the tutor poses a similar practice item and grades a numeric attempt without guessing.

