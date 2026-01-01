import Foundation

struct ArchiveLinkedData: LinkedData {
    let context: String = "https://schema.org"
    let type: String = "WebPage"
    let id: String = "https://michaelnisi.com/archive)#webpage"
    let url = "https://michaelnisi.com/archive"
    let name: String
    let inLanguage: String = "en"
    let isPartOf = LinkedDataReference(id: "https://michaelnisi.com#website")
    let mainEntity = LinkedDataReference(id: "https://michaelnisi.com#person")

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type = "@type"
        case id = "@id"
        case url
        case name
        case inLanguage
        case isPartOf
        case mainEntity
    }

    init(name: String) {
        self.name = name
    }
}
