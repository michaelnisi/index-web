# AGENTS.md

Guide for AI agents working on `index-web` (https://michaelnisi.com).

---

## Rules

- **Prefer readability over conciseness.**
- **Never commit unless instructed.**
- `Version.swift` is a build artifact — do not commit it.
- Git tags are the single source of truth for versioning.
- When editing GitHub Actions, preserve idempotency.

### When Done

- Build the project to check for compilation errors.
- Run `swift-format -ri --configuration .swift-format Sources Tests` on modified Swift files.
- Ask before committing.

---

## Architecture

Entrypoint: `Sources/App/App.swift`

### Static Site Served Dynamically

Content (Markdown in `Partials/`) is scanned into an in-memory `FileNode` tree at startup. No runtime I/O for path lookups. New content requires redeployment.

### CDN Layer

Cloudflare caches responses at the edge. Most requests never hit the origin. Cloudflare validates with `If-None-Match`; origin returns 304 when unchanged. Data is immutable at runtime — new content = new deployment = new ETags.

### Path Conventions

- **URL**: `/posts/YYYY/MM/DD/slug`
- **File**: `Partials/posts/YYYY-MM-DD-slug.md`

---

## CI/CD

- **CI** (`ci.yml`): Runs `swift test` on push/PR
- **CD** (`fly-deploy.yml`): On push to `main` — computes next version tag, updates changelog, deploys to Fly.io, creates git tag and GitHub release

Version format: `v1`, `v2`, `v3` (simple integers, not semver). Use annotated tags for releases.
