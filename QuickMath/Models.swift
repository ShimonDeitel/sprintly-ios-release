import SwiftUI
import SwiftData

// MARK: - SwiftData models

@Model
final class Sprint {
    var id: UUID
    var weekStart: Date
    var goalTitle: String
    var targetCount: Int
    @Relationship(deleteRule: .cascade) var logs: [DayLog]

    init(id: UUID = UUID(), weekStart: Date, goalTitle: String, targetCount: Int = 7) {
        self.id = id
        self.weekStart = weekStart
        self.goalTitle = goalTitle
        self.targetCount = targetCount
        self.logs = []
    }

    var hitRate: Double {
        guard targetCount > 0 else { return 0 }
        let hits = logs.filter { $0.progressMade }.count
        return Double(hits) / Double(targetCount)
    }

    var completed: Bool { hitRate >= 1.0 }

    var daysLogged: Int { logs.filter { $0.progressMade }.count }
}

@Model
final class DayLog {
    var id: UUID
    var date: Date
    var progressMade: Bool
    var note: String

    init(id: UUID = UUID(), date: Date, progressMade: Bool, note: String = "") {
        self.id = id
        self.date = date
        self.progressMade = progressMade
        self.note = note
    }
}

@Model
final class SprintStat {
    var id: UUID
    var weekStart: Date
    var completed: Bool
    var hitRate: Double

    init(id: UUID = UUID(), weekStart: Date, completed: Bool, hitRate: Double) {
        self.id = id
        self.weekStart = weekStart
        self.completed = completed
        self.hitRate = hitRate
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var currentSprint: Sprint?
    @Published private(set) var pastSprints: [Sprint] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([Sprint.self, DayLog.self, SprintStat.self])
        let config = ModelConfiguration("sprintly", schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallback]))!
        }
    }

    func reload() {
        let ctx = container.mainContext
        let allSprints = (try? ctx.fetch(FetchDescriptor<Sprint>(sortBy: [SortDescriptor(\.weekStart, order: .reverse)]))) ?? []
        let todayWeekStart = Self.weekStart(for: Date())
        currentSprint = allSprints.first(where: { Self.weekStart(for: $0.weekStart) == todayWeekStart })
        pastSprints = allSprints.filter { Self.weekStart(for: $0.weekStart) != todayWeekStart }
    }

    func refresh() { reload() }

    // MARK: - Sprint creation

    func createOrUpdateSprint(goalTitle: String, targetCount: Int = 7) {
        let ctx = container.mainContext
        let todayWeekStart = Self.weekStart(for: Date())
        if let existing = currentSprint {
            existing.goalTitle = goalTitle
            existing.targetCount = targetCount
        } else {
            let sprint = Sprint(weekStart: todayWeekStart, goalTitle: goalTitle, targetCount: targetCount)
            ctx.insert(sprint)
        }
        try? ctx.save()
        reload()
    }

    func toggleToday() {
        guard let sprint = currentSprint else { return }
        let ctx = container.mainContext
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = sprint.logs.first(where: { Calendar.current.startOfDay(for: $0.date) == today }) {
            existing.progressMade.toggle()
        } else {
            let log = DayLog(date: today, progressMade: true)
            ctx.insert(log)
            sprint.logs.append(log)
        }
        try? ctx.save()
        reload()
    }

    func todayLogged() -> Bool {
        guard let sprint = currentSprint else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        return sprint.logs.first(where: { Calendar.current.startOfDay(for: $0.date) == today })?.progressMade == true
    }

    // MARK: - Stats helpers

    var overallWinRate: Double {
        let all = pastSprints + (currentSprint.map { [$0] } ?? [])
        guard !all.isEmpty else { return 0 }
        let wins = all.filter { $0.completed }.count
        return Double(wins) / Double(all.count)
    }

    var currentStreak: Int {
        let sorted = pastSprints.sorted { $0.weekStart > $1.weekStart }
        var streak = 0
        for s in sorted {
            if s.completed { streak += 1 } else { break }
        }
        return streak
    }

    // MARK: - Delete all

    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: DayLog.self)
        try? ctx.delete(model: SprintStat.self)
        try? ctx.delete(model: Sprint.self)
        try? ctx.save()
        reload()
    }

    // MARK: - Utilities

    static func weekStart(for date: Date) -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // Monday
        return cal.startOfWeek(for: date) ?? Calendar.current.startOfDay(for: date)
    }
}

// MARK: - Calendar helper

private extension Calendar {
    func startOfWeek(for date: Date) -> Date? {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps)
    }
}
