import SwiftUI
import SwiftData

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false
    @State private var showGoalEntry = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("This Week")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)
                            Text(weekRangeString())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        if let sprint = appModel.currentSprint {
                            GridView()
                        } else {
                            // No sprint this week — prompt to set one
                            noSprintCard
                        }

                        // Stats row
                        HStack(spacing: 12) {
                            MetricTile(value: "\(appModel.currentStreak)", label: "Week Streak")
                            MetricTile(value: winRateStr(), label: "Win Rate")
                            MetricTile(value: "\(appModel.pastSprints.count)", label: "Total Sprints")
                        }
                        .padding(.horizontal)

                        // Pro tile
                        Button {
                            Haptics.tap()
                            if store.isPro { showInsights = true } else { showPaywall = true }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(store.isPro ? "Sprint Archive" : "Sprintly Pro")
                                        .font(.headline.weight(.semibold))
                                    Text(store.isPro ? "View your history and trends" : "Unlock history, trends & reminders")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: store.isPro ? "chart.line.uptrend.xyaxis" : "lock.fill")
                                    .foregroundStyle(Color.qmAccent)
                            }
                            .padding()
                            .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Haptics.tap()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if appModel.currentSprint != nil {
                        Button {
                            Haptics.tap()
                            showGoalEntry = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(Color.qmAccent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
                    .environmentObject(appModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showInsights) {
                InsightsView()
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showGoalEntry) {
                GoalEntrySheet(isPresented: $showGoalEntry)
                    .environmentObject(appModel)
            }
        }
        .onAppear {
            handleForceScreen()
        }
    }

    private var noSprintCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.qmAccent)
            Text("No sprint this week")
                .font(.title3.weight(.semibold))
            Text("Set a single goal to focus on for the next 7 days.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Start This Week's Sprint") {
                Haptics.tap()
                showGoalEntry = true
            }
            .prominentButton()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal)
    }

    private func weekRangeString() -> String {
        let cal = Calendar.current
        let start = AppModel.weekStart(for: Date())
        guard let end = cal.date(byAdding: .day, value: 6, to: start) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: start)) – \(fmt.string(from: end))"
    }

    private func winRateStr() -> String {
        let pct = Int(appModel.overallWinRate * 100)
        return "\(pct)%"
    }

    private func handleForceScreen() {
        guard let screen = forceScreen else { return }
        switch screen {
        case "paywall": showPaywall = true
        case "insights": showInsights = true
        case "settings": showSettings = true
        default: break
        }
    }
}

// MARK: - Goal Entry Sheet

struct GoalEntrySheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appModel: AppModel
    @State private var goalText: String = ""
    @State private var targetDays: Int = 5

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's your goal this week?")
                            .font(.headline)
                        TextField("e.g. Run 20 minutes", text: $goalText)
                            .padding(12)
                            .background(Color.qmField, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target days: \(targetDays)")
                            .font(.headline)
                        Slider(value: Binding(get: { Double(targetDays) }, set: { targetDays = Int($0) }),
                               in: 1...7, step: 1)
                            .tint(Color.qmAccent)
                    }

                    Spacer()

                    Button("Save Sprint") {
                        let trimmed = goalText.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        Haptics.success()
                        appModel.createOrUpdateSprint(goalTitle: trimmed, targetCount: targetDays)
                        isPresented = false
                    }
                    .prominentButton()
                    .disabled(goalText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
            .navigationTitle("New Sprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            if let sprint = appModel.currentSprint {
                goalText = sprint.goalTitle
                targetDays = sprint.targetCount
            }
        }
    }
}
