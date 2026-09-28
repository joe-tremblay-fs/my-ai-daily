# Task: restructure my-ai-daily's site layout

This repo publishes a daily AI news brief to GitHub Pages. An LLM (driven by `src/prompt.md` and shell scripts in `src/`) writes one `YYYY-MM-DD.html` per day into the repo root and prepends a "day card" to `index.html`. Three problems need fixing:

1. `index.html` grows forever (~400 KB now). It should show only the latest **5** day cards.
2. Once the index is trimmed, older days need a way to be reached, so there must be an **archive page**.
3. Day pages clutter the root. They should live at **`YYYY/MM/YYYY-MM-DD.html`**, and old URLs must keep working.

## Files provided alongside this prompt

- `src/organize.sh`: idempotent, run on every publish. On the first run it splits the legacy `index.html` into `cards/YYYY-MM-DD.html` fragments and saves the page chrome to `src/templates/index-head.html` (adding an Archive nav link). On every run it moves root-level `YYYY-MM-DD.html` files into `YYYY/MM/`, rewrites their relative links (prefixes `../../`, maps flat day links to the nested path), and fixes flat day links in other root pages such as `topics.html`.
- `src/build-index.sh`: regenerates `index.html` (latest N cards, default 5, override with `RECENT_DAYS`) and `archive.html` (all days grouped by month, with each day's lead headline) from `cards/` and `YYYY/MM/`.
- `404.html`: goes in the repo root. It redirects old flat URLs (`/my-ai-daily/2026-09-12.html`) to the nested path, preserving `#anchors`.

These were tested against a fixture that uses the real card markup, but **not against the real repo**. Treat them as a strong starting point and adapt them where the repo differs.

## Design principle

The LLM produces content, and scripts handle assembly and layout. The model should keep writing flat filenames and flat links (`2026-09-12.html`), and `organize.sh` normalizes them. Don't ask the model to produce `../../` paths.

## Steps

### 1. Investigate before changing anything
Work on a new branch (`git checkout -b layout-restructure`). Then read and summarize for me:
- `src/prompt.md`: every place it tells the model to create, read, or edit `index.html`, day pages, or `topics.html`, and whether it uses `index.html` as memory of prior coverage (for corrections and "yesterday we reported…" references).
- Every script in `src/`: how the model is invoked, how files are staged and committed (look for globs like `*.html` or `20*.html` and hardcoded paths), and anything else that assumes day pages are in the root.
- The tail of the current `index.html`: is there a `<footer>` or other content after the last card? `build-index.sh` doesn't carry it over, so if one exists, add it to the end of the generated index and archive.
- A few day pages: list every kind of relative reference (`href`, `src`, CSS `url()`, inline JS paths, links spanning multiple lines). `organize.sh` only rewrites `href="…"` and `src="…"` attributes on a single line, so extend it if the pages use anything else.
- `topics.html`: who generates it (the model, a script, or nobody) and how it links to days.

If anything you find conflicts with the plan below, stop and tell me before proceeding.

### 2. Install the files
Copy `src/organize.sh`, `src/build-index.sh`, and `404.html` into place and `chmod +x` the scripts. `404.html` hardcodes the `/my-ai-daily/` base path, so confirm that matches the Pages URL (`https://joe-tremblay-fs.github.io/my-ai-daily/`).

### 3. Update `src/prompt.md`
Make minimal, surgical edits that preserve everything unrelated:
- Remove all instructions to edit or prepend to `index.html`.
- Add: write the day card to `cards/YYYY-MM-DD.html` as a single `<a class="day-card" href="YYYY-MM-DD.html">…</a>` block, using the same markup as before.
- Keep writing the full brief to `YYYY-MM-DD.html` in the repo root. A script moves it, so the model shouldn't.
- Links to other days use the flat `YYYY-MM-DD.html` form.
- Explicitly forbid editing `index.html` and `archive.html`, because they're generated.
- If the prompt used `index.html` for recent-coverage context, redirect it to read the 7–10 most recent files in `cards/`, and `YYYY/MM/YYYY-MM-DD.html` for full detail on a given day.
- If the model maintains `topics.html`, flat day links there are still fine because `organize.sh` fixes them.

Show me the diff of `prompt.md`.

### 4. Wire the scripts into the publish flow
In the existing publish script, run `src/organize.sh && src/build-index.sh` after the model finishes and before staging or committing. Update any staging globs so they include `cards/`, `YYYY/MM/`, `archive.html`, `404.html`, and `src/templates/`. Make sure `.gitignore` doesn't exclude any of these.

### 5. Run the migration and verify
Run `src/organize.sh && src/build-index.sh` once on the current repo, then check:
- The root has no `20??-??-??.html` files left, and every day is in `YYYY/MM/`.
- `cards/` has one file per day that was in the old index. Report any days that have a page but no card, or a card but no page.
- `index.html` has exactly 5 day cards, newest first, and every card's `href` resolves to an existing file.
- `archive.html` lists every day page.
- There are no broken relative links anywhere. Write a quick check that walks every `.html` file, resolves each relative `href`/`src` against the file's directory, and reports missing targets (ignore `#` anchors and external URLs).
- Running both scripts a second time produces no further changes (`git status` stays clean apart from regenerated timestamps, if any).
- Serve the repo under the Pages base path and click through: index → day page → nav back to index, topics, and archive. For example: `mkdir -p /tmp/pages && ln -sfn "$PWD" /tmp/pages/my-ai-daily && cd /tmp/pages && python3 -m http.server`, then open `http://localhost:8000/my-ai-daily/`. Note that `python -m http.server` won't serve `404.html` for missing paths, so verify the redirect logic by reading it, or test it after deploy.

### 6. Dry-run a daily cycle
Without calling the model, simulate one day. Create a root-level `2099-01-01.html` with flat links and a matching `cards/2099-01-01.html`, run the publish flow up to (but not including) commit and push, and confirm the page lands in `2099/01/`, appears first on the index, and appears in the archive. Then remove the test files and rebuild.

### 7. Commit
Make two commits on the branch:
1. "Add layout scripts, 404 redirect, and prompt changes": the scripts, `404.html`, the `prompt.md` edits, and the publish-script wiring.
2. "Migrate day pages to YYYY/MM and generate index/archive": the file moves, `cards/`, the template, and the regenerated pages. Use `git mv` so history follows the files.

Don't push or merge. Give me a summary of what changed, anything you adapted in the scripts and why, and anything you couldn't verify.
