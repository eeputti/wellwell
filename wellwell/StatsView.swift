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
                    statCard(title: "streak", value: "\(vm.streakDays) days")
                    statCard(title: "sessions", value: "\(vm.totalCompletedSessions)")
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

                Text(historyLabel)
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.6))

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(minWidth: 560, minHeight: 420, alignment: .topLeading)
        }
    }

    private var displayedWeeklyData: [WeeklyFocusPoint] {
        let allData = vm.weeklyFocusSummary.map { WeeklyFocusPoint(day: $0.dayLabel, minutes: $0.minutes) }
        if purchaseManager.isPro {
            return allData
        }

        return Array(allData.prefix(3))
    }

    private var historyLabel: String {
        if purchaseManager.isPro {
            return "pro: full history unlocked"
        }

        return "free: showing limited history"
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
}

private struct WeeklyFocusPoint: Identifiable {
    let id = UUID()
    let day: String
    let minutes: Int
}
