import SwiftUI
import AppKit

/// Fluid-functionalism slider: 18px pill track, 16px dot (full-height hit target),
/// value motion on the moderate spring, chrome (hover/drag scale) on the fast spring.
/// The dot springs toward the cursor rather than snapping — interruptible by design.
struct FluidSlider<V: BinaryFloatingPoint>: View {
    @Binding var value: V
    let range: ClosedRange<V>

    @State private var hovering = false
    @State private var dragging = false

    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat((value - range.lowerBound) / span)
    }

    private let dot: CGFloat = 16
    private let inset: CGFloat = 1  // dot rides just inside the track edge

    // resizeLeftRight over columnResize: the CI SDK lacks the macOS 15 symbol at compile time
    private var resizeCursor: NSCursor { .resizeLeftRight }

    var body: some View {
        GeometryReader { geo in
            let travel = geo.size.width - dot - inset * 2
            let dotX = inset + fraction * max(travel, 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(hovering || dragging ? Theme.surface3 : Theme.surface2)
                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: dotX + dot / 2 + inset)
                Circle()
                    .fill(Theme.textPrimary)
                    .frame(width: dot, height: dot)
                    .scaleEffect(dragging ? 1.1 : 1)
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                    .offset(x: dotX)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        dragging = true
                        resizeCursor.set()
                        let f = ((g.location.x - inset - dot / 2) / max(travel, 1)).clamped01()
                        value = range.lowerBound + V(f) * (range.upperBound - range.lowerBound)
                    }
                    .onEnded { _ in
                        dragging = false
                        // AppKit resets the cursor on mouse-up; reassert while still hovering
                        (hovering ? resizeCursor : NSCursor.arrow).set()
                    }
            )
            .animation(Theme.moderate, value: fraction)
            .animation(Theme.fast, value: dragging)
            .animation(Theme.fast, value: hovering)
            .onHover { h in
                hovering = h
                (h ? resizeCursor : NSCursor.arrow).set()
            }
        }
        .frame(height: 18)
    }
}

private extension CGFloat {
    func clamped01() -> CGFloat { Swift.min(Swift.max(self, 0), 1) }
}
