import SwiftUI
import PaperShadersMetal

/// Two-column grid of preset buttons at the top of the param panel. Hidden when the shader has none.
struct PresetBar: View {
    @Bindable var model: ParamsModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        if !model.entry.presets.isEmpty {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(model.entry.presets, id: \.name) { preset in
                    Button {
                        withAnimation(Theme.moderate) { model.apply(preset: preset) }
                    } label: {
                        Text(preset.name).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FluidButtonStyle())
                }
            }
            .padding(14)
            .background(Theme.surface1)
            .overlay(alignment: .bottom) { Theme.hairline.frame(height: 1) }
        }
    }
}
