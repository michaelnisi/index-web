import HTTPTypes
import Hummingbird
import NIOCore

public struct HeadMiddleware<Context: RequestContext>: RouterMiddleware {
    public init() {}

    public func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        let response = try await next(request, context)

        guard request.method == .head else {
            return response
        }

        return Response(status: response.status, headers: response.headers, body: .init())
    }
}
