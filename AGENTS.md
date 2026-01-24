# AGENTS.md — Architecture Guide

`index-web` is a personal website (https://michaelnisi.com) built with server-side Swift. 

The stack is **Hummingbird** (HTTP server), **Markdown-to-HTML** transformation, and **Mustache templates** for rendering pages.

---

## General Instructions

Pay attention to these general instructions and closely follow them!

- **Always prefer readability over conciseness/compactness.**
- **Never commit unless instructed to do so.**
- Keep `Version.swift` as a build artifact; do not commit or rely on it in git history.
- Git tags are the single source of truth for versioning and releases.
- When editing GitHub Actions, preserve idempotency (re-runs should not create new tags or duplicate changelog entries).
- For changelog updates, keep the `# Changelog` header and description at the top; insert new entries below them without extra blank lines between the header and bullets.
- Use annotated tags (`git tag -a vN -m "Release vN"`) for releases.

### When you are done

- Always build the project to check for compilation errors.
- When you have added or modified Swift files, always run `swiftformat --config ".swiftformat" {files}`.
- Ask the user before committing changes.

## Build Instructions

### Using Makefile (Recommended)
The project includes a `Makefile` for common development tasks:
- `make format` — Run swift-format on Sources and Tests
- `make build` — Format then build
- `make run` — Format then run the server
- `make test` — Format then run tests
- `make docker-build` — Build Docker image
- `make docker-run` — Run Docker container on port 8080

**Note**: All Makefile targets automatically apply code formatting before executing.

### Direct Swift Commands
If you need to run commands directly without the Makefile:
- Build: `swift build` (use `--quiet` to reduce noise)
- Test: `swift test`
- Run: `swift run`
- Format: `swift-format -ri --configuration .swift-format Sources Tests`

**Configuration**: Code formatting uses `.swift-format` configuration file.
---

## Architecture Overview

### Technology Stack

- **Server Framework**: Hummingbird 2.0 (Swift HTTP server)
- **Templating**: Mustache templates (via swift-mustache)
- **Content**: Markdown files (via swift-markdown) compiled to HTML
- **CLI**: ArgumentParser for command-line interface
- **Compression**: HummingbirdCompression for response compression
- **Crypto**: Swift Crypto for ETag generation

### Static Site Architecture

**Important**: This is a **static site generator served dynamically**. Unlike traditional dynamic servers that fetch content from databases or external sources, this application:

- **Content lives in the repository**: All Markdown content is in the `Partials/` directory, committed to git alongside code
- **Single deployment unit**: Each push to `main` deploys both code AND content together
- **Startup I/O**: The entire content tree is scanned and loaded into memory at application startup
- **No runtime I/O for content discovery**: Once started, the server uses the in-memory `FileNode` tree to locate content (though files are still read from disk when rendering)
- **Fast restarts required for content updates**: New content requires a redeployment, not just a file upload

This design trades flexibility for simplicity, performance, and version control of content.

### Publishing Workflow Philosophy

**Everything is a Pull Request**. The entire site — content, code, templates, styles — lives in a single repository. This creates a **frictionless publishing experience** for engineers:

**To publish a new post**:
1. Create Markdown file in `Partials/posts/`
2. Open a PR
3. Merge to `main`
4. CI/CD automatically: deploys, tags, creates GitHub Release, updates changelog

**To change code**:
1. Edit Swift files
2. Open a PR
3. Merge to `main`
4. Same automatic deployment flow

**To update styles/templates**:
1. Edit CSS or Mustache templates
2. Open a PR
3. Merge to `main`
4. Same automatic deployment flow

**Key advantages**:
- **No context switching**: Blog post or bug fix? Same workflow.
- **Code and content never out of sync**: They're deployed atomically together.
- **Full version control**: Every post, every style change, every bug fix in git history.
- **Pull request workflow**: Review posts and code changes the same way.
- **Automatic releases**: Merging to `main` is publishing — no manual steps.
- **Rollback everything**: Reverting a commit rolls back code AND content.
- **Minimal friction**: The barrier to publishing is as low as possible.

For a software engineer, this feels natural. No separate CMS login, no admin panel, no database migrations, no deploy scripts. Just **git push** and the site updates.

### Comparison to Traditional CMS

**Traditional approach (WordPress, Ghost, etc.)**:
- Log into admin panel
- Write post in web editor
- Click "Publish"
- Content stored in database
- Code deployed separately
- Content and code can be out of sync
- No version control for content
- Hard to review before publishing
- Database backups needed
- Migrations for schema changes

**This approach (git-based)**:
- Write post in your favorite editor (VS Code, Vim, etc.)
- Commit to git
- Open PR (optional review)
- Merge to `main`
- Content and code deployed together
- Everything versioned in git
- Pull request workflow for review
- Full history with git log
- Rollback with git revert
- No database to manage

**Trade-offs**:
- ✅ **Lower friction** for engineers comfortable with git
- ✅ **Better versioning** and history
- ✅ **Simpler infrastructure** (no database)
- ✅ **Atomic deployments** (code + content)
- ✅ **Free backups** (git is the backup)
- ❌ **Higher friction** for non-technical users
- ❌ **No web-based editor** (must use local tools)
- ❌ **Deployment required** for content changes (no instant publish)
- ❌ **Requires git knowledge**

For a personal technical blog, the trade-offs heavily favor the git-based approach.

### Core Concepts

#### 1. Application Entry Point

**File**: `App.swift`

The main entry point uses `ArgumentParser` to create an `AsyncParsableCommand`:
- Accepts hostname, port, and log level arguments
- Calls `buildApplication()` to construct the Hummingbird application
- Runs the service with `app.runService()`

#### 2. Application Builder

**File**: `Application+build.swift`

The `buildApplication()` function orchestrates application construction:

```swift
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol
```

Key responsibilities:
- Creates a logger with configured log level
- Builds the router with middleware stack
- Configures the HTTP server (hostname, port, server name)
- Returns a configured `Application` instance

#### 3. Router and Middleware

**File**: `Router.swift` (Hummingbird library)

The router uses a **trie-based routing system** for efficient path matching:
- Supports wildcards (`*`) and parameter extraction (`:id`)
- Routes defined in `WebsiteController.addRoutes()`

**Middleware Stack** (applied in order):
1. `LogErrorsMiddleware()` — Logs errors
2. `LogRequestsMiddleware()` — Logs incoming requests
3. `RequestDecompressionMiddleware()` — Decompresses request bodies
4. `FileMiddleware()` — Serves static files with 24-hour cache control
5. `ETagVaryMiddleware()` — Handles ETag and Vary headers
6. `ResponseCompressionMiddleware()` — Compresses responses (min 512 bytes)
7. `HeadMiddleware()` — Auto-generates HEAD responses from GET handlers

#### 4. Content Model

**File**: `FileNode.swift`

`FileNode` is a recursive enum representing the content tree:

```swift
enum FileNode {
    case file(name: String)
    case directory(name: String, children: [FileNode])
}
```

**Critical Architecture Detail**: The `FileNode` tree is built **once at application startup** by scanning the file system:

- **When**: During `buildApplication()` in `Application+build.swift`, before the server starts accepting requests
- **How**: `buildFileTree(at: URL)` recursively scans `Bundle.module.resourcePath/Partials/`
- **Why**: This creates an in-memory index of all content, enabling fast path lookups without I/O
- **Trade-off**: Content updates require redeployment (not hot-reloading)

The tree is then used throughout the application's lifetime:
- Provides `find(path:)` to traverse the tree and locate content files
- No database queries or dynamic file system scans during request handling
- Content discovery is O(k) where k is path depth, not O(n) directory scans

**Key Advantage**: Having the complete content catalog in memory enables **zero-I/O sitemap generation**:
- **Index pages** (`/`) can list all posts without scanning directories
- **Archive pages** (`/archive`) can organize content by date without filesystem queries
- **Navigation** can be built from the complete sitemap
- All aggregate views have instant access to the full content structure
- This makes generating pages that need "whole site knowledge" trivially fast at runtime

#### 5. Request Handling

**File**: `WebsiteController.swift` and extensions

Routes handled:
- `/` — Index page (list of posts) — **uses full sitemap**
- `/posts/**` — Individual post pages (wildcard matching)
- `/now` — "Now" page
- `/about` — About page
- `/archive` — Archive page — **uses full sitemap**

Each handler:
1. Checks cache for pre-rendered HTML
2. Locates Markdown content in the `FileNode` tree
3. Loads and processes Markdown → HTML
4. Renders with Mustache template
5. Caches the result
6. Returns `HTML` response with ETag support

**Note**: Index and archive handlers can traverse the entire `FileNode` tree without I/O to build lists of all posts, sorted by date, grouped by year, etc. This "whole site reasoning" is instant because the complete content catalog is already in memory.

#### 6. Caching Strategy

**File**: `WebsiteController.swift`

Simple in-memory cache using `KeyValueStore<String, String>`:
- Key: Request URI path
- Value: Rendered HTML
- Cache checked on every request
- Cache populated after rendering

#### 7. Content Processing

**File**: `WebsiteController+Post.swift` (and similar extensions)

Content processing flow:
1. Convert request path to Markdown file path
2. Load content via `ContentProvider.file.post(matching:)`
3. Extract metadata (title, date, description, word count)
4. Generate JSON-LD structured data for SEO
5. Render with Mustache template
6. Return `HTML` response

#### 8. Response Generation

**Files**: `WebsiteController.swift`, custom middleware

The `HTML` struct implements `ResponseGenerator`:
- Generates HTTP responses with proper headers
- Supports ETag/If-None-Match for 304 Not Modified responses
- Sets appropriate Content-Type headers

---

## Project Structure

```
Sources/App/
├── App.swift                           # Entry point (ArgumentParser CLI)
├── Application+build.swift             # Application builder and router setup
├── WebsiteController.swift             # Base controller with route definitions
├── WebsiteController+Post.swift        # Post/article handler
├── WebsiteController+Index.swift       # Index page handler
├── WebsiteController+About.swift       # About page handler
├── FileNode.swift                      # Content tree model
├── Router.swift                        # Hummingbird router (library code)
├── Application.swift                   # Hummingbird application (library code)
├── Middleware/                         # Custom middleware
├── Resources/                          # Static assets (CSS, JS, images)
└── Partials/                          # Markdown content files

Tests/AppTests/
├── AppTests.swift
├── ETagTests.swift
└── ...
```

---

## Key Patterns and Conventions

### 1. Request Context

Uses `BasicRequestContext` (aliased as `AppRequestContext`) throughout:
- Simple context type for basic HTTP requests
- No custom context extensions needed

### 2. Async/Await

All route handlers use Swift Concurrency:
```swift
@Sendable func postHandler(request: Request, context: some RequestContext) async throws -> HTML
```

### 3. Error Handling

HTTP errors thrown using `HTTPError`:
```swift
throw HTTPError(.notFound)
throw HTTPError(.internalServerError, message: "Failed to render template.")
```

### 4. String Extensions

Helper methods for common operations:
- `String.title(_:)` — Formats page titles
- `String.canonicalURL(for:)` — Generates canonical URLs
- `String.date(date:)` — Formats dates for display
- `String.markdownPath()` — Converts request paths to Markdown file paths

### 5. Resource Loading

Resources loaded from `Bundle.module.resourcePath`:
- Mustache templates (`.html` files)
- Markdown content (in `Partials/` directory)
- Static assets served by `FileMiddleware`

---

## Common Tasks

### Adding a New Route

1. Add route definition in `WebsiteController.addRoutes()`:
   ```swift
   router.get("/new-page", use: newPageHandler)
   router.head("/new-page", use: newPageHandler)
   ```

2. Create handler method in an extension:
   ```swift
   extension WebsiteController {
       @Sendable func newPageHandler(request: Request, context: some RequestContext) async throws -> HTML {
           // Implementation
       }
   }
   ```

### Adding Middleware

Add to the middleware stack in `buildRouter()` within `Application+build.swift`:
```swift
router.addMiddleware {
    // ... existing middleware
    YourNewMiddleware()
}
```

Note: Middleware order matters! They execute in the order added.

### Working with Content

**Publishing workflow** (recommended):
1. Create a new branch: `git checkout -b new-post`
2. Add Markdown file to `Partials/posts/YYYY-MM-DD-slug.md`
3. Commit: `git commit -m "Add post about Swift concurrency"`
4. Push and open PR: `git push origin new-post`
5. Review (optional) and merge to `main`
6. CI/CD automatically:
   - Deploys to Fly.io
   - Creates git tag (e.g., `v34`)
   - Creates GitHub Release
   - Updates `CHANGELOG.md`
7. Content is live!

**Alternative (direct push)**:
```bash
git add Partials/posts/2025-01-24-new-post.md
git commit -m "Add new post"
git push origin main
# CI/CD deploys → server restarts → FileNode tree rebuilt with new content
```

**Key points**:
- **Everything goes through git**: Posts, code, styles, templates
- **PR workflow is optional but recommended**: Allows review and preview
- **Merge = publish**: No separate deploy step
- **Atomic deployments**: Content and code always in sync
- **Full history**: Every change tracked in git
- **Easy rollback**: `git revert` or force-push previous commit

This is not a hot-reload system, but it's designed for engineers who think in git commits and pull requests.

---

## Testing

- Test target: `AppTests`
- Uses `HummingbirdTesting` for integration tests
- Run tests: `swift test`

---

## Deployment Considerations

### Static Site Deployment Model

This application follows a **"code + content"** deployment model:

- **Single artifact**: Content (Markdown) and code (Swift) are deployed together
- **Atomic updates**: Each deployment includes both application logic and all content
- **No separate CMS**: Content lives in git, not in a database or S3 bucket
- **Version control**: Every content change is tracked in git history
- **Rollbacks are complete**: Rolling back to a previous tag restores both code and content

**Startup sequence**:
1. Application starts
2. `buildApplication()` scans `Partials/` directory (I/O operation)
3. `FileNode` tree built in memory with complete content catalog
4. Routes and middleware configured
5. Server begins accepting requests

**Content update workflow**:
1. Edit/add Markdown files locally
2. Commit to git
3. Push to `main` branch
4. CI/CD pipeline deploys to Fly.io
5. Server restarts with new content

### Server Configuration

- Server listens on `127.0.0.1:8080` by default
- Hostname and port configurable via CLI arguments
- Log level configurable via `--log-level` or `LOG_LEVEL` environment variable
- Static files cached with 24-hour `max-age`
- Response compression enabled for responses > 512 bytes
- ETag support for efficient caching

### Fly.io Deployment
The project is deployed to Fly.io with automated CD pipeline:
- Deployment triggered on push to `main` branch
- GitHub Actions workflow handles build, version, and deployment
- See `.github/workflows/fly-deploy.yml` for configuration

---

## CI/CD Pipeline

### Continuous Integration (`ci.yml`)
**Trigger**: Push to `main` (`.swift` or `.yml` files), PRs, or manual dispatch

**Jobs**:
- **linux**: Runs `swift test` on `ubuntu-latest` with `swift:latest` container
- Validates code compiles and all tests pass

### Continuous Deployment (`fly-deploy.yml`)
**Trigger**: Push to `main` branch (not from `github-actions[bot]`)

**Deployment Flow**:
1. **Checkout** repository with full git history and tags
2. **Compute next tag**: 
   - Checks if HEAD already has a valid `vN` tag
   - If tagged, skip release creation (`SKIP_RELEASE=true`)
   - If not tagged, increment from latest tag (or use `v1` if no tags exist)
   - Validates tag format: must be `v<integer>` (e.g., `v1`, `v2`, `v42`)
3. **Generate version file**: Creates `Sources/App/Version.swift` with tag
4. **Update changelog** (if not skipping):
   - Extract commits since previous tag
   - Format as bullet list under new tag header
   - Insert below `# Changelog` header
   - Preserve existing entries
5. **Commit changelog** (if changed)
6. **Deploy to Fly.io**: `flyctl deploy --remote-only`
7. **Tag release**: Create annotated git tag and push
8. **Create GitHub release**: Auto-generate release notes

**Key Features**:
- **Idempotent**: Re-running doesn't create duplicate tags or changelog entries
- **Tag-driven**: Version comes from git tags, not manual version files
- **Automatic**: No manual version bumping required
- **Rollback-safe**: Can re-deploy any tagged commit

### Version Management
- **Source of truth**: Git tags (`v1`, `v2`, `v3`, ...)
- **Version.swift**: Generated at build time, never committed
- **Format**: Simple integers (no semver): `v1`, `v2`, `v3`
- **Access in code**: `Version.current` (String, e.g., `"v42"`)
- **Server header**: `"Index/v42"` sent as `Server` response header

---

## Content Path Conventions

### URL-to-File Path Mapping
Posts use a date-based URL structure that maps to flat Markdown files:

**URL Format**: `/posts/YYYY/MM/DD/slug`
**File Format**: `Partials/posts/YYYY-MM-DD-slug.md`

**Example**:
- URL: `/posts/2025/01/24/my-post`
- File: `Partials/posts/2025-01-24-my-post.md`

**Conversion Functions** (`String+Path.swift`):
- `toFilename()`: Converts URL path to filename (e.g., `posts/2025/01/24/nuts` → `posts/2025-01-24-nuts.md`)
- `toDirectoryPath()`: Converts filename to URL path (e.g., `posts/2025-01-24-nuts.md` → `posts/2025/01/24/nuts`)
- `isValidDirectoryPath()`: Validates URL format (regex: `^.+/\d{4}/\d{2}/\d{2}/[a-z0-9-]+$`)
- `isValidFilename()`: Validates filename format (regex: `^.+/\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.md$`)
- `inPartialsDirectory`: Prefixes path with `Partials/`

### Date Extraction from Post Files
Post files embed the date in their filename:
- Extracted by `PostFile.init(string:)` in `ContentProvider+File.swift`
- Date parsed from filename components (YYYY-MM-DD)
- Used for display and JSON-LD metadata

---

## Response Headers and Caching

### ETag Generation (`Response+ETag.swift`)
**Algorithm**: Weak ETag using SHA-256 hash of response body
```swift
W/"<sha256-hex-digest>"
```

**Conditional Requests**:
- Checks `If-None-Match` request header against computed ETag
- Returns `304 Not Modified` if ETag matches
- Always includes ETag in response headers

**Default Response Headers**:
```http
Content-Type: text/html; charset=utf-8
Cache-Control: public, max-age=86400, stale-while-revalidate=604800, stale-if-error=604800
Connection: keep-alive
ETag: W/"<hash>"
Vary: Accept-Encoding
```

**Cache Strategy**:
- **max-age**: 24 hours (86400 seconds)
- **stale-while-revalidate**: 7 days (604800 seconds) — serve stale while fetching fresh
- **stale-if-error**: 7 days — serve stale if origin fails
- **Vary**: Ensures separate cache entries for different encodings

### HEAD Request Handling
- `HeadMiddleware` auto-generates HEAD responses from GET handlers
- HEAD responses include full headers but no body
- Allows clients to check ETag without downloading content

---

## SEO and Structured Data

### JSON-LD Implementation
All pages include JSON-LD structured data for search engines:

**Types**:
- **ProfilePage**: About page (`AboutLinkedData.swift`)
- **Article**: Blog posts (`PostLinkedData.swift`)  
- **WebPage**: General pages (`NowLinkedData.swift`, etc.)
- **Collection**: Archive page (`ArchiveLinkedData.swift`)

**Common Fields**:
- `@context`: "https://schema.org"
- `@type`: Schema.org type
- `@id`: Unique identifier URL
- `url`: Canonical URL
- `inLanguage`: "en"
- `name`: Page title
- `description`: Meta description
- `wordCount`: Calculated from content

**Relationships**:
- `isPartOf`: Links to website entity
- `mainEntity`: Links to person entity (for profile pages)

**Generation**:
- Each handler creates appropriate `LinkedData` struct
- Serialized to JSON and embedded in `<script type="application/ld+json">`
- Rendered via Mustache templates

### Canonical URLs
- Generated by `String.canonicalURL(for:)` helper
- Always absolute: `https://michaelnisi.com<path>`
- Ensures consistent indexing across mirrors/proxies

---

## Content Rendering Pipeline

### 1. Request → Path Resolution
**File**: `WebsiteController+Post.swift`

```swift
request.uri.path.markdownPath().inPartialsDirectory
```

**Steps**:
1. Extract path from request URI (e.g., `/posts/2025/01/24/my-post`)
2. Convert to Markdown filename using path conventions
3. Prefix with `Partials/` directory

### 2. Markdown Loading
**File**: `ContentProvider+File.swift`

**Two file types**:
- `PostFile`: Extracts date from filename, loads Markdown
- `PageFile`: Simple page without date extraction

**Process**:
1. Resolve path to file URL in `Bundle.module.resourcePath`
2. Check file exists (`FileManager.default.fileExists`)
3. Load as UTF-8 string
4. Throw `.notFound` if missing

### 3. Markdown → HTML Transformation
**File**: `MarkdownHTMLTransformer.swift` (referenced, not shown)

**Output**: `Content` struct containing:
- `html`: Rendered HTML string
- `title`: Extracted from Markdown (first heading)
- `description`: Meta description or excerpt
- `wordCount`: Calculated word count
- `date`: Publication date

**Features**:
- Uses `swift-markdown` for parsing
- Custom `MarkupVisitor` for HTML generation
- Safe HTML output (no script injection)
- Syntax highlighting hooks for code blocks

### 4. Template Rendering
**File**: `WebsiteController+Post.swift`, `MustacheLibrary`

**Data Structure**:
```swift
struct PostData {
    let title: String          // Page title with site prefix
    let post: String           // Rendered HTML content
    let canonical: String      // Canonical URL
    let description: String    // Meta description
    let wordCount: Int         // Word count
    let dateString: String     // Formatted date string
    let ld: String            // JSON-LD structured data
}
```

**Mustache Templates**:
- Base template: `page.html` (or similar)
- Article template: `article` (renders post content)
- Loaded from `Bundle.module.resourcePath` with `.html` extension
- Library initialized: `MustacheLibrary(directory:withExtension:)`

**Rendering**:
```swift
mustacheLibrary.render(data, withTemplate: "article")
```

### 5. Caching
**File**: `WebsiteController.swift`

**In-Memory Cache**:
- Type: `KeyValueStore<String, String>`
- Key: Request URI path
- Value: Final rendered HTML string
- No TTL or eviction policy (cache grows indefinitely)

**Cache Flow**:
1. Check cache with `cachedHTML(request:)`
2. On hit: Return cached HTML immediately
3. On miss: Render full pipeline, then `cacheHTML(request:html:)`

### 6. Response Generation
**File**: `Response+ETag.swift`

**Final Response**:
```swift
Response.ifNoneMatch(html: html, request: request)
```

**Process**:
1. Convert HTML string to `ByteBuffer`
2. Generate weak ETag from SHA-256 hash
3. Check `If-None-Match` header
4. Return `304` if match, else `200` with full body
5. Handle HEAD requests (no body)

---

## Middleware Deep Dive

Middleware executes in the order added. Current stack (see `Application+build.swift`):

### 1. LogErrorsMiddleware
- Catches errors from downstream handlers
- Logs error details
- Ensures errors are visible for debugging

### 2. LogRequestsMiddleware
- Logs incoming HTTP requests
- Includes method, path, status
- Respects configured log level

### 3. RequestDecompressionMiddleware
- Decompresses request bodies (gzip, deflate)
- Transparent to handlers
- Allows clients to compress uploads

### 4. FileMiddleware
**Configuration**: 
```swift
FileMiddleware(cacheControl: .allMediaTypes(maxAge: 86400), logger: logger)
```

**Behavior**:
- Serves static files from `Resources/` directory
- Sets `Cache-Control: public, max-age=86400` (24 hours)
- Applies to all media types (application, audio, font, image, text, video, etc.)
- Short-circuits request chain if file found
- Returns 404 if not found

**Served Assets**:
- CSS files (`style.css`)
- JavaScript (`index.js`, `highlight.min.js`, `swift.min.js`)
- Images (`favicon.ico`, etc.)

### 5. ETagVaryMiddleware
- Ensures `Vary: Accept-Encoding` header is set
- Critical for proper cache behavior with compression
- Prevents serving compressed content to clients that don't support it

### 6. ResponseCompressionMiddleware
**Configuration**:
```swift
ResponseCompressionMiddleware(minimumResponseSizeToCompress: 512)
```

**Behavior**:
- Compresses responses > 512 bytes
- Supports gzip, deflate, br (Brotli)
- Checks `Accept-Encoding` request header
- Updates `Content-Encoding` response header
- Significantly reduces bandwidth for HTML pages

### 7. HeadMiddleware
- Auto-generates HEAD responses from GET handlers
- Runs GET handler but strips body from response
- Preserves all headers (including ETag, Content-Length)
- Allows ETag validation without downloading content

**Note**: While HEAD endpoints are explicitly defined in routes, this middleware provides a fallback.

---

## FileNode Architecture

**File**: `FileNode.swift`

### Purpose
Models content as a virtual file tree, decoupling logical structure from physical storage.

**Key Architectural Decision**: The FileNode tree represents a **snapshot of content at startup time**. This is fundamentally different from traditional CMS or dynamic servers:

- **Static site approach**: Content is versioned with code in git
- **Startup-time I/O**: File system is scanned once during application initialization
- **In-memory index**: The tree lives in memory for the application's lifetime
- **Fast lookups**: Path resolution is tree traversal, not file system operations
- **Deployment = Content updates**: New posts require `git push` → redeploy cycle

This design assumes infrequent content updates and prioritizes performance over runtime flexibility.

### Structure
```swift
enum FileNode {
    case file(name: String)
    case directory(name: String, children: [FileNode])
}
```

### Tree Building
**Function**: `buildFileTree(at: URL)`
- **Timing**: Called during `buildApplication()` at startup, before server accepts connections
- **I/O Operation**: Recursively scans the file system using `FileManager.default.contentsOfDirectory`
- Creates nested `FileNode` structure representing the entire content hierarchy
- Loaded from `Bundle.module.resourcePath/Partials/`
- **Blocking operation**: Must complete before server starts (intentional design)
- **One-time cost**: Never rescans during runtime; content is "frozen" until restart

**Why this matters**: Unlike frameworks like WordPress or Ghost that query databases or scan files on each request, this server knows its entire content catalog before handling the first request. This enables:

1. **Sub-millisecond path resolution** for individual content lookups
2. **Zero-I/O sitemap generation** for index and archive pages
3. **Instant aggregate views** that need knowledge of all content
4. **No database queries** or filesystem scans during request handling

However, it requires redeployment for content changes (no hot-reloading).

### Tree Navigation
**Function**: `find(path:)`
```swift
markdownTree.find(path: "posts/2025-01-24-my-post.md")
```

**Algorithm**:
1. Split path by `/` into components
2. Recursively traverse tree matching each component
3. Return matching `FileNode` or `nil`

**Helper**: `findWithPath(path:)`
- Returns tuple: `(FileNode, String)` — node and full path
- Used when you need both the node and its resolved path

### Utility Functions
- `flattenedPaths(prefix:)`: Returns all paths as flat string array
- `logPaths(logger:)`: Logs all paths for debugging (called at startup)

**Sitemap Operations**: These utility functions enable zero-I/O sitemap generation:
- Iterate over all content files without filesystem access
- Filter and sort posts for index/archive pages
- Build navigation structures from the complete content catalog
- Generate feeds (RSS/Atom) with full post lists

Example use cases:
- **Index page**: `markdownTree.flattenedPaths()` → filter posts → sort by date → render list
- **Archive page**: Group posts by year/month using in-memory tree traversal
- **RSS feed**: Iterate all posts, extract metadata, generate XML — all without I/O

### Usage Example
```swift
let markdownFiles = try FileNode(directory: directory)
markdownFiles.logPaths(logger: logger)  // Debug output

// Later, in handler:
guard let (node, path) = markdownTree.findWithPath(path: requestPath) else {
    throw HTTPError(.notFound)
}
```

---

## Testing Strategy

### Test Framework
- Uses `HummingbirdTesting` for integration tests
- Tests against real HTTP server
- Validates full request/response cycle

### Test Files
- `AppTests.swift`: General application tests
- `ETagTests.swift`: ETag generation and conditional request tests
- `RequestPathTests.swift`: Path conversion tests
- `FilenameTests.swift`: Filename validation tests

### Running Tests
```bash
swift test                    # Run all tests
swift test --parallel         # Parallel execution
make test                     # Format + test
```

### Test Coverage Areas
1. **Path Conversion**: URL ↔ filename transformations
2. **ETag Generation**: Weak ETag computation and matching
3. **Conditional Requests**: If-None-Match handling
4. **Routing**: Correct handler invocation for paths
5. **Content Loading**: Markdown file resolution
6. **Middleware**: Proper execution order and behavior

---

## Troubleshooting

### Common Issues

#### 1. Missing Bundle Resources
**Error**: `"no resource path"` or `FileNode.Failure.noResourcePath`

**Cause**: Bundle resources not properly configured

**Fix**: Ensure `Package.swift` includes:
```swift
resources: [
    .process("Resources"),
    .copy("Partials")
]
```

#### 2. Template Not Found
**Error**: `"Failed to render template"`

**Cause**: Mustache template missing or wrong name

**Fix**: 
- Verify template exists in Resources directory
- Check template name matches (case-sensitive)
- Ensure `.html` extension is used for template files

#### 3. Content Not Found (404)
**Error**: `HTTPError(.notFound)`

**Cause**: Markdown file path doesn't match URL structure

**Fix**:
- Verify filename follows convention: `YYYY-MM-DD-slug.md`
- Check file exists in `Partials/posts/` directory
- Test path conversion with unit tests

#### 4. Cache Issues
**Symptom**: Stale content served after updates

**Fix**: Restart server to clear in-memory cache
- No persistent cache, so restart always works
- Consider adding cache invalidation for development

#### 5. ETag Mismatches
**Symptom**: No 304 responses even with matching content

**Fix**:
- Check `Vary` header is set correctly
- Verify client sends `If-None-Match` header
- Inspect ETag generation (should be deterministic for same content)

#### 6. Compression Not Applied
**Symptom**: Large responses not compressed

**Fix**:
- Verify response size > 512 bytes
- Check client sends `Accept-Encoding: gzip` header
- Ensure middleware order is correct (compression after content generation)

### Debugging Tips

1. **Enable Debug Logging**:
   ```bash
   swift run App --log-level debug
   # or
   LOG_LEVEL=debug swift run App
   ```

2. **Inspect File Tree**:
   - Check startup logs for file tree dump
   - Look for missing or unexpected files

3. **Test Path Conversion**:
   ```swift
   print("posts/2025/01/24/my-post".toFilename())
   // Should output: posts/2025-01-24-my-post.md
   ```

4. **Check Middleware Execution**:
   - Add logging middleware at different positions
   - Verify execution order matches expectations

5. **Validate Markdown Content**:
   - Ensure UTF-8 encoding
   - Check for proper frontmatter/structure expected by transformer

---

## Code Style and Conventions

### Swift Style
- Configured via `.swift-format` file
- Enforced by `swift-format -ri --configuration .swift-format`
- Automatically applied by Makefile targets

### Key Conventions

1. **Access Control**:
   - Public API: `public` (for application/router protocol conformance)
   - Internal: Default for most app code
   - Private: Helper functions, nested types

2. **Error Handling**:
   - Use `HTTPError` for HTTP-related errors
   - Custom error types for domain logic (e.g., `FileNode.Failure`)
   - Always provide context in error messages

3. **Naming**:
   - Route handlers: `<page>Handler` (e.g., `postHandler`, `indexHandler`)
   - Data structures: `<Page>Data` (e.g., `PostData`, `ArchiveData`)
   - Linked data: `<Page>LinkedData` (e.g., `PostLinkedData`)

4. **File Organization**:
   - Controller extensions: `WebsiteController+<Page>.swift`
   - Protocol conformances: `Type+Protocol.swift`
   - Utilities: `Type+Utility.swift` (e.g., `String+Path.swift`)

5. **Async/Await**:
   - All route handlers are `async throws`
   - Mark handlers as `@Sendable` for safe concurrency
   - Use `await` for all async operations (no callbacks/completion handlers)

6. **Documentation**:
   - Document public APIs with `///` doc comments
   - Explain complex algorithms inline
   - Keep comments up-to-date with code

### Type Safety
- Leverage Swift's type system
- Use enums for exhaustive cases (e.g., `FileNode`)
- Protocol-oriented design where appropriate
- Avoid stringly-typed APIs (use enums/structs)

---

## Performance Considerations

### Current Optimizations
1. **In-Memory Caching**: Rendered HTML cached by request path
2. **ETag Support**: Reduces bandwidth with 304 responses
3. **Response Compression**: gzip/Brotli reduces payload size
4. **Static File Caching**: 24-hour browser cache for assets
5. **Efficient Routing**: Trie-based router for O(k) lookup (k = path depth)
6. **Zero-I/O Sitemaps**: Index and archive pages built from in-memory tree without filesystem access
7. **Startup Content Catalog**: Complete site structure known before first request

### Potential Bottlenecks
1. **Unbounded Cache**: In-memory cache grows indefinitely
2. **Synchronous I/O**: File loading blocks request handling
3. **Markdown Parsing**: CPU-intensive for large documents
4. **No CDN**: Origin server handles all requests

### Improvement Ideas
1. **Cache Eviction**: Add LRU or TTL-based eviction
2. **Prerendering**: Build static HTML at deploy time
3. **Async File I/O**: Use NIO file I/O for non-blocking reads
4. **CDN Integration**: Serve static assets from CDN
5. **Markdown Caching**: Cache parsed Markdown AST, not just HTML

---

## Release and Changelog Workflow

### Version Scheme
- Simple integer tags: `v1`, `v2`, `v3`, ...
- No semantic versioning (not a library)
- Monotonically increasing
- Git tags are authoritative
### Creating a Release
**Automatic** (preferred):
1. Push code to `main` branch
2. CI detects no existing tag on HEAD
3. CI increments latest tag
4. CI generates `Version.swift`
5. CI updates `CHANGELOG.md`
6. CI deploys to Fly.io
7. CI creates git tag and GitHub release

**Manual** (if needed):
```bash
# Create annotated tag
git tag -a v42 -m "Release v42"
git push origin v42

# CI will deploy and create GitHub release
```

### Changelog Format
```markdown
# Changelog

All notable changes to this project will be documented in this file.

## v42 - 2026-01-24
- Add new feature X
- Fix bug in Y
- Update dependency Z

## v41 - 2026-01-20
- Initial release
```

### Skipping Releases
If HEAD already has a valid tag:
- CI sets `SKIP_RELEASE=true`
- No changelog update
- No tag creation
- Still deploys to Fly.io

### Rollback Procedure
1. Find previous tag: `git tag -l 'v*' --sort=-v:refname`
2. Check out tag: `git checkout v41`
3. Push to main: `git push origin HEAD:main --force`
4. CI will re-deploy old version (tag already exists, so no new release)

