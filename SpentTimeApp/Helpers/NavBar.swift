

import Foundation

import SwiftUI

private enum NavTheme {
    static let appBackground = Color(hexString: "#0C0C0C")
    static let barBackground = Color(hexString: "#0C0C0C")
    static let line = Color(hexString: "#FEBA07")
    static let title = Color.white
    static let buttonTint = Color.white
}


struct CustomNavBar<Left: View, Right: View>: View {
    let title: String
    let left: Left
    let right: Right
    
    private let barHeight: CGFloat = 44
    
    init(title: String,
         @ViewBuilder left: () -> Left,
         @ViewBuilder right: () -> Right) {
        self.title = title
        self.left = left()
        self.right = right()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(NavTheme.line)
                    .frame(height: onePixel)
                ZStack {
                    NavTheme.barBackground
                    
                    HStack {
                        HStack { left }
                            .frame(width: 64, alignment: .leading)
                            .tint(NavTheme.buttonTint)
                        
                        Spacer(minLength: 0)
                        
                        Text(title)
                            .font(.osBold(20))
                            .disableDynamicTypeScaling()
                            .foregroundStyle(NavTheme.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Spacer(minLength: 0)
                        
                        HStack { right }
                            .frame(width: 64, alignment: .trailing)
                            .tint(NavTheme.buttonTint)
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: barHeight)
                
                Rectangle()
                    .fill(NavTheme.line)
                    .frame(height: onePixel)
            }
        }
        .background(NavTheme.appBackground.ignoresSafeArea(edges: .top))
    }
    
    private var onePixel: CGFloat {
        1.5
    }
}

struct UsesCustomNavBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarHidden(true)
            .toolbar(.hidden)
    }
}

extension View {
    func usesCustomNavBar() -> some View {
        self.modifier(UsesCustomNavBar())
    }
}
