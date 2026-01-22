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
    var name: String {
        switch self {
        case let .file(name):
            return name
        case let .directory(name, _):
            return name
        }
    }
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
    func find(path: String) -> FileNode? {
        let components =
            path
            .split(separator: "/")
            .map(String.init)

        return find(pathComponents: components)
    }

    private func find(pathComponents: [String]) -> FileNode? {
        guard let head = pathComponents.first else {
            return self
        }

        switch self {
        case .file(let name):
            return (pathComponents.count == 1 && name == head) ? self : nil

        case .directory(_, let children):
            for child in children {
                switch child {
                case .file(let name) where name == head:
                    if pathComponents.count == 1 {
                        return child
                    }
                case .directory(let name, _):
                    if name == head {
                        return child.find(pathComponents: Array(pathComponents.dropFirst()))
                    }
                default:
                    continue
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
    func prettyDescription(indent: String = "") -> String {
        switch self {
        case .file(let name):
            return "\(indent)\(name)"
        case .directory(let name, let children):
            let header = "\(indent)\(name)"
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

extension FileNode: Equatable {
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        switch (lhs, rhs) {
        case let (.file(a), .file(b)):
            return a == b
        case let (.directory(aName, aChildren), .directory(bName, bChildren)):
            return aName == bName && aChildren == bChildren
        default:
            return false
        }
    }
}

extension FileNode {
    func findWithPath(path: String) -> (node: FileNode, path: String)? {
        let components =
            path
            .split(separator: "/")
            .map(String.init)

        return findWithPath(components: components, currentPath: "")
    }

    private func findWithPath(components: [String], currentPath: String) -> (node: FileNode, path: String)? {
        guard let head = components.first else {
            return (self, currentPath)
        }

        switch self {
        case .file(let name):
            if components.count == 1 && name == head {
                return (self, currentPath.isEmpty ? name : "\(currentPath)/\(name)")
            }
            return nil

        case .directory(_, let children):
            for child in children {
                let name: String
                switch child {
                case .file(let n): name = n
                case .directory(let n, _): name = n
                }

                if name == head {
                    let nextPath = currentPath.isEmpty ? name : "\(currentPath)/\(name)"
                    return child.findWithPath(components: Array(components.dropFirst()), currentPath: nextPath)
                }
            }
            return nil
        }
    }
}

extension FileNode {
    func allNodes(matching name: String, path: String = "") -> [(path: String, node: FileNode)] {
        var results: [(String, FileNode)] = []

        switch self {
        case .file(let fileName):
            let fullPath = path.isEmpty ? fileName : "\(path)/\(fileName)"
            if fileName == name {
                results.append((fullPath, self))
            }

        case .directory(let dirName, let children):
            let currentPath = path.isEmpty ? dirName : "\(path)/\(dirName)"
            if dirName == name {
                results.append((currentPath, self))
            }
            for child in children {
                results += child.allNodes(matching: name, path: currentPath)
            }
        }

        return results
    }
}
