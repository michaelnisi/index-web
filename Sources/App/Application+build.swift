import Foundation
import Hummingbird
import Logging
import Mustache
import System

public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

typealias AppRequestContext = BasicRequestContext

public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()

    let logger = {
        var logger = Logger(label: "Index")
        logger.logLevel = arguments.logLevel ?? environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .info

        return logger
    }()

    let router = try await buildRouter()

    return Application(
        router: router,
        configuration: .init(
            address: .hostname(
                arguments.hostname,
                port: arguments.port
            ),
            serverName: "Index"
        ),
        logger: logger
    )
}

private func buildRouter() async throws -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)

    router.addMiddleware {
        LogRequestsMiddleware(.info)
        FileMiddleware()
    }

    let templates = try await buildTemplates()

    WebsiteController(mustacheLibrary: templates)
        .addRoutes(to: router)

    return router
}

private func buildTemplates() async throws -> MustacheLibrary {
    guard let directory = Bundle.module.resourcePath else {
        fatalError("no resource path")
    }

    printTree(at: FilePath(directory))

    let templates = try await MustacheLibrary(
        directory: directory,
        withExtension: "html"
    )

    assert(templates.getTemplate(named: "page") != nil)

    return templates
}
