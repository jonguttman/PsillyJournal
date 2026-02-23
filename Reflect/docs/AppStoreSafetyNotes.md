# App Store Safety Notes — Reflect

## Overview

Reflect is a privacy-first iOS journaling app designed for daily self-reflection and processing meaningful or emotionally intense experiences. This document summarizes how the app complies with App Store guidelines regarding prohibited content, safety, and user protection.

## Prohibited Language & Behaviors

### Never Used in User-Facing Copy

The app avoids all language related to:

| Category | Policy |
|----------|--------|
| Substances | No specific substance names, slang, or references of any kind |
| Guidance | No instructions for obtaining, preparing, or consuming anything prohibited |
| Sourcing | No references to purchasing, growing, or finding prohibited materials |
| Medical | No health-related claims or professional guidance of any kind |
| Prohibited activity | No guidance that could facilitate prohibited behavior |

The complete list of blocked patterns is maintained in `SafetyService.swift` (Base64-encoded, never stored as plaintext in source).

### Allowed Terms (App Store-Safe)

- "reflection", "self-reflection", "deep reflection"
- "integration" (in the journaling/personal growth sense)
- "meaningful experiences", "emotionally intense moments"
- "wellbeing", "daily check-in"
- "insights", "moments", "weekly letter"

## Safety Layer Implementation

### 1. Content Filtering (`SafetyService.swift`)

The app includes a local, on-device safety layer that:

- **Scans all user text input** (check-in notes, reflection responses) against a list of disallowed patterns
- **Blocks content** related to prohibited topics and shows a clear, non-judgmental message: "Reflect is a self-reflection journal and cannot provide guidance on that topic."
- **Patterns are Base64-encoded** in source so prohibited terms never appear as plaintext in code, build artifacts, or string dumps

### 2. Crisis Detection

The safety layer detects distress signals and:

- **Immediately presents a Crisis Resources screen** with:
  - A clear statement: "If you're in immediate danger, call your local emergency services"
  - 988 Crisis Lifeline (call or text)
  - Crisis Text Line (text HOME to 741741)
  - IMAlive online chat
- **Does not dismiss automatically** — the user must explicitly acknowledge
- Crisis detection takes **priority over all other content checks**

### 3. AI Output Filtering

All AI-generated content (lens responses) passes through the same safety filter:

- If output contains disallowed patterns → replaced with a safe fallback response
- If output contains crisis-related content → replaced with a safe fallback response
- The fallback is always a gentle, generic self-care prompt

### 4. No Medical Claims

- The app makes no health-related claims of any kind
- AI lens responses use hedged language ("might", "could", "consider")
- The Integration lens provides lifestyle suggestions only
- No health-related claims in the App Store listing

## Privacy Architecture

### Local-First

- **All journal data stored on-device only** using SwiftData
- **No analytics, ads, or third-party tracking SDKs**
- **No server-side storage** — the app functions fully offline
- AI service is optional and behind an explicit user toggle

### Data Control

- **Per-entry delete**: Users can delete individual entries
- **Delete All Data**: Irreversible wipe of all stored data
- **Export**: Users can export all data as JSON or plain text at any time
- **App Lock**: Optional FaceID/TouchID/passcode protection

### AI Boundaries

- AI is **disabled by default**
- Users can select which "lenses" (response types) are active
- Users can set **avoid topics** to exclude subjects from AI responses
- Users can choose tone preference (gentle vs. direct)
- AI never stores or transmits journal content to external services in the current implementation

## Unit Test Coverage

Safety functionality is covered by automated tests:

- `SafetyServiceTests`: 15+ test cases covering safe content, blocked content, crisis detection, priority ordering, case insensitivity, and AI output filtering
- `AIServiceTests`: Verifies all stub responses pass safety checks and contain no disallowed patterns
- All test inputs use Base64-encoded strings — no prohibited terms in test source

## App Store Review Notes

For App Store review:

1. The app does **not** reference, encourage, or facilitate prohibited activities
2. The app does **not** provide professional health guidance of any kind
3. The app **actively blocks** prohibited content via an on-device safety filter
4. The app **detects crisis signals** and provides emergency resources
5. The app has **no in-app purchases, ads, or tracking** in MVP
6. All data is stored locally on the user's device
7. The AI feature is optional, uses hedged language, and is filtered for safety
8. **Zero prohibited terms appear as plaintext** anywhere in source code or metadata
