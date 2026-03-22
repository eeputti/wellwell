import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var vm: TimerViewModel

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("stats")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.75))

                HStack(spacing: 12) {
                    statCard(title: "today's sessions", value: "\(vm.todaySessionCount)")
                    statCard(title: "completed sessions", value: "\(vm.totalCompletedSessions)")
                    statCard(title: "total focus", value: "\(vm.totalFocusMinutesAllTime)m")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("last 7 days")
                        .font(.headline)
                        .foregroundStyle(.black.opacity(0.72))

                    Chart(vm.weeklyFocusSummary, id: \.dayLabel) { point in
                        BarMark(
                            x: .value("day", point.dayLabel),
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
                        .fill(Color.white.opacity(0.84))
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("reflection")
                        .font(.headline)
                    Text("coverage: \(vm.reflectionCompletionRate)%")
                        .font(.subheadline)
                    Text("productivity: \(vm.productivitySummaryText)")
                        .font(.subheadline)
                    if let feeling = vm.averageFeelingScore {
                        Text(String(format: "average feeling: %.1f / 3", feeling))
                            .font(.subheadline)
                    }
                }
                .foregroundStyle(.black.opacity(0.68))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.84))
                )

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(minWidth: 560, minHeight: 420, alignment: .topLeading)
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.58))

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.black.opacity(0.8))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.84))
        )
    }
}
