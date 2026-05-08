import Testing

@testable import App

struct LinkedDataTests {
    @Test func postMainEntityHasType() {
        let ld = PostLinkedData(
            canonical: "https://michaelnisi.com/posts/2025/01/01/test",
            name: "Test", description: "Desc", wordCount: 100)
        #expect(ld.json.contains("\"@type\" : \"Person\""))
    }

    @Test func aboutMainEntityHasType() {
        let ld = AboutLinkedData(name: "About", description: "Desc", wordCount: 50)
        #expect(ld.json.contains("\"@type\" : \"Person\""))
    }

    @Test func nowMainEntityHasType() {
        let ld = NowLinkedData(name: "Now", description: "Desc", wordCount: 50)
        #expect(ld.json.contains("\"@type\" : \"Person\""))
    }

    @Test func archiveMainEntityHasType() {
        let ld = ArchiveLinkedData(name: "Archive")
        #expect(ld.json.contains("\"@type\" : \"Person\""))
    }
}
