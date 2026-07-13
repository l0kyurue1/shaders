import SwiftUI
import Metal
import AppKit
import PaperShadersMetal

struct ContentView: View {
    @State private var selected: String?
    @State private var store: SessionStore
    @State private var collapsedCategories: Set<String> = []
    private let manifest: Manifest?
    private let distURL: URL?

    init() {
        distURL = DistLocator.locate()
        manifest = distURL.flatMap { try? Manifest.load(distURL: $0) }
        // …/Sources/PaperShadersPreview/ContentView.swift → up 3 = package root.
        // #filePath is baked at compile time; in a distributed .app the build
        // machine's source tree doesn't exist, so fall back to Application Support.
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let sessionDir = FileManager.default.fileExists(atPath: packageRoot.path)
            ? packageRoot.appendingPathComponent("session")
            : FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("PaperShadersMetal/session")
        let store = SessionStore(directory: sessionDir)
        _store = State(initialValue: store)
        // launch selection: last session's shader if valid, else first shader in sidebar order
        if let manifest {
            let sessionShader = store.currentDocument()?.shader
            let valid = sessionShader.flatMap { s in manifest.shaders.contains { $0.id == s } ? s : nil }
            let first = Self.orderedCategories(manifest.shaders).first
                .flatMap { c in manifest.shaders.first { $0.category == c }?.id }
            _selected = State(initialValue: valid ?? first)
        }
    }

    var body: some View {
        if let manifest, let distURL {
            NavigationSplitView {
                sidebar(manifest)
            } detail: {
                Group {
                    if let id = selected, let entry = manifest.shaders.first(where: { $0.id == id }) {
                        ShaderPane(entry: entry, distURL: distURL, store: store,
                                   onSwitchShader: { selected = $0 })
                            .id(id)   // rebuild renderer on selection change
                    } else {
                        Text("Select a shader")
                    }
                }
                .background(Theme.surface1)
            }
            .toolbarBackground(Theme.surface1, for: .windowToolbar)
            .toolbarBackground(.visible, for: .windowToolbar)
        } else {
            ContentUnavailableView("dist/ not found",
                systemImage: "exclamationmark.triangle",
                description: Text("Run `bun run build` in packages/shaders-metal first."))
        }
    }

    /// Custom sidebar (no List): fluid hover rows, whole-row section toggle,
    /// no NSTableView chrome (the black scroll-edge line).
    private func sidebar(_ manifest: Manifest) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(Self.orderedCategories(manifest.shaders).enumerated()), id: \.element) { i, category in
                    if i > 0 {
                        Theme.hairline.frame(height: 1)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                    }
                    CollapsibleSectionHeader(
                        title: category,
                        expanded: !collapsedCategories.contains(category),
                        chevronSize: 7,
                        insets: EdgeInsets(top: 10, leading: 8, bottom: 4, trailing: 8)
                    ) {
                        withAnimation(Theme.moderate) {
                            if collapsedCategories.contains(category) {
                                collapsedCategories.remove(category)
                            } else {
                                collapsedCategories.insert(category)
                            }
                        }
                    }
                    if !collapsedCategories.contains(category) {
                        ForEach(manifest.shaders.filter { $0.category == category }) { entry in
                            SidebarRow(name: entry.name, selected: selected == entry.id) {
                                selected = entry.id
                            }
                        }
                    }
                }
            }
            .padding(8)
        }
        .background(Theme.surface1)
        .navigationSplitViewColumnWidth(min: 170, ideal: 200)
    }

    /// Category sections ordered Image Filters → Logo Animations → Effects, then any others (first-seen).
    private static func orderedCategories(_ shaders: [ShaderEntry]) -> [String] {
        let priority = ["Image Filters", "Logo Animations", "Effects"]
        var seen: [String] = []
        for c in shaders.map(\.category) where !seen.contains(c) { seen.append(c) }
        return priority.filter(seen.contains) + seen.filter { !priority.contains($0) }
    }
}

private struct SidebarRow: View {
    let name: String
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(Theme.ui(12.5))
                .foregroundStyle(selected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    selected ? Color.white.opacity(0.08) : (hovering ? Color.white.opacity(0.04) : .clear),
                    in: RoundedRectangle(cornerRadius: Theme.radius - 2)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(Theme.fast, value: hovering)
        .onHover { hovering = $0 }
    }
}

struct ShaderPane: View {
    let entry: ShaderEntry
    let distURL: URL
    let store: SessionStore
    let onSwitchShader: (String) -> Void
    @State private var renderer: ShaderRenderer?
    @State private var model: ParamsModel?
    @State private var error: String?
    @State private var showExport = false

    var body: some View {
        ZStack(alignment: .trailing) {
            content
            if showExport {
                ExportOverlay(isPresented: $showExport,
                              metalSource: { metalSource() ?? "" },
                              swiftUISource: swiftUISnippet)
            }
        }
        .navigationTitle(entry.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(Theme.slow) { showExport = true }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .fluidTooltip("Export code")
            }
        }
        .overlay(alignment: .topTrailing) {
            if let err = store.lastError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .padding(6)
                    .background(.yellow.opacity(0.9), in: RoundedRectangle(cornerRadius: 6))
                    .padding()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            if let renderer, let model {
                HSplitView {
                    ShaderView(renderer: renderer)
                    ParamPanel(model: model)
                }
            } else if let error {
                ContentUnavailableView("Pipeline failed", systemImage: "xmark.octagon", description: Text(error))
            } else {
                ProgressView().task {
                    do {
                        let r = try ShaderRenderer(device: MTLCreateSystemDefaultDevice()!, entry: entry, distURL: distURL)
                        renderer = r
                        model = ParamsModel(entry: entry, renderer: r)
                        model?.onEdit = { [weak store] in
                            guard let model else { return }
                            store?.write(SessionDocument(shader: entry.id, params: model.sessionParams()))
                        }
                        switch SessionAdoption.onMount(document: store.currentDocument(), shaderID: entry.id) {
                        case .adopt(let params):
                            model?.apply(sessionParams: params)
                        case .overwrite:
                            store.write(SessionDocument(shader: entry.id, params: r.params.isEmpty ? [:] : model!.sessionParams()))
                        }
                        store.onChange = { doc in
                            switch SessionAdoption.onChange(document: doc, shaderID: entry.id) {
                            case .apply(let params): model?.apply(sessionParams: params)
                            case .switchShader(let id): onSwitchShader(id)
                            }
                        }
                    } catch { self.error = "\(error)" }
                }
            }
        }
    }

    /// Raw Metal source for the current shader, read from dist/.
    /// ponytail: the .metal file is guaranteed present — the app already loaded it to build the pipeline.
    private func metalSource() -> String? {
        let url = distURL.appendingPathComponent("\(entry.id).metal")
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private func swiftUISnippet() -> String {
        let url = distURL.appendingPathComponent("snippet.swift.tmpl")
        guard let template = try? String(contentsOf: url, encoding: .utf8) else {
            return "// template missing — rebuild dist"
        }
        let params = model?.sessionParams() ?? [:]
        let typeName = entry.name.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        let dict = params.keys.sorted()
            .map { "                \"\($0)\": \(Self.swiftLiteral(params[$0]!))," }
            .joined(separator: "\n")
        return template
            .replacingOccurrences(of: "__TYPE_NAME__", with: typeName)
            .replacingOccurrences(of: "__SHADER_ID__", with: entry.id)
            .replacingOccurrences(of: "__PARAMS__", with: dict.isEmpty ? "                :" : dict)
    }

    // Emits plain JSON-shaped literals — JSONValue's literal conformances make
    // them compile as [String: JSONValue] in the generated snippet.
    private static func swiftLiteral(_ value: JSONValue) -> String {
        switch value {
        case .bool(let b): return b ? "true" : "false"
        case .number(let d): return String(format: "%g", d)
        case .string(let s): return "\"\(s)\""
        case .stringArray(let arr): return "[" + arr.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
        }
    }
}
