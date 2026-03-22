import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.92)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    Text("your focus story")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.75))

                    HStack(spacing: 12) {
                        statCard(title: "today", value: "\(vm.todaySessionCount) sessions")
                        statCard(title: "this week", value: "\(vm.weeklySessionsCount) sessions")
                        statCard(title: "all-time focus", value: formattedDuration(minutes: vm.totalFocusMinutesAllTime))
                    }

                    weeklyIdentityCard

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

                    recentTimelineCard

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("close stats")
                }
            }
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

    private var weeklyIdentityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("this week")
                .font(.headline)
                .foregroundStyle(.black.opacity(0.72))

            ForEach(weeklyIdentityLines, id: \.self) { line in
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.66))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.84))
        )
    }

    private var recentTimelineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("recent timeline")
                .font(.headline)
                .foregroundStyle(.black.opacity(0.72))

            if vm.recentSessions.isEmpty {
                Text("no sessions yet — your timeline starts with one calm session.")
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.58))
            } else {
                ForEach(vm.recentSessions.prefix(6)) { session in
                    HStack(alignment: .top, spacing: 10) {
                        Text(session.completedAt.formatted(.dateTime.hour().minute()))
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 56, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("focus • \(session.focusSeconds / 60)m")
                                .font(.subheadline)
                            if let productivity = session.reflectionProductivity {
                                Text(reflectionTag(for: productivity))
                                    .font(.caption)
                                    .foregroundStyle(.black.opacity(0.55))
                            }
                        }
                        .foregroundStyle(.black.opacity(0.68))
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.84))
        )
    }

    private var weeklyIdentityLines: [String] {
        if vm.weeklySessionsCount == 0 {
            return [
                "you can always begin again.",
                "one focused block is enough for today."
            ]
        }

        var lines: [String] = [
            "you showed up \(vm.weeklyActiveDaysCount) day\(vm.weeklyActiveDaysCount == 1 ? "" : "s") this week.",
            "you focused \(formattedDuration(minutes: vm.weeklyFocusMinutesTotal)) this week."
        ]

        if let bestDay = vm.bestWeekdayThisWeek {
            lines.append("your strongest day was \(bestDay.lowercased()).")
        }

        lines.append(vm.weeklyActiveDaysCount >= 3 ? "you’re building consistency." : "this one counted — keep it light.")
        return Array(lines.prefix(4))
    }

    private func reflectionTag(for productivity: ReflectionProductivity) -> String {
        switch productivity {
        case .low:
            return "reflection: low energy"
        case .okay:
            return "reflection: steady"
        case .high:
            return "reflection: solid session"
        }
    }

    private func formattedDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60

        if hours > 0 && remainder > 0 {
            return "\(hours)h \(remainder)m"
        } else if hours > 0 {
            return "\(hours)h"
        }
        return "\(remainder)m"
    }
}
