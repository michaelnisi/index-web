import Foundation
import Markdown

private struct HTMLVisitor: MarkupVisitor {
    typealias Result = String

    mutating func defaultVisit(_ markup: any Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

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
        t.string.escape()
    }

    mutating func visitInlineCode(_ ic: InlineCode) -> String {
        "<code>\(ic.code.escape())</code>"
    }

    mutating func visitCodeBlock(_ cb: CodeBlock) -> String {
        let lang = cb.language.map { " class=\"language-\($0)\"" } ?? ""

        return "<pre><code\(lang)>\(cb.code.escape())</code></pre>"
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
        let d = l.destination?.escape() ?? "#"
        let t = l.title.map { " title=\"\($0.escape())\"" } ?? ""
        let body = l.children.map { visit($0) }.joined()

        return "<a href=\"\(d)\"\(t)>\(body)</a>"
    }

    mutating func visitImage(_ i: Image) -> String {
        let src = i.source?.escape() ?? ""
        let titleAttr = i.title.map { " title=\"\($0.escape())\"" } ?? ""
        let altText = i.plainText.escape()

        return "<img class=\"inline_image\" src=\"\(src)\" alt=\"\(altText)\"\(titleAttr)>"
    }

    mutating func visitThematicBreak(_ _: ThematicBreak) -> String { "<hr>" }
    mutating func visitBlockQuote(_ q: BlockQuote) -> String {
        "<blockquote>\(q.children.map { visit($0) }.joined())</blockquote>"
    }
}

enum MarkdownHTMLTransformer {
    static func content(from markdown: String, canonical: String, date: Date) -> Content {
        var visitor = HTMLVisitor()
        let document = Document(parsing: markdown)
        let html = visitor.visit(document)
        let firstTopLevelHeading = document.children.compactMap { $0 as? Heading }.first
        let title = firstTopLevelHeading.map(\.plainText) ?? ""
        let description = document.description()
        let fullPlain = document.plainText
        let wordCount = fullPlain.split { $0.isWhitespace || $0.isNewline }.filter { !$0.isEmpty }.count

        return .init(
            html: html,
            date: date,
            title: title,
            canonical: canonical,
            description: description,
            wordCount: wordCount
        )
    }
}
