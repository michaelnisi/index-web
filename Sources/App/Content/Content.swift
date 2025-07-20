import Foundation

enum Category: String, Sendable, CaseIterable {
    case personal
    case swiftui
    case swiftserver
    case quote
}

struct HTMLPartial: Sendable {
    let date: Date
    let html: String
    let category: Category
}

// Not sure about Identifiable yet. Might be
// useful, especially once posts are stored
// in a database.
extension HTMLPartial: Hashable, Identifiable {
    var id: Int { hashValue }
}
