import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    private let streakWeekdayColumns = Array(repeating: GridItem(.flexible(minimum: 24, maximum: 36), spacing: 10), count: 7)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("your focus story")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.black.opacity(0.75))
                            Text("\(vm.currentYear)")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.black.opacity(0.55))
                        }
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        statCard(title: "today", value: "\(vm.todaySessionCount) sessions")
                        statCard(title: "this week", value: "\(vm.weeklySessionsCount) sessions")
                        statCard(title: "all-time focus", value: formattedDuration(minutes: vm.totalFocusMinutesAllTime))
                    }

                    streakOverviewCard

                    yearlyOverviewCard

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

                    if !vm.recentIntentions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("recent intentions")
                                .font(.headline)
                            ForEach(vm.recentIntentions, id: \.self) { intention in
                                Text("• \(intention)")
                                    .font(.subheadline)
                                    .foregroundStyle(.black.opacity(0.68))
                                    .lineLimit(2)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.84))
                        )
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(minWidth: 560, minHeight: 420, alignment: .topLeading)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 22)
            .accessibilityLabel("close stats")
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

    private var yearlyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("month at a glance")
                .font(.headline)
                .foregroundStyle(.black.opacity(0.72))

            LazyVGrid(columns: streakWeekdayColumns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.45))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: streakWeekdayColumns, spacing: 8) {
                ForEach(vm.currentMonthActivityGrid) { day in
                    Circle()
                        .fill(dayFillColor(for: day.sessionCount, isVisible: day.isInCurrentMonth))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if day.isInCurrentMonth {
                                Text("\(day.dayNumber)")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(day.sessionCount > 0 ? .white : .black.opacity(0.58))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .opacity(day.isInCurrentMonth ? 1 : 0)
                        .accessibilityLabel(day.isInCurrentMonth ? "day \(day.dayNumber), \(day.sessionCount > 0 ? "active" : "inactive")" : "")
                        .allowsHitTesting(false)
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

    private var streakOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("streaks")
                .font(.headline)
                .foregroundStyle(.black.opacity(0.72))

            HStack(spacing: 14) {
                statCard(title: "current streak", value: "\(vm.currentStreakDays) day\(vm.currentStreakDays == 1 ? "" : "s")")
                statCard(title: "longest streak", value: "\(vm.longestStreakDays) day\(vm.longestStreakDays == 1 ? "" : "s")")
                statCard(title: "active days", value: "\(vm.totalActiveDays)")
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

    private func dayFillColor(for sessionCount: Int, isVisible: Bool) -> Color {
        guard isVisible else { return .clear }
        return sessionCount > 0
            ? Color(red: 0.94, green: 0.69, blue: 0.33)
            : Color.black.opacity(0.08)
    }

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        let shift = max(0, min(symbols.count - 1, calendar.firstWeekday - 1))
        return Array(symbols[shift...] + symbols[..<shift])
    }
}
