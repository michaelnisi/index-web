import System
import XCTest

@testable import App

final class FileNodeTests: XCTestCase {
    func testFind() {
        let tree = FileNode.directory(
            name: "root",
            children: [
                .file(name: "README.md"),
                .directory(
                    name: "Sources",
                    children: [
                        .file(name: "main.swift"),
                        .file(name: "utils.swift"),
                    ]
                ),
                .directory(
                    name: "Tests",
                    children: [
                        .file(name: "main.swift")  // duplicate name
                    ]
                ),
            ]
        )
        XCTAssertEqual(tree.find(name: "README.md"), .file(name: "README.md"))

        XCTAssertEqual(
            tree.find(name: "Sources"),
            .directory(
                name: "Sources",
                children: [
                    .file(name: "main.swift"),
                    .file(name: "utils.swift"),
                ]
            )
        )

        XCTAssertEqual(tree.find(name: "main.swift"), .file(name: "main.swift"))  // finds the first one

        XCTAssertEqual(tree.find(name: "utils.swift"), .file(name: "utils.swift"))

        XCTAssertNil(tree.find(name: "missing.md"))
    }
}
