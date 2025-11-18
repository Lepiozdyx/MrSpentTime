

import SwiftUI


struct TipsScreen: View {
    @EnvironmentObject private var store: DataStore
    
    var body: some View {
        ZStack {
            HomeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 12) {
                CustomNavBar(
                    title: "Tips",
                    left: { EmptyView() },
                    right: { EmptyView() }
                )
                .disableDynamicTypeScaling()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        VStack(spacing: 16) {
                            NavigationLink(value: Tip.Kind.productivity) {
                                TipCategoryCard(
                                    title: "Productivity",
                                    imageName: "tipsProductivity"
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(value: Tip.Kind.healthyHabits) {
                                TipCategoryCard(
                                    title: "Healthy Habits",
                                    imageName: "tipsHealthy"
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(value: Tip.Kind.unhealthy) {
                                TipCategoryCard(
                                    title: "Unhealthy Habits (and How to Avoid Them)",
                                    imageName: "tipsUnhealthy"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .navigationDestination(for: Tip.Kind.self) { kind in
            TipDetailScreen(
                kind: kind,
                title: titleFor(kind),
                headerImageName: imageFor(kind)
            )
            .environmentObject(store)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    
    private func titleFor(_ kind: Tip.Kind) -> String {
        switch kind {
        case .productivity:
            return "Productivity"
        case .healthyHabits:
            return "Healthy Habits"
        case .unhealthy:
            return "Unhealthy Habits (and How to Avoid Them)"
        }
    }
    
    private func imageFor(_ kind: Tip.Kind) -> String {
        switch kind {
        case .productivity:
            return "tipsProductivity"
        case .healthyHabits:
            return "tipsHealthy"
        case .unhealthy:
            return "tipsUnhealthy"
        }
    }
}


private struct TipCategoryCard: View {
    let title: String
    let imageName: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 190)
                .clipped()
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.75)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            
            Text(title)
                .font(.osBold(28))
                .disableDynamicTypeScaling()
                .foregroundStyle(HomeTheme.white)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(HomeTheme.yellow, lineWidth: 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}


struct TipDetailScreen: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    
    let kind: Tip.Kind
    let title: String
    let headerImageName: String
    
    private var tips: [Tip] {
        store.tips.filter { $0.kind == kind }
    }
    
    var body: some View {
        ZStack {
            HomeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomNavBar(
                    title: title,
                    left: {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.white)
                        }
                    },
                    right: { EmptyView() }
                )
                .disableDynamicTypeScaling()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Image(headerImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 230)
                            .clipped()
                            .overlay(
                                Rectangle()
                                    .stroke(HomeTheme.yellow, lineWidth: 0)
                            )
                            .padding(.bottom, 8)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(tips) { tip in
                                TipBulletRow(text: tip.text)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }
}


private struct TipBulletRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(HomeTheme.white)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            
            Text(text)
                .font(.osRegular(18))
                .disableDynamicTypeScaling()
                .foregroundStyle(HomeTheme.white)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
    }
}


#Preview {
    NavigationStack {
        TipsScreen()
            .environmentObject(DataStore())
    }
}
