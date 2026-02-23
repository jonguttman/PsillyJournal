# Reflect – SwiftUI iOS App Implementation Plan

## Overview

Replace the existing React Native "PsillyJournal" app with a native SwiftUI iOS app called **Reflect**. The new app uses entirely App Store-safe language and is a privacy-first journaling app with Daily Check-ins, Deep Reflection Sessions, AI Lenses, Moments gallery, and Weekly Reflection Letters.

**Key constraint**: We're on a Linux environment without Xcode, so we'll create the full Xcode project structure and all Swift source files. The project will compile when opened in Xcode on macOS. We'll include an `.xcodeproj` via Swift Package Manager-style or create a proper directory layout that Xcode can open.

**Approach**: Create a new `Reflect/` directory at the repo root containing the complete iOS app. The existing React Native code stays untouched (it can be removed later by the team).

---

## Phase 1: Project Scaffold & Folder Structure

Create the Xcode project skeleton:

```
Reflect/
├── Reflect.xcodeproj/           # Generated or manual project file
├── Reflect/
│   ├── ReflectApp.swift         # @main App entry point
│   ├── ContentView.swift        # Root TabView
│   ├── Info.plist               # App configuration
│   ├── Models/
│   │   ├── CheckIn.swift        # Daily check-in model
│   │   ├── ReflectionSession.swift  # Deep reflection session model
│   │   ├── Moment.swift         # Saved moment/highlight model
│   │   ├── WeeklyLetter.swift   # Weekly reflection letter model
│   │   ├── LensResponse.swift   # AI lens response model
│   │   └── UserPreferences.swift    # User settings/boundaries
│   ├── Services/
│   │   ├── SafetyService.swift      # Content filtering + crisis detection
│   │   ├── AIService.swift          # AI interface + stub provider
│   │   ├── ExportService.swift      # JSON + text export
│   │   ├── LockService.swift        # FaceID/TouchID/passcode
│   │   ├── WeeklyLetterService.swift # Letter generation logic
│   │   └── PersistenceService.swift  # SwiftData container setup
│   ├── ViewModels/
│   │   ├── TodayViewModel.swift
│   │   ├── CheckInViewModel.swift
│   │   ├── ReflectionViewModel.swift
│   │   ├── MomentsViewModel.swift
│   │   ├── InsightsViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── Today/
│   │   │   ├── TodayView.swift
│   │   │   └── CheckInFormView.swift
│   │   ├── Reflect/
│   │   │   ├── ReflectTabView.swift
│   │   │   ├── ReflectionSetupView.swift
│   │   │   ├── ReflectionStepView.swift
│   │   │   └── ReflectionDetailView.swift
│   │   ├── Moments/
│   │   │   ├── MomentsGalleryView.swift
│   │   │   ├── MomentCardView.swift
│   │   │   └── SaveMomentView.swift
│   │   ├── Insights/
│   │   │   ├── InsightsView.swift
│   │   │   ├── TrendsView.swift
│   │   │   └── WeeklyLetterView.swift
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   ├── PrivacySettingsView.swift
│   │   │   └── AISettingsView.swift
│   │   ├── Safety/
│   │   │   └── CrisisResourcesView.swift
│   │   └── Components/
│   │       ├── MetricSliderView.swift
│   │       ├── TagPickerView.swift
│   │       ├── VoiceNoteButton.swift
│   │       ├── LensResponseCard.swift
│   │       └── EmptyStateView.swift
│   └── Resources/
│       ├── DesignSystem.swift       # Spacing, typography, colors
│       └── Strings.swift            # User-facing copy constants
├── ReflectTests/
│   ├── SafetyServiceTests.swift
│   ├── ModelTests.swift
│   ├── WeeklyLetterServiceTests.swift
│   ├── ExportServiceTests.swift
│   └── AIServiceTests.swift
└── docs/
    └── AppStoreSafetyNotes.md
```

**Files to create**: ~45 Swift files + project config + docs + README

---

## Phase 2: Models + Persistence (SwiftData)

Create all `@Model` classes with SwiftData:

1. **CheckIn** – mood (1–10), energy (1–10), stress (1–10), sleepHours (Double), sleepQuality (1–10), note (String?), voiceNotePath (String?), createdAt (Date), updatedAt (Date)
2. **ReflectionSession** – title, intensity (0–10), environment (enum: home/outdoors/quiet_space/other), support (enum: solo/trusted_person/professional), themeTags ([String]), notes (String?), voiceNotePath (String?), captureResponse (String), meaningResponse (String), nextStepResponse (String), createdAt, updatedAt
3. **Moment** – quote (<=240 chars), themes ([String]), emotions ([String]), intensity (0–10), askOfMe (String, 1 line), sourceType (enum: checkIn/reflection), sourceId (String), createdAt
4. **WeeklyLetter** – startDate, endDate, themes ([String]), moments (String), questions (String), commitment (String), fullText (String), createdAt
5. **LensResponse** – entryType (enum), entryId (String), lensType (enum: grounding/meaning/integration), content (String), createdAt
6. **UserPreferences** – singleton: aiEnabled (Bool), selectedLens (enum?), tone (enum: gentle/direct), avoidTopics ([String]), appLockEnabled (Bool), lastExportDate (Date?)

Set up `ModelContainer` in the App entry point with all models registered.

---

## Phase 3: Core Services

### 3a. SafetyService
- `checkContent(_ text: String) -> SafetyResult` – returns `.safe`, `.blocked(reason)`, or `.crisisDetected`
- Keyword/pattern matching for disallowed content (prohibited topics, prohibited behavior, health-related claims)
- Self-harm detection (keyword list + patterns)
- `filterAIOutput(_ text: String) -> String` – strips disallowed content or returns fallback
- All pure functions, highly testable

### 3b. LockService
- Wraps `LAContext` from LocalAuthentication framework
- `authenticate() async -> Bool`
- `canUseBiometrics() -> Bool`
- Graceful degradation if biometrics unavailable

### 3c. ExportService
- `exportToJSON(checkIns:sessions:moments:) -> Data`
- `exportToText(checkIns:sessions:moments:) -> String`
- Uses `Codable` for JSON, formatted strings for text
- File sharing via `ShareLink` or `UIActivityViewController`

### 3d. AIService (protocol + stub)
- Protocol: `AIServiceProtocol` with `generateLensResponse(entry:lens:preferences:) async throws -> String`
- `StubAIService`: returns canned responses per lens type
- `LiveAIService`: placeholder with TODO for real API integration
- Respects `avoidTopics` from preferences
- All output run through `SafetyService.filterAIOutput`

### 3e. WeeklyLetterService
- `generateLetter(checkIns:sessions:moments:dateRange:) -> WeeklyLetter`
- Pure function: extracts top 3 themes, picks 3 moments, generates 2 questions, 1 commitment
- Local-only logic (no AI required for MVP)

### 3f. PersistenceService
- SwiftData `ModelContainer` + `ModelContext` setup
- `deleteAllData()` – irreversible wipe
- Per-entry delete support

---

## Phase 4: Core UI – Tab Bar + Empty States

1. **ReflectApp.swift**: `@main` App with ModelContainer, app lock gate
2. **ContentView.swift**: `TabView` with 5 tabs (Today, Reflect, Moments, Insights, Settings)
3. Each tab view with proper icons and empty states
4. **DesignSystem.swift**: spacing constants, font styles, color palette
5. **Strings.swift**: all user-facing copy (App Store-safe language only)

---

## Phase 5: Daily Check-in Flow

1. **TodayView**: CTA card to start check-in, recent moment preview, last check-in summary
2. **CheckInFormView**: mood/energy/stress sliders (MetricSliderView), sleep hours + quality, text note field, voice note button (AVAudioRecorder), save/cancel
3. **TodayViewModel**: CRUD operations on CheckIn model, validation
4. **CheckInViewModel**: form state management, save logic
5. Edit/delete existing check-ins

---

## Phase 6: Deep Reflection Session Flow

1. **ReflectTabView**: list of past sessions + "Start New Session" CTA
2. **ReflectionSetupView**: title, intensity slider, environment picker, support picker, theme tags, notes/voice
3. **ReflectionStepView**: 3-step guided flow (Capture → Meaning → Next Step) with text input per step
4. **ReflectionDetailView**: view saved session with all fields + lens responses
5. **ReflectionViewModel**: manages setup → steps → save flow, integrates with AIService for optional lens responses

---

## Phase 7: Moments

1. **SaveMomentView**: sheet to create moment from any entry – quote field (240 char limit), theme/emotion tags, intensity, "What this asks of me"
2. **MomentsGalleryView**: grid/list of moments with filters (tag, date, source type)
3. **MomentCardView**: compact card showing quote + tags
4. **MomentsViewModel**: CRUD, filtering, sorting

---

## Phase 8: Weekly Letter + Insights

1. **InsightsView**: tab showing 7-day averages for check-in metrics (mood, energy, stress, sleep) + weekly letter section
2. **TrendsView**: simple bar/line representation of last 7 days (SwiftUI Charts if available, else simple bars)
3. **WeeklyLetterView**: generate/view/regenerate letter, export button
4. **InsightsViewModel**: aggregates check-in data, drives letter generation

---

## Phase 9: AI Stubs + Wiring

1. Implement `StubAIService` with thoughtful canned responses per lens
2. Wire AI toggle in Settings → when enabled, show lens selection
3. On entry save (if AI enabled): generate up to 3 lens responses via AIService
4. Display `LensResponseCard` under entries in detail views
5. All AI output filtered through SafetyService

---

## Phase 10: Settings + Privacy

1. **SettingsView**: sections for Privacy, AI, Data, About
2. **PrivacySettingsView**: app lock toggle (triggers LockService), boundaries (avoid topics)
3. **AISettingsView**: AI enabled toggle, lens selection, tone preference
4. Export buttons (JSON + text) via ExportService
5. "Delete All Data" with confirmation alert (irreversible)
6. App lock gate on app launch

---

## Phase 11: Safety Layer Integration

1. Wire SafetyService into all text input points
2. Check user input on save (check-in notes, reflection responses)
3. If self-harm detected → present CrisisResourcesView as sheet
4. If disallowed content → show alert with safe alternative message
5. Filter all AI output before display
6. **CrisisResourcesView**: emergency guidance, US crisis hotlines, generic "call local emergency services"

---

## Phase 12: Voice Notes

1. `VoiceNoteButton` component using AVAudioRecorder
2. Record/stop/play controls
3. Store audio files in app's documents directory
4. Link file path to CheckIn or ReflectionSession
5. Basic playback with AVAudioPlayer

---

## Phase 13: Tests

1. **SafetyServiceTests**: test blocked content detection, self-harm detection, safe content passes, AI output filtering
2. **ModelTests**: create/read/update/delete for each model (in-memory SwiftData container)
3. **WeeklyLetterServiceTests**: test letter generation with known inputs, edge cases (no data, partial data)
4. **ExportServiceTests**: test JSON/text export format correctness
5. **AIServiceTests**: test stub responses, safety filtering of output

---

## Phase 14: Documentation

1. **README.md** at repo root: build/run/test instructions, privacy posture, architecture overview
2. **docs/AppStoreSafetyNotes.md**: prohibited language/behaviors list, how the app complies, safety layer description

---

## Phase 15: Build Verification & Cleanup

1. Verify all files have correct imports and compile (manual review)
2. Ensure no prohibited language anywhere in source
3. Ensure all user-facing strings use App Store-safe language
4. Final commit and push

---

## File Creation Order (Execution Plan)

The implementation will proceed in this order, creating files in logical dependency order:

| Step | Files | Description |
|------|-------|-------------|
| 1 | Project structure, Info.plist, ReflectApp.swift | Scaffold |
| 2 | DesignSystem.swift, Strings.swift | Resources |
| 3 | All Models/*.swift | Data models |
| 4 | PersistenceService.swift | SwiftData setup |
| 5 | SafetyService.swift | Safety layer |
| 6 | LockService.swift | App lock |
| 7 | ExportService.swift | Export |
| 8 | AIService.swift | AI interface + stub |
| 9 | WeeklyLetterService.swift | Letter generation |
| 10 | Components/*.swift | Reusable UI components |
| 11 | ContentView.swift + all tab views (empty states) | Navigation shell |
| 12 | ViewModels/*.swift | All view models |
| 13 | Today/ views + CheckIn flow | Daily check-in |
| 14 | Reflect/ views + session flow | Deep reflection |
| 15 | Moments/ views | Moments gallery |
| 16 | Insights/ views + weekly letter | Insights tab |
| 17 | Settings/ views | Settings screens |
| 18 | Safety/CrisisResourcesView.swift | Crisis screen |
| 19 | VoiceNoteButton integration | Voice notes |
| 20 | All test files | Unit tests |
| 21 | README.md, docs/AppStoreSafetyNotes.md | Documentation |
| 22 | Final review + commit + push | Delivery |

---

## Estimated File Count
- ~45 Swift source files
- ~5 test files
- ~3 documentation/config files
- Total: ~53 files

## Key Decisions
- **SwiftData** over CoreData (modern, less boilerplate, iOS 17+)
- **No external dependencies** – pure SwiftUI + Apple frameworks only
- **Stub AI** – real API integration left as TODO with clean interface
- **Voice notes** – record/play only, no transcription in MVP
- **Charts** – use Swift Charts framework (iOS 16+) for trends if available, else simple custom bars
- **Existing RN code untouched** – new app lives in `Reflect/` directory
