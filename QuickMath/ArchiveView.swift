import SwiftUI
import Charts

/// Pro feature: full sprint archive with win-rate and momentum trends.
struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                if appModel.pastSprints.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            summaryRow
                            trendChart
                            sprintList
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Sprint Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack(spacing: 12) {
            MetricTile(value: "\(appModel.pastSprints.count)", label: "Sprints")
            MetricTile(value: winStr(), label: "Win Rate")
            MetricTile(value: "\(appModel.currentStreak)", label: "Streak")
        }
        .padding(.horizontal)
        .padding(.top)
    }

    // MARK: - Trend chart

    private var trendChart: some View {
        let data = chartData()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Hit Rate Trend")
                .font(.headline.weight(.semibold))
                .padding(.horizontal)
            Chart {
                ForEach(data, id: \.week) { point in
                    LineMark(
                        x: .value("Week", point.week),
                        y: .value("Hit Rate", point.rate)
                    )
                    .foregroundStyle(Color.qmAccent)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Week", point.week),
                        y: .value("Hit Rate", point.rate)
                    )
                    .foregroundStyle(point.completed ? Color.qmCorrect : Color.qmAccent)
                    .symbolSize(64)
                }
            }
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(values: [0, 0.5, 1.0]) { val in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text("\(Int(v * 100))%")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(.horizontal)
        }
        .qmCard()
        .padding(.horizontal)
    }

    // MARK: - Sprint list

    private var sprintList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Past Sprints")
                .font(.headline.weight(.semibold))
                .padding(.horizontal)
            ForEach(appModel.pastSprints.sorted { $0.weekStart > $1.weekStart }) { sprint in
                SprintRow(sprint: sprint)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.qmAccent)
            Text("No past sprints yet")
                .font(.title3.weight(.semibold))
            Text("Complete your first week to see your archive and trends here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Helpers

    private func winStr() -> String {
        "\(Int(appModel.overallWinRate * 100))%"
    }

    private struct ChartPoint {
        let week: String
        let rate: Double
        let completed: Bool
    }

    private func chartData() -> [ChartPoint] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return appModel.pastSprints
            .sorted { $0.weekStart < $1.weekStart }
            .suffix(10)
            .map { ChartPoint(week: fmt.string(from: $0.weekStart), rate: $0.hitRate, completed: $0.completed) }
    }
}

// MARK: - SprintRow

private struct SprintRow: View {
    let sprint: Sprint

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(sprint.completed ? Color.qmCorrect.opacity(0.15) : Color.qmCard2)
                    .frame(width: 40, height: 40)
                Image(systemName: sprint.completed ? "flag.checkered.fill" : "flag")
                    .foregroundStyle(sprint.completed ? Color.qmCorrect : .secondary)
                    .font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(sprint.goalTitle)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(weekLabel(sprint.weekStart))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(sprint.daysLogged)/\(sprint.targetCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(sprint.completed ? Color.qmCorrect : .primary)
                Text("\(Int(sprint.hitRate * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func weekLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        return "Week of \(fmt.string(from: date))"
    }
}
