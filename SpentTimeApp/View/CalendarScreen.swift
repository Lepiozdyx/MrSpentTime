

import SwiftUI


struct CalendarScreen: View {
    @EnvironmentObject private var store: DataStore

    @State private var monthReference: Date = Date()

    @State private var activeDate: Date? = nil
    @State private var showDayOverlay: Bool = false
    @State private var showEmptyAlert: Bool = false

    @State private var addDateTarget: Date = Date()
    @State private var showAddForDate: Bool = false

    private var overlayVisible: Bool { showDayOverlay || showEmptyAlert }

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }

    private var onePixel: CGFloat { 1.0 / (UIScreen.main.scale == 0 ? 2.0 : UIScreen.main.scale) }

    private var tabBarVisualHeight: CGFloat { 60 }
    private func safeBottom() -> CGFloat {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return 0 }
        return window.safeAreaInsets.bottom
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                CustomNavBar(title: "Calendar", left: { EmptyView() }, right: { EmptyView() })
                    .disableDynamicTypeScaling()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        calendarCard
                            .padding(.horizontal, 12)
                            .padding(.top, 8)

                        Rectangle()
                            .fill(HomeTheme.yellow)
                            .frame(height: onePixel)
                            .padding(.horizontal, 12)
                            .padding(.top, 6)

                        MonthlySummaryView(referenceDate: monthReference)
                            .environmentObject(store)
                            .padding(.horizontal, 6)

                        Color.clear.frame(height: 80)
                    }
                }
            }
            .background(HomeTheme.background.ignoresSafeArea())
            .blur(radius: overlayVisible ? 12 : 0) // <<< блюр
            .animation(.easeOut(duration: 0.15), value: overlayVisible)

            if overlayVisible {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { // тап по фону закрывает оверлей
                        showDayOverlay = false
                        showEmptyAlert = false
                    }
            }

            if showEmptyAlert, let d = activeDate {
                CenteredAlert(date: d,
                              isPresented: $showEmptyAlert,
                              onAdd: {
                                  addDateTarget = d
                                  showAddForDate = true
                                  showEmptyAlert = false
                              })
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }

            if showDayOverlay, let d = activeDate {
                CenteredDayOverlay(date: d,
                                   isPresented: $showDayOverlay,
                                   onEdit: { _ in /* hook for editor */ },
                                   onDelete: { id in store.deleteTimeEntry(id: id) })
                .environmentObject(store)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }

            if showDayOverlay, let d = activeDate {
                Button {
                    addDateTarget = d
                    showAddForDate = true
                    showDayOverlay = false
                } label: {
                    ZStack {
                        Circle().fill(HomeTheme.yellow)
                            .frame(width: 64, height: 64)
                            .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 8)
                        Image(systemName: "plus")
                            .resizable().scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(HomeTheme.navy)
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, safeBottom() + tabBarVisualHeight + 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .zIndex(1100)
                .accessibilityLabel("Add activity")
            }

            NavigationLink(
                destination:
                    AddActivityView(date: addDateTarget)
                    .environmentObject(store)
                    .navigationBarBackButtonHidden(true),
                isActive: $showAddForDate
            ) { EmptyView() }
            .hidden()
        }
    }


    private var calendarCard: some View {
        VStack(spacing: 12) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 12)

            weekdaysRow
                .padding(.horizontal, 18)
                .padding(.top, 6)

            Divider()
                .background(HomeTheme.white)
                .frame(height: onePixel)
                .padding(.horizontal, 6)

            monthGrid
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
        .background(HomeTheme.navy)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HomeTheme.yellow, lineWidth: 2))
        .cornerRadius(18, antialiased: true)
    }

    private var header: some View {
        HStack {
            Text(monthTitle(for: monthReference))
                .font(.osBold(28))
                .foregroundStyle(HomeTheme.yellow)
                .disableDynamicTypeScaling()

            Spacer()

            HStack(spacing: 18) {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(HomeTheme.yellow)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(HomeTheme.yellow)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var weekdaysRow: some View {
        let symbols = ["M","T","W","T","F","S","S"]
        return HStack {
            ForEach(Array(symbols.enumerated()), id: \.offset) { _, s in
                Text(s)
                    .font(.osRegular(18))
                    .foregroundStyle(HomeTheme.white)
                    .frame(maxWidth: .infinity)
                    .disableDynamicTypeScaling()
            }
        }
    }

    private var monthGrid: some View {
        let days = makeMonthGridDates(for: monthReference)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(days, id: \.self) { d in
                dayCell(for: d)
                    .onTapGesture {
                        if calendar.isDate(d, equalTo: monthReference, toGranularity: .month) {
                            activeDate = d
                            if store.entries(on: d).isEmpty {
                                showEmptyAlert = true
                                showDayOverlay = false
                            } else {
                                showDayOverlay = true
                                showEmptyAlert = false
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isInMonth = calendar.isDate(date, equalTo: monthReference, toGranularity: .month)
        let isToday = calendar.isDateInToday(date)
        let dominant = store.dominantSphere(on: date)

        let bgColor: Color = {
            if !isInMonth { return HomeTheme.navy.opacity(0.25) }
            if let d = dominant { return d.color.color }
            return Color.gray.opacity(0.22)
        }()

        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                )
                .frame(height: 44)

            Text("\(calendar.component(.day, from: date))")
                .font(isToday ? .osBold(18) : .osRegular(16))
                .foregroundStyle(isToday ? HomeTheme.yellow : HomeTheme.white)
                .disableDynamicTypeScaling()
        }
        .opacity(isInMonth ? 1.0 : 0.85)
    }

    // MARK: helpers

    private func changeMonth(by offset: Int) {
        guard let new = calendar.date(byAdding: .month, value: offset, to: monthReference) else { return }
        monthReference = new
    }

    private func monthTitle(for date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "LLL yyyy"
        return df.string(from: date)
    }

    private func makeMonthGridDates(for reference: Date) -> [Date] {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: reference)) else {
            return []
        }
        let firstWeekdayOfMonth = calendar.component(.weekday, from: startOfMonth)
        let leading = (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leading, to: startOfMonth)!
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }
}



private struct CenteredAlert: View {
    @EnvironmentObject private var store: DataStore
    let date: Date
    @Binding var isPresented: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("No data for this day.\nTap + to add.")
                .font(.osSemiBold(20))
                .multilineTextAlignment(.center)
                .foregroundStyle(HomeTheme.white)
                .disableDynamicTypeScaling()
                .padding(.top, 18)

            Button {
                onAdd()
            } label: {
                ZStack {
                    Circle().fill(HomeTheme.yellow).frame(width: 64, height: 64)
                    Image(systemName: "plus")
                        .resizable().scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(HomeTheme.navy)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: 360)
        .background(RoundedRectangle(cornerRadius: 18).fill(HomeTheme.navy))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HomeTheme.yellow, lineWidth: 2))
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct CenteredDayOverlay: View {
    @EnvironmentObject private var store: DataStore

    let date: Date
    @Binding var isPresented: Bool
    let onEdit: (TimeEntry) -> Void
    let onDelete: (UUID) -> Void

    private var grouped: [(TimeOfDay, [TimeEntry])] {
        let entries = store.entries(on: date)
        let groups = Dictionary(grouping: entries, by: { $0.timeOfDay })
        let order: [TimeOfDay] = [.morning, .day, .evening, .night, .any]
        return order.compactMap { k in
            guard let arr = groups[k], !arr.isEmpty else { return nil }
            return (k, arr)
        }
    }

    private var totalRows: Int { grouped.reduce(0) { $0 + $1.1.count } }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .background(HomeTheme.white)
                .frame(height: 1.0 / (UIScreen.main.scale == 0 ? 2.0 : UIScreen.main.scale))
                .padding(.horizontal, 10)

            
            Group {
                if totalRows <= 4 {
                    contentList
                        .padding(.vertical, 12)
                } else {
                    ScrollView {
                        contentList
                            .padding(.vertical, 12)
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                }
            }
        }
        .frame(maxWidth: 560)
        .background(RoundedRectangle(cornerRadius: 18).fill(HomeTheme.navy))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HomeTheme.yellow, lineWidth: 2))
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var header: some View {
        HStack {
            Text(dateTitle())
                .font(.osBold(22))
                .foregroundStyle(HomeTheme.white)
                .disableDynamicTypeScaling()
            Spacer()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(HomeTheme.white)
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var contentList: some View {
        VStack(spacing: 16) {
            ForEach(grouped, id: \.0) { (period, items) in
                VStack(alignment: .leading, spacing: 10) {
                    Text(titleFor(period))
                        .font(.osBold(20))
                        .foregroundStyle(HomeTheme.white)
                        .disableDynamicTypeScaling()
                        .padding(.horizontal, 12)

                    ForEach(items) { e in
                        HStack(spacing: 12) {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                                .background(Circle().fill(store.spheres.first(where: { $0.id == e.sphereID })?.color.color ?? .gray))
                                .frame(width: 48, height: 48)

                            Text(store.spheres.first(where: { $0.id == e.sphereID })?.name ?? "Unknown")
                                .font(.osRegular(18))
                                .foregroundStyle(HomeTheme.white)
                                .disableDynamicTypeScaling()

                            Spacer()

                            Text(formatHM(e.minutes))
                                .font(.osRegular(16).monospacedDigit())
                                .foregroundStyle(HomeTheme.white)
                                .disableDynamicTypeScaling()

                            Button { onEdit(e) } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(HomeTheme.white)
                            }
                            .buttonStyle(.plain)

                            Button { onDelete(e.id) } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(HomeTheme.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.white.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(HomeTheme.navy))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HomeTheme.yellow, lineWidth: 1))
                        .padding(.horizontal, 12)
                    }
                }
            }
        }
    }

    private func dateTitle() -> String {
        let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX"); df.dateFormat = "d MMM"
        return df.string(from: date)
    }
    private func titleFor(_ p: TimeOfDay) -> String {
        switch p {
        case .morning: return "Morning"
        case .day:     return "Day"
        case .evening: return "Evening"
        case .night:   return "Night"
        case .any:     return "Any"
        }
    }
    private func formatHM(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}

#Preview {
    let store = DataStore()
    store.ensurePresetSpheresIfNeeded()
    if let s = store.spheres.first(where: { $0.name.lowercased().contains("social") }) {
        _ = store.addTimeEntry(date: Date(), minutes: 105, sphereID: s.id, timeOfDay: .morning)
    }
    if let w = store.spheres.first(where: { $0.name.lowercased().contains("work") }) {
        _ = store.addTimeEntry(date: Date(), minutes: 230, sphereID: w.id, timeOfDay: .day)
    }

    return NavigationStack {
        CalendarScreen()
            .environmentObject(store)
    }
}


struct MonthlySummaryView: View {
    @EnvironmentObject private var store: DataStore
    let referenceDate: Date

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Monthly Summary")
                    .font(.osBold(30))
                    .foregroundStyle(HomeTheme.white)
                    .disableDynamicTypeScaling()
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)

            Rectangle()
                .fill(HomeTheme.yellow)
                .frame(height: onePixel)
                .padding(.horizontal, 12)

            VStack(spacing: 12) {
                ForEach(aggregatedSpheres(), id: \.sphere.id) { item in
                    SummaryRoow(sphere: item.sphere, minutes: item.minutes)
                        .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 6)
        }
    }


    private struct AggregatedItem {
        let sphere: LifeSphere
        let minutes: Int
    }

    private func aggregatedSpheres() -> [AggregatedItem] {
        let cal = Calendar.current
        let start = DateStripper.startOfMonth(for: referenceDate)
        let end   = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? referenceDate

        let entries = store.entries(from: start, to: end)
        let groupedMinutes = Dictionary(grouping: entries, by: { $0.sphereID })
            .mapValues { $0.reduce(0) { $0 + $1.minutes } }

        var items: [AggregatedItem] = []
        for (id, minutes) in groupedMinutes {
            if let sphere = store.spheres.first(where: { $0.id == id }) {
                items.append(.init(sphere: sphere, minutes: minutes))
            }
        }
        return items.sorted { $0.minutes > $1.minutes }
    }

    private var onePixel: CGFloat {
        1.0 / (UIScreen.main.scale == 0 ? 2.0 : UIScreen.main.scale)
    }
}

private struct SummaryRoow: View {
    let sphere: LifeSphere
    let minutes: Int

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                .background(Circle().fill(sphere.color.color))
                .frame(width: 48, height: 48)

            Text(sphere.name)
                .font(.osRegular(18))
                .foregroundStyle(HomeTheme.white)
                .disableDynamicTypeScaling()

            Spacer()

            Text(formattedHM(minutes))
                .font(.osRegular(18).monospacedDigit())
                .foregroundStyle(HomeTheme.white)
                .disableDynamicTypeScaling()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HomeTheme.navy)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(HomeTheme.yellow, lineWidth: 2)
                )
        )
    }

    private func formattedHM(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}
