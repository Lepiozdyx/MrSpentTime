//
//  AppRootView.swift
//  SpentTimeApp
//
//  Created by Алексей Авер on 18.11.2025.
//

import SwiftUI

struct AppRootView: View {
    @StateObject private var store = DataStore()
    
    @AppStorage("mst.onboardingShown") private var onboardingShown: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if onboardingShown {
                    CustomTabContainer()
                        .environmentObject(store)
                } else {
                    OnboardingView {
                        onboardingShown = true
                    }
                    .environmentObject(store)
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    AppRootView()
}
