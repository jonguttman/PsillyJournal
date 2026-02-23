import Foundation

/// All user-facing copy in one place.
/// App Store-safe language only. See docs/AppStoreSafetyNotes.md for policy.
enum Strings {
    // MARK: - App
    static let appName = "Reflect"
    static let appTagline = "Your private space for self-reflection"

    // MARK: - Tabs
    static let tabToday = "Today"
    static let tabReflect = "Reflect"
    static let tabMoments = "Moments"
    static let tabInsights = "Insights"
    static let tabSettings = "Settings"

    // MARK: - Today Tab
    static let todayGreeting = "How are you today?"
    static let todayCheckInCTA = "Start Daily Check-in"
    static let todayRecentMoment = "Recent Moment"
    static let todayLastCheckIn = "Last Check-in"
    static let todayNoCheckIns = "No check-ins yet"
    static let todayNoCheckInsBody = "Start your first daily check-in to begin tracking your wellbeing."

    // MARK: - Check-in
    static let checkInTitle = "Daily Check-in"
    static let checkInMood = "Mood"
    static let checkInEnergy = "Energy"
    static let checkInStress = "Stress"
    static let checkInSleepHours = "Sleep (hours)"
    static let checkInSleepQuality = "Sleep Quality"
    static let checkInNote = "Any thoughts you'd like to capture..."
    static let checkInVoiceNote = "Voice Note"
    static let checkInSave = "Save Check-in"
    static let checkInEdit = "Edit Check-in"
    static let checkInDelete = "Delete Check-in"
    static let checkInDeleteConfirm = "Are you sure? This cannot be undone."

    // MARK: - Deep Reflection
    static let reflectTitle = "Deep Reflection"
    static let reflectStartCTA = "Start Reflection Session"
    static let reflectSetupTitle = "Set the Scene"
    static let reflectSessionTitle = "Session Title"
    static let reflectIntensity = "Intensity"
    static let reflectEnvironment = "Environment"
    static let reflectSupport = "Support"
    static let reflectThemes = "Themes"
    static let reflectNotes = "Notes"
    static let reflectNoSessions = "No reflection sessions yet"
    static let reflectNoSessionsBody = "Deep reflection helps you process meaningful and emotionally intense experiences."

    // Guided steps
    static let reflectStepCapture = "What stands out most from this experience?"
    static let reflectStepMeaning = "What might this be pointing to in your life?"
    static let reflectStepNextStep = "What's one small action that honors this insight?"
    static let reflectStepCaptureTitle = "Capture"
    static let reflectStepMeaningTitle = "Meaning"
    static let reflectStepNextStepTitle = "Next Step"

    // MARK: - Moments
    static let momentsTitle = "Moments"
    static let momentsSaveCTA = "Save Moment"
    static let momentsQuote = "Quote or highlight"
    static let momentsQuoteHint = "Up to 240 characters"
    static let momentsThemes = "Themes"
    static let momentsEmotions = "Emotions"
    static let momentsAskOfMe = "What this asks of me"
    static let momentsNoMoments = "No moments saved"
    static let momentsNoMomentsBody = "Save highlights from your check-ins and reflections to revisit later."

    // MARK: - Insights
    static let insightsTitle = "Insights"
    static let insightsTrends = "7-Day Trends"
    static let insightsAverage = "Average"
    static let insightsWeeklyLetter = "Weekly Reflection Letter"
    static let insightsGenerateLetter = "Generate Letter"
    static let insightsRegenerateLetter = "Regenerate"
    static let insightsNoData = "Not enough data"
    static let insightsNoDataBody = "Complete a few daily check-ins to see your trends."

    // MARK: - Weekly Letter
    static let weeklyLetterTitle = "Your Weekly Reflection"
    static let weeklyLetterThemes = "Themes This Week"
    static let weeklyLetterMoments = "Key Moments"
    static let weeklyLetterQuestions = "Questions to Sit With"
    static let weeklyLetterCommitment = "A Small Commitment"
    static let weeklyLetterExport = "Export Letter"

    // MARK: - AI / Lenses
    static let aiEnabled = "AI Reflections"
    static let aiDisabledNote = "App works fully offline. AI adds optional reflection lenses."
    static let lensGrounding = "Grounding"
    static let lensGroundingDesc = "Supportive reflection with gentle self-care reminders"
    static let lensMeaning = "Meaning"
    static let lensMeaningDesc = "Explore possible interpretations of your experience"
    static let lensIntegration = "Integration"
    static let lensIntegrationDesc = "A gentle 7-day plan for bringing insights into daily life"
    static let lensToneGentle = "More gentle"
    static let lensToneDirect = "More direct"

    // MARK: - Settings
    static let settingsTitle = "Settings"
    static let settingsPrivacy = "Privacy & Security"
    static let settingsAI = "AI Reflections"
    static let settingsData = "Your Data"
    static let settingsExportJSON = "Export as JSON"
    static let settingsExportText = "Export as Text"
    static let settingsDeleteAll = "Delete All Data"
    static let settingsDeleteAllConfirm = "This will permanently delete all your entries, sessions, moments, and letters. This action cannot be undone."
    static let settingsAppLock = "App Lock"
    static let settingsAppLockDesc = "Require Face ID or passcode to open Reflect"
    static let settingsBoundaries = "Boundaries"
    static let settingsAvoidTopics = "Topics to Avoid"
    static let settingsAvoidTopicsHint = "Comma-separated list of topics the AI should not discuss"
    static let settingsTone = "Response Tone"
    static let settingsAbout = "About Reflect"
    static let settingsVersion = "Version"

    // MARK: - Safety / Crisis
    static let crisisTitle = "You're Not Alone"
    static let crisisBody = "It sounds like you may be going through a really difficult time. Please reach out to someone who can help."
    static let crisisEmergency = "If you're in immediate danger, call your local emergency services."
    static let crisisHotlineUS = "988 Crisis Lifeline"
    static let crisisHotlineUSNumber = "988"
    static let crisisCrisisTextLine = "Crisis Text Line"
    static let crisisCrisisTextLineInfo = "Text HOME to 741741"
    static let crisisIMAlive = "IMAlive Chat"
    static let crisisIMAliveInfo = "Online chat support"
    static let crisisDismiss = "I'm okay, continue"

    // MARK: - Safety Blocking
    static let safetyBlockedTitle = "Content Not Supported"
    static let safetyBlockedBody = "Reflect is a self-reflection journal and cannot provide guidance on that topic. Please rephrase or try a different reflection."

    // MARK: - General
    static let save = "Save"
    static let cancel = "Cancel"
    static let delete = "Delete"
    static let edit = "Edit"
    static let done = "Done"
    static let next = "Next"
    static let back = "Back"
    static let export_ = "Export"
    static let share = "Share"
    static let noResults = "No results"
    static let loading = "Loading..."
    static let retry = "Retry"
    static let emptyState = "Nothing here yet"
}
