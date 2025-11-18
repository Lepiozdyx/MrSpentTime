

import SwiftUI
import UIKit

private enum OpenSansName {
    static let regular  = "OpenSans-Regular"
    static let semiBold = "OpenSans-SemiBold"
    static let bold     = "OpenSans-Bold"
}

extension Font {
    static func osRegular(_ size: CGFloat) -> Font   { .custom(OpenSansName.regular,  size: size) }
    static func osSemiBold(_ size: CGFloat) -> Font  { .custom(OpenSansName.semiBold, size: size) }
    static func osBold(_ size: CGFloat) -> Font      { .custom(OpenSansName.bold,     size: size) }

    static var osRegular12: Font { .custom(OpenSansName.regular,  size: 12) }
    static var osSemiBold12: Font{ .custom(OpenSansName.semiBold, size: 12) }
    static var osBold12: Font    { .custom(OpenSansName.bold,     size: 12) }

    static var osRegular16: Font { .custom(OpenSansName.regular,  size: 16) }
    static var osSemiBold16: Font{ .custom(OpenSansName.semiBold, size: 16) }
    static var osBold16: Font    { .custom(OpenSansName.bold,     size: 16) }

    static var osRegular20: Font { .custom(OpenSansName.regular,  size: 20) }
    static var osSemiBold20: Font{ .custom(OpenSansName.semiBold, size: 20) }
    static var osBold20: Font    { .custom(OpenSansName.bold,     size: 20) }

    static func osRegularFixed(_ size: CGFloat) -> Font  { Font(UIFont.osRegular(size)) }
    static func osSemiBoldFixed(_ size: CGFloat) -> Font { Font(UIFont.osSemiBold(size)) }
    static func osBoldFixed(_ size: CGFloat) -> Font     { Font(UIFont.osBold(size)) }
}


extension UIFont {
    private static func safeFont(name: String, size: CGFloat, fallbackWeight: UIFont.Weight) -> UIFont {
        if let f = UIFont(name: name, size: size) { return f }
        return .systemFont(ofSize: size, weight: fallbackWeight)
    }
    static func osRegular(_ size: CGFloat) -> UIFont  { safeFont(name: OpenSansName.regular,  size: size, fallbackWeight: .regular) }
    static func osSemiBold(_ size: CGFloat) -> UIFont { safeFont(name: OpenSansName.semiBold, size: size, fallbackWeight: .semibold) }
    static func osBold(_ size: CGFloat) -> UIFont     { safeFont(name: OpenSansName.bold,     size: size, fallbackWeight: .bold) }
}


public struct NoDynamicTypeScaling: ViewModifier {
    public func body(content: Content) -> some View {
        content.dynamicTypeSize(.medium)
    }
}

public extension View {
    func disableDynamicTypeScaling() -> some View {
        self.modifier(NoDynamicTypeScaling())
    }
}
