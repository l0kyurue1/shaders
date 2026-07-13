import SwiftUI

/// Custom select: trigger + floating menu rendered by the panel root via
/// `fluidSelectHost()`, so the menu escapes ScrollView clipping. Opens on mouse-DOWN
/// (native-menu responsiveness); menu enters opacity 0→1, y −4→0, scaleY 0.96→1 from
/// the top edge on the fast spring, exits on a quicker tween.
struct SelectOption: Equatable {
    let label: String
    let value: Double
}

struct FluidSelect: View {
    let id: String
    let options: [SelectOption]
    @Binding var selection: Double
    @Binding var openID: String?

    @State private var hovering = false
    @State private var pressing = false

    private var isOpen: Bool { openID == id }

    var body: some View {
        HStack(spacing: 6) {
            Text(options.first(where: { $0.value == selection })?.label ?? "—")
                .font(Theme.ui(12))
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 6)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(hovering || isOpen ? Theme.surface3 : Theme.surface2,
                    in: RoundedRectangle(cornerRadius: Theme.radius))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressing else { return }
                    pressing = true
                    openID = isOpen ? nil : id
                }
                .onEnded { _ in pressing = false }
        )
        .animation(Theme.fast, value: hovering)
        .onHover { hovering = $0 }
        .anchorPreference(key: SelectAnchorKey.self, value: .bounds) {
            isOpen ? [id: SelectAnchor(bounds: $0, options: options, selection: $selection)] : [:]
        }
    }
}

struct SelectAnchor {
    let bounds: Anchor<CGRect>
    let options: [SelectOption]
    let selection: Binding<Double>
}

struct SelectAnchorKey: PreferenceKey {
    static let defaultValue: [String: SelectAnchor] = [:]
    static func reduce(value: inout [String: SelectAnchor], nextValue: () -> [String: SelectAnchor]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    /// Attach once at the panel root (outside any ScrollView) to host open select menus.
    func fluidSelectHost(openID: Binding<String?>) -> some View {
        overlayPreferenceValue(SelectAnchorKey.self) { anchors in
            GeometryReader { geo in
                if let open = openID.wrappedValue, let anchor = anchors[open] {
                    let rect = geo[anchor.bounds]
                    // click-away catcher
                    Color.black.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture { openID.wrappedValue = nil }
                    SelectMenu(options: anchor.options, selection: anchor.selection) {
                        openID.wrappedValue = nil
                    }
                    .frame(minWidth: rect.width, alignment: .leading)
                    .fixedSize()
                    .offset(x: rect.minX, y: rect.maxY + 6)
                }
            }
        }
    }
}

private struct SelectMenu: View {
    let options: [SelectOption]
    let selection: Binding<Double>
    let dismiss: () -> Void
    /// Entry animates via local state, not a transition: insertion happens inside
    /// overlayPreferenceValue where SwiftUI drops the withAnimation transaction and
    /// falls back to the slow default curve. onAppear + spring is deterministic.
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(options, id: \.value) { option in
                SelectRow(option: option, selected: option.value == selection.wrappedValue) {
                    selection.wrappedValue = option.value
                    dismiss()
                }
            }
        }
        .padding(2)
        .background(Theme.popover, in: RoundedRectangle(cornerRadius: Theme.radiusFocus))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusFocus).strokeBorder(Theme.popoverBorder))
        .shadow(color: .black.opacity(0.45), radius: 18, y: 8)
        .opacity(shown ? 1 : 0)
        .scaleEffect(x: 1, y: shown ? 1 : 0.96, anchor: .top)
        .offset(y: shown ? 0 : -4)
        .onAppear { withAnimation(Theme.fast) { shown = true } }
    }
}

private struct SelectRow: View {
    let option: SelectOption
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(option.label)
                    .font(Theme.ui(12))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 12)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .opacity(selected ? 1 : 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(hovering ? Theme.surface3 : .clear,
                        in: RoundedRectangle(cornerRadius: Theme.radius - 2))
        }
        .buttonStyle(.plain)
        .animation(Theme.fast, value: hovering)
        .onHover { hovering = $0 }
    }
}

