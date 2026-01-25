# AGENTS.md — Architecture Guide

`index-web` is a personal website (https://michaelnisi.com) built with server-side Swift.

**Stack**: Hummingbird (HTTP server), Markdown-to-HTML transformation, Mustache templates.

---

## General Instructions

- **Prefer readability over conciseness.**
- **Never commit unless instructed.**
- Keep `Version.swift` as a build artifact; do not commit it.
- Git tags are the single source of truth for versioning.
- When editing GitHub Actions, preserve idempotency.
- Use annotated tags (`git tag -a vN -m "Release vN"`) for releases.

### When Done

- Build the project to check for compilation errors.
- Run `swiftformat --config ".swiftformat" {files}` on modified Swift files.
- Ask before committing.

---

## Build

```bash
make build    # Format + build
make test     # Format + test
make run      # Format + run server
```

Direct commands: `swift build`, `swift test`, `swift run`

---

## Architecture

### Static Site Served Dynamically

This is a **static site generator served dynamically**:

- **Content in git**: All Markdown lives in `Partials/`, versioned with code
- **Startup I/O**: The entire content tree is scanned into memory at startup
- **No runtime I/O for discovery**: The in-memory `FileNode` tree handles path lookups
- **Deployment = Content update**: New posts require redeployment

**Trade-off**: Flexibility for simplicity, performance, and version-controlled content.

### CDN Layer

The site is fronted by Cloudflare, which caches responses at the edge. This is why the dynamic-but-static approach works well:

- **Most requests never hit the origin** — Cloudflare serves from edge cache
- **ETag validation** — Cloudflare checks back with `If-None-Match`; origin returns 304 when content unchanged
- **Data is immutable at runtime** — No invalidation complexity; new content = new deployment = new ETags

### FileNode Tree

The core architectural concept. Built once at startup by scanning `Partials/`:

```swift
enum FileNode {
    case file(name: String)
    case directory(name: String, children: [FileNode])
}
```

**Why this matters**:
- Sub-millisecond path resolution
- Zero-I/O sitemap generation (index, archive pages)
- No database or filesystem queries during request handling

### Request Flow

1. Check in-memory cache for pre-rendered HTML
2. Locate content via `FileNode` tree traversal
3. Load Markdown → transform to HTML
4. Render with Mustache template
5. Cache result, return response with ETag

### Middleware Stack

Applied in order:
1. `LogErrorsMiddleware` — Error logging
2. `LogRequestsMiddleware` — Request logging
3. `RequestDecompressionMiddleware` — Decompress requests
4. `FileMiddleware` — Static files (24h cache)
5. `ETagVaryMiddleware` — Vary header handling
6. `ResponseCompressionMiddleware` — Compress responses >512 bytes
7. `HeadMiddleware` — Auto-generate HEAD from GET

---

## Project Structure

```
Sources/App/
├── App.swift                       # Entry point (ArgumentParser CLI)
├── Application+build.swift         # Application builder, router setup
├── WebsiteController.swift         # Base controller with routes
├── WebsiteController+*.swift       # Page-specific handlers
├── FileNode.swift                  # Content tree model
├── Middleware/                     # Custom middleware
├── Resources/                      # Static assets
└── Partials/                       # Markdown content
```

---

## Key Patterns

### Routes

```swift
router.get("/posts/**", use: postHandler)
```

Handlers are `@Sendable async throws` functions returning `HTML`.

### Path Conventions

- **URL**: `/posts/YYYY/MM/DD/slug`
- **File**: `Partials/posts/YYYY-MM-DD-slug.md`

### Error Handling

```swift
throw HTTPError(.notFound)
```

### JSON-LD

All pages include structured data for SEO (`PostLinkedData`, `AboutLinkedData`, etc.).

---

## Adding Content

1. Add Markdown to `Partials/posts/YYYY-MM-DD-slug.md`
2. Commit and push to `main`
3. CI deploys → server restarts → FileNode tree rebuilt

---

## CI/CD

- **CI** (`ci.yml`): Runs `swift test` on push/PR
- **CD** (`fly-deploy.yml`): On push to `main`:
  1. Compute next version tag
  2. Update changelog
  3. Deploy to Fly.io
  4. Create git tag and GitHub release

Version format: `v1`, `v2`, `v3` (simple integers, not semver).
