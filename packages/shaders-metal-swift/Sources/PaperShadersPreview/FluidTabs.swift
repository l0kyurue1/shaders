import SwiftUI

/// Horizontal tab bar. The active pill tracks the selected tab via
/// matchedGeometryEffect; hovering any other tab shows a second pill that "merges"
/// out of the active pill's rect toward the hovered tab, rather than fading in place.
struct FluidTabs: View {
    let titles: [String]
    @Binding var selection: Int

    @Namespace private var ns
    @State private var frames: [Int: CGRect] = [:]
    @State private var hoverRect: CGRect?
    @State private var hoverOpacity: Double = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(titles.indices, id: \.self) { i in
                Text(titles[i])
                    .font(Theme.ui(12, .medium))
                    .foregroundStyle(i == selection ? Theme.textPrimary : Theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        if i == selection {
                            RoundedRectangle(cornerRadius: Theme.radius)
                                .fill(Theme.surface2)
                                .matchedGeometryEffect(id: "active", in: ns)
                        }
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: TabFramesKey.self,
                                                    value: [i: geo.frame(in: .named("tabs"))])
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(Theme.moderate) { selection = i } }
                    .onHover { setHover($0 ? i : nil) }
            }
        }
        .coordinateSpace(name: "tabs")
        .onPreferenceChange(TabFramesKey.self) { frames = $0 }
        .animation(Theme.moderate, value: selection)
        .background(alignment: .topLeading) {
            if let hoverRect {
                RoundedRectangle(cornerRadius: Theme.radius)
                    .fill(Theme.surface3)
                    .frame(width: hoverRect.width, height: hoverRect.height)
                    .offset(x: hoverRect.minX, y: hoverRect.minY)
                    .opacity(hoverOpacity)
            }
        }
    }

    private func setHover(_ i: Int?) {
        guard i != selection else { return }
        if let i {
            if hoverRect == nil { hoverRect = frames[selection] }  // merge origin: the active pill's rect
            withAnimation(Theme.fast) {
                hoverRect = frames[i]
                hoverOpacity = 1
            }
        } else {
            withAnimation(Theme.fastExit) {
                hoverRect = frames[selection]
                hoverOpacity = 0
            }
        }
    }
}

private struct TabFramesKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
