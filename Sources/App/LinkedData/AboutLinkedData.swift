import Foundation

struct AboutLinkedData: Codable {
    let context: String
    let type: String
    let id: String
    let url: String
    let inLanguage: String
    let name: String
    let description: String
    let wordCount: Int
    let isPartOf: ThingRef
    let mainEntity: ThingRef

    private enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type = "@type"
        case id = "@id"
        case url
        case inLanguage
        case name
        case description
        case wordCount
        case isPartOf
        case mainEntity
    }

    struct ThingRef: Codable {
        let id: String

        private enum CodingKeys: String, CodingKey {
            case id = "@id"
        }
    }

    init(name: String, description: String, wordCount: Int) {
        self.context = "https://schema.org"
        self.type = "ProfilePage"
        self.id = "https://michaelnisi.com/about#webpage"
        self.url = "https://michaelnisi.com/about"
        self.inLanguage = "en"
        self.name = name
        self.description = description
        self.wordCount = wordCount
        self.isPartOf = ThingRef(id: "https://michaelnisi.com#website")
        self.mainEntity = ThingRef(id: "https://michaelnisi.com#person")
    }

    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if #available(macOS 13, iOS 16, *) {
            encoder.outputFormatting.insert(.withoutEscapingSlashes)
        }

        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            assertionFailure("Failed to encode AboutLinkedData: \(error)")
            return "{}"
        }
    }
}
