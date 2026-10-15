#!/usr/bin/env bash
# organize.sh: idempotent layout housekeeping. Safe to run on every publish.
#   1. (first run only) splits the legacy index.html into cards/YYYY-MM-DD.html
#      fragments and saves its page chrome and footer to src/templates/
#   2. moves any root-level YYYY-MM-DD.html into YYYY/MM/, adding an Archive nav
#      link and fixing its relative links
#   3. adds the Archive nav link and rewrites flat day links in the remaining
#      root pages (topics.html etc.)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
shopt -s nullglob

TEMPLATE=src/templates/index-head.html
FOOTER=src/templates/index-footer.html

# Insert an Archive link into a page's nav, right after the Topics link.
# No-op when the page already links archive.html, so re-runs are safe and the
# model may emit the link itself without producing a duplicate.
add_archive_nav() {
  local f=$1
  if grep -q 'href="[^"]*archive\.html"' "$f"; then return 0; fi
  SNIPPET="$2" perl -0777 -i -pe \
    's{(<a href="topics\.html"[^>]*>Topics</a>)}{$1 . $ENV{SNIPPET}}e' "$f"
}

DAY_NAV=$'\n  <span style="color:var(--border)">\xc2\xb7</span>\n  <a href="archive.html">Archive</a>'
ROOT_NAV=$'\n  <a href="archive.html">Archive</a>'
INDEX_NAV=$'\n  <a href="archive.html" style="color:var(--muted);font-size:13px;border:none;">Archive</a>'

# 1. One-time bootstrap from the legacy index.html
if [ ! -d cards ]; then
  mkdir -p cards "$(dirname "$TEMPLATE")"
  perl -0777 -ne '
    while (m{(<a class="day-card" href="(\d{4}-\d{2}-\d{2})\.html">.*?</a>)}sg) {
      open my $fh, ">", "cards/$2.html" or die "cards/$2.html: $!";
      print $fh "$1\n"; close $fh;
    }' index.html
  # Everything before the first <h2> is page chrome (head, styles, nav, header);
  # the <footer> after the last card is kept so generated pages still carry it.
  perl -0777 -ne 'print $1 if m{\A(.*?)<h2>}s' index.html > "$TEMPLATE"
  perl -0777 -ne 'print "$1\n" if m{(<footer>.*?</footer>)}s' index.html > "$FOOTER"
  add_archive_nav "$TEMPLATE" "$INDEX_NAV"
  echo "bootstrapped $(ls cards | wc -l | tr -d ' ') cards, $TEMPLATE, $FOOTER"
fi

# 2. Move root-level day pages into YYYY/MM/
for f in 20[0-9][0-9]-[01][0-9]-[0-3][0-9].html; do
  y=${f:0:4}; m=${f:5:2}
  add_archive_nav "$f" "$DAY_NAV"
  # The page moves two levels down: prefix relative links with ../../ and map
  # flat day links (2026-09-12.html) to 2026/09/2026-09-12.html. Only values
  # that look like a real relative path are rewritten — briefs quote things
  # like grep -oE 'href="[^"]+"' as literal prose, and that must not be touched.
  perl -i -pe '
    s{\b(href|src)="((?![a-zA-Z][a-zA-Z0-9+.-]*:|#|/|\.\./)[A-Za-z0-9._/-]+\.html)"}{
      my ($attr, $p) = ($1, $2);
      $p =~ s{^(\d{4})-(\d{2})-(\d{2}\.html)$}{$1/$2/$1-$2-$3};
      qq{$attr="../../$p"}
    }ge' "$f"
  mkdir -p "$y/$m"
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    git mv "$f" "$y/$m/$f"
  else
    mv "$f" "$y/$m/$f"
  fi
  echo "moved $f -> $y/$m/$f"
done

# 3. Add the Archive nav link and fix flat day links in the remaining root pages
for f in *.html; do
  case "$f" in index.html|archive.html|404.html) continue ;; esac
  add_archive_nav "$f" "$ROOT_NAV"
  perl -i -pe 's{\b(href|src)="(\d{4})-(\d{2})-(\d{2}\.html)"}{$1="$2/$3/$2-$3-$4"}g' "$f"
done
