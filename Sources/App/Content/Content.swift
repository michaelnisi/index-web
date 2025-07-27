import Foundation

struct HTMLPartial: Sendable {
    let html: String
}

// Not sure about Identifiable yet. Might be
// useful, especially once posts are stored
// in a database.
extension HTMLPartial: Hashable, Identifiable {
    var id: Int { hashValue }
}
