#!/usr/bin/env python3
"""Resolve every relative href/src in every .html file against that file's own
directory and report targets that don't exist. Anchors and external URLs are
skipped. Exits non-zero if anything is broken."""
import os
import re
import sys
from urllib.parse import unquote, urlparse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAGES_BASE = '/my-ai-daily/'   # GitHub Pages serves the repo under this prefix
ATTR = re.compile(r'\b(?:href|src)\s*=\s*"([^"]*)"', re.I)

# Values that are prose rather than paths (briefs quote grep patterns verbatim)
LOOKS_LIKE_PATH = re.compile(r'^[A-Za-z0-9._/#?~%-]+$')

broken, checked = [], 0
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in ('.git', 'tmp', 'src')]
    for name in filenames:
        if not name.endswith('.html'):
            continue
        path = os.path.join(dirpath, name)
        with open(path, encoding='utf-8', errors='replace') as fh:
            body = fh.read()
        for raw in ATTR.findall(body):
            target = raw.strip()
            if not target or target.startswith(('#', '//')):
                continue
            if urlparse(target).scheme:          # http:, mailto:, data:, ...
                continue
            if not LOOKS_LIKE_PATH.match(target):
                continue                          # quoted prose, not a link
            rel = unquote(target.split('#')[0].split('?')[0])
            if not rel:
                continue
            checked += 1
            if rel.startswith('/'):
                # Root-absolute links are served under the Pages base path
                if not rel.startswith(PAGES_BASE):
                    broken.append((os.path.relpath(path, ROOT), target))
                    continue
                rel = rel[len(PAGES_BASE):]
                base = ROOT
            else:
                base = dirpath
            resolved = os.path.normpath(os.path.join(base, rel.lstrip('/')))
            if os.path.isdir(resolved):
                resolved = os.path.join(resolved, 'index.html')
            if not os.path.exists(resolved):
                broken.append((os.path.relpath(path, ROOT), target))

print(f'checked {checked} relative references across the site')
for src, target in broken:
    print(f'  BROKEN  {src} -> {target}')
print(f'{len(broken)} broken' if broken else 'no broken links')
sys.exit(1 if broken else 0)
