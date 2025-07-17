import Foundation

enum Category: Sendable, CaseIterable {
    case personal
    case swiftui
    case swiftserver
    case quote
}

struct Post: Sendable {
    let date: Date
    let html: String
    let category: Category
}

// Not sure about Identifiable yet. Might be
// useful, especially once posts are stored
// in a database.
extension Post: Hashable, Identifiable {
    var id: Int { hashValue }
}
