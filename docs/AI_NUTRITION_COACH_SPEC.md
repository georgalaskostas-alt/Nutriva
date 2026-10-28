# Nutriva AI Nutrition Coach — Product Specification

## Core experience
Users can ask conversational questions before eating, e.g. "Can I eat an apple now?", "What should I eat for dinner?", "I am hungry before night shift", "I want something sweet", and "I only have eggs and yogurt".

The coach reads the user's *actual* logged meals, verified nutritional values, goals, schedule, preferences, allergies and remaining planned meals (where provided). It must never pretend missing or stale data is known.

## Example decision flow
1. Parse question locally.
2. Fetch today's food log and targets, meal plan, shift context, and relevant preferences.
3. Look up nutrient values and estimate portions with explicit assumptions.
4. Recommend a food or alternatives; explain calorie/protein implications and satiety.
5. Ask user whether to log it. Do not log proposed meals as consumed without confirmation.
6. Recalculate remaining daily totals only after confirmation.
7. Use online AI only when local knowledge and clarification are insufficient, with opt-in and a usage budget.

## Safety and quality
- Avoid rigid permission language, food guilt, punitive restriction or claiming the coach is a registered dietitian.
- Consider allergies, medical restrictions, eating-disorder risk and user preferences when known; ask when relevant.
- A calorie target is adjustable and provisional, not a hard prohibition.
- Nutrient values are estimates with serving size and source; never invent exact portion weights.
- Explicitly distinguish *planned*, *suggested* and *eaten* meals.
- In offline mode, offer reliable deterministic guidance based on stored data and clearly say when context is missing.
- For repeated known questions, use rules, retrieval and local model first (zero cloud tokens).

## UI
- AI Coach chat tab with input and suggested prompts.
- "Log this" and "Show alternatives" actions.
- Visible local/cloud mode, clear cloud consent, and daily request usage counter.
- Explanation card: estimated calories, protein, remaining daily totals, confidence and assumptions.

## Initial acceptance criteria
- "Can I eat an apple now?" responds with a grounded estimate and context, without automatically logging it.
- "Log the apple" adds a single confirmed food entry.
- Repeated question with same known context triggers zero cloud calls.
- Missing today's log is disclosed instead of pretending it is complete.
- Cloud disabled or budget exhausted still permits basic advice.
- Changes to logged meals immediately change recommendations.

## Status
Specification only. No on-device coach or cloud AI implementation verified yet.
