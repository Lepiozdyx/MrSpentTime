import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    let onFinish: () -> Void
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "onboarding1",
            title: "SEE WHERE YOUR TIME REALLY GOES",
            subtitle: "Track your day by activities — work, rest, family, and more. Find your real-life balance."
        ),
        OnboardingPage(
            imageName: "onboarding2",
            title: "ADD ACTIVITIES EASILY",
            subtitle: "Choose a category, set duration, and you’re done. Simple, fast, and mindful."
        ),
        OnboardingPage(
            imageName: "onboarding3",
            title: "BALANCE YOUR DAYS",
            subtitle: "Discover insights and gentle tips to improve your routine. Small changes, big difference."
        )
    ]
    
    @State private var currentPage: Int = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hexString: "#080B24"),
                    Color(hexString: "#0C0C0C")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topImage
                
                Spacer(minLength: 16)
                
                pageTexts
                
                Spacer(minLength: 24)
                
                // Индикатор страниц
                PageIndicator(
                    total: pages.count,
                    index: currentPage
                )
                .padding(.bottom, 24)
                
                // Кнопка Next / Get Started
                nextButton
                    .padding(.horizontal, 36)
                    .padding(.bottom, 32 + bottomSafeArea())
            }
        }
    }
    
    
    private var topImage: some View {
        GeometryReader { geo in
            Image(pages[currentPage].imageName)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width,
                       height: geo.size.height, alignment: .top)
        }
        .frame(height: UIScreen.main.bounds.height * 0.5)
        .ignoresSafeArea(edges: .top)
    }
    
    
    private var pageTexts: some View {
        let page = pages[currentPage]
        return VStack(spacing: 16) {
            Text(page.title)
                .font(.osBold(30))
                .disableDynamicTypeScaling()
                .multilineTextAlignment(.center)
                .foregroundStyle(HomeTheme.white)
                .padding(.horizontal, 24)
            
            Text(page.subtitle)
                .font(.osRegular(17))
                .disableDynamicTypeScaling()
                .multilineTextAlignment(.center)
                .foregroundStyle(HomeTheme.white)
                .padding(.horizontal, 32)
        }
    }
    
    
    private var nextButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                goNext()
            }
        } label: {
            Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                .font(.osBold(32))                     // увеличенный размер шрифта
                .disableDynamicTypeScaling()
                .foregroundStyle(HomeTheme.navy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule(style: .continuous)
                        .fill(HomeTheme.yellow)
                )
        }
        .buttonStyle(.plain)
    }
    
    
    private func goNext() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        } else {
            onFinish()
        }
    }
    
    
    private func bottomSafeArea() -> CGFloat {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
}


private struct PageIndicator: View {
    let total: Int
    let index: Int
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { i in
                if i == index {
                    Capsule(style: .continuous)
                        .fill(HomeTheme.yellow)
                        .frame(width: 24, height: 10)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(HomeTheme.yellow, lineWidth: 1)
                        )
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(HomeTheme.yellow, lineWidth: 2)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: index)
    }
}


#Preview {
    OnboardingView {
    }
}
