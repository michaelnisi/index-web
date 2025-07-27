import Testing

@testable import App

struct RequestPathTests {
    @Test func markdownPath() {
        #expect("/".markdownPath() == "index.md")
        #expect("/index.html".markdownPath() == "index.md")
        #expect("/index.htm".markdownPath() == "index.md")
        #expect("/index.md".markdownPath() == "index.md")

        #expect("/about".markdownPath() == "about.md")
        #expect("/about.html".markdownPath() == "about.md")
        #expect("/about.htm".markdownPath() == "about.md")

        #expect("/posts/2025/7/hello".markdownPath() == "posts/2025-07-hello.md")
        #expect("/posts/2025/07/hello".markdownPath() == "posts/2025-07-hello.md")
        #expect("/posts/2025/07/hello.html".markdownPath() == "posts/2025-07-hello.md")
        #expect("/posts/2025/07/hello.htm".markdownPath() == "posts/2025-07-hello.md")

        #expect("/posts/20x5/07/hello".markdownPath() == "posts/20x5/07/hello.md")
        #expect("/posts/2025/13/hello".markdownPath() == "posts/2025/13/hello.md")
        #expect("/posts/2025//hello".markdownPath() == "posts/2025//hello.md")
    }
}
