# Testing Post-Dose Check-In

## Option 1: Simulate Notification (Manual Navigation)

1. After completing pre-dose, find your dose ID in browser console or localStorage
2. Manually navigate to: `/check-in/post-dose?dose_id=YOUR_DOSE_ID&entry_id=YOUR_ENTRY_ID`
3. This simulates clicking the notification

## Option 2: Temporarily Shorten Notification Timing

Edit `src/services/notificationService.ts` line 11:
```typescript
export const NOTIFICATION_TIMING = {
  '2h': 10 * 1000,   // 10 seconds for testing
  '4h': 20 * 1000,   // 20 seconds for testing
  '6h': 30 * 1000,   // 30 seconds for testing
  '8h': 40 * 1000,   // 40 seconds for testing
};
```

Then wait 10-20 seconds after logging a dose.

## What to Test on Post-Dose Screen

### Visual Elements
- ✅ Shows ✨ icon
- ✅ Title: "How was your experience?"
- ✅ Cooler color scheme (blue/purple)
- ✅ Indigo "Save reflection" button

### Sliders
- ✅ Energy: "low" ↔ "high"
- ✅ Clarity: "foggy" ↔ "clear"
- ✅ Mood: "difficult" ↔ "good"
- ✅ All start at 5/10

### Context Capture Section
- ✅ Shows divider line above
- ✅ Label: "Optional: What were you doing?"
- ✅ Hint text: "Helps you discover patterns later"
- ✅ 8 activity tags with emojis (multi-select):
  - 🚶 Moving, 🧘 Still, 👥 Social, 🎨 Creating
  - 🤔 Thinking, 🌳 Nature, 🏠 Home, 💼 Work
- ✅ Tags turn purple when selected
- ✅ Can select multiple tags
- ✅ Optional text field: "Any details? (50 char max)"
- ✅ Character counter shows: 0/50

### Test Cases
1. **Save with just sliders** (no tags or notes)
2. **Save with tags selected** (try selecting 2-3)
3. **Save with notes** (type some text, verify 50 char limit)
4. **Save with everything** (sliders + tags + notes)

## Verify Data Persistence

Open browser DevTools → Application → Local Storage → localhost:
- Find the entry in `psilly_entries`
- Check for:
  - `postDoseMetrics`: `{"energy":7,"clarity":8,"mood":6}`
  - `contextActivity`: `["moving","nature","social"]`
  - `contextNotes`: "Went hiking with friends"
  - `checkInCompleted`: true
