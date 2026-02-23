# Reflect

A privacy-first iOS journaling app for daily self-reflection and processing meaningful experiences.

## Features

- **Daily Check-ins**: Track mood, energy, stress, and sleep with optional notes and voice recordings
- **Deep Reflection Sessions**: Guided 3-step flow (Capture → Meaning → Next Step) for processing emotionally intense experiences
- **AI Lenses** (optional): Grounding, Meaning, and Integration perspectives on your entries
- **Moments Gallery**: Save and revisit highlights from your journal with tags, emotions, and themes
- **Weekly Reflection Letter**: Auto-generated summary of your week with themes, key moments, and gentle questions
- **App Lock**: FaceID/TouchID/passcode protection
- **Export**: JSON and plain text export of all data
- **Delete All**: Irreversible wipe for full data control

## Privacy Posture

- **Local-first**: All data stored on-device using SwiftData. No server-side storage.
- **No tracking**: Zero analytics, ads, or third-party SDKs.
- **AI is optional**: Disabled by default. When enabled, uses a local stub provider (no network calls in MVP).
- **User controls**: Export, per-entry delete, delete-all, avoid-topics, app lock.
- **Safety layer**: On-device content filtering blocks disallowed content and detects crisis signals.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Build & Run

1. Open `Reflect/` in Xcode (File → Open → select the `Reflect` folder)
2. Select an iOS simulator or device
3. Build and run (⌘R)

No external dependencies — the project uses only Apple frameworks:
- SwiftUI, SwiftData, LocalAuthentication, AVFoundation

## Project Structure

```
Reflect/
├── Reflect/
│   ├── ReflectApp.swift          # App entry point + lock gate
│   ├── ContentView.swift         # Tab navigation
│   ├── Models/                   # SwiftData models
│   ├── Services/                 # Business logic
│   ├── ViewModels/               # MVVM view models
│   ├── Views/                    # SwiftUI views by tab
│   │   ├── Today/                # Daily check-in
│   │   ├── Reflect/              # Deep reflection sessions
│   │   ├── Moments/              # Moments gallery
│   │   ├── Insights/             # Trends + weekly letter
│   │   ├── Settings/             # App settings
│   │   ├── Safety/               # Crisis resources
│   │   └── Components/           # Reusable UI
│   └── Resources/                # Design system + strings
├── ReflectTests/                 # Unit tests
└── docs/                         # Safety documentation
```

## Testing

Run tests in Xcode:
- ⌘U to run all tests
- Or: Product → Test

Test suites:
- `SafetyServiceTests` — Content filtering, crisis detection, AI output filtering
- `ModelTests` — CRUD operations on all SwiftData models
- `WeeklyLetterServiceTests` — Letter generation logic
- `ExportServiceTests` — JSON and text export format verification
- `AIServiceTests` — Stub AI responses and safety compliance

## Architecture

- **MVVM**: Views observe `@Observable` view models. Models are SwiftData `@Model` classes.
- **Services**: Stateless structs/protocols for business logic (Safety, Export, AI, WeeklyLetter).
- **Safety-first**: All user input checked by `SafetyService`. All AI output filtered before display.
- **Testable**: Services are pure functions or protocol-based for easy mocking.

## AI Integration

The AI system uses a protocol (`AIServiceProtocol`) with two implementations:

- `StubAIService` — Local canned responses (default, no network)
- `LiveAIService` — Placeholder for real API integration (currently delegates to stub)

To integrate a real AI provider:
1. Implement `AIServiceProtocol` with your API calls
2. Pass all responses through `SafetyService.filterAIOutput()` before returning
3. Respect `avoidTopics` from user preferences

## Safety

See [docs/AppStoreSafetyNotes.md](docs/AppStoreSafetyNotes.md) for full safety documentation.

Key safety features:
- On-device content filter blocks prohibited topics (patterns are Base64-encoded in source)
- Detects distress signals and shows crisis resources
- Filters all AI output for safety
- Zero prohibited terms appear as plaintext anywhere in source code or metadata

## License

Private — all rights reserved.
