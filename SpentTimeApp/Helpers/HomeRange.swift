
import SwiftUI

enum HomeRange: CaseIterable {
    case day, week, month, year
    var title: String {
        switch self {
        case .day:   return "Day"
        case .week:  return "Week"
        case .month: return "Month"
        case .year:  return "Year"
        }
    }
}

private enum HRTheme {
    static let outerStroke  = Color(hexString: "#FEBA07")
    static let selectedBG   = Color(hexString: "#0E2656")
    static let selectedLine = Color(hexString: "#FEBA07")
    static let divider      = Color(hexString: "#FEBA07")
    static let text         = Color.white
}

struct HomeRangePicker: View {
    @Binding var selection: HomeRange

    private let height: CGFloat = 40
    private let outerCorner: CGFloat = 5
    private let outerStrokeWidth: CGFloat = 1
    private let innerStrokeWidth: CGFloat = 0.5
    private let dividerInset: CGFloat = 12
    private let horizontalPad: CGFloat = 12

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                        .stroke(HRTheme.outerStroke, lineWidth: outerStrokeWidth)
                )

            HStack(spacing: 0) {
                let all = HomeRange.allCases
                ForEach(Array(all.enumerated()), id: \.offset) { idx, item in
                    let isFirst = idx == 0
                    let isLast  = idx == all.count - 1
                    let isSel   = (item == selection)

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.18)) { selection = item }
                    } label: {
                        ZStack {
                            
                            if isSel {
                                let inset = (outerStrokeWidth ) + (innerStrokeWidth )

                                
                                RoundedCornersShape(
                                    tl: outerCorner,
                                    tr: outerCorner,
                                    bl: outerCorner,
                                    br: outerCorner
                                )
                                .fill(HRTheme.selectedBG)
                                .padding(EdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset))

                               
                                RoundedCornersShape(
                                    tl: isFirst ? outerCorner - 2 : 5,
                                    tr: isLast  ? outerCorner - 2 : 5,
                                    bl: isFirst ? outerCorner - 2 : 5,
                                    br: isLast  ? outerCorner - 2 : 5
                                )
                                .stroke(HRTheme.selectedLine, lineWidth: innerStrokeWidth)
                                .padding(EdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset))
                            }

                            Text(item.title)
                                .font(isSel ? .osBold(18) : .osRegular(18))
                                .disableDynamicTypeScaling()
                                .foregroundStyle(HRTheme.text)
                                .padding(.horizontal, horizontalPad)
                                .frame(maxWidth: .infinity, minHeight: height)
                                .contentShape(Rectangle())
                        }
                    }
                    .buttonStyle(.plain)

                    if idx < all.count - 1 {
                        let selectedIndex = all.firstIndex(of: selection)!
                        let shouldHide = (idx == selectedIndex) || (idx == selectedIndex - 1)
                        if !shouldHide {
                            Rectangle()
                                .fill(HRTheme.divider)
                                .frame(width: onePixel)
                                .padding(.vertical, dividerInset)
                        }
                    }
                }
            }
        }
        .frame(height: height)
        .disableDynamicTypeScaling()
        .accessibilityElement(children: .contain)
    }

    private var onePixel: CGFloat {
        1
    }
}


private struct RoundedCornersShape: Shape {
    var tl: CGFloat = 0
    var tr: CGFloat = 0
    var bl: CGFloat = 0
    var br: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height

        let tr = min(min(self.tr, h/2), w/2)
        let tl = min(min(self.tl, h/2), w/2)
        let bl = min(min(self.bl, h/2), w/2)
        let br = min(min(self.br, h/2), w/2)

        path.move(to: CGPoint(x: tl, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr,
                    startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br,
                    startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl,
                    startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl,
                    startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}


#Preview {
    HomeView()
}
