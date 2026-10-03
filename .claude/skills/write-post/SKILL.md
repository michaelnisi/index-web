---
name: write-post
description: Use when writing, drafting, editing, proofreading, or reviewing a post in Sources/App/Partials/posts/—quotes, quotes with commentary, essays, or code posts. Applies STYLE.md (typography, voice, structure) and the post file conventions. Load before writing any post prose.
---

# Write Post

Write, edit, or review posts for michaelnisi.com.

## Before You Start

Read `STYLE.md` in full. It is the source of truth for typography, voice, post types, and formatting. Then skim two or three recent posts in `Sources/App/Partials/posts/` of the same type to match their tone and length.

## New Post

1. **Choose the type** from `STYLE.md`: quote, quote with commentary, essay, or code. If the author hasn't said, infer it from the material or ask.
2. **Create the file** at `Sources/App/Partials/posts/YYYY-MM-DD-slug.md`.
   - The date is the publish date. It comes from the filename; there is no front matter.
   - The slug is one short, lowercase word taken from the title's key idea: `welfare`, `systems`, `constraint`.
   - The URL becomes `/posts/YYYY/MM/DD/slug`.
3. **Write the title** as the only `#` heading, in title case.
4. **Write the body** in the post type's shape.
5. **Check the meta description.** It is built from the first top-level paragraphs, not the blockquote, and cut to about 160 characters. Make sure the first paragraph after the quote reads well on its own in a feed or search result.

## Editing and Reviewing

- Keep the author's voice. Fix what breaks a rule in `STYLE.md`; don't rewrite what already works.
- Never change the wording inside a quote. Typography fixes, such as curly apostrophes, are fine.
- Leave code blocks and URLs untouched. Straight quotes belong in code.
- When reviewing, list each issue with the line and the rule it breaks, then offer the fix.

## Checklist

Run the checklist at the end of `STYLE.md`, then confirm:

- [ ] Filename matches `YYYY-MM-DD-slug.md`
- [ ] Exactly one `#` heading
- [ ] Every quote has a linked source
- [ ] No straight apostrophes outside code

To find straight apostrophes, run:

```sh
grep -n "'" Sources/App/Partials/posts/<file>.md
```

Any match outside a code block is a bug.

## Committing

Follow `AGENTS.md`: ask before committing. The commit message is `Add post: <Title>`, prefixed with `GH-{issue}` when there is an issue.
