import Foundation

struct NowLinkedData: LinkedData {
    let context = "https://schema.org"
    let type = "ProfilePage"
    let id = "https://michaelnisi.com/now#webpage"
    let url = "https://michaelnisi.com/now"
    let name: String
    let description: String
    let wordCount: Int
    let inLanguage = "en"
    let isPartOf = LinkedDataReference(id: "https://michaelnisi.com#website")
    let mainEntity = LinkedDataReference(id: "https://michaelnisi.com#person")

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
        self.name = name
        self.description = description
        self.wordCount = wordCount
    }
}
