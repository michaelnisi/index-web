import Foundation
import Markdown

extension Markup {
    var plainText: String {
        if let t = self as? Text { return t.string }

        return children.map(\.plainText).joined()
    }
}

extension String {
    func escape() -> String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Returns the last index of a sentence terminator (. ! ?) that is followed
    /// by a space, end of string, or a quote character—filtering out periods
    /// embedded in version numbers like "26.3" or abbreviations.
    func lastSentenceTerminator(in range: Range<String.Index>? = nil) -> String.Index? {
        let searchRange = range ?? startIndex..<endIndex
        let terminators: Set<Character> = [".", "!", "?"]
        var best: String.Index?
        var i = searchRange.lowerBound
        while i < searchRange.upperBound {
            let ch = self[i]
            if terminators.contains(ch) {
                let next = index(after: i)
                if next >= endIndex || self[next].isWhitespace || self[next] == "\"" || self[next] == "'" || self[next] == "\u{201D}" {
                    best = i
                }
            }
            i = index(after: i)
        }
        return best
    }
}

extension Document {
    func rawDescription(threshold: Int = 160) -> String {
        let paragraphs = children.compactMap { $0 as? Paragraph }.map { $0.plainText.trimmingCharacters(in: .whitespacesAndNewlines) }
        var chosen: String = ""
        for p in paragraphs {
            if p.count >= threshold {
                chosen = p
                break
            }
            if chosen.isEmpty { chosen = p }
        }

        if chosen.count < 160 {
            var combined = ""
            for p in paragraphs {
                if combined.isEmpty {
                    combined = p
                } else if !p.isEmpty {
                    combined += " " + p
                }
                if combined.count >= 160 { break }
            }
            if !combined.isEmpty { chosen = combined }
        }

        return chosen
    }

    func description() -> String {
        let rawDescription = rawDescription()

        let description: String
        if rawDescription.count > 160 {
            let limitIndex = rawDescription.index(rawDescription.startIndex, offsetBy: 160)
            let prefix = String(rawDescription[..<limitIndex])
            // Try to find the last sentence terminator before the limit
            if let lastTerminatorIndex = prefix.lastSentenceTerminator() {
                let end = prefix.index(after: lastTerminatorIndex)
                let sentence = prefix[..<end].trimmingCharacters(in: .whitespacesAndNewlines)
                // If the sentence is reasonably long, use it; otherwise fall back to word-boundary truncation
                if sentence.count >= 40 {  // heuristic minimum length
                    description = String(sentence)
                } else {
                    // word-boundary fallback
                    if let lastSpace = prefix.lastIndex(where: { $0.isWhitespace }) {
                        let trimmed = prefix[..<lastSpace].trimmingCharacters(in: .whitespacesAndNewlines)
                        description = trimmed + "…"
                    } else {
                        description = prefix + "…"
                    }
                }
            } else {
                // No sentence boundary found; fall back to word-boundary truncation with ellipsis
                if let lastSpace = prefix.lastIndex(where: { $0.isWhitespace }) {
                    let trimmed = prefix[..<lastSpace].trimmingCharacters(in: .whitespacesAndNewlines)
                    description = trimmed + "…"
                } else {
                    description = prefix + "…"
                }
            }
        } else {
            // Already within limit; try to end at a sentence boundary if one exists
            if let lastTerminatorIndex = rawDescription.lastSentenceTerminator() {
                let end = rawDescription.index(after: lastTerminatorIndex)
                description = String(rawDescription[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                description = rawDescription
            }
        }

        return description
    }
}
