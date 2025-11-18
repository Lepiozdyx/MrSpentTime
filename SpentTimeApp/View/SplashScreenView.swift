

import SwiftUI

struct SplashScreenView: View {
    @State private var progress: CGFloat = 0.0
    
    let onFinished: (() -> Void)?
    
    init(onFinished: (() -> Void)? = nil) {
        self.onFinished = onFinished
    }
    
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
            
            VStack {
                Spacer(minLength: 40)
                
                logoCard
                
                Spacer()
                
                tagline
                
                Spacer()
                
                loadingBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
}


private extension SplashScreenView {
    
    var logoCard: some View {
        Image(.startLogo)
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 24)
    }
    
    var tagline: some View {
        Text("Every hour’s a\nnew chance.")
            .font(.osBold(42))
            .disableDynamicTypeScaling()
            .multilineTextAlignment(.center)
            .foregroundStyle(HomeTheme.yellow)
            .padding(.horizontal, 32)
    }
    
    var loadingBar: some View {
        GeometryReader { geo in
            ZStack {
                Capsule()
                    .fill(HomeTheme.navy)
                    .overlay(
                        Capsule()
                            .stroke(Color(hexString: "#0033FF"), lineWidth: 3)
                    )
                
                HStack(spacing: 0) {
                    Capsule()
                        .fill(HomeTheme.yellow)
                        .frame(width: geo.size.width * progress)
                    
                    Spacer(minLength: 0)
                }
                
                Text("Loading...")
                    .font(.osBold(20))
                    .disableDynamicTypeScaling()
                    .foregroundStyle(HomeTheme.navy)
            }
        }
        .frame(height: 32)
    }
}


private extension SplashScreenView {
    func startAnimation() {
        progress = 0
        
        withAnimation(.linear(duration: 2.2)) {
            progress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            onFinished?()
        }
    }
}


#Preview {
    SplashScreenView()
        .environmentObject(DataStore())
}
