
import SwiftUI

private enum TabTheme {
    static let appBackground = Color(hexString: "#0C0C0C")
    static let barBackground = Color(hexString: "#081734")
    static let barStroke = Color(hexString: "#FEBA07")
    static let active = Color(hexString: "#FF8C00")
    static let inactive = Color.white
    static let label = Color.white
}


private enum AppTab: CaseIterable, Hashable {
    case home
    case calendar
    case statistics
    case favorites
    case tips
    
    var title: String {
        switch self {
        case .home:       return "Home"
        case .calendar:   return "Calendar"
        case .statistics: return "Statistics"
        case .favorites:  return "Favorites"
        case .tips:       return "Tips"
        }
    }
    
    var imageName: String {
        switch self {
        case .home:       return "tab_home"
        case .calendar:   return "tab_calendar"
        case .statistics: return "tab_statistics"
        case .favorites:  return "tab_favorites"
        case .tips:       return "tab_tips"
        }
    }
}


struct CustomTabContainer: View {
    @State private var selection: AppTab = .home
    @EnvironmentObject private var store: DataStore
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                TabTheme.appBackground
                    .ignoresSafeArea()
                
                contentView(for: selection)
                    .environmentObject(store)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TabTheme.appBackground.ignoresSafeArea())
                
                CustomTabBar(selection: $selection)
                    .padding(.horizontal, 16)
                    .padding(.bottom, bottomSafeAreaPadding())
                    .padding(.bottom, 8)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private func contentView(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .calendar:
            CalendarScreen()
        case .statistics:
            StatisticsScreen()
        case .favorites:
            FavoritesScreen()
        case .tips:
            TipsScreen()
        }
    }
    
    private func bottomSafeAreaPadding() -> CGFloat {
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return 2
        }
        return max(2, window.safeAreaInsets.bottom * 0.2)
    }
}


private struct CustomTabBar: View {
    @Binding var selection: AppTab
    
    private let barHeight: CGFloat = 80
    private let cornerRadius: CGFloat = 20
    private let strokeWidth: CGFloat = 2
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(TabTheme.barBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(TabTheme.barStroke, lineWidth: strokeWidth)
                )
            
            
            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.calendar)
                tabButton(.statistics)
                tabButton(.favorites)
                tabButton(.tips)
            }
            .padding(.horizontal, 18)
        }
        .frame(height: barHeight)
        .accessibilityElement(children: .contain)
    }
    
    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = (selection == tab)
        let tint = isSelected ? TabTheme.active : TabTheme.inactive
        
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.88)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 8) {
                Image(tab.imageName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundStyle(tint)
                    .contentShape(Rectangle())
                
                Text(tab.title)
                    .font(.custom("OpenSans-Regular", size: 12))
                    .disableDynamicTypeScaling()
                    .foregroundStyle(tint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}


#Preview {
    let store = DataStore()
    CustomTabContainer()
        .environmentObject(store)
}

