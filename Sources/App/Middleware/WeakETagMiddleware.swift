import Foundation
import HTTPTypes
import Hummingbird
import NIOCore

public struct WeakETagMiddleware<Context: RequestContext>: RouterMiddleware {
    public init() {}

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
