import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var vm: TimerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text("stats")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black.opacity(0.7))

                HStack(spacing: 12) {
                    statCard(title: "today's focus", value: "\(vm.todayFocusMinutes)m")
                    statCard(title: "streak", value: "\(vm.currentStreakDays) days")
                    statCard(title: "sessions", value: "\(vm.totalSessionsCompleted)")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("weekly focus")
                        .font(.headline)
                        .foregroundStyle(.black.opacity(0.75))

                    Chart(displayedWeeklyData) { point in
                        BarMark(
                            x: .value("day", point.day),
                            y: .value("minutes", point.minutes)
                        )
                        .foregroundStyle(Color(red: 0.94, green: 0.79, blue: 0.39))
                        .cornerRadius(4)
                    }
                    .frame(height: 170)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.82))
                )

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("recent sessions")
                            .font(.headline)
                            .foregroundStyle(.black.opacity(0.75))
                        Spacer()
                        Text(historyLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if displayedHistory.isEmpty {
                        Text("finish your first focus session and it will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.55))
                    } else {
                        ForEach(displayedHistory) { record in
                            historyRow(record)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.82))
                )

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(minWidth: 560, minHeight: 460, alignment: .topLeading)
        }
    }

    private var displayedWeeklyData: [WeeklyFocusPoint] {
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let minutes = vm.weeklyFocusMinutes()
        let zipped = zip(labels, minutes).map { WeeklyFocusPoint(day: $0.0, minutes: $0.1) }

        if purchaseManager.isPro {
            return zipped
        }

        return Array(zipped.prefix(4))
    }

    private var displayedHistory: [SessionRecord] {
        if purchaseManager.isPro {
            return Array(vm.sessionHistory.prefix(8))
        }
        return Array(vm.sessionHistory.prefix(3))
    }

    private var historyLabel: String {
        purchaseManager.isPro ? "pro: full history" : "free: last 3 sessions"
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.6))

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.black.opacity(0.8))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.82))
        )
    }

    private func historyRow(_ record: SessionRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.sessionLabel.isEmpty ? "focus session" : record.sessionLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.black.opacity(0.8))
                Text(record.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(record.focusMinutes)m")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(red: 0.94, green: 0.79, blue: 0.39).opacity(0.25))
                )
        }
    }
}

private struct WeeklyFocusPoint: Identifiable {
    let id = UUID()
    let day: String
    let minutes: Int
}
