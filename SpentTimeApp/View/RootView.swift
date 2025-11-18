import SwiftUI

struct RootView: View {
    
    @StateObject private var state = AppStateManager()
    @StateObject private var fcmManager = TokenManager.shared
        
    var body: some View {
        Group {
            switch state.appState {
            case .fetch:
                SplashScreenView()
            case .supp:
                if let url = state.webManager.targetURL {
                    WebViewManager(url: url, webManager: state.webManager)
                } else if let fcmToken = fcmManager.fcmToken {
                    WebViewManager(
                        url: NetworkManager.getInitialURL(fcmToken: fcmToken),
                        webManager: state.webManager
                    )
                } else {
                    WebViewManager(
                        url: NetworkManager.initialURL,
                        webManager: state.webManager
                    )
                }
            case .final:
                AppRootView()
            }
        }
        .onAppear {
            state.stateCheck()
        }
    }
}

#Preview {
    RootView()
}
