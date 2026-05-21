# LLM Wiki Schema

This document defines how the LLM maintains the wiki. It is the operating manual.
Read this first before performing any wiki operation.

## Directory Layout

```
~/wiki/
├── raw/              ← IMMUTABLE. Source documents you add. LLM reads only.
├── wiki/             ← LLM OWNS THIS. Markdown knowledge base.
│   ├── index.md      ← Catalog of every page, with summary + metadata
│   ├── log.md        ← Append-only chronological record of all operations
│   ├── entities/     ← Pages about specific things (people, tools, papers, projects)
│   ├── concepts/     ← Pages about abstract ideas (attention, recursion, emergence)
│   ├── syntheses/    ← Cross-topic analysis, comparisons, compiled insights
│   └── assets/       ← Images, diagrams, data files referenced by wiki pages
└── schemas/
    └── schema.md     ← THIS FILE. Rules for wiki maintenance.
```

## Page Format

Every wiki page follows this structure:

```markdown
---
type: entity | concept | synthesis
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [source-file-1.md, source-file-2.md]
tags: [tag1, tag2]
---

# Title

One-paragraph summary of what this page is about.

## Body

Structured content. Use sections as appropriate for the topic.
Use [[wikilinks]] to reference other wiki pages.
Use `[source: filename.md]` to cite sources.

## References

- [source: filename.md] — what this source contributed
```

## Operations

### 1. Ingest

When a new source appears in `raw/`:

1. Read the source document
2. Scan the wiki index to find existing pages it relates to
3. Discuss key takeaways with the user (if in interactive session)
4. Write a summary page in `wiki/entities/` or `wiki/concepts/`
5. Update `wiki/index.md`:
   - Add the new page with a one-line summary
   - Update existing entries that now have new connections
6. Update all affected entity and concept pages (cross-references)
7. Append an entry to `wiki/log.md`
8. The source stays in `raw/` — never modify it

A single source may touch 5-15 wiki pages. Process them all.

### 2. Query

When the user asks a question:

1. Read `wiki/index.md` to find relevant pages
2. Read the relevant entity, concept, and synthesis pages
3. Synthesize an answer with citations to both wiki pages and raw sources
4. **If the answer contains valuable insight**, file it as a new synthesis page

### 3. Lint

Periodically health-check the wiki:

1. Find contradictions between pages (flag both sides, don't silently pick one)
2. Find stale claims superseded by newer sources
3. Find orphan pages with zero inbound wikilinks
4. Find missing pages for concepts mentioned but not defined
5. Find missing cross-references between related pages
6. Suggest new sources to find or questions to investigate

### 4. Fix

One-shot cleanup:

1. Run lint checks
2. Fix every fixable issue
3. Re-lint until clean
4. Log all changes

## Conventions

- **Wikilinks**: Use `[[Page Name]]` — the LLM resolves these when reading. The file path is `entities/page-name.md` or `concepts/page-name.md`.
- **Citations**: Use `[source: filename.md]` inline, with the short filename from `raw/`.
- **Frontmatter**: Every page gets YAML frontmatter with type, dates, sources, and tags.
- **Synthesis pages** in `wiki/syntheses/` are for cross-topic analysis: comparisons, timelines, compiled insights, answered questions that are worth keeping.
- **Log entries** start with `## [YYYY-MM-DD] operation | Title` for grep-ability.

## Quality Rules

1. Never modify files in `raw/` — they are the immutable source of truth.
2. Never delete a wiki page without user confirmation.
3. When updating a page, preserve what's still correct and integrate new information.
4. If new data contradicts an existing claim, flag it explicitly — don't silently overwrite.
5. Keep summaries concise (1-2 sentences). Detailed content goes in the body.
6. Every page needs at least one `[source:]` citation.
7. Index only the `wiki/` directory, not `raw/`.
