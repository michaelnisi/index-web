import Crypto
import Foundation
import Hummingbird

extension Response {
    static func ifNoneMatch(html: String, request: Request) -> Response {
        let buffer = ByteBuffer(string: html)
        let tag = weakETag(for: buffer)

        var headers = defaultHeaders
        headers[.eTag] = tag
        ensureVaryAcceptEncoding(&headers)

        if request.method == .head {
            return .init(status: .ok, headers: headers)
        }

        if let ifNoneMatch = request.headers[.ifNoneMatch] {
            let candidates = ifNoneMatch.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if candidates.contains(tag) {
                return .init(status: .notModified, headers: headers)
            }
        }

        return .init(status: .ok, headers: headers, body: .init(byteBuffer: buffer))
    }
}

extension Response {
    fileprivate static func weakETag(for buffer: ByteBuffer) -> String {
        let view = buffer.readableBytesView
        let digest = SHA256.hash(data: Data(view))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "W/\"\(hex)\""
    }

    fileprivate static func ensureVaryAcceptEncoding(_ headers: inout HTTPFields) {
        if let vary = headers[.vary], !vary.isEmpty {
            let components = vary.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if !components.contains("Accept-Encoding") {
                headers[.vary] = vary + ", Accept-Encoding"
            }
        } else {
            headers[.vary] = "Accept-Encoding"
        }
    }

    fileprivate static let defaultHeaders: HTTPFields = [
        .contentType: "text/html; charset=utf-8",
        .cacheControl: "public, max-age=86400, stale-while-revalidate=604800, stale-if-error=604800",
        .connection: "keep-alive",
    ]
}
