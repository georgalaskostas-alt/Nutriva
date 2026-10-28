# Nutriva — Local-First Hybrid AI Architecture

## Objective
Native SwiftUI iPhone app with near-zero routine cloud inference cost. A cloud LLM is a controlled fallback, not the primary food calculator.

## Decision path
1. Normalize user input locally; search personal saved meals and aliases.
2. Match verified foods/recipes in an on-device nutrition database.
3. Use an eligible on-device language model for intent and ingredient extraction where supported; fall back to deterministic forms and search where unavailable.
4. Compute energy and protein deterministically from nutrient values per 100 g and confirmed portions. Record source, assumptions and confidence.
5. Ask the user about missing portion size, oil, sauces and ingredients before considering a cloud call.
6. Escalate to the online model only for genuinely unresolved cases or when explicitly requested; send minimum necessary data with consent.
7. Present results for user confirmation; save reusable recipe and alias for subsequent zero-token matches.

## Model selection
- Prefer Apple's on-device Foundation Models framework on supported OS/hardware, after capability checks.
- Core ML / compact bundled model is an alternative subject to device benchmarks, licensing and download size.
- Never assume on-device generative AI is supported on every iPhone.
- Local-first does not imply all image recognition works offline: phase separately and test.

## Memory
- SavedMeal: id, ownerId, normalized aliases, ingredients, quantities, nutrients, verifiedAt, provenance.
- FoodEntry: id, ownerId, date, consumed quantity, nutrient snapshot, estimated/confirmed flag.
- Correction: original extraction, corrected structured meal, user confirmation, timestamps.
- Prefer retrieval and rule improvements over claims of automatic neural-network training.
- Store locally with SwiftData; sync per user only after secure auth and authorization are ready.

## Cloud fallback policy
- Off by default until backend and consent controls are ready.
- Ask clarification first. Cloud requests require clear UI indicator, per-day request cap and configurable monthly budget.
- API keys stay on backend; enforce authentication, rate limiting and user ownership.
- No raw medical/health history or photos sent by default.
- Cache safe, normalized, confirmed interpretations; never silently treat model guesses as nutrition facts.

## Acceptance tests
- Repeated confirmed meal: 0 cloud calls and same nutrition values.
- Unknown portion: asks question instead of inventing grams.
- Offline: saved meals and manual logging still work.
- Unsupported on-device model: graceful manual logging fallback.
- Cloud disabled / budget reached: no network inference.
- Cross-user memory isolation and secure sync.
- Food calculations reproducible from ingredients and quantities.

## Delivery order
1. Local food library, meal aliases, portion confirmation and SwiftData.
2. Shift-aware daily meal planning and local nutrition calculations.
3. On-device intent parsing with device capability detection.
4. Secure online AI fallback for unresolved inputs.
5. Optional photo workflow and controlled personalization.

## Status
Architecture approved; implementation not yet verified in Xcode. Existing prototype currently uses UserDefaults and manual food entry.
