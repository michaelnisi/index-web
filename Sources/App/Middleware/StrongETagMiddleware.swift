import Foundation
import Hummingbird
import CryptoKit
import NIOCore
import HTTPTypes

public struct StrongETagMiddleware<Context: RequestContext>: RouterMiddleware {
    public init() {}

    public func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        var response = try await next(request, context)

        // Only consider successful responses and don't overwrite existing ETag
        guard response.status == .ok, response.headers[.eTag] == nil else {
            return response
        }

        // Collect the final response body into memory so we can hash exact bytes
        var collector = CollectingBodyWriter()
        try await response.body.write(collector)

        // Compute SHA-256 over collected buffers
        var hasher = SHA256()
        var totalLength = 0
        for var buf in collector.buffers {
            let view = buf.readableBytesView
            hasher.update(data: Data(view))
            totalLength += view.count
        }
        let digest = hasher.finalize()
        let etag = "\"" + digest.map { String(format: "%02x", $0) }.joined() + "\""

        // Ensure Vary includes Accept-Encoding
        if let vary = response.headers[.vary], !vary.isEmpty {
            let components = vary.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if !components.contains("Accept-Encoding") {
                response.headers[.vary] = vary + ", Accept-Encoding"
            }
        } else {
            response.headers[.vary] = "Accept-Encoding"
        }

        // If-None-Match short-circuit
        if let ifNoneMatch = request.headers[.ifNoneMatch] {
            let candidates = ifNoneMatch.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if candidates.contains(etag) {
                response.status = .notModified
                response.headers[.eTag] = etag
                response.body = ResponseBody() // empty
                response.headers[.contentLength] = "0"
                return response
            }
        }

        // Rebuild the body from collected buffers without capturing `collector`
        var combined = ByteBufferAllocator().buffer(capacity: totalLength)
        for buf in collector.buffers {
            let view = buf.readableBytesView
            combined.writeBytes(view)
        }
        response.headers[.eTag] = etag
        response.body = ResponseBody(byteBuffer: combined)
        if response.headers[.contentLength] == nil {
            response.headers[.contentLength] = String(totalLength)
        }

        return response
    }
}

// A ResponseBodyWriter that collects all written buffers into memory
private struct CollectingBodyWriter: ResponseBodyWriter {
    var buffers: [ByteBuffer] = []

    mutating func write(_ buffer: ByteBuffer) async throws {
        buffers.append(buffer)
    }

    mutating func write(contentsOf buffers: some Sequence<ByteBuffer>) async throws {
        self.buffers.append(contentsOf: buffers)
    }

    consuming func finish(_ trailingHeaders: HTTPFields?) async throws {
        // No-op for collector; we ignore trailers here
    }
}

