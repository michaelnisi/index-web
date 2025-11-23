import Hummingbird
import Logging

struct LogErrorsMiddleware<Context: RequestContext>: RouterMiddleware {
    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        do {
            return try await next(request, context)
        } catch {
            let metadata: Logger.Metadata = [
                "path": .string(request.uri.path),
                "error": .string(error.localizedDescription),
            ]

            context.logger.error("Error in route", metadata: metadata)
            throw error
        }
    }
}
