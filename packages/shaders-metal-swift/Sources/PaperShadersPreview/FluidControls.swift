import SwiftUI

/// Button: press is a plain 0.98-scale tween (80ms), deliberately not a spring;
/// hover brightens one surface step with the fast spring.
struct FluidButtonStyle: ButtonStyle {
    var filled = true

    func makeBody(configuration: Configuration) -> some View {
        Impl(configuration: configuration, filled: filled)
    }

    private struct Impl: View {
        let configuration: Configuration
        let filled: Bool
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(Theme.ui(12, .medium))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    hovering ? Theme.surface3 : (filled ? Theme.surface2 : .clear),
                    in: RoundedRectangle(cornerRadius: Theme.radius)
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(Theme.moderateExit, value: configuration.isPressed)
                .animation(Theme.fast, value: hovering)
                .onHover { hovering = $0 }
        }
    }
}

struct FluidToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Impl(configuration: configuration)
    }

    private struct Impl: View {
        let configuration: Configuration
        @State private var hovering = false

        var body: some View {
            HStack {
                configuration.label
                Spacer(minLength: 0)
                Capsule()
                    .fill(configuration.isOn ? Theme.accent : (hovering ? Theme.surface3 : Theme.surface2))
                    .frame(width: 30, height: 17)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(Theme.textPrimary)
                            .frame(width: 13, height: 13)
                            .padding(2)
                    }
                    .onTapGesture {
                        withAnimation(Theme.moderate) { configuration.isOn.toggle() }
                    }
                    .onHover { h in withAnimation(Theme.fast) { hovering = h } }
            }
        }
    }
}

/// Dark inset field chrome for text inputs.
struct FluidFieldBackground: ViewModifier {
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(Theme.mono(11))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(hovering ? Theme.surface3 : Theme.surface2,
                        in: RoundedRectangle(cornerRadius: Theme.radius - 2))
            .animation(Theme.fast, value: hovering)
            .onHover { hovering = $0 }
    }
}

extension View {
    func fluidField() -> some View { modifier(FluidFieldBackground()) }
}

/// Shared collapsible-section header: rotating chevron + uppercased title,
/// hover-driven emphasis. Sidebar and param panel both render through this.
struct CollapsibleSectionHeader: View {
    let title: String
    let expanded: Bool
    var chevronSize: CGFloat = 8
    var insets: EdgeInsets = EdgeInsets()
    let toggle: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.right")
                    .font(.system(size: chevronSize, weight: .semibold))
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                Text(title.uppercased())
                    .font(Theme.sectionHeader)
                    .kerning(0.6)
                Spacer()
            }
            .foregroundStyle(hovering ? Theme.textSecondary : Theme.textTertiary)
            .padding(insets)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(Theme.fast, value: hovering)
        .onHover { hovering = $0 }
    }
}
