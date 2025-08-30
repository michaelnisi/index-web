import Foundation
import Hummingbird
import Logging
import Mustache

public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level { get }
}

typealias AppRequestContext = BasicRequestContext

public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let serverName = "Index"

    let logger = {
        var logger = Logger(label: serverName)
        logger.logLevel = arguments.logLevel

        return logger
    }()

    let router = try await buildRouter(logger: logger)

    return Application(
        router: router,
        configuration: .init(
            address: .hostname(
                arguments.hostname,
                port: arguments.port
            ),
            serverName: serverName
        ),
        logger: logger
    )
}

private func buildRouter(logger: Logger) async throws -> Router<AppRequestContext> {
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

    logger.debug(
        "Initializing WebsiteController",
        metadata: { ["files": .array(markdownFiles.flattenedPaths().map { .string($0) })] }()
    )

    WebsiteController(
        markdownTree: markdownFiles,
        mustacheLibrary: templates,
        logger: logger
    )
    .addRoutes(to: router)

    return router
}

extension FileNode {
    enum Failure: Error {
        case noResourcePath(String)
    }

    init(directory: String) throws {
        guard let directory = Bundle.module.resourcePath else {
            throw Failure.noResourcePath(directory)
        }

        let url = URL(fileURLWithPath: directory)

        self = try buildFileTree(at: url)
    }
}
