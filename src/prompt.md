You are running the daily AI briefing scan.

All file paths below are relative to the project root — your current working directory. The project root contains index.html, topics.html, the past daily briefs (YYYY-MM-DD.html), and a src/ subfolder holding this prompt and sources.md. Output files are written to the project root (the directory above src/).

Today's date is available via bash. Start by running: date +%Y-%m-%d to get it, then use it for the output filename (formatted like YYYY-MM-DD.html).

## WHAT TO SCAN

Read src/sources.md for the full source list — it is the single
source of truth, grouped by category (Major AI Company News; AI Labs — Open Weights /
Emerging; Research & Aggregators; Practitioner Blogs & Newsletters; Substacks; Community
Discussions; X/Social). Scan every source listed there. Treat sources.md as a checklist:
run at least one WebSearch per source, one source at a time. Do NOT batch multiple sources
into a single conclusion, and do NOT skip the long tail of practitioner/Substack sources
because the day already has big company news. Each source gets its own query and its own
recorded result.

sources.md may end with a "Retired / Dropped" section. Do NOT scan those entries, and
EXCLUDE them from the coverage ledger and the count check. Only sources in the sections
above it count.

Some entries carry inline tags like "(sparse)", "(search-only / best-effort)", or
"(JS-heavy)". These lower the expected effort or set expectations about fetchability — they
do NOT exempt a source from being scanned. Every non-retired source still gets its own query
and its own ledger line.

### Fetch strategy by source type

**Provenance rule (applies to ALL web fetching):** web_fetch only retrieves a URL that
has already appeared in the conversation — in a WebSearch result or a prior fetch's body.
URLs read from sources.md do NOT qualify. So the pattern for every web source is:
WebSearch first to surface the real URL, then web_fetch that exact URL. Fetching a URL
straight from sources.md fails with "URL not in provenance set."

  - **Company blogs, practitioner blogs, aggregators**: WebSearch the source + timeframe (e.g. `Anthropic news July 2026`, `Simon Willison blog July 2026`) to surface current article URLs, then web_fetch the specific articles you want in full. The sources.md URL is a label/starting point, not something to fetch cold.

  - **Substacks and beehiiv newsletters — use WebSearch, NOT the /api/v1/posts endpoint.**
  The JSON API and the /archive page both fail here: the API URL never enters provenance, and the HTML homepage returns only a JavaScript shell. What works: WebSearch the publication for the current month (e.g. `Ethan Mollick One Useful Thing July 2026`, or `site:jessicatalisman.substack.com 2026`) to get recent post titles, dates, and exact `/p/<slug>` URLs — then web_fetch those `/p/` URLs. Individual Substack and beehiiv post pages (e.g. The Rundown AI, The AI Daily Brief) ARE server-rendered and return full, clean article text; beehiiv `/archive` pages are also server-rendered and list titles, dates, and `/p/` URLs. Pull the full post only for items worth detail; search snippets alone usually tell you what's new.

  - **X/Twitter**: cannot fetch directly — use WebSearch for the handles in sources.md.
  e.g., Search: "from:karpathy AI OR LLM OR agents" (last 7 days)

  - **Podcasts**: audio is not scannable. Use the show's text companion (newsletter/archive
  page) or WebSearch episode titles instead.

  - **Most sources** (company blogs, practitioner blogs, aggregators): WebFetch the listed page URL directly.

### Priority notes
- Simon Willison is the most important practitioner source — check for multiple posts.
- Note when a source has nothing new (e.g. "No new posts since [date]") rather than
  omitting it — the footer should list every source checked.

## NO UNVERIFIED NEGATIVES

* Write "no new post" for a source ONLY if you ran a search for that specific source in this run and it returned nothing recent. Absence must be observed, not assumed.
* A blanket sentence covering several sources at once ("no new posts across the rest of the list") is FORBIDDEN unless each of those sources was individually searched this run.
* Never infer a source is quiet from the fact that the day is busy elsewhere, that the source is "usually quiet," or that its activity is "just reactions." That reasoning is banned.
* Per-source query format: <author/publication> <month year> — e.g. Addy Osmani Substack July 2026. For anyone who both blogs AND Substacks, search both; use site: when helpful (site:addyo.substack.com 2026).

### The banned pattern (this exact mistake has happened)

FORBIDDEN — collapsing the long tail into one unqueried verdict:
> "Pragmatic Engineer, Lenny's, Adam Tornhill, Casey Muratori, jxnl, Addy Osmani, Jessica Talisman, Latent Space, Chip Huyen, Hamel Husain, Eugene Yan, LangChain — no new AI post surfaced."

This is invalid even if it turns out to be true, because it asserts negatives for a dozen sources without a per-source query. In one real run it hid live posts from Simon Willison (llm 0.31.1), Lilian Weng, Lenny, the Pragmatic Engineer, LangChain, and Addy Osmani.

REQUIRED — each source searched, each result recorded:
> "Adam Tornhill — searched 'Adam Tornhill Substack July 2026', nothing since ~May 7.
>  Lenny Rachitsky — searched 'Lenny's Newsletter July 2026', NEW: 'a workforce splitting in two' (Jul 7). ..."

A grouped "quiet this window" block is allowed ONLY when each named source was individually searched this run and each appears with its own query/result in the footer.

## NO UNVALIDATED LINKS — every href must be verified, not merely plausible

This is a hard requirement, equal in weight to "no unverified negatives." A wrong link
that *looks* right is worse than no link, because the reader trusts it.

### The rule

Every hyperlink in the brief (and in index.html / topics.html) must use a URL that
literally appeared THIS run — either in a WebSearch result's link list, or in the body of
a page you fetched. Never construct, guess, shorten, hand-edit, or "upgrade" a URL. Never
substitute a section / landing / homepage / index URL as a stand-in for a specific article.

**The anchor text must match what the URL actually is.** If you hyperlink the words
"How Anthropic runs large-scale code migrations," the href must be *that article's own
permalink* — not the blog index, not `/engineering`, not a tag page. A real URL pointing
at the wrong page is still a wrong link.

"It was in the search results" is NOT sufficient justification. The test is stronger:
the URL must have surfaced this run **as the exact thing you are citing it as.**

### The mistake this prevents (it has happened)

A real run linked "How Anthropic runs large-scale code migrations with Claude Code" to
`https://www.anthropic.com/engineering`. That URL was real and had appeared in search —
but it is the section landing page, not the article. The true permalink
(`https://claude.com/blog/ai-code-migration`) never surfaced in the run, so the landing
page got used as a stand-in. A naive "is this URL real?" check passes; the correct test —
"did this URL surface as THIS article?" — fails.

### What to do when you only have a title, not a permalink

If a search snippet gives you an article's title/date but its real permalink never
surfaced, choose in this order:
1. **Link the exact source URL that DID surface, with honest anchor text** — e.g. link the
   words "the Claude blog" to `https://claude.com/blog`, not the article title to a made-up
   article URL.
2. **State the item with no hyperlink**, naming the source in prose ("per Anthropic's blog").
3. **Fetch to resolve the real permalink.** REQUIRED for any `.significant` headline item —
   confirm the permalink by an actual web_fetch (or by seeing it verbatim in results), never
   from a snippet alone.

### Degrade gracefully, never fabricate

An unlinked, correctly-attributed item is a success. A confidently-linked wrong URL is a
failure. When in doubt, drop the link and keep the text.

## COVERAGE LEDGER — mandatory gate before writing

* Maintain the ledger as an explicit written list BEFORE composing the brief. For every source in sources.md (excluding the "Retired / Dropped" section), one line: `<source> | <exact query run> | <result: URL + date, or "nothing recent">`.
* Count check: the ledger must have the same number of lines as sources.md has scannable sources (i.e. everything above the "Retired / Dropped" section). State the two counts explicitly (e.g. "44 scannable sources in sources.md, 44 ledger lines"). If they don't match, find the missing sources and search them — do NOT write the brief until the counts match.
* Every ledger line must name a single source and cite a query actually run THIS run. A line covering two or more sources is invalid — split it and search each.
* Tags like "(sparse)" or "(search-only / best-effort)" lower the expected effort for a source but never exempt it from a query or a ledger line. A sparse source still gets one search and one recorded result.
* The footer must reproduce the ledger 1:1: every source individually, with its own result. Never comma-join multiple source names under one shared verdict.

## LINK AUDIT — mandatory gate before finalizing

After drafting the HTML but BEFORE writing the footer / saving the final file:

1. Extract every `href` in the drafted brief (and in the index.html / topics.html edits).
2. For each one, confirm it appeared this run in a WebSearch result list or a fetched page
   body, AND that it points to the specific thing its anchor text claims (see "NO
   UNVALIDATED LINKS" above).
3. Any href that fails either test is downgraded to unlinked text or replaced with the
   verified source URL with honest anchor text. Do NOT keep it just because it renders.
4. For `.significant` items specifically, the permalink must have been confirmed by an
   actual fetch this run — not inferred from a snippet.
5. State the audit result explicitly (e.g. "27 links, all traced to this run's results;
   2 downgraded to unlinked"). Do not save the final file until this passes.

You may run this mechanically: `grep -oE 'href="[^"]+"'` the draft, then check each URL
against the run.

## RESILIENCE — never abort mid-run

Individual source failures are EXPECTED and NON-FATAL. The goal is always to
produce a brief with whatever succeeded, never to stop.

- **Any single source failing is non-fatal.** Fetch error, timeout, non-200,
  empty body, rate limit, or malformed response — note it and move on to the
  next source. One bad source must never end the run.
- **Retry once, then skip.** On a failed fetch, wait briefly and retry it a
  single time. If it fails again, record it as "unavailable today" and continue.
- **No source is a hard dependency.** Even if a major company blog (including
  Anthropic) fails, keep going. There are no must-succeed sources.
- **Always write the brief.** After scanning, produce and write today's HTML
  file with whatever content you gathered — even if several sources failed.
  A partial brief is a success; no brief is a failure.
- **"Always write the brief" applies to fetch failures, never to sources you
  chose not to query.** An unqueried source is not a failure to note — it is a
  gap to fill before writing. Complete the coverage ledger first (see gate above).
- **List failures in the footer.** The footer's source list should mark each
  failed source as unavailable so the gap is visible, not silent.
- **A link that can't be validated is a link to drop, not a run to abort.** Follow
  the "degrade gracefully" rule — unlink it and keep going.

## WHAT TO WRITE

Create YYYY-MM-DD.html (today's date) in the project root.

Use the same dark-theme HTML design as 2026-06-05.html (read that file for the exact CSS). Structure:

1. Nav (links to index.html and topics.html)
2. Header with date
3. "generated at" timestamp
4. begin with a "What's Actually New Today" bullet list (not a paragraph of text)
5. Company sections (one per company with items found) — include an "Open Weights /
   Emerging labs" subsection for xAI, DeepSeek, Qwen, GLM, Meta Llama, Cognition, etc.
6. Research & Aggregators section (Hugging Face, The Batch, arXiv, The Rundown, The AI Daily Brief)
7. Practitioners section (subsections per source)
8. X/Social section
9. Community/HN section
10. Notable Themes (3-5 cross-cutting observations)
11. Footer listing all sources checked

Item classes:
- `.item.significant` — purple left border, for major announcements
- `.item.new-item` — teal left border, for notable but not headline items
- Plain `.item` — for routine updates

Mark items as NEW only if they weren't in the previous brief (read the most recent .html brief in the project root to check).

## AFTER WRITING THE BRIEF

1. Update index.html (in the project root):
   - Read the file first (required before editing)
   - Add a new day-card for today at the top of the cards list (after the h2 year heading)
   - Day card should show source count and 5-6 highlight bullets (most significant items)

2. Update topics.html (in the project root):
   - Read the file first
   - Add new entries to existing topic cards where relevant
   - Add new topic cards if a theme appears across 2+ sources or seems likely to recur
   - Update "Last updated" dates on any topics you add entries to

3. DON'T add any other files to the project root!

## STYLE NOTES
- Be specific and factual — include model names, numbers, dollar amounts
- Note when something is absent (e.g. "No new posts since [date]") rather than omitting sources
- Avoid vague summaries; if a post has a clear argument, state it
- Cross-reference: if multiple sources cover the same event, note that
- Prefer accuracy over completeness on links: an unlinked true statement beats a linked wrong URL

## CSS VARIABLES (for consistency)
--bg: #0f1117; --surface: #1a1d27; --surface2: #22263a; --border: #2e3348;
--text: #e2e5f0; --muted: #7c82a0; --accent: #7b6ef6; --accent2: #56cfb2;
--warn: #f0a850; --red: #e06060