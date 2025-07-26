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

    guard let directory = Bundle.module.resourcePath else {
        fatalError("no resource path")
    }

    let templates = try await MustacheLibrary(
        directory: directory,
        withExtension: "html"
    )

    let markdownFiles = try FileNode(directory: directory)

    WebsiteController(
        markdownTree: markdownFiles,
        mustacheLibrary: templates
    )
    .addRoutes(to: router)

    return router
}

extension FileNode {
    enum Failure: Error {
        case noResourcePath(String)
        case noURL(FilePath)
    }

    init(directory: String) throws {
        guard let directory = Bundle.module.resourcePath else {
            throw Failure.noResourcePath(directory)
        }

        let filePath = FilePath(directory)
        guard let url = URL(filePath: filePath) else {
            throw Failure.noURL(filePath)
        }

        self = try buildFileTree(at: url)
    }
}
