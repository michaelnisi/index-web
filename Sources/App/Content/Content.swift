import Foundation

struct Content {
    let html: String
    let date: Date
    let title: String
    let canonical: String
    let description: String
    let wordCount: Int
}

extension String {
    func strippingLeadingH1() -> String {
        guard let range = range(of: #"^<h1>.*?</h1>\n?"#, options: .regularExpression) else {
            return self
        }

        return String(self[range.upperBound...])
    }
}
