import SwiftUI
import Foundation

/// Language for `CodeHighlighter.highlight` — selects the keyword/type vocabulary.
enum CodeLanguage {
    case metal
    case swift
}

/// Hand-rolled regex tokenizer → AttributedString. Zero dependencies.
/// Single NSRegularExpression with ordered alternation: block/line comments and
/// strings are tried before preprocessor/numbers/identifiers, so a keyword spelled
/// out inside a string or comment is never mis-colored. Xcode-dark palette.
enum CodeHighlighter {
    private static let commentColor = Color(hex: 0x6C7986)
    private static let stringColor = Color(hex: 0xFC6A5D)
    private static let numberColor = Color(hex: 0xD0BF69)
    private static let keywordColor = Color(hex: 0xFC5FA3)
    private static let typeColor = Color(hex: 0x5DD8FF)
    private static let preprocessorColor = Color(hex: 0xFD8F3F)
    private static let plainColor = Color(hex: 0xFFFFFF)

    private static let metalKeywords: Set<String> = [
        "kernel", "vertex", "fragment", "using", "namespace", "struct", "return",
        "if", "else", "for", "while", "switch", "case", "break", "continue",
        "constexpr", "static", "const", "inline", "typedef", "template",
        "class", "public", "private", "void", "true", "false", "default"
    ]
    private static let metalTypes: Set<String> = [
        "device", "constant", "threadgroup", "thread",
        "half", "half2", "half3", "half4",
        "float", "float2", "float3", "float4", "float2x2", "float3x3", "float4x4",
        "int", "int2", "int3", "int4", "uint", "uint2", "uint3", "uint4",
        "bool", "texture2d", "texture2d_array", "sampler", "packed_float2", "packed_float3"
    ]
    private static let swiftKeywords: Set<String> = [
        "func", "var", "let", "struct", "class", "enum", "protocol", "extension",
        "if", "else", "guard", "for", "while", "switch", "case", "return",
        "import", "private", "public", "static", "init", "self", "Self",
        "true", "false", "nil", "in", "where", "try", "catch", "throw", "throws",
        "async", "await", "weak", "some", "default", "break", "continue"
    ]
    private static let swiftTypes: Set<String> = [
        "View", "String", "Int", "Double", "Float", "Bool", "URL", "Color",
        "Font", "Animation", "CGFloat", "Any", "Void", "Group", "State", "Binding"
    ]

    /// Ordered alternation: comments/strings/preprocessor/numbers before bare words —
    /// `NSRegularExpression` alternation picks the first matching branch at each position.
    private static let tokenRegex: NSRegularExpression = {
        let pattern = #"(?<blockComment>/\*[\s\S]*?\*/)|(?<lineComment>//[^\n]*)|(?<string>"(?:\\.|[^"\\])*")|(?<preprocessor>^#[^\n]*)|(?<number>\b\d+\.\d+f?\b|\b\d+f?\b)|(?<word>\b[A-Za-z_][A-Za-z0-9_]*\b)"#
        return try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
    }()

    static func highlight(_ code: String, language: CodeLanguage) -> AttributedString {
        let keywords = language == .metal ? metalKeywords : swiftKeywords
        let types = language == .metal ? metalTypes : swiftTypes
        let full = NSRange(location: 0, length: (code as NSString).length)
        let matches = tokenRegex.matches(in: code, range: full)

        var result = AttributedString()
        var lastEnd = code.startIndex

        func append(_ range: Range<String.Index>, _ color: Color) {
            guard !range.isEmpty else { return }
            var chunk = AttributedString(String(code[range]))
            chunk.font = Theme.mono(11)
            chunk.foregroundColor = color
            result += chunk
        }

        for match in matches {
            guard let span = Range(match.range, in: code) else { continue }
            append(lastEnd..<span.lowerBound, plainColor)

            let color: Color
            if match.range(withName: "blockComment").location != NSNotFound
                || match.range(withName: "lineComment").location != NSNotFound {
                color = commentColor
            } else if match.range(withName: "string").location != NSNotFound {
                color = stringColor
            } else if match.range(withName: "preprocessor").location != NSNotFound {
                color = preprocessorColor
            } else if match.range(withName: "number").location != NSNotFound {
                color = numberColor
            } else {
                let word = String(code[span])
                color = keywords.contains(word) ? keywordColor
                    : types.contains(word) ? typeColor
                    : plainColor
            }
            append(span, color)
            lastEnd = span.upperBound
        }
        append(lastEnd..<code.endIndex, plainColor)
        return result
    }
}
