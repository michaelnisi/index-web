# AGENTS.md

Guide for AI agents working on `index-web` (https://michaelnisi.com).

---

## Rules

- **Prefer readability over conciseness.**
- **Never commit unless instructed.**
- `Version.swift` is a build artifact — do not commit it.
- Git tags are the single source of truth for versioning.
- When editing GitHub Actions, preserve idempotency.

### Decisions

- **No JSON-LD or other schema.org structured data.** Removed deliberately in #118 (PR #119) because of the maintenance cost. Keep semantic HTML instead (`<article>`, `<time datetime>`). Don't propose it in issues or PRs.
- **Check history before proposing features.** Before suggesting something that may have existed before, run `git log -S<term>` and search closed issues. A feature missing from the current tree may have been removed on purpose.

### Git Conventions

- Branch names: `GH-{issue_number}-{short-description}` — e.g. `GH-116-fix-json-ld-main-entity-type`
- Commit prefix: `GH-{issue_number} {Short description}` — e.g. `GH-116 Add @type to mainEntity in JSON-LD structured data`
- PR title matches the commit; body opens with `Closes #N`

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
