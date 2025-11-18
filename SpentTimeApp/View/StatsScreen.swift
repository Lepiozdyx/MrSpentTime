//
//  StatisticsScreen.swift
//  MrSpentTime
//

import SwiftUI

// MARK: - Основной экран статистики

struct StatisticsScreen: View {
    @EnvironmentObject private var store: DataStore
    
    @State private var range: HomeRange = .day
    @State private var refDate: Date = Date()
    
    // меню периодов
    @State private var showRangeMenu = false
    
    // кастомный период
    @State private var showCustomRange = false
    @State private var period1Start: Date = Date()
    @State private var period1End: Date = Date()
    @State private var period2Start: Date = Date()
    @State private var period2End: Date = Date()
    
    // экран сравнения
    @State private var showCompareScreen = false
    
    var body: some View {
        ZStack {
            HomeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 12) {
                CustomNavBar(
                    title: "Statistics",
                    left: { EmptyView() },
                    right: {
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                showRangeMenu.toggle()
                            }
                        } label: {
                            Image("icon_filter") // твой ассет с иконкой
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                )
                .disableDynamicTypeScaling()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Пикер Day / Week / Month / Year
                        HomeRangePicker(selection: $range)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        // Донат + сумма времени
                        donutBlock
                            .padding(.horizontal, 16)
                        
                        // Бар-чарт длительностей по сферам (от коротких к длинным)
                        barChartBlock
                            .padding(.horizontal, 12)
                        
                        // Разделитель
                        Rectangle()
                            .fill(HomeTheme.yellow)
                            .frame(height: onePixel)
                            .padding(.horizontal, 12)
                            .padding(.top, 4)
                        
                        // Список сфер
                        summaryList
                            .padding(.horizontal, 12)
                        
                        Color.clear.frame(height: 70)
                    }
                }
            }
            
            // меню периодов
            if showRangeMenu {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showRangeMenu = false }
                    }
                
                VStack {
                    HStack {
                        Spacer()
                        StatisticsPeriodMenu { option in
                            handlePeriodChoice(option)
                        }
                        .padding(.trailing, 18)
                        .padding(.top, 4)
                    }
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale))
                .zIndex(999)
            }
            
            // Кастомный период: два календаря в оверлее
            if showCustomRange {
                CustomPeriodOverlay(
                    start1: $period1Start,
                    end1: $period1End,
                    start2: $period2Start,
                    end2: $period2End,
                    onClose: {
                        withAnimation { showCustomRange = false }
                    },
                    onCompare: {
                        withAnimation {
                            showCustomRange = false
                            showCompareScreen = true
                        }
                    }
                )
                .zIndex(1000)
            }
        }
        // экран сравнения двух периодов
        .navigationDestination(isPresented: $showCompareScreen) {
            ComparePeriodsView(
                period1Start: DateStripper.startOfDay(period1Start),
                period1End: DateStripper.startOfDay(period1End),
                period2Start: DateStripper.startOfDay(period2Start),
                period2End: DateStripper.startOfDay(period2End)
            )
            .environmentObject(store)
        }
    }
}

// MARK: - Donut

private extension StatisticsScreen {
    var donutBlock: some View {
        let slices = pieSlices(for: range, refDate: refDate)
        let total  = totalMinutes(for: range, refDate: refDate)
        
        return ZStack {
            DonutChartSimple(slices: slices, spheres: store.spheres, lineWidth: 22)
                .frame(height: 240)
                .padding(.top, 4)
            
            VStack(spacing: 4) {
                Text(centerTitle(for: range))
                    .font(.osSemiBold(26))
                    .foregroundStyle(HomeTheme.white)
                    .disableDynamicTypeScaling()
                Text(formattedHM(total))
                    .font(.osBold(30))
                    .monospacedDigit()
                    .foregroundStyle(HomeTheme.white)
                    .disableDynamicTypeScaling()
            }
        }
    }
}

// MARK: - Bar chart

private extension StatisticsScreen {
    var barChartBlock: some View {
        let items = aggregatedForBar(range: range, refDate: refDate)
        return RoundedBarChart(items: items)
            .frame(height: 190)
    }
    
    struct AggItem: Identifiable {
        let id = UUID()
        let sphere: LifeSphere
        let minutes: Int
    }
    
    func aggregatedForBar(range: HomeRange, refDate: Date) -> [AggItem] {
        let entries = entries(for: range, refDate: refDate)
        let grouped = Dictionary(grouping: entries, by: { $0.sphereID })
            .compactMap { (id, vals) -> AggItem? in
                guard let s = store.spheres.first(where: { $0.id == id }) else { return nil }
                return AggItem(sphere: s, minutes: vals.reduce(0) { $0 + $1.minutes })
            }
            .filter { $0.minutes > 0 }
        
        return grouped.sorted { $0.minutes < $1.minutes }
    }
}

private struct RoundedBarChart: View {
    let items: [StatisticsScreen.AggItem]
    
    private var maxHours: Int {
        let maxMin = max(60, items.map(\.minutes).max() ?? 60)
        let h = Int(ceil(Double(maxMin) / 60.0))
        return max(h, 1)
    }
    
    private var topHours: Int {
        max(maxHours, 4)
    }
    
    private var onePixel: CGFloat {
        1.0 / (UIScreen.main.scale == 0 ? 2.0 : UIScreen.main.scale)
    }
    
    var body: some View {
        GeometryReader { geo in
            let fullWidth  = geo.size.width
            let fullHeight = geo.size.height
            
            
            let axisZoneWidth: CGFloat = 44
            let barAreaWidth = fullWidth - axisZoneWidth
            let axisX        = barAreaWidth
            
            let topInset: CGFloat    = 8
            let bottomInset: CGFloat = 24
            let chartHeight = max(10, fullHeight - topInset - bottomInset)
            let baseY       = topInset + chartHeight
            
            let count       = max(items.count, 1)
            let slotWidth   = barAreaWidth / CGFloat(count)
            let barWidth    = slotWidth * 0.7
            let radius      = min(12, barWidth / 2)
            
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: baseY))
                    p.addLine(to: CGPoint(x: barAreaWidth, y: baseY))
                    p.move(to: CGPoint(x: axisX, y: topInset))
                    p.addLine(to: CGPoint(x: axisX, y: baseY))
                }
                .stroke(HomeTheme.yellow, lineWidth: onePixel * 2)
                
                let labels = yLabels()
                ForEach(labels.indices, id: \.self) { i in
                    let label = labels[i]
                    let y = yPos(forHours: label.hours,
                                 top: topInset,
                                 chartHeight: chartHeight)
                    Text(label.text)
                        .font(.osRegular(16))
                        .foregroundStyle(HomeTheme.white)
                        .position(
                            x: axisX + axisZoneWidth * 0.5,
                            y: y
                        )
                        .disableDynamicTypeScaling()
                }
                
                ForEach(items.indices, id: \.self) { idx in
                    let item = items[idx]
                    let centerX = (CGFloat(idx) + 0.5) * slotWidth
                    let barHeight = barHeight(minutes: item.minutes,
                                              chartHeight: chartHeight)
                    
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(item.sphere.color.color)
                            .frame(width: barWidth, height: barHeight)
                        
                        Text(item.sphere.name)
                            .font(.osRegular(13))
                            .foregroundStyle(HomeTheme.white)
                            .frame(width: max(barWidth, 52))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .disableDynamicTypeScaling()
                    }
                    .frame(height: chartHeight, alignment: .bottom)
                    .position(
                        x: centerX,
                        y: topInset + chartHeight / 2
                    )
                }
            }
        }
        .disableDynamicTypeScaling()
    }
    
    private func yLabels() -> [(hours: Int, text: String)] {
        let values = [max(2, topHours - 2), max(3, topHours - 1), topHours]
        return values.map { ($0, "\($0)h") }
    }
    
    private func barHeight(minutes: Int, chartHeight: CGFloat) -> CGFloat {
        let maxMinutes = CGFloat(topHours * 60)
        let h = (CGFloat(minutes) / maxMinutes) * (chartHeight - 12)
        return max(4, h)
    }
    
    private func yPos(forHours hours: Int,
                      top: CGFloat,
                      chartHeight: CGFloat) -> CGFloat {
        let maxMinutes     = CGFloat(topHours * 60)
        let clampedMinutes = min(maxMinutes, CGFloat(hours * 60))
        let progress       = clampedMinutes / maxMinutes
        let yFromBottom    = progress * (chartHeight - 12)
        return top + chartHeight - yFromBottom
    }
}


private extension StatisticsScreen {
    var summaryList: some View {
        VStack(spacing: 10) {
            HStack {
                Text(listTitle(for: range))
                    .font(.osBold(26))
                    .foregroundStyle(HomeTheme.white)
                    .disableDynamicTypeScaling()
                Spacer()
            }
            
            ForEach(cardItems(), id: \.sphere.id) { item in
                SummaryRow(color: item.sphere.color.color,
                           title: item.sphere.name,
                           time: formattedHM(item.minutes))
            }
        }
    }
    
    struct CardItem {
        let sphere: LifeSphere
        let minutes: Int
    }
    
    func cardItems() -> [CardItem] {
        let entries = entries(for: range, refDate: refDate)
        let grouped = Dictionary(grouping: entries, by: { $0.sphereID })
        let pairs: [CardItem] = grouped.compactMap { (id, arr) in
            guard let s = store.spheres.first(where: { $0.id == id }) else { return nil }
            return CardItem(sphere: s, minutes: arr.reduce(0) { $0 + $1.minutes })
        }
        return pairs.sorted { $0.minutes > $1.minutes }
    }
}


private extension StatisticsScreen {
    func entries(for range: HomeRange, refDate: Date) -> [TimeEntry] {
        switch range {
        case .day:
            return store.entries(on: refDate)
        case .week:
            let s = DateStripper.startOfWeek(for: refDate)
            let e = Calendar.current.date(byAdding: .day, value: 6, to: s) ?? refDate
            return store.entries(from: s, to: e)
        case .month:
            let s = DateStripper.startOfMonth(for: refDate)
            let e = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: s) ?? refDate
            return store.entries(from: s, to: e)
        case .year:
            let cal = Calendar.current
            let y = cal.component(.year, from: refDate)
            let s = cal.date(from: DateComponents(year: y, month: 1, day: 1)) ?? refDate
            let e = cal.date(byAdding: DateComponents(year: 1, day: -1), to: s) ?? refDate
            return store.entries(from: s, to: e)
        }
    }
    
    func pieSlices(for range: HomeRange, refDate: Date) -> [PieSlice] {
        switch range {
        case .day:   return store.pieData(for: .day,   refDate: refDate)
        case .week:  return store.pieData(for: .week,  refDate: refDate)
        case .month: return store.pieData(for: .month, refDate: refDate)
        case .year:
            let grouped = Dictionary(grouping: entries(for: .year, refDate: refDate), by: { $0.sphereID })
            return grouped.map { (id, vals) in
                PieSlice(sphereID: id, totalMinutes: vals.reduce(0) { $0 + $1.minutes })
            }
            .filter { $0.totalMinutes > 0 }
        }
    }
    
    func totalMinutes(for range: HomeRange, refDate: Date) -> Int {
        entries(for: range, refDate: refDate).reduce(0) { $0 + $1.minutes }
    }
    
    func formattedHM(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
    
    func centerTitle(for r: HomeRange) -> String {
        switch r {
        case .day:   return "Today"
        case .week:  return "This Week"
        case .month: return "This Month"
        case .year:  return "This Year"
        }
    }
    
    func listTitle(for r: HomeRange) -> String {
        switch r {
        case .day:   return "Daily Summary"
        case .week:  return "Weekly Summary"
        case .month: return "Monthly Summary"
        case .year:  return "Yearly Summary"
        }
    }
    
    var onePixel: CGFloat {
        1.0 / (UIScreen.main.scale == 0 ? 2.0 : UIScreen.main.scale)
    }
}


enum StatisticsPeriodOption {
     case reset, previousDay, previousWeek, previousMonth, custom
}

struct StatisticsPeriodMenu: View {
    let choose: (StatisticsPeriodOption) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            item("Reset filter", .reset)
            divider
            
            item("Previous day", .previousDay)
            divider
            
            item("Previous week", .previousWeek)
            divider
            
            item("Previous month", .previousMonth)
            divider
            
            item("Custom period", .custom)
        }
        .padding(.vertical, 14)
        .background(HomeTheme.navy)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(HomeTheme.yellow, lineWidth: 3)
        )
        .cornerRadius(22)
        .frame(width: 280)
    }
    
    private func item(_ title: String, _ option: StatisticsPeriodOption) -> some View {
        Button {
            choose(option)
        } label: {
            Text(title)
                .font(.osRegular(22))
                .foregroundStyle(HomeTheme.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .disableDynamicTypeScaling()
        }
        .buttonStyle(.plain)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(HomeTheme.yellow.opacity(0.8))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }
}

private extension StatisticsScreen {
    func handlePeriodChoice(_ option: StatisticsPeriodOption) {
        withAnimation {
            showRangeMenu = false
        }
        
        let cal = Calendar.current
        let now = Date()
        
        switch option {
        case .reset:
            refDate = now
            
            
        case .previousDay:
            range = .day
            refDate = cal.date(byAdding: .day, value: -1, to: now) ?? now
            
        case .previousWeek:
            range = .week
            refDate = cal.date(byAdding: .day, value: -7, to: now) ?? now
            
        case .previousMonth:
            range = .month
            refDate = cal.date(byAdding: .month, value: -1, to: now) ?? now
            
        case .custom:
            let today = DateStripper.startOfDay(now)
            period1Start = today
            period1End   = today
            period2Start = today
            period2End   = today
            
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                showCustomRange = true
            }
        }
    }
}


struct CustomPeriodOverlay: View {
    @Binding var start1: Date
    @Binding var end1: Date
    @Binding var start2: Date
    @Binding var end2: Date
    
    let onClose: () -> Void
    let onCompare: () -> Void
    
    private var onePixel: CGFloat {
        1.0 / (UIScreen.main.scale == 0 ? 2.0 : UIScreen.main.scale)
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .ignoresSafeArea()
                .blur(radius: 1)
                .onTapGesture {
                    onClose()
                }
            
            VStack {
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 18) {
                        RangeCalendarView(title: "Period 1",
                                          start: $start1,
                                          end: $end1)
                        
                        RangeCalendarView(title: "Period 2",
                                          start: $start2,
                                          end: $end2)
                        
                        Button {
                            onCompare()
                        } label: {
                            Text("Compare")
                                .font(.osBold(26))
                                .foregroundStyle(HomeTheme.navy)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 14)
                                .background(HomeTheme.yellow)
                                .cornerRadius(40)
                                .disableDynamicTypeScaling()
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                        .padding(.bottom, 6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                }
                .frame(maxHeight: 520)
            }
            .padding(4)
            .background(HomeTheme.navy)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(HomeTheme.yellow, lineWidth: 3 * onePixel)
            )
            .cornerRadius(22)
            .padding(18)
        }
    }
}


struct RangeCalendarView: View {
    @Binding var start: Date
    @Binding var end: Date
    
    @State private var monthReference: Date = Date()
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }
    
    let title: String
    
    init(title: String, start: Binding<Date>, end: Binding<Date>) {
        self._start = start
        self._end = end
        self.title = title
        self._monthReference = State(initialValue: DateStripper.startOfMonth(for: start.wrappedValue))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(monthTitle(for: monthReference))
                    .font(.osBold(24))
                    .foregroundStyle(HomeTheme.yellow)
                    .disableDynamicTypeScaling()
                
                Spacer()
                
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(HomeTheme.yellow)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(HomeTheme.yellow)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            
            HStack {
                ForEach(["m","t","w","t","f","s","s"], id: \.self) { s in
                    Text(s)
                        .font(.osRegular(16))
                        .foregroundStyle(HomeTheme.white)
                        .frame(maxWidth: .infinity)
                        .disableDynamicTypeScaling()
                }
            }
            .padding(.horizontal, 12)
            
            Divider()
                .background(HomeTheme.white)
                .frame(height: 1.0 / UIScreen.main.scale)
                .padding(.horizontal, 6)
            
            let days = makeMonthGridDates(for: monthReference)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(days, id: \.self) { d in
                    dayCell(for: d)
                        .onTapGesture {
                            select(date: d)
                        }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
        .background(HomeTheme.navy)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(HomeTheme.yellow, lineWidth: 2)
        )
        .cornerRadius(18)
    }
    
    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isInMonth = calendar.isDate(date, equalTo: monthReference, toGranularity: .month)
        let d = DateStripper.startOfDay(date)
        let s = DateStripper.startOfDay(start)
        let e = DateStripper.startOfDay(end)
        let inRange = (d >= s && d <= e)
        
        let bg: Color = {
            if inRange { return HomeTheme.yellow.opacity(0.9) }
            if !isInMonth { return HomeTheme.navy.opacity(0.25) }
            return HomeTheme.navy
        }()
        
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(HomeTheme.yellow.opacity(inRange ? 1 : 0.3), lineWidth: inRange ? 2 : 1)
                )
                .frame(height: 34)
            
            Text("\(calendar.component(.day, from: date))")
                .font(.osRegular(16))
                .foregroundStyle(inRange ? HomeTheme.navy : HomeTheme.white)
                .disableDynamicTypeScaling()
        }
        .opacity(isInMonth ? 1.0 : 0.6)
    }
    
    
    private func select(date: Date) {
        let d = DateStripper.startOfDay(date)
        let s = DateStripper.startOfDay(start)
        let e = DateStripper.startOfDay(end)
        
        if s == e {
            if d < s {
                start = d
                end = s
            } else if d > e {
                end = d
            } else {
                start = d
                end = d
            }
        } else {
            start = d
            end = d
        }
    }
    
    private func changeMonth(by offset: Int) {
        if let new = calendar.date(byAdding: .month, value: offset, to: monthReference) {
            monthReference = new
        }
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
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        _ = range.count
        
        let firstWeekdayOfMonth = calendar.component(.weekday, from: startOfMonth)
        let leading = (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7
        
        let gridStart = calendar.date(byAdding: .day, value: -leading, to: startOfMonth)!
        let totalCells = 42
        return (0..<totalCells).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: gridStart)
        }
    }
}


struct ComparePeriodsView: View {
    @EnvironmentObject private var store: DataStore
    
    let period1Start: Date
    let period1End: Date
    let period2Start: Date
    let period2End: Date
    
    private var cal: Calendar { Calendar.current }
    
    var body: some View {
        ZStack {
            HomeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 12) {
                CustomNavBar(
                    title: titleText(),
                    left: { EmptyView() },
                    right: { EmptyView() }
                )
                .disableDynamicTypeScaling()
                
                ScrollView {
                    VStack(spacing: 18) {
                        HStack(spacing: 20) {
                            donutForPeriod(start: period1Start, end: period1End, label: formattedPeriod(period1Start, period1End))
                            donutForPeriod(start: period2Start, end: period2End, label: formattedPeriod(period2Start, period2End))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        Rectangle()
                            .fill(HomeTheme.yellow)
                            .frame(height: 1.0 / UIScreen.main.scale)
                            .padding(.horizontal, 12)
                        
                        VStack(spacing: 12) {
                            ForEach(compareItems(), id: \.sphere.id) { item in
                                SummaryRow(
                                    color: item.sphere.color.color,
                                    title: item.sphere.name,
                                    time: "\(formattedHM(item.minutes1)) / \(formattedHM(item.minutes2))"
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                        
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
    }
    
    private func donutForPeriod(start: Date, end: Date, label: String) -> some View {
        let slices = pieSlices(start: start, end: end)
        let total = slices.reduce(0) { $0 + $1.totalMinutes }
        let dominantName = dominantSphereName(from: slices)
        
        return ZStack {
            DonutChartSimple(slices: slices, spheres: store.spheres, lineWidth: 18)
                .frame(height: 220)
            
            VStack(spacing: 6) {
                Text(dominantName)
                    .font(.osSemiBold(22))
                    .foregroundStyle(HomeTheme.white)
                    .disableDynamicTypeScaling()
                Text(formattedHM(total))
                    .font(.osBold(24))
                    .foregroundStyle(HomeTheme.white)
                    .disableDynamicTypeScaling()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private struct CompareItem {
        let sphere: LifeSphere
        let minutes1: Int
        let minutes2: Int
    }
    
    private func compareItems() -> [CompareItem] {
        let entries1 = store.entries(from: period1Start, to: period1End)
        let entries2 = store.entries(from: period2Start, to: period2End)
        
        let grouped1 = Dictionary(grouping: entries1, by: { $0.sphereID })
            .mapValues { $0.reduce(0) { $0 + $1.minutes } }
        let grouped2 = Dictionary(grouping: entries2, by: { $0.sphereID })
            .mapValues { $0.reduce(0) { $0 + $1.minutes } }
        
        var result: [CompareItem] = []
        
        for sphere in store.spheres {
            let m1 = grouped1[sphere.id] ?? 0
            let m2 = grouped2[sphere.id] ?? 0
            if m1 > 0 || m2 > 0 {
                result.append(.init(sphere: sphere, minutes1: m1, minutes2: m2))
            }
        }
        
        return result.sorted { ($0.minutes1 + $0.minutes2) > ($1.minutes1 + $1.minutes2) }
    }
    
    private func pieSlices(start: Date, end: Date) -> [PieSlice] {
        let entries = store.entries(from: start, to: end)
        let grouped = Dictionary(grouping: entries, by: { $0.sphereID })
        return grouped.map { (id, vals) in
            PieSlice(sphereID: id, totalMinutes: vals.reduce(0) { $0 + $1.minutes })
        }.filter { $0.totalMinutes > 0 }
    }
    
    private func dominantSphereName(from slices: [PieSlice]) -> String {
        guard let maxSlice = slices.max(by: { $0.totalMinutes < $1.totalMinutes }),
              let sphere = store.spheres.first(where: { $0.id == maxSlice.sphereID }) else {
            return "—"
        }
        return sphere.name
    }
    
    private func titleText() -> String {
        "\(formattedPeriod(period1Start, period1End)) / \(formattedPeriod(period2Start, period2End))"
    }
    
    private func formattedPeriod(_ s: Date, _ e: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        if cal.isDate(s, equalTo: e, toGranularity: .day) {
            df.dateFormat = "d MMM"
            return df.string(from: s)
        } else {
            df.dateFormat = "d MMM"
            let sStr = df.string(from: s)
            let eStr = df.string(from: e)
            return "\(sStr)-\(eStr)"
        }
    }
    
    private func formattedHM(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}


struct SummaryRow: View {
    let color: Color
    let title: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                .background(Circle().fill(color))
                .frame(width: 48, height: 48)
            
            Text(title)
                .font(.osRegular(18))
                .foregroundStyle(HomeTheme.white)
                .disableDynamicTypeScaling()
            
            Spacer()
            
            Text(time)
                .font(.osRegular(18))
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
}


#Preview {
    let store = DataStore()
    return NavigationStack {
        StatisticsScreen()
            .environmentObject(store)
    }
}
