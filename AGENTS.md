# Reflect – Agent Instructions (AGENTS.md)

## Prime directive
Ship a privacy-first iOS journaling app. Do not introduce drug/psychedelic framing, dosing guidance, illegal activity instructions, or medical claims.

## Workflow
- Work in small, reviewable slices.
- Prefer adding/expanding unit tests alongside features.
- Keep changes scoped to the current task.

## Commands
- Build: Xcode build (or xcodebuild) as appropriate.
- Tests: run unit tests frequently; keep them green.

## Code style
- SwiftUI + MVVM-ish separation (Views vs ViewModels vs Services).
- Keep business logic out of Views.
- Prefer pure functions for formatting and summary generation.

## Safety rails
- If user text asks for illegal activity or dosing: refuse with a safe reflection alternative.
- If self-harm intent: show crisis resources screen.
- Filter AI output; if disallowed, regenerate or fallback.

## Data handling
- Local-first by default.
- No analytics/ads SDKs.
- Provide export + delete-all.
