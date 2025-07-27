import Foundation

extension ContentProvider {
    static let mock: ContentProvider = .init(
        dependencies: .init(partial: getPartial)
    )
}

private func getPartial(path: String) async throws -> HTMLPartial {
    .mock
}

extension HTMLPartial {
    static let mock: HTMLPartial = .init(
        html: MarkdownHTMLTransformer.html(from: markdownSource)
    )
}

private let markdownSource = """
    # Hello Markdown

    This is **bold** and *italic* text, with a [link](http://example.com).

    - Item 1
    - Item 2

    | Column A | Column B |
    |---------|---------:|
    | Cell 1A | Cell 1B  |
    | Cell 2A | Cell 2B  |

    Here is code:

    ```swift
    import Hummingbird
    import Mustache
    import Foundation
    import MarkdownKit

    struct WebsiteController {
        let mustacheLibrary: MustacheLibrary
        
        func addRoutes(to router: Router<some RequestContext>) {
            router.get("/", use: indexHandler)
        }
        
        @Sendable func indexHandler(request: Request, context: some RequestContext) async throws -> HTML {
            let doc = MarkdownParser.standard.parse(markdownSource)
            let string = HtmlGenerator.standard.generate(doc: doc)
            let data = ["post": string]
            
            guard let html = mustacheLibrary.render(data, withTemplate: "index") else {
                throw HTTPError(.internalServerError, message: "Failed to render template.")
            }
            
            return HTML(html: html)
        }
    }

    struct HTML: ResponseGenerator {
        let html: String

        public func response(from request: Request, context: some RequestContext) throws -> Response {
            let buffer = ByteBuffer(string: self.html)
            
            return .init(status: .ok, headers: [.contentType: "text/html"], body: .init(byteBuffer: buffer))
        }
    }
    ```

    This is an example of the `WebsiteController` that renders this site.
    """
