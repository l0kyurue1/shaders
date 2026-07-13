import SwiftUI
import AppKit

/// Right-edge slide-over for exporting shader code. Built as a plain `if`-conditional
/// view (not `overlayPreferenceValue` — withAnimation transactions are silently dropped
/// through that, see FluidSelect.swift), so `.transition` + explicit `withAnimation`
/// calls on `isPresented` animate correctly and stay interruptible: presenting and
/// dismissing are both ordinary state writes, so a re-tap mid-flight just redirects
/// the same spring instead of racing a second animation.
///
/// Esc-to-dismiss uses a hidden `.keyboardShortcut(.escape)` button rather than
/// `.onExitCommand`: this view is a bare overlay inside a `WindowGroup`, not a
/// sheet/popover/NSViewController, and `onExitCommand` relies on the exitCommand
/// responder chain that isn't reliably wired for that case. A keyboard-shortcut
/// button hooks into SwiftUI's command dispatch directly, independent of first responder.
struct ExportOverlay: View {
    @Binding var isPresented: Bool
    let metalSource: () -> String
    let swiftUISource: () -> String

    @State private var tab = 0
    @State private var copied = false

    var body: some View {
        ZStack(alignment: .trailing) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }
                .transition(.opacity)

            panel
                .transition(.move(edge: .trailing))

            Button("", action: dismiss)
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(.plain)
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                FluidTabs(titles: ["Metal", "SwiftUI"], selection: $tab)
                Spacer()
                Button(action: copy) {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(FluidButtonStyle())
            }
            ScrollView {
                Text(highlighted)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .background(Theme.surface0, in: RoundedRectangle(cornerRadius: Theme.radius))
        }
        .padding(16)
        .frame(width: 460)
        .frame(maxHeight: .infinity)
        .background(Theme.surface1)
        .overlay(alignment: .leading) { Theme.hairline.frame(width: 1) }
        .shadow(color: .black.opacity(0.4), radius: 24, x: -4)
        .onChange(of: tab) { copied = false }
    }

    private var highlighted: AttributedString {
        tab == 0 ? CodeHighlighter.highlight(metalSource(), language: .metal)
                 : CodeHighlighter.highlight(swiftUISource(), language: .swift)
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(tab == 0 ? metalSource() : swiftUISource(), forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
    }

    private func dismiss() {
        withAnimation(Theme.slowExit) { isPresented = false }
    }
}
