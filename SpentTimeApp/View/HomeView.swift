import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: DataStore
    
    @State private var homeRange: HomeRange = .day
    @State private var refDate: Date = Date()
    @State private var showAdd = false
    
    private let ringWidth: CGFloat = 26
    
    var body: some View {
        ZStack {
            HomeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 12) {
                CustomNavBar(title: "Home", left: {
                    EmptyView()
                }, right: {
                    EmptyView()
                })
                .disableDynamicTypeScaling()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 26) {
                        HomeRangePicker(selection: $homeRange)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        
                        let hasData = totalMinutes(for: homeRange, refDate: refDate) > 0
                        
                        ringContainer
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                        
                        if hasData {
                            Rectangle()
                                .fill(HomeTheme.yellow.opacity(0.9))
                                .frame(height: onePixel)
                                .padding(.horizontal, 12)
                            
                            dataList
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        } else {
                            Rectangle()
                                .fill(HomeTheme.yellow.opacity(0.9))
                                .frame(height: onePixel)
                                .padding(.horizontal, 10)
                            
                            Text("Tap + to add your first activity")
                                .font(.osRegular(18))
                                .disableDynamicTypeScaling()
                                .foregroundStyle(HomeTheme.white)
                                .padding(.top, 4)
                        }
                        
                        Color.clear.frame(height: tabBarClearance() + 24)
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showAdd = true
            } label: {
                ZStack {
                    Circle()
                        .fill(HomeTheme.yellow)
                        .frame(width: 64, height: 64)
                        .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 8)
                    
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .font(.system(size: 24, weight: .bold))
                        .disableDynamicTypeScaling()
                        .foregroundStyle(HomeTheme.navy)
                }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, tabBarClearance())
            .zIndex(999)
            .accessibilityLabel("Add activity")
        }
        .navigationDestination(isPresented: $showAdd) {
            AddActivityView(date: refDate)
                .environmentObject(store)
                .navigationBarBackButtonHidden(true)
        }
    }
}


private extension HomeView {
    var ringContainer: some View {
        GeometryReader { geo in
            let size = geo.size.width
            
            ZStack {
                if totalMinutes(for: homeRange, refDate: refDate) == 0 {
                    Circle()
                        .stroke(
                            HomeTheme.greyRing,
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                    
                    Text(emptyTitle())
                        .font(.osBold(28))
                        .disableDynamicTypeScaling()
                        .foregroundStyle(HomeTheme.white)
                        .multilineTextAlignment(.center)
                        .padding(24)
                } else {
                    let slices = pieSlices(for: homeRange, refDate: refDate)
                    let total  = totalMinutes(for: homeRange, refDate: refDate)
                    
                    DonutChartSimple(
                        slices: slices,
                        spheres: store.spheres,
                        lineWidth: ringWidth
                    )
                    
                    VStack(spacing: 8) {
                        Text(centerTitle(for: homeRange))
                            .font(.osSemiBold(32))
                            .disableDynamicTypeScaling()
                            .foregroundStyle(HomeTheme.white)
                        
                        Text(formattedHM(total))
                            .font(.osBold(34))
                            .disableDynamicTypeScaling()
                            .monospacedDigit()
                            .foregroundStyle(HomeTheme.white)
                    }
                    .padding(8)
                }
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .disableDynamicTypeScaling()
    }
    
    func emptyTitle() -> String {
        switch homeRange {
        case .day:   return "Nothing\ntracked today!"
        case .week:  return "Nothing\ntracked this week!"
        case .month: return "Nothing\ntracked this month!"
        case .year:  return "Nothing\ntracked this year!"
        }
    }
}


private extension HomeView {
    var dataList: some View {
        VStack(spacing: 14) {
            ForEach(cardItems(), id: \.sphere.id) { item in
                HomeCardRow(
                    color: item.sphere.color.color,
                    title: item.sphere.name,
                    time: formattedHM(item.minutes)
                )
            }
        }
    }
    
    struct CardItem {
        let sphere: LifeSphere
        let minutes: Int
    }
    
    func cardItems() -> [CardItem] {
        let entries = entries(for: homeRange, refDate: refDate)
        let grouped = Dictionary(grouping: entries, by: { $0.sphereID })
        let pairs: [CardItem] = grouped.compactMap { (id, arr) in
            guard let s = store.spheres.first(where: { $0.id == id }) else { return nil }
            return CardItem(sphere: s, minutes: arr.reduce(0) { $0 + $1.minutes })
        }
        return pairs.sorted { $0.minutes > $1.minutes }
    }
}


private extension HomeView {
    func totalMinutes(for range: HomeRange, refDate: Date) -> Int {
        entries(for: range, refDate: refDate).reduce(0) { $0 + $1.minutes }
    }
    
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
            let entries = entries(for: .year, refDate: refDate)
            let grouped = Dictionary(grouping: entries, by: { $0.sphereID })
            return grouped.map { (id, vals) in
                PieSlice(sphereID: id, totalMinutes: vals.reduce(0) { $0 + $1.minutes })
            }
            .filter { $0.totalMinutes > 0 }
        }
    }
    
    func centerTitle(for r: HomeRange) -> String {
        switch r {
        case .day:   return "Today's activity:"
        case .week:  return "This week's activity:"
        case .month: return "This month's activity:"
        case .year:  return "This year's activity:"
        }
    }
    
    func formattedHM(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
    
    var onePixel: CGFloat {
        1.0 / (UIScreen.main.scale == 0 ? 2.0 : UIScreen.main.scale)
    }
    
    func tabBarClearance() -> CGFloat {
        let barHeight: CGFloat = 46
        let extra: CGFloat = 24
        let safe = bottomSafeArea()
        return barHeight + safe + extra
    }
    
    func bottomSafeArea() -> CGFloat {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
}


private struct HomeCardRow: View {
    let color: Color
    let title: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 2)
                .background(Circle().fill(color))
                .frame(width: 34, height: 34)
            
            Text(title)
                .font(.osRegular(15))
                .disableDynamicTypeScaling()
                .foregroundStyle(HomeTheme.cardText)
            
            Spacer()
            
            Text(time)
                .font(.osRegular(18).monospacedDigit())
                .disableDynamicTypeScaling()
                .foregroundStyle(HomeTheme.cardText)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HomeTheme.navy)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(HomeTheme.cardStroke, lineWidth: 2)
                )
        )
        .disableDynamicTypeScaling()
    }
}


struct DonutChartSimple: View {
    let slices: [PieSlice]
    let spheres: [LifeSphere]
    let lineWidth: CGFloat

    private struct ArcSpec: Identifiable {
        let id: UUID
        let start: Angle
        let end: Angle
        let color: Color
    }

    private var specs: [ArcSpec] {
        let total = max(1, slices.reduce(0) { $0 + $1.totalMinutes })
        var acc = 0
        var out: [ArcSpec] = []
        out.reserveCapacity(slices.count)
        
        for s in slices {
            let startDeg = -90.0 + (360.0 * Double(acc) / Double(total))
            acc += s.totalMinutes
            let endDeg   = -90.0 + (360.0 * Double(acc) / Double(total))
            let color = spheres.first(where: { $0.id == s.sphereID })?.color.color ?? .gray
            out.append(
                .init(
                    id: s.sphereID,
                    start: .degrees(startDeg),
                    end: .degrees(endDeg),
                    color: color
                )
            )
        }
        return out
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(specs) { spec in
                    DonutArc(start: spec.start, end: spec.end)
                        .stroke(
                            spec.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                }
            }
            .frame(
                width: min(geo.size.width, geo.size.height),
                height: min(geo.size.width, geo.size.height)
            )
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .disableDynamicTypeScaling()
    }

    private struct DonutArc: Shape {
        let start: Angle
        let end: Angle
        
        func path(in rect: CGRect) -> Path {
            let radius = min(rect.width, rect.height) / 2
            let center = CGPoint(x: rect.midX, y: rect.midY)
            var p = Path()
            p.addArc(center: center,
                     radius: radius,
                     startAngle: start,
                     endAngle: end,
                     clockwise: false)
            return p
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(DataStore())
}
