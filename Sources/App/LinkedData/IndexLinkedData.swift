import Foundation

struct IndexLinkedData: LinkedData {
    let context = "https://schema.org"
    let graph: [GraphElement]

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case graph = "@graph"
    }

    enum GraphElement: Encodable {
        case webSite(WebSite)
        case webPage(WebPage)
        case person(Person)

        func encode(to encoder: Encoder) throws {
            switch self {
            case .webSite(let site):
                try site.encode(to: encoder)
            case .webPage(let page):
                try page.encode(to: encoder)
            case .person(let person):
                try person.encode(to: encoder)
            }
        }
    }

    struct WebSite: Codable {
        let type: String
        let id: String
        let url: String
        let name: String
        let inLanguage: String

        enum CodingKeys: String, CodingKey {
            case type = "@type"
            case id = "@id"
            case url
            case name
            case inLanguage
        }
    }

    struct WebPage: Codable {
        let type: String
        let id: String
        let url: String
        let name: String
        let isPartOf: LinkedDataReference
        let primaryImageOfPage: ImageObject

        enum CodingKeys: String, CodingKey {
            case type = "@type"
            case id = "@id"
            case url
            case name
            case isPartOf
            case primaryImageOfPage
        }
    }

    struct Person: Codable {
        let type: String
        let id: String
        let name: String
        let url: String
        let image: String
        let description: String
        let jobTitle: String
        let worksFor: Organization
        let sameAs: [String]
        let knowsAbout: [String]

        enum CodingKeys: String, CodingKey {
            case type = "@type"
            case id = "@id"
            case name
            case url
            case image
            case description
            case jobTitle
            case worksFor
            case sameAs
            case knowsAbout
        }
    }

    struct Organization: Codable {
        let type: String
        let name: String

        enum CodingKeys: String, CodingKey {
            case type = "@type"
            case name
        }
    }

    struct ImageObject: Codable {
        let type: String
        let url: String

        enum CodingKeys: String, CodingKey {
            case type = "@type"
            case url
        }
    }

    init(title: String) {
        let imageURL = "https://res.cloudinary.com/duiiv2f8o/image/upload/v1762078766/IMG_0126_xws0m4.jpg"
        let site = WebSite(
            type: "WebSite",
            id: "https://michaelnisi.com#website",
            url: "https://michaelnisi.com",
            name: "Michael Nisi",
            inLanguage: "en"
        )
        let page = WebPage(
            type: "WebPage",
            id: "https://michaelnisi.com#webpage",
            url: "https://michaelnisi.com",
            name: title,
            isPartOf: LinkedDataReference(id: "https://michaelnisi.com#website"),
            primaryImageOfPage: ImageObject(type: "ImageObject", url: imageURL)
        )
        let person = Person(
            type: "Person",
            id: "https://michaelnisi.com#person",
            name: "Michael Nisi",
            url: "https://michaelnisi.com",
            image: imageURL,
            description:
                "Michael Nisi is a seasoned Apple-platform software engineer, Swift maximalist, type-driven design enthusiast, and full-time romantic about the personal web — currently balancing strict Swift 6 concurrency, Solarized color systems, Swiss-grid typography, and single-fin longboard sessions between Cantabria, Thy, and the rest of Europe.",
            jobTitle: "Software Engineer",
            worksFor: Organization(type: "Organization", name: "apploft."),
            sameAs: [
                "https://keybase.io/nisi",
                "https://linktr.ee/michaelnisi",
                "https://github.com/michaelnisi",
                "https://instagram.com/podustle/",
                "https://michaelnisi.substack.com/",
                "https://flickr.com/people/michaelnisi/",
                "https://mubi.com/en/users/164590",
                "https://forums.swift.org/u/mic",
            ],
            knowsAbout: ["Apple", "iOS", "Swift", "Literature", "Music", "Movies", "Surfing"]
        )
        self.graph = [.webSite(site), .webPage(page), .person(person)]
    }
}
