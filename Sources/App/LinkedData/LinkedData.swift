import Foundation

protocol LinkedData: Encodable {
    var json: String { get }
}

struct LinkedDataReference: Codable {
    let id: String
    enum CodingKeys: String, CodingKey { case id = "@id" }
}

extension LinkedData {
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
            assertionFailure("Failed to encode LinkedData: \(error)")
            return "{}"
        }
    }
}
