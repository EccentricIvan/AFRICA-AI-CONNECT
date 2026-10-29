"""Structured curriculum teaching notes for topics with identified misconceptions.

The nutrition classifications were checked against OpenStax Biology 2e 8.1 and
34.1; nutrient roles and food tests follow the app's existing school curriculum.
These notes are educational content, not clinical guidance.
"""
import re

NUTRITION_LESSON = """## Meaning and background
**Nutrition** is how living things obtain and use materials needed for energy, growth and repair. Two different questions help us understand this topic:
1. **Mode of nutrition:** How does an organism obtain its organic food?
2. **Nutrient classes:** Which useful substances does that food contain?
A mode of nutrition describes an organism's feeding relationship. A nutrient class describes a component of food. They are not interchangeable classifications.

## Main modes of nutrition
**Autotrophic nutrition:** an organism builds organic food from inorganic materials. Green plants are familiar photoautotrophs: they use light energy to make sugars from carbon dioxide and water. Some microorganisms use chemical energy instead of light, so not every autotroph depends on sunlight.
**Heterotrophic nutrition:** an organism obtains organic food from other organisms or material produced by them. Animals and fungi are examples. A goat or deer eats plants and is therefore a heterotroph; eating a plant does not make the animal an autotroph.
Among animals, **herbivores** eat plant food, **carnivores** eat animal food, and **omnivores** eat both. These are dietary groups within heterotrophic nutrition. Fungi obtain nutrients from organic material by digestion outside their bodies followed by absorption.

## Nutrients and their roles
A balanced diet provides suitable amounts of different food components for a person's needs.
- **Carbohydrates:** supply energy. Examples include maize, rice, cassava and matooke.
- **Proteins:** provide building materials for growth and tissue repair. Beans, peas, fish, eggs and meat are useful sources.
- **Fats and oils:** provide a concentrated energy store and help form cell structures. Sources include groundnuts, seeds and cooking oils.
- **Vitamins:** needed in small amounts for particular body functions. Different vitamins have different roles; fruit and vegetables supply several of them.
- **Minerals:** elements needed in small amounts. For example, iron is needed in haemoglobin, while calcium is important for bones and teeth.
- **Fibre or roughage:** supports movement of material through the digestive tract. Whole grains, beans, fruit and vegetables provide fibre.
- **Water:** acts as a solvent, supports transport and reactions in the body, and helps regulate temperature.
Foods often contain more than one nutrient. Beans, for instance, provide protein as well as carbohydrates and fibre. A balanced diet is not a rule that every food supplies only one nutrient.

## An everyday example: maize, a goat and a family meal
A maize plant uses sunlight, carbon dioxide and water to make sugars. It is an autotroph. A goat eats plant material: it is both a herbivore and a heterotroph. A lion eating another animal is both a carnivore and a heterotroph.
A person eating a varied meal of matooke, beans and vegetables obtains nutrients made by other organisms and is a heterotroph. This meal can supply energy, protein, vitamins, minerals and fibre; water is also needed. The amount and variety required depend on factors such as age and activity.

## How classroom food tests help
With teacher supervision, food tests can identify certain components: iodine gives a blue-black colour with starch; Benedict's solution gives a coloured precipitate with reducing sugars after heating, with the colour depending on concentration; the Biuret test gives violet with protein; an ethanol emulsion test gives a milky emulsion with fats. One positive test does not show that a food contains every nutrient or that a whole diet is balanced.

## Common confusions
Sunlight is an energy input, not a carbohydrate supplied to roots. Green plants manufacture sugars; roots take in water and mineral ions. A herbivore is not an autotroph. Nutrient classes such as proteins and vitamins are not feeding modes such as autotrophic and heterotrophic nutrition.

## Key takeaways
Separate how food is obtained from what food contains. Explain an animal's classification using what it eats. Relate each nutrient to its function, and use a varied diet as the practical example.

## Check your understanding
Classify a goat and a maize plant by mode of nutrition, and explain your reason for each. Then name two nutrient classes supplied by a meal containing beans and matooke.
"""

NUTRITION_EXAMPLE = """## Context: two ideas to keep separate
A **mode of nutrition** describes how an organism obtains food. A **nutrient class** describes a substance in that food. Autotrophs make organic food from inorganic materials; heterotrophs obtain organic food from other organisms or their products.

## Worked example: maize, a goat and a family meal
**1. The maize plant makes food.** Its green leaves use light energy, carbon dioxide and water to produce sugars. This is photoautotrophic nutrition. Roots absorb water and mineral ions; they do not absorb sunlight as a nutrient.
**2. A goat eats plants.** The goat gets ready-made organic food by feeding. It is a **heterotroph** and, because its diet is plant-based, a **herbivore**. A deer is classified in the same way. Neither animal photosynthesises.
**3. A lion eats animals.** The lion is also a heterotroph, but its dietary group is **carnivore**. A person who eats both plant and animal foods is an omnivore and a heterotroph.
**4. Consider a meal of matooke, beans and vegetables.** Matooke supplies carbohydrate for energy. Beans supply protein for growth and repair, as well as carbohydrate and fibre. Vegetables contribute fibre and various vitamins and minerals. Suitable fats and sufficient water are also parts of a balanced diet.

## Why the example works
The maize, goat and lion demonstrate different ways food is obtained. The meal demonstrates what food contains and how those components help the body. A food can supply several nutrient classes: it should not be assigned to exactly one nutrient in every situation.

## Common confusion
Eating plants does not turn an animal into an autotroph. Herbivore, carnivore and omnivore are animal dietary groups within heterotrophic nutrition. They are a different classification from carbohydrates, proteins, fats, vitamins, minerals, fibre and water.

## Key takeaway
Ask two questions: **How is the food obtained?** and **Which nutrients does it provide?** Giving a reason for each classification is more useful than memorising a label alone.

## Check your understanding
Why are a goat and a lion both heterotrophs even though they eat different foods? Which nutrient classes would you look for in a meal of beans and matooke?
"""


def structured_nutrition_lesson(question: str, previous_topic: str = "") -> str | None:
    text = question.lower().strip().rstrip('.!?')
    if previous_topic and re.fullmatch(r'(?:tell me more|explain more|go deeper|expound(?: more)?|(?:give|show) me (?:another|an?) example)', text):
        if structured_nutrition_lesson(previous_topic) is not None:
            expanded = ('Give me an example of ' if 'example' in text else 'Explain ') + 'Nutrition Types and Nutrient Compounds'
            return structured_nutrition_lesson(expanded)

    pattern = (r'(?:please )?(?:(?:what (?:is|are)|explain|describe|teach me(?: about)?|tell me about|'
               r'give me (?:an? )?example(?: of)?) )?'
               r'(?:nutrition types and nutrient compounds|types of nutrition|modes of nutrition|nutrition and nutrients)'
               r'(?: (?:in detail|fully|please))?')
    if not re.fullmatch(pattern, text):
        return None
    body = NUTRITION_EXAMPLE if 'example' in text else NUTRITION_LESSON
    return body + '\n\n*Structured curriculum teaching note. Classification reference: OpenStax Biology 2e, sections 8.1 and 34.1.*'