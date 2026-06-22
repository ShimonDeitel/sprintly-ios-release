import SwiftUI
import SwiftData

/// Primary sprint tracking screen — shows the current week's goal and daily progress dots.
struct GridView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        if let sprint = appModel.currentSprint {
            sprintContent(sprint: sprint)
        }
    }

    @ViewBuilder
    private func sprintContent(sprint: Sprint) -> some View {
        VStack(spacing: 20) {
            // Goal title card
            VStack(spacing: 8) {
                Text("Sprint Goal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(sprint.goalTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
            }
            .qmCard()
            .padding(.horizontal)

            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(sprint.daysLogged) / \(sprint.targetCount) days")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.qmAccent)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.qmCard)
                            .frame(height: 14)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(progressColor(sprint: sprint))
                            .frame(width: max(0, geo.size.width * CGFloat(sprint.hitRate)), height: 14)
                            .animation(.spring(response: 0.4), value: sprint.hitRate)
                    }
                }
                .frame(height: 14)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)

            // Day dots grid
            VStack(spacing: 12) {
                Text("Tap today to mark progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let weekDays = weekDates(for: sprint)
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { idx in
                        let day = weekDays[idx]
                        let label = dayLabels[idx]
                        DayDot(
                            label: label,
                            date: day,
                            isLogged: isLogged(sprint: sprint, date: day),
                            isToday: Calendar.current.isDateInToday(day),
                            isPast: day < Calendar.current.startOfDay(for: Date())
                        ) {
                            guard Calendar.current.isDateInToday(day) else { return }
                            Haptics.tap()
                            appModel.toggleToday()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal)

            // Main CTA — log today
            let todayDone = appModel.todayLogged()
            Button {
                Haptics.success()
                appModel.toggleToday()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: todayDone ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                    Text(todayDone ? "Today logged!" : "Mark today as done")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .prominentButton()
            .padding(.horizontal)
            .opacity(sprint.completed ? 0.6 : 1)

            if sprint.completed {
                HStack(spacing: 6) {
                    Image(systemName: "flag.checkered.2.crossed")
                        .foregroundStyle(Color.qmCorrect)
                    Text("Sprint complete! Great week.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.qmCorrect)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Helpers

    private func progressColor(sprint: Sprint) -> Color {
        if sprint.completed { return Color.qmCorrect }
        return Color.qmAccent
    }

    private func weekDates(for sprint: Sprint) -> [Date] {
        let start = AppModel.weekStart(for: sprint.weekStart)
        return (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: start)
        }
    }

    private func isLogged(sprint: Sprint, date: Date) -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return sprint.logs.first(where: {
            Calendar.current.startOfDay(for: $0.date) == startOfDay
        })?.progressMade == true
    }
}

// MARK: - DayDot

private struct DayDot: View {
    let label: String
    let date: Date
    let isLogged: Bool
    let isToday: Bool
    let isPast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isToday ? Color.qmAccent : .secondary)
                ZStack {
                    Circle()
                        .fill(isLogged ? Color.qmAccent : (isPast ? Color.qmCard2 : Color.qmCard2))
                        .frame(width: 36, height: 36)
                    if isLogged {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    if isToday && !isLogged {
                        Circle()
                            .strokeBorder(Color.qmAccent, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }
                }
                Text(dayNum(date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func dayNum(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }
}
