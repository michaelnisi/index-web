import System
import XCTest

@testable import App

final class FilePathTests: XCTestCase {
    func testPostFlowTypes() {
        XCTAssertTrue(makePostFlow(string: "/posts/2025/07/hello") is PostFile)
        XCTAssertTrue(makePostFlow(string: "/posts/2025") is PostDirectory)
        XCTAssertTrue(makePostFlow(string: "/dog") is PostIgnore)
    }

    func testPostsPath() throws {
        let paths: [(String, String)] = [
            ("/posts/2025/07/hello", "2025-07-hello.md"),
            ("/posts/2025/07//hello///", "2025-07-hello.md"),
            ("/posts", "posts"),
            ("/posts/", "posts"),
            ("/posts/2025", "2025"),
            ("/posts/2025/", "2025"),
            ("/posts/2025/07", "2025-07"),
        ]

        for path in paths {
            let postFlow: PostFlow = makePostFlow(string: path.0)

            XCTAssertEqual(postFlow.filePath.lastComponent, FilePath.Component(path.1))
        }
    }
}
