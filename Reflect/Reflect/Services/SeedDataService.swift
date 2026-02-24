import Foundation
import SwiftData

#if DEBUG
/// Generates realistic sample data for previewing the app.
/// Call `SeedDataService.populate(context:)` to fill the database.
@MainActor
enum SeedDataService {

    static func populate(context: ModelContext) {
        // Clear existing data first
        try? context.delete(model: CheckIn.self)
        try? context.delete(model: ReflectionSession.self)
        try? context.delete(model: Moment.self)
        try? context.delete(model: WeeklyLetter.self)
        try? context.delete(model: LensResponse.self)
        try? context.save()

        let checkIns = insertCheckIns(context: context)
        let sessions = insertReflections(context: context)
        insertMoments(context: context, checkIns: checkIns, sessions: sessions)
        insertWeeklyLetter(context: context)
        insertRoutineData(context: context)

        try? context.save()
    }

    // MARK: - Check-Ins (14 days)

    private static func insertCheckIns(context: ModelContext) -> [CheckIn] {
        let entries: [(daysAgo: Int, mood: Int, energy: Int, stress: Int, sleep: Double, quality: Int, note: String?)] = [
            // Today — feeling good after morning walk
            (0, 8, 7, 3, 7.5, 8, "Walked along the river before sunrise. The mist was incredible."),
            // Yesterday — solid day
            (1, 7, 8, 4, 8.0, 7, "Productive day at work. Made time for a long lunch outside."),
            // 2 days ago — a harder day
            (2, 5, 4, 7, 5.5, 4, "Restless night. Hard to focus. Sat with it instead of pushing through."),
            // 3 days ago — reflective
            (3, 6, 6, 5, 7.0, 6, "Quiet evening. Read for two hours. Mind feels clearer."),
            // 4 days ago — great day
            (4, 9, 8, 2, 8.5, 9, "Deep conversation with an old friend. Felt really seen."),
            // 5 days ago
            (5, 7, 7, 4, 7.0, 7, "Cooked a proper meal for the first time in weeks. Small victory."),
            // 6 days ago — weekend
            (6, 8, 9, 2, 9.0, 8, "Spent the whole day outdoors. No screens until evening."),
            // 7 days ago — low point
            (7, 4, 3, 8, 4.5, 3, "Anxiety crept in around 3am. Journaled until it passed."),
            // 8 days ago
            (8, 6, 5, 6, 6.0, 5, nil),
            // 9 days ago
            (9, 7, 7, 4, 7.5, 7, "Started the day with breathwork. Noticed how much it shifts my baseline."),
            // 10 days ago
            (10, 5, 6, 5, 6.5, 6, "Middling day. Not bad, not great. Learning to be okay with neutral."),
            // 11 days ago — high
            (11, 9, 9, 1, 8.0, 9, "Everything clicked today. Flow state for hours. Grateful."),
            // 12 days ago
            (12, 6, 5, 6, 5.5, 5, "Work stress bleeding into evening. Need better boundaries."),
            // 13 days ago
            (13, 7, 6, 4, 7.0, 7, "Good therapy session. Unpacked some old patterns around avoidance."),
        ]

        var checkIns: [CheckIn] = []
        let calendar = Calendar.current

        for entry in entries {
            let date = calendar.date(byAdding: .day, value: -entry.daysAgo, to: Date())!
            let hour = entry.daysAgo == 0 ? calendar.component(.hour, from: Date()) : Int.random(in: 7...22)
            let minute = Int.random(in: 0...59)
            let createdAt = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!

            let checkIn = CheckIn(
                mood: entry.mood,
                energy: entry.energy,
                stress: entry.stress,
                sleepHours: entry.sleep,
                sleepQuality: entry.quality,
                note: entry.note,
                createdAt: createdAt,
                updatedAt: createdAt
            )
            context.insert(checkIn)
            checkIns.append(checkIn)
        }

        return checkIns
    }

    // MARK: - Reflection Sessions

    private static func insertReflections(context: ModelContext) -> [ReflectionSession] {
        let calendar = Calendar.current
        var sessions: [ReflectionSession] = []

        // Session 1: Recent deep reflection (3 days ago)
        let s1Date = calendar.date(byAdding: .day, value: -3, to: Date())!
        let s1 = ReflectionSession(
            title: "Evening stillness",
            intensity: 6,
            environment: .quietSpace,
            support: .solo,
            themeTags: ["Growth", "Identity"],
            notes: "Lit a candle. Put on ambient music. Let whatever needed to surface come through.",
            captureResponse: "There's a version of myself I keep performing for others — competent, easygoing, together. Tonight I noticed how exhausting it is to maintain that mask. The real me is messier, more uncertain, and honestly more interesting.",
            meaningResponse: "Maybe the exhaustion isn't from life being hard. It's from the gap between who I present and who I actually am. The energy drain is the performance itself.",
            nextStepResponse: "This week, say one honest thing I'd normally smooth over. Just one. See what happens.",
            createdAt: s1Date,
            updatedAt: s1Date
        )
        context.insert(s1)
        sessions.append(s1)

        // Session 2: Nature reflection (6 days ago)
        let s2Date = calendar.date(byAdding: .day, value: -6, to: Date())!
        let s2 = ReflectionSession(
            title: "By the water",
            intensity: 4,
            environment: .outdoors,
            support: .solo,
            themeTags: ["Nature", "Wonder", "Gratitude"],
            notes: "Sat by the creek for an hour. Watched the light change.",
            captureResponse: "The water doesn't try to go anywhere specific. It just follows the path of least resistance and eventually reaches the ocean. I keep trying to force my life into a shape, and maybe that's exactly what's making it so hard.",
            meaningResponse: "Trust the process. Not in a passive way — but in the way that water trusts gravity. Keep moving, stop forcing the direction.",
            nextStepResponse: "When I catch myself forcing an outcome this week, pause. Take three breaths. Ask: what would ease look like here?",
            createdAt: s2Date,
            updatedAt: s2Date
        )
        context.insert(s2)
        sessions.append(s2)

        // Session 3: Integration session (10 days ago)
        let s3Date = calendar.date(byAdding: .day, value: -10, to: Date())!
        let s3 = ReflectionSession(
            title: "After the ceremony",
            intensity: 8,
            environment: .home,
            support: .trustedPerson,
            themeTags: ["Connection", "Purpose", "Change"],
            notes: "Processing with M. Grateful to have someone who understands.",
            captureResponse: "The boundaries I thought were protecting me were actually walls keeping out the very things I need — vulnerability, connection, being truly known. The medicine showed me my own fortress from the outside, and it looked so lonely.",
            meaningResponse: "Protection strategies that served me at 15 are imprisoning me at 32. The world is not as dangerous as my nervous system believes. I can start to lower the drawbridge.",
            nextStepResponse: "Share something vulnerable with one person this week. Not performance vulnerability — real, uncomfortable honesty about something I'm struggling with.",
            createdAt: s3Date,
            updatedAt: s3Date
        )
        context.insert(s3)
        sessions.append(s3)

        return sessions
    }

    // MARK: - Moments

    private static func insertMoments(context: ModelContext, checkIns: [CheckIn], sessions: [ReflectionSession]) {
        let calendar = Calendar.current

        let momentData: [(quote: String, themes: [String], emotions: [String], intensity: Int, ask: String, sourceIdx: Int, isReflection: Bool, daysAgo: Int)] = [
            (
                "The mist on the river felt like the world was still deciding what to become today. I want to live with that openness.",
                ["Nature", "Wonder"],
                ["Awe", "Peace"],
                7,
                "Stay open to not-knowing. Let the day reveal itself.",
                0, false, 0
            ),
            (
                "Being seen by someone who really knows you is terrifying and the most healing thing in the world.",
                ["Connection", "Relationships"],
                ["Love", "Gratitude"],
                8,
                "Let myself be seen more. The real version, not the curated one.",
                4, false, 4
            ),
            (
                "The gap between who I present and who I am is where all my energy goes.",
                ["Identity", "Growth"],
                ["Curiosity", "Sadness"],
                6,
                "Notice when I'm performing. Gently choose authenticity instead.",
                0, true, 3
            ),
            (
                "Water doesn't try to go anywhere specific. It just follows the path and eventually reaches the ocean.",
                ["Nature", "Purpose"],
                ["Peace", "Hope"],
                5,
                "Stop forcing. Move with intention but release the grip on outcomes.",
                1, true, 6
            ),
            (
                "Protection strategies that served me at 15 are imprisoning me at 32.",
                ["Change", "Growth"],
                ["Curiosity", "Fear", "Hope"],
                9,
                "Start lowering the drawbridge. The world is safer than my body believes.",
                2, true, 10
            ),
            (
                "Journaling at 3am: the anxiety isn't about anything specific. It's old fear wearing a new costume.",
                ["Identity", "Challenge"],
                ["Fear", "Curiosity"],
                7,
                "When the old fear visits, greet it. It's trying to protect me from a danger that no longer exists.",
                7, false, 7
            ),
            (
                "Flow state for hours today. This is what it feels like when I stop getting in my own way.",
                ["Creativity", "Purpose"],
                ["Joy", "Gratitude"],
                9,
                "Create the conditions for flow more often. Less planning, more doing.",
                11, false, 11
            ),
        ]

        for data in momentData {
            let date = calendar.date(byAdding: .day, value: -data.daysAgo, to: Date())!
            let sourceId: UUID
            let sourceType: MomentSourceType

            if data.isReflection {
                sourceId = sessions[data.sourceIdx].id
                sourceType = .reflection
            } else {
                sourceId = checkIns[data.sourceIdx].id
                sourceType = .checkIn
            }

            let moment = Moment(
                quote: data.quote,
                themes: data.themes,
                emotions: data.emotions,
                intensity: data.intensity,
                askOfMe: data.ask,
                sourceType: sourceType,
                sourceId: sourceId,
                createdAt: date
            )
            context.insert(moment)
        }
    }

    // MARK: - Weekly Letter

    private static func insertWeeklyLetter(context: ModelContext) {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: -1, to: Date())!
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!

        let letter = WeeklyLetter(
            startDate: startDate,
            endDate: endDate,
            themes: ["Authenticity", "Nature as teacher", "Lowering walls"],
            moments: "You were moved by the mist on the river, by being truly seen by a friend, and by the realization that your protective walls may have outlived their purpose.",
            questions: "What would it feel like to let one person see the version of you that exists behind the performance? And: when you stop forcing the direction, where does the current naturally want to take you?",
            commitment: "This week, I will share one honest, unpolished thing with someone I trust.",
            fullText: """
            Dear You,

            This was a week of contrasts — restless 3am anxiety and sunlit river walks, \
            low-energy days and deep conversations that left you feeling truly seen. \
            The range itself is worth noticing: you're not flattening your experience anymore.

            Three things stood out:

            The mist on the river reminded you that not everything needs to be decided yet. \
            There's beauty in the becoming.

            A friend saw you — really saw you — and instead of deflecting, you let it land. \
            That takes courage you rarely give yourself credit for.

            And in a quiet evening reflection, you named something important: the exhaustion \
            isn't from life being hard. It's from the performance. The gap between the you \
            that shows up and the you that exists underneath.

            Two questions to sit with:

            What would it feel like to let one person see the unperformed version of you? \
            Not the crisis version — just the ordinary, uncertain, figuring-it-out version.

            When you stop forcing the river's direction, where does it naturally want to go?

            Your commitment for the week ahead: share one honest, unpolished thing \
            with someone you trust.

            You're doing the work. Not perfectly — but honestly. And that's what matters.
            """,
            createdAt: endDate
        )
        context.insert(letter)
    }
    // MARK: - Routine Data

    private static func insertRoutineData(context: ModelContext) {
        let calendar = Calendar.current

        // Clear existing routine data
        try? context.delete(model: VerifiedProduct.self)
        try? context.delete(model: RoutineEntry.self)
        try? context.delete(model: RoutineLog.self)
        try? context.delete(model: PendingToken.self)

        // Product 1: Daily supplement — linked with logs
        let product1 = VerifiedProduct(
            productId: "prod_seed_001",
            token: "qr_seedChamomileCalm01abcd",
            name: "Chamomile Calm Blend",
            category: "Herbal Tea",
            productDescription: "A soothing herbal tea blend with chamomile, lavender, and passionflower.",
            batchId: "batch_2024Q1_042",
            verifiedAt: calendar.date(byAdding: .day, value: -14, to: Date())!
        )
        context.insert(product1)

        let entry1 = RoutineEntry(product: product1, schedule: .daily)
        entry1.linkedAt = calendar.date(byAdding: .day, value: -10, to: Date())!
        context.insert(entry1)

        // Log 6 of the last 7 days (skipped 3 days ago)
        for daysAgo in [0, 1, 2, 4, 5, 6] {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let log = RoutineLog(routineEntry: entry1, loggedAt: date)
            context.insert(log)
        }
        // Skipped entry for 3 days ago
        let skipDate = calendar.date(byAdding: .day, value: -3, to: Date())!
        let skipLog = RoutineLog(routineEntry: entry1, loggedAt: skipDate, skipped: true, note: "Ran out, need to restock")
        context.insert(skipLog)

        // Product 2: Weekly supplement
        let product2 = VerifiedProduct(
            productId: "prod_seed_002",
            token: "qr_seedLionsMane01abcdefgh",
            name: "Lion's Mane Extract",
            category: "Functional Mushroom",
            productDescription: "Dual-extracted lion's mane mushroom for cognitive support.",
            batchId: "batch_2024Q2_018",
            verifiedAt: calendar.date(byAdding: .day, value: -7, to: Date())!
        )
        context.insert(product2)

        let entry2 = RoutineEntry(
            product: product2,
            schedule: .weekly,
            scheduleDays: [1, 3, 5],
            reminderTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()),
            reminderEnabled: true
        )
        entry2.linkedAt = calendar.date(byAdding: .day, value: -7, to: Date())!
        context.insert(entry2)

        // Log 2 of 3 expected this week
        for daysAgo in [1, 5] {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let log = RoutineLog(routineEntry: entry2, loggedAt: date)
            context.insert(log)
        }

        // Product 3: Saved but not yet added to routine
        let product3 = VerifiedProduct(
            productId: "prod_seed_003",
            token: "qr_seedReishiCalm01abcdefg",
            name: "Reishi Calm Tincture",
            category: "Adaptogen",
            productDescription: "Organic reishi mushroom tincture for stress resilience.",
            batchId: "batch_2024Q3_007",
            verifiedAt: calendar.date(byAdding: .day, value: -2, to: Date())!
        )
        context.insert(product3)
    }
}
#endif
