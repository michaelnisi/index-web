import Foundation
import Hummingbird
import HummingbirdCompression
import Logging
import Mustache

public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level { get }
}

typealias AppRequestContext = BasicRequestContext

public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let serverName = "Index/\(Version.current)"

    let logger = {
        var logger = Logger(label: serverName)
        logger.logLevel = arguments.logLevel

        return logger
    }()

    let router = try await buildRouter(logger: logger)
    let address = BindAddress.hostname(arguments.hostname, port: arguments.port)

    let app = Application(
        router: router,
        configuration: .init(address: address, serverName: serverName),
        logger: logger
    )

    return app
}

private func buildRouter(logger: Logger) async throws -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)

    router.addMiddleware {
        LogErrorsMiddleware()
        LogRequestsMiddleware(logger.logLevel)
        RequestDecompressionMiddleware()
        FileMiddleware(cacheControl: .allMediaTypes(maxAge: 86400), logger: logger)
        ETagVaryMiddleware()
        ResponseCompressionMiddleware(minimumResponseSizeToCompress: 512)
        HeadMiddleware()
    }

    guard let directory = Bundle.module.resourcePath else {
        fatalError("no resource path")
    }

    let templates = try await MustacheLibrary(
        directory: directory,
        withExtension: "html"
    )

    let markdownFiles = try FileNode(directory: directory)

    markdownFiles.logPaths(logger: logger)

    let cache = KeyValueStore<String, String>()

    WebsiteController(
        markdownTree: markdownFiles,
        mustacheLibrary: templates,
        logger: logger,
        cache: cache
    )
    .addRoutes(to: router)

    JSONFeedController(
        markdownTree: markdownFiles,
        logger: logger
    )
    .addRoutes(to: router)

    RSSFeedController(
        markdownTree: markdownFiles,
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

    func logPaths(logger: Logger) {
        let paths = flattenedPaths()
        typealias MetadataValue = Logger.MetadataValue
        let files = MetadataValue.array(paths.map(MetadataValue.string))

        logger.debug("Using file tree", metadata: { ["files": files] }())
    }
}

extension MediaType.Category {
    fileprivate static let all: [MediaType.Category] = [.application, .audio, .example, .font, .message, .model, .multipart, .text, .video]
}

extension MediaType {
    fileprivate static let all: [MediaType] = MediaType.Category.all.map { MediaType(type: $0) }
}

extension CacheControl {
    fileprivate static func allMediaTypes(maxAge: Int) -> CacheControl {
        .init(MediaType.all.map { ($0, [.public, .maxAge(maxAge)]) })
    }
}
