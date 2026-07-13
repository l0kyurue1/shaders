import Foundation
import Observation

public struct SessionDocument: Codable {
    public var shader: String
    public var params: [String: JSONValue]
    public init(shader: String, params: [String: JSONValue]) {
        self.shader = shader
        self.params = params
    }
}

/// File-as-protocol endpoint (spec §4.3): watches session/params.json, exposes
/// last parse error without ever dropping the last-good state.
@Observable
public final class SessionStore {
    public let fileURL: URL
    public var onChange: ((SessionDocument) -> Void)?
    public private(set) var lastError: String?
    private var lastWritten: Data?
    private var source: DispatchSourceFileSystemObject?
    private var debounce: DispatchWorkItem?

    public init(directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("params.json")
        let fd = open(directory.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        src.setEventHandler { [weak self] in self?.scheduleRead() }
        src.setCancelHandler { close(fd) }
        src.resume()
        source = src
    }

    deinit { source?.cancel() }

    private func scheduleRead() {
        debounce?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.readNow() }
        debounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: work)
    }

    public func readNow() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if data == lastWritten { return }   // self-write suppression
        guard let doc = parse(data) else {
            lastError = "malformed params.json — keeping last-good state"
            return
        }
        lastError = nil
        onChange?(doc)
    }

    /// Current file state without firing onChange — for initial adoption on mount,
    /// where routing through onChange would bounce a fresh sidebar selection back to
    /// the previous shader still persisted in the file.
    public func currentDocument() -> SessionDocument? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return parse(data)
    }

    private func parse(_ data: Data) -> SessionDocument? {
        try? JSONDecoder().decode(SessionDocument.self, from: data)
    }

    public func write(_ doc: SessionDocument) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        guard let data = try? encoder.encode(doc) else { return }
        lastWritten = data
        do {
            try data.write(to: fileURL, options: .atomic)
            lastError = nil
        } catch {
            lastError = "params.json write failed: \(error.localizedDescription)"
        }
    }
}
