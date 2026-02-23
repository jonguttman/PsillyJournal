# Bug Log

## BUG-001: App letterboxed with black bars — content clipped at edges

**Date:** 2026-02-23

**Symptoms:**
- Black bars visible above (between Dynamic Island and content) and below (under tab bar) the app content
- Text cut off at left edge ("G" in "Good morning", "H" in "How are you today?")
- "Edit" button too close to right edge
- App appeared to render at a smaller resolution than the device screen
- Landscape orientation did NOT have the clipping issue (wider screen masked the problem)

**Root Cause:**
Missing `UILaunchScreen` key in `Info.plist`. Without this key, iOS assumes the app was built for older/smaller screen sizes and renders it in a **legacy compatibility mode** — letterboxing the app with black bars to fit a smaller virtual screen inside the actual display. This made it look like margins were too small and text was clipped, when in reality the entire app was being rendered in a shrunken frame.

**Fix:**
Added an empty `UILaunchScreen` dictionary to `Reflect/Info.plist`:
```xml
<key>UILaunchScreen</key>
<dict/>
```
This tells iOS the app natively supports the full device screen at all sizes. No launch storyboard file is needed — the empty dict is sufficient.

**Misdiagnoses along the way:**
- Increased horizontal padding multiple times (16 → 24 → 32 → 60pt) — no effect because the rendering frame itself was too small
- Added `.scrollClipDisabled()` — irrelevant
- Added extra `.padding(.leading, 4)` for "serif glyph overhangs" — irrelevant
- Restructured background modifiers (`.warmBackground()` → ZStack → `.background()`) — irrelevant
- Added `.frame(maxWidth: .infinity)` to force width — irrelevant

**Lessons Learned:**

1. **Always add `UILaunchScreen` to Info.plist for new iOS projects.** This is the #1 thing to check when an app appears letterboxed or doesn't fill the screen. An empty `<dict/>` is all that's needed — no storyboard required.

2. **When content appears clipped on ALL sides equally, suspect the rendering frame, not the margins.** The clue was that increasing padding had no visible effect and the user reported black bars on all four sides. This points to a viewport/frame issue, not a padding issue.

3. **The landscape test was the key diagnostic.** The user noted that rotating to landscape fixed the clipping. This was a strong signal that the app's virtual screen size was wrong — in landscape, a legacy-sized frame happens to be wider, so horizontal clipping disappears.

4. **xcodegen-generated projects may not include `UILaunchScreen` by default.** When generating an Xcode project from `project.yml`, verify the Info.plist contains this key. Native Xcode project templates include it automatically, but code-gen tools may not.

5. **Don't chase padding when the problem is structural.** Multiple rounds of padding adjustments were wasted effort. Before tweaking spacing, verify the app is actually rendering at the expected resolution by checking for letterboxing or scale issues.

**Prevention:**
- Add `UILaunchScreen` to the Info.plist template or `project.yml` info section for all new iOS projects
- When debugging layout issues, first confirm the app fills the full screen before adjusting margins
