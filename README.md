# Index

This repository contains the source code for my personal website, https://michaelnisi.com. It’s a small, fast site focused on strong types, simplicity, and hand-crafted content. The stack is server-side Swift with Hummingbird, Markdown-to-HTML transformation, and Mustache templates for rendering pages.

## Overview

- Server: Hummingbird (Swift) HTTP server
- Templating: Mustache templates (e.g., `page.html`, `article`)
- Content: Markdown files compiled to HTML
- Rendering: Custom Markdown → HTML transformer
- SEO: Open Graph, Twitter Card, and JSON-LD structured data
- Syntax Highlighting: Highlight.js (with Swift support)
- Assets: Static files (CSS, JS, images) served statically

The design philosophy is minimalism and performance. Content is written in Markdown and transformed on the server. HTML is assembled using Mustache templates and returned as lightweight pages.

## Project Structure

- `Sources/App/` (Swift server code)
  - `WebsiteController+Post.swift`: Route handler(s) for posts/pages. Finds the matching Markdown content, renders it to HTML, wraps it in a Mustache template, and returns it as an HTTP response. It also injects JSON-LD into the page.
  - `MarkdownHTMLTransformer.swift`: Custom Markdown renderer using Swift’s `Markdown` package and a `MarkupVisitor` that produces safe, minimal HTML.
- `Resources/Templates/` (templating)
  - `page.html`: Base Mustache template (document head, meta tags, scripts, and `{{$body}}` partial for content).
  - `article.mustache` (or similar): Article/body template used by `WebsiteController+Post`.
- `Resources/Partials/` (content partials)
  - Markdown content fragments assembled by the controller (e.g., `Partials/...`).
- `Public/` (static assets)
  - `style.css`, `index.js`, `highlight.min.js`, `swift.min.js`, `favicon.ico`, etc.

Note: Exact layout may vary depending on your build setup. The important parts are the Swift server, transformer, templates, and content.

## Key Components

### Hummingbird Server and Routing

The `WebsiteController` extensions handle HTTP requests. For posts, the route handler:

1. Resolves a Markdown partial path from the request URI.
2. Loads/compiles the Markdown into HTML.
3. Wraps it in an `article` Mustache template.
4. Returns the final HTML response.

Example (simplified) flow from `WebsiteController+Post.swift`:

- Convert request path into a partials path: `String.partialsPath(_:)`
- Fetch content via `ContentProvider.file.post(matching:)`
- Render the Mustache template with `PostData` (contains `post` HTML and JSON-LD `ld`)
- Return `HTML(html:)` to the client
