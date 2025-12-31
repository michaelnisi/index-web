import Foundation

struct NowLinkedData: LinkedData {
    let context: String
    let type: String
    let id: String
    let url: String
    let name: String
    let description: String
    let wordCount: Int
    let inLanguage: String
    let isPartOf: LinkedDataReference
    let mainEntity: LinkedDataReference

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type = "@type"
        case id = "@id"
        case url
        case name
        case description
        case wordCount
        case inLanguage
        case isPartOf
        case mainEntity
    }

    init(name: String, description: String, wordCount: Int) {
        self.context = "https://schema.org"
        self.type = "ProfilePage"
        self.id = "https://michaelnisi.com/now#webpage"
        self.url = "https://michaelnisi.com/now"
        self.name = name
        self.description = description
        self.wordCount = wordCount
        self.inLanguage = "en"
        self.isPartOf = LinkedDataReference(id: "https://michaelnisi.com#website")
        self.mainEntity = LinkedDataReference(id: "https://michaelnisi.com#person")
    }
}
