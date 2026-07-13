import SwiftUI
import AppKit

/// Attach with `.fluidTooltip("Label")`. The bubble renders in a borderless child
/// window, not an in-place overlay: toolbar items (NSToolbar) and scroll views clip
/// overlays to their own bounds, so an overlay bubble gets cut and stacks over the
/// trigger. Shows below the trigger after a 200ms hover delay, 8px offset; entrance
/// is fade + 4px slide toward the trigger (fast spring), exit a fade-only fast tween.
struct FluidTooltipModifier: ViewModifier {
    let text: String

    @State private var showWork: DispatchWorkItem?
    @State private var controller = TooltipController()

    func body(content: Content) -> some View {
        content
            .background(TooltipAnchor(controller: controller))
            .onHover { hovering in
                showWork?.cancel()
                if hovering {
                    let work = DispatchWorkItem { controller.show(text: text) }
                    showWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
                } else {
                    controller.hide()
                }
            }
            .onDisappear {
                showWork?.cancel()
                controller.hide(immediately: true)
            }
    }
}

extension View {
    func fluidTooltip(_ text: String) -> some View {
        modifier(FluidTooltipModifier(text: text))
    }
}

/// Grabs the AppKit view backing the trigger so the tooltip window can be
/// positioned in screen coordinates.
private struct TooltipAnchor: NSViewRepresentable {
    let controller: TooltipController

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        controller.anchorView = view
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        controller.anchorView = view
    }
}

final class TooltipController {
    weak var anchorView: NSView?
    private var window: NSWindow?

    private let gap: CGFloat = 8
    private let slide: CGFloat = 4

    func show(text: String) {
        guard window == nil, let anchor = anchorView, let parent = anchor.window else { return }
        let hosting = NSHostingView(rootView: TooltipBubble(text: text, slide: slide))
        let size = hosting.fittingSize
        hosting.frame = NSRect(origin: .zero, size: size)

        let win = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                           styleMask: .borderless, backing: .buffered, defer: false)
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.ignoresMouseEvents = true
        win.isReleasedWhenClosed = false
        win.contentView = hosting

        let screenRect = parent.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        win.setFrameOrigin(NSPoint(x: screenRect.midX - size.width / 2,
                                   y: screenRect.minY - gap - size.height))
        parent.addChildWindow(win, ordered: .above)
        window = win
    }

    func hide(immediately: Bool = false) {
        guard let win = window else { return }
        window = nil
        let close = {
            win.parent?.removeChildWindow(win)
            win.orderOut(nil)
        }
        if immediately || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            close()
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.06
                win.animator().alphaValue = 0
            }, completionHandler: close)
        }
    }
}

private struct TooltipBubble: View {
    let text: String
    let slide: CGFloat
    @State private var shown = false

    var body: some View {
        Text(text)
            .font(Theme.ui(11))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.popover, in: RoundedRectangle(cornerRadius: Theme.radius - 2))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius - 2).strokeBorder(Theme.popoverBorder))
            .fixedSize()
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : slide)
            // slide headroom so the pre-entrance offset isn't clipped by the window
            .padding(.bottom, slide)
            .onAppear { withAnimation(Theme.fast) { shown = true } }
    }
}
