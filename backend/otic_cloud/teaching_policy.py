"""Question-specific teaching structure and bounded context for school replies."""
from __future__ import annotations
import re
from dataclasses import dataclass

@dataclass(frozen=True)
class TeachingProfile:
    mode: str
    max_tokens: int
    context_chars: int
    instruction: str


def profile_for(question: str) -> TeachingProfile:
    text = question.lower()
    if re.search(r'\b(brief|briefly|short answer|in one sentence|more simply|simplify)\b', text):
        return TeachingProfile('simple', 750, 3200,
            'Give a direct, simple explanation, a concrete example and a short recap. '
            'Define unfamiliar words; keep only context needed for this question.')
    if re.search(r'\b(example|examples|worked problem|demonstrate)\b', text):
        return TeachingProfile('example', 1200, 5000,
            'Answer the requested example rather than restarting an unrelated lesson. Use headings: '
            'Context (briefly define the idea); Worked example (one coherent everyday scenario, '
            'with steps or a compact comparison where useful); Why it works (connect each part '
            'to the definition); Common confusion; Key takeaway; one unanswered Check question. '
            'For a multi-part topic cover each named part, keeping the examples connected. '
            'Use each heading once and avoid repeating definitions or the same example.')
    return TeachingProfile('explanation', 1800, 6200,
        'Teach a complete school-level explanation of the requested concept, not just a definition. '
        'Use relevant headings: Meaning and background; Main ideas or types; How it works '
        '(ordered steps and reasons); Everyday or worked examples; Why it matters; '
        'Common mistakes; Key takeaways; one unanswered Check your understanding question. '
        'Explain prerequisites and key terms as they arise, include units for formulas, and use '
        'familiar Uganda/East Africa examples when natural. Select only headings that serve the '
        'question; a narrow follow-up stays focused. Aim for 450-700 useful words for a broad '
        'topic, with no filler or repetition. Do not invent facts to fill a heading.')


# These are focused misconception notes, not replacement syllabus material.
# References: OpenStax Biology 2e, 8.1 and 34.1 (see docs/TEACHING_QUALITY.md).
NUTRITION_CHECKS = (
    'Autotrophs build organic food from inorganic materials; green plants use light energy. '
    'Animals obtain organic food by feeding and are heterotrophs. A deer or goat eating '
    'plants is a herbivore AND a heterotroph; it does not photosynthesise. A lion is a '
    'carnivore AND a heterotroph. Herbivore/carnivore/omnivore describe diets within '
    'heterotrophic animal nutrition, not alternatives to autotroph/heterotroph. '
    'Sunlight supplies energy, not carbohydrates or mineral nutrients. Green plants make '
    'sugars using carbon dioxide and water, and absorb water/minerals through roots. '
    'Explain nutrient classes separately from modes of nutrition. Do not infer a medical '
    'diagnosis from one visible symptom in a classroom example.'
)


def teaching_context(question: str, titles: list[str]) -> str:
    result = 'TEACHING PLAN:\n' + profile_for(question).instruction
    topic = question + ' ' + ' '.join(titles)
    if re.search(r'\b(nutrition|nutrient|nutrients|autotroph\w*|heterotroph\w*|photosynth\w*)\b', topic, re.I):
        result += '\n\nACCURACY CHECKS FOR THIS TOPIC:\n' + NUTRITION_CHECKS
    return result