import Foundation

/// A `FileNode` represents a conceptual file or directory in a tree structure.
///
/// It models the logical layout of content (like markdown files or Mustache templates),
/// regardless of its physical source — which may be the file system, a database,
/// or in-memory structures.
///
/// Used to build virtual file trees from sources such as the bundle’s `Partials`
/// and `Resources` directories.
enum FileNode {
    case file(name: String)
    case directory(name: String, children: [FileNode])
}

extension FileNode {
    func flattenedPaths(prefix: String = "") -> [String] {
        switch self {
        case .file(let name):
            return [prefix + name]
        case .directory(let name, let children):
            let newPrefix = prefix + name + "/"
            return children.flatMap { $0.flattenedPaths(prefix: newPrefix) }
        }
    }
}

extension FileNode {
    func find(name targetName: String) -> FileNode? {
        switch self {
        case .file(let name):
            return name == targetName ? self : nil
        case .directory(let name, let children):
            if name == targetName {
                return self
            }
            for child in children {
                if let match = child.find(name: targetName) {
                    return match
                }
            }
            return nil
        }
    }
}

extension FileNode {
    func allFiles(path: String = "") -> [(path: String, node: FileNode)] {
        switch self {
        case .file(let name):
            return [(path + name, self)]
        case .directory(let name, let children):
            let prefix = path + name + "/"
            return children.flatMap { $0.allFiles(path: prefix) }
        }
    }
}

extension FileNode {
    func walk(_ visit: (FileNode) -> Void) {
        visit(self)
        if case .directory(_, let children) = self {
            for child in children {
                child.walk(visit)
            }
        }
    }
}

extension FileNode {
    func prettyDescription(indent: String = "") -> String {
        switch self {
        case .file(let name):
            return "\(indent) \(name)"
        case .directory(let name, let children):
            let header = "\(indent) \(name)"
            let childDescriptions = children.map { $0.prettyDescription(indent: indent + "  ") }
            return ([header] + childDescriptions).joined(separator: "\n")
        }
    }
}

extension FileNode: CustomStringConvertible {
    public var description: String {
        prettyDescription()
    }
}
