#!/usr/bin/env bash
# build-index.sh: regenerate index.html (latest N days) and archive.html (every day).
# Reads cards/YYYY-MM-DD.html and YYYY/MM/YYYY-MM-DD.html; never modifies them.
#   RECENT_DAYS=7 src/build-index.sh   # override the default of 5
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

N="${RECENT_DAYS:-5}"
TEMPLATE=src/templates/index-head.html
FOOTER=src/templates/index-footer.html

# The legacy index.html ended with a <footer>; organize.sh saved it so both
# generated pages keep it.
emit_footer() { if [ -s "$FOOTER" ]; then cat "$FOOTER"; fi; }
MONTHS=(January February March April May June July August September October November December)

path_of()      { echo "${1:0:4}/${1:5:2}/$1.html"; }
month_name()   { echo "${MONTHS[$((10#${1:5:2} - 1))]}"; }
pretty()       { echo "$(month_name "$1") $((10#${1:8:2})), ${1:0:4}"; }
pretty_short() { echo "$(month_name "$1" | cut -c1-3) $((10#${1:8:2}))"; }

# Every published day, newest first (the filesystem is the source of truth)
days=()
while IFS= read -r p; do days+=("$(basename "$p" .html)"); done \
  < <(ls 20[0-9][0-9]/[01][0-9]/20[0-9][0-9]-[01][0-9]-[0-3][0-9].html 2>/dev/null | sort -r)
[ ${#days[@]} -gt 0 ] || { echo "build-index: no day pages found" >&2; exit 1; }

# ---- index.html ----
{
  cat "$TEMPLATE"
  echo '<h2>Latest</h2>'
  shown=0
  for d in "${days[@]}"; do
    [ "$shown" -ge "$N" ] && break
    if [ -f "cards/$d.html" ]; then
      # Point the card at the page's real location, whatever href it was written with
      P="$(path_of "$d")" perl -pe 's{(<a class="day-card" href=")[^"]*}{$1$ENV{P}}' "cards/$d.html"
    else
      echo "build-index: warning: no card for $d, using a plain one" >&2
      echo "<a class=\"day-card\" href=\"$(path_of "$d")\"><div class=\"day-card-header\"><div class=\"day-card-date\">$(pretty "$d")</div></div><div class=\"day-card-footer\">Read the full brief →</div></a>"
    fi
    shown=$((shown + 1))
  done
  echo "<p style=\"margin-top:28px;\"><a href=\"archive.html\">All ${#days[@]} briefs in the archive →</a></p>"
  emit_footer
  echo '</body>'
  echo '</html>'
} > index.html.tmp
mv index.html.tmp index.html

# ---- archive.html ----
{
  perl -0777 -pe 's{<title>.*?</title>}{<title>AI Daily — Archive</title>}s; s{<h1>.*?</h1>}{<h1>Archive</h1>}s' "$TEMPLATE"
  cat <<'CSS'
<style>
.archive { list-style: none; }
.archive li { display: flex; gap: 16px; padding: 8px 0; border-bottom: 1px solid var(--border); font-size: 14px; }
.archive .date { flex: 0 0 56px; font-variant-numeric: tabular-nums; }
.archive .lead { color: #b0b6cc; }
</style>
CSS
  prev=""
  for d in "${days[@]}"; do
    ym=${d:0:7}
    if [ "$ym" != "$prev" ]; then
      [ -n "$prev" ] && echo '</ul>'
      echo "<h2>$(month_name "$d") ${d:0:4}</h2>"
      echo '<ul class="archive">'
      prev=$ym
    fi
    lead=""
    if [ -f "cards/$d.html" ]; then
      # First highlight's bold lead-in, tags stripped
      lead=$(perl -0777 -ne 'if (m{<div class="highlight-text"><strong>(.*?)</strong>}s) { ($x = $1) =~ s/<[^>]+>//g; print $x }' "cards/$d.html")
    fi
    echo "<li><a class=\"date\" href=\"$(path_of "$d")\">$(pretty_short "$d")</a><span class=\"lead\">$lead</span></li>"
  done
  echo '</ul>'
  emit_footer
  echo '</body>'
  echo '</html>'
} > archive.html.tmp
mv archive.html.tmp archive.html

echo "build-index: index.html shows $([ ${#days[@]} -lt "$N" ] && echo ${#days[@]} || echo "$N") of ${#days[@]} days; archive.html rebuilt"
