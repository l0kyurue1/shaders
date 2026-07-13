import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PaperShadersMetal

struct ParamPanel: View {
    @Bindable var model: ParamsModel
    @State private var openSelectID: String?
    @State private var collapsed: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            PresetBar(model: model)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if model.usesImage {
                        group("Image") { imageContent }
                        divider
                    }
                    paramGroups
                    Button {
                        withAnimation(Theme.moderate) { model.reset() }
                    } label: {
                        Label("Reset to defaults", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FluidButtonStyle())
                    .padding(.top, 4)
                }
                .padding(14)
            }
            // overlay-style scrolling: indicators must not consume layout width
            .scrollIndicators(.hidden)
        }
        .frame(width: 320)
        .background(Theme.surface1)
        .fluidSelectHost(openID: $openSelectID)
    }


    private var paramGroups: some View {
        let visible = model.entry.params.filter { model.isVisible($0) }
        let order = ["Effect", "Colors", "Transform", "Motion"]
        let groups = order.compactMap { title -> (String, [ParamEntry])? in
            let params = visible.filter { ($0.group ?? "Effect") == title }
            return params.isEmpty ? nil : (title, params)
        }
        return ForEach(Array(groups.enumerated()), id: \.element.0) { i, g in
            if i > 0 { divider }
            group(g.0) {
                ForEach(g.1, id: \.name) { param in
                    control(for: param)
                }
            }
        }
    }

    private func group(_ title: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        ParamGroup(title: title, collapsed: $collapsed, content: content)
    }

    private var divider: some View {
        Theme.hairline.frame(height: 1)
    }


    private var imageContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(model.sampleImageURLs, id: \.self) { url in
                        GalleryThumbnail(url: url, selected: model.selectedImageURL == url) {
                            withAnimation(Theme.moderate) { model.setImage(url: url) }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            Button {
                uploadImage()
            } label: {
                Label("Upload image…", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(FluidButtonStyle())
        }
    }

    private func uploadImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { model.setImage(url: url) }
    }


    private func row(_ name: String, @ViewBuilder control: () -> some View) -> some View {
        HStack(spacing: 10) {
            Text(name)
                .font(Theme.label)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 96, alignment: .leading)
            control()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(minHeight: 22)
    }

    @ViewBuilder
    private func control(for param: ParamEntry) -> some View {
        if param.isRuntimeOnly {
            if param.name == ParamEntry.speedName {
                row(ParamEntry.speedName) { sliderWithValue($model.speed, in: 0...4) }
            } // "frame" intentionally omitted
        } else if let uniform = param.uniform {
            switch param.kind {
            case .number:
                if let min = param.min, let max = param.max {
                    row(param.name) { sliderWithValue(model.float(uniform), in: min...max) }
                } else {
                    row(param.name) {
                        TextField("", value: model.float(uniform), format: .number)
                            .fluidField()
                            .frame(width: 72)
                    }
                }
            case .boolean:
                Toggle(isOn: model.bool(uniform)) {
                    Text(param.name).font(Theme.label).foregroundStyle(Theme.textSecondary)
                }
                .toggleStyle(FluidToggleStyle())
            case .string:
                if let options = param.options {
                    // `fit` offers only contain/cover — "none" (unsized) is not a useful preview choice.
                    let shown = param.name == "fit" ? options.filter { $0.key != "none" } : options
                    row(param.name) {
                        FluidSelect(
                            id: param.name,
                            options: shown.sorted(by: { $0.value < $1.value })
                                .map { SelectOption(label: $0.key, value: $0.value) },
                            selection: model.float(uniform),
                            openID: $openSelectID
                        )
                        .frame(maxWidth: 140)
                    }
                } else {
                    row(param.name) { colorWell(model.color(uniform)) }
                }
            case .colors:
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<model.colorsCount(uniform), id: \.self) { i in
                        row("color \(i + 1)") { colorWell(model.colorAt(uniform, i)) }
                    }
                    HStack(spacing: 6) {
                        Button {
                            withAnimation(Theme.moderate) { model.removeColor(uniform) }
                        } label: {
                            Image(systemName: "minus").frame(width: 16, height: 12)
                        }
                        .buttonStyle(FluidButtonStyle())
                        .disabled(model.colorsCount(uniform) <= 1)
                        .fluidTooltip("Remove color")
                        Button {
                            withAnimation(Theme.moderate) { model.addColor(uniform) }
                        } label: {
                            Image(systemName: "plus").frame(width: 16, height: 12)
                        }
                        .buttonStyle(FluidButtonStyle())
                        .disabled(model.colorsCount(uniform) >= (param.maxCount ?? 10))
                        .fluidTooltip("Add color")
                    }
                }
            }
        }
    }

    private func sliderWithValue<V: BinaryFloatingPoint>(_ value: Binding<V>, in range: ClosedRange<V>) -> some View {
        HStack(spacing: 8) {
            FluidSlider(value: value, range: range)
            Text(Double(value.wrappedValue), format: .number.precision(.fractionLength(2)))
                .font(Theme.value)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private func colorWell(_ binding: Binding<Color>) -> some View {
        ColorPicker("", selection: binding)
            .labelsHidden()
            .controlSize(.small)
    }
}

private struct GalleryThumbnail: View {
    let url: URL
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Group {
                if let img = NSImage(contentsOf: url) {
                    Image(nsImage: img).resizable().scaledToFill()
                } else {
                    Theme.surface2
                }
            }
            .frame(width: 56, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        selected ? Theme.accent : (hovering ? Theme.popoverBorder : Theme.hairline),
                        lineWidth: selected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(Theme.fast, value: selected)
        .animation(Theme.fast, value: hovering)
        .onHover { hovering = $0 }
    }
}

/// Collapsible parameter group: chevron header, content animates open/closed.
private struct ParamGroup<Content: View>: View {
    let title: String
    @Binding var collapsed: Set<String>
    @ViewBuilder let content: () -> Content

    private var expanded: Bool { !collapsed.contains(title) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CollapsibleSectionHeader(title: title, expanded: expanded) {
                withAnimation(Theme.moderate) {
                    if expanded { collapsed.insert(title) } else { collapsed.remove(title) }
                }
            }
            if expanded {
                VStack(alignment: .leading, spacing: 10) { content() }
                    .transition(.opacity)
            }
        }
    }
}
