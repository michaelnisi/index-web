import Foundation
import Markdown

private struct HTMLVisitor: MarkupVisitor {
    typealias Result = String

    // Required fallback
    mutating func defaultVisit(_ markup: any Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

    // Required overrides for node types we want to handle
    mutating func visitDocument(_ doc: Document) -> String {
        doc.children.map { visit($0) }.joined(separator: "\n")
    }

    mutating func visitHeading(_ h: Heading) -> String {
        "<h\(h.level)>" + h.children.map { visit($0) }.joined() + "</h\(h.level)>"
    }

    mutating func visitParagraph(_ p: Paragraph) -> String {
        "<p>" + p.children.map { visit($0) }.joined() + "</p>"
    }

    mutating func visitText(_ t: Text) -> String {
        escape(t.string)
    }

    mutating func visitInlineCode(_ ic: InlineCode) -> String {
        "<code>\(escape(ic.code))</code>"
    }

    mutating func visitCodeBlock(_ cb: CodeBlock) -> String {
        let lang = cb.language.map { " class=\"language-\($0)\"" } ?? ""
        return "<pre><code\(lang)>\(escape(cb.code))</code></pre>"
    }

    mutating func visitSoftBreak(_ _: SoftBreak) -> String { "\n" }
    mutating func visitLineBreak(_ _: LineBreak) -> String { "<br>" }
    mutating func visitEmphasis(_ em: Emphasis) -> String {
        "<em>" + em.children.map { visit($0) }.joined() + "</em>"
    }

    mutating func visitStrong(_ s: Strong) -> String {
        "<strong>" + s.children.map { visit($0) }.joined() + "</strong>"
    }

    mutating func visitLink(_ l: Link) -> String {
        let d = escape(l.destination ?? "#")
        let t = l.title.map { " title=\"\(escape($0))\"" } ?? ""
        let body = l.children.map { visit($0) }.joined()
        return "<a href=\"\(d)\"\(t)>\(body)</a>"
    }

    mutating func visitThematicBreak(_ _: ThematicBreak) -> String { "<hr>" }
    mutating func visitBlockQuote(_ q: BlockQuote) -> String {
        "<blockquote>\(q.children.map { visit($0) }.joined())</blockquote>"
    }

    // --- helper ---
    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

public enum MarkdownHTMLTransformer {
    public static func html(from markdown: String) -> String {
        var v = HTMLVisitor()
        let doc = Document(parsing: markdown)
        return v.visit(doc)
    }
}
