import Foundation

/// Reconciles the persisted session file with the active sidebar selection.
/// Pure decision logic, pinned by SessionAdoptionTests — switching shaders
/// must never bounce back to the stale shader persisted in the file.
public enum SessionAdoption {
    /// On mount: adopt persisted params only if the file already targets this
    /// shader; otherwise the selection wins and becomes the new truth.
    /// Routing this through onChange instead would bounce the selection back
    /// to the stale shader.
    public enum MountDecision {
        case adopt(params: [String: JSONValue])
        case overwrite
    }

    public static func onMount(document: SessionDocument?, shaderID: String) -> MountDecision {
        if let document, document.shader == shaderID { return .adopt(params: document.params) }
        return .overwrite
    }

    /// On a live file change: apply params if the document targets this shader,
    /// otherwise it is an external shader switch.
    public enum ChangeDecision {
        case apply(params: [String: JSONValue])
        case switchShader(String)
    }

    public static func onChange(document: SessionDocument, shaderID: String) -> ChangeDecision {
        document.shader == shaderID ? .apply(params: document.params) : .switchShader(document.shader)
    }
}
