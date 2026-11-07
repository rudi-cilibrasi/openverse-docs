#!/usr/bin/env python3
"""Check the links of the assembled website.

    scripts/check-site.py build/site                  # every page
    scripts/check-site.py build/site --without demo/  # the playground is added later

Every relative href and src in every HTML page must name a file of the site
(a directory means its index.html), and a #fragment must name an id in the
page it points into, unless it carries parameters (#code=…, read by the
playground's script). Links to other sites are not fetched. With --without
PREFIX, links into PREFIX (relative to the site root) are skipped, and pages
under it are not read.
"""
import argparse
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links, self.ids = [], set()

    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name == "id" and value:
                self.ids.add(value)
            if value and ((name == "href" and tag in ("a", "link")) or (name == "src" and tag in ("script", "img"))):
                self.links.append((self.getpos()[0], value))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("site", type=Path)
    ap.add_argument("--without", action="append", default=[])
    args = ap.parse_args()
    root = args.site.resolve()
    skip = [root / p for p in args.without]

    def skipped(path):
        return any(path == s or s in path.parents for s in skip)

    pages = {}
    for f in sorted(root.rglob("*.html")):
        if skipped(f):
            continue
        p = Page()
        p.feed(f.read_text(encoding="utf-8"))
        pages[f] = p

    problems, checked = [], 0
    for f, page in pages.items():
        for line, link in page.links:
            parts = urlsplit(link)
            if parts.scheme or parts.netloc or link.startswith(("mailto:", "data:", "javascript:")):
                continue
            target = f if not parts.path else (f.parent / unquote(parts.path)).resolve()
            if skipped(target):
                continue
            if target.is_dir():
                target = target / "index.html"
            where = f"{f.relative_to(root)}:{line}: {link}"
            checked += 1
            if root not in target.parents and target != root:
                problems.append(f"{where}: leaves the site")
            elif not target.is_file():
                problems.append(f"{where}: no such file")
            elif parts.fragment and "=" not in parts.fragment and target.suffix == ".html":
                ids = pages[target].ids if target in pages else set()
                if unquote(parts.fragment) not in ids:
                    problems.append(f"{where}: no id {parts.fragment!r} in {target.relative_to(root)}")
    for p in problems:
        print(p, file=sys.stderr)
    print(f"check-site.py: {len(pages)} pages, {checked} links, {len(problems)} broken")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
