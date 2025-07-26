import XCTest
@testable import App

final class RequestPathTests: XCTestCase {
    func testMarkdownPath() {
        XCTAssertEqual("/".markdownPath(), "index.md")
        XCTAssertEqual("/index.html".markdownPath(), "index.md")
        XCTAssertEqual("/index.htm".markdownPath(), "index.md")
        XCTAssertEqual("/index.md".markdownPath(), "index.md")

        XCTAssertEqual("/about".markdownPath(), "about.md")
        XCTAssertEqual("/about.html".markdownPath(), "about.md")
        XCTAssertEqual("/about.htm".markdownPath(), "about.md")

        XCTAssertEqual("/posts/2025/7/hello".markdownPath(), "posts/2025-07-hello.md")
        XCTAssertEqual("/posts/2025/07/hello".markdownPath(), "posts/2025-07-hello.md")
        XCTAssertEqual("/posts/2025/07/hello.html".markdownPath(), "posts/2025-07-hello.md")
        XCTAssertEqual("/posts/2025/07/hello.htm".markdownPath(), "posts/2025-07-hello.md")

        XCTAssertEqual("/posts/20x5/07/hello".markdownPath(), "posts/20x5/07/hello.md")
        XCTAssertEqual("/posts/2025/13/hello".markdownPath(), "posts/2025/13/hello.md")
        XCTAssertEqual("/posts/2025//hello".markdownPath(), "posts/2025//hello.md")
    }
}
