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

    mutating func visitImage(_ i: Image) -> String {
        let src = escape(i.source ?? "")
        let titleAttr = i.title.map { " title=\"\(escape($0))\"" } ?? ""
        let altText = escape(plainText(i))
        return "<img class=\"inline_image\" src=\"\(src)\" alt=\"\(altText)\"\(titleAttr)>"
    }

    mutating func visitThematicBreak(_ _: ThematicBreak) -> String { "<hr>" }
    mutating func visitBlockQuote(_ q: BlockQuote) -> String {
        "<blockquote>\(q.children.map { visit($0) }.joined())</blockquote>"
    }

    // --- helper ---
    private func plainText(_ markup: any Markup) -> String {
        if let t = markup as? Text {
            return t.string
        }
        return markup.children.map { plainText($0) }.joined()
    }
    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

private func plainText(_ markup: any Markup) -> String {
    if let t = markup as? Text { return t.string }
    return markup.children.map { plainText($0) }.joined()
}

public enum MarkdownHTMLTransformer {
    @available(*, deprecated, message: "use htmlAndTitle")
    public static func html(from markdown: String) -> String {
        var v = HTMLVisitor()
        let doc = Document(parsing: markdown)

        return v.visit(doc)
    }

    public struct HTMLAndTitle {
        public let html: String
        public let title: String
        public init(html: String, title: String) {
            self.html = html
            self.title = title
        }
    }

    public static func htmlAndTitle(from markdown: String) -> HTMLAndTitle {
        var v = HTMLVisitor()
        let doc = Document(parsing: markdown)
        let html = v.visit(doc)
        let firstTopLevelHeading = doc.children.compactMap { $0 as? Heading }.first
        let title = firstTopLevelHeading.map { plainText($0) } ?? ""
        return HTMLAndTitle(html: html, title: title)
    }
}
