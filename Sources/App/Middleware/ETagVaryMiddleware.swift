import Foundation
import HTTPTypes
import Hummingbird
import NIOCore

public struct ETagVaryMiddleware<Context: RequestContext>: RouterMiddleware {
    public init() {}

    /// Ensures "Vary: Accept-Encoding" is present on 200 OK responses that include an ETag.
    /// This avoids caches mixing compressed and uncompressed variants under the same ETag.
    public func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        var response = try await next(request, context)

        guard response.status == .ok else {
            return response
        }

        guard response.headers[.eTag] != nil else {
            return response
        }

        if let vary = response.headers[.vary], !vary.isEmpty {
            let components = vary.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if !components.contains("Accept-Encoding") {
                response.headers[.vary] = vary + ", Accept-Encoding"
            }
        } else {
            response.headers[.vary] = "Accept-Encoding"
        }

        return response
    }
}
