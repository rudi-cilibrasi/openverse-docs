#!/usr/bin/env bash
# Assemble the website (published on GitHub Pages) in build/site/:
#
#   index.html, style.css, favicon.svg   the landing page (site/), and 404.html
#   book.css                             the style of the web editions
#   <book>/index.html                    the web edition: the book as one HTML page, math in MathML
#   <book>/<book>.pdf                    the PDF from scripts/build.sh (build it first: make pdf)
#   <book>/<book>.md                     the Markdown edition: metadata and chapters in one file
#   demo/                                the playground: a built dist/ of the demo submodule
#   sim/                                 the 3D simulator: a built dist/ of the sim submodule
#
#   scripts/build-site.sh                                   # the playground from demo/dist
#   DEMO_DIST=../openverse-online-demo/dist scripts/build-site.sh
#   DEMO_DIST=none SIM_DIST=none scripts/build-site.sh      # books only; CI adds both toys later
#
# It fails on any pandoc warning (math that MathML cannot show, for one) and,
# through scripts/check-site.py, on a link to a file or anchor the site lacks.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
command -v pandoc >/dev/null || { echo "build-site.sh: pandoc is not installed" >&2; exit 2; }

site=build/site
demo_dist="${DEMO_DIST:-demo/dist}"
sim_dist="${SIM_DIST:-sim/dist}"
date_str="${PROMODOC_DATE:-$(date +'%B %Y')}"

if [[ "$demo_dist" != none ]] && ! [[ -f "$demo_dist/index.html" && -f "$demo_dist/wasm/compiler.wasm" ]]; then
  echo "build-site.sh: no built playground in $demo_dist." >&2
  echo "  Build it (demo/scripts/build.sh), point DEMO_DIST at one, or set DEMO_DIST=none." >&2
  exit 2
fi

if [[ "$sim_dist" != none ]] && ! [[ -f "$sim_dist/index.html" && -f "$sim_dist/wasm/compiler.wasm" && -f "$sim_dist/wasm/map-runtime.wasm" ]]; then
  echo "build-site.sh: no built simulator in $sim_dist." >&2
  echo "  Build it (cd sim && npm ci && npm run build), point SIM_DIST at one, or set SIM_DIST=none." >&2
  exit 2
fi

# Which sources this site was built from, named on the landing page and in each book.
docs_commit="$(git rev-parse HEAD)"
if [[ -n "${OPENVERSE:-}" ]]; then
  openverse_commit="$(git -C "$OPENVERSE" rev-parse HEAD)"
else
  openverse_commit="$(git rev-parse HEAD:openverse)"
fi

rm -rf "$site"
mkdir -p "$site"
cp site/index.html site/404.html site/style.css site/book.css site/favicon.svg "$site/"
touch "$site/.nojekyll"   # GitHub Pages: serve the files as they are

for d in books/*/; do
  book="$(basename "$d")"
  src="books/$book"
  out="$site/$book"
  pdf="build/$book/$book.pdf"
  [[ -f "$pdf" ]] || { echo "build-site.sh: $pdf is missing; build it first (make pdf)" >&2; exit 2; }
  mkdir -p "$out"
  cp "$pdf" "$out/"
  mapfile -t parts < <(ls "$src"/*.md | sort)

  # The Markdown edition: exactly what the PDF is built from, as one file.
  { cat "$src/metadata.yaml"; for p in "${parts[@]}"; do printf '\n'; cat "$p"; done; } > "$out/$book.md"

  # The web edition, with contents one level deeper than the PDF's.
  depth="$(sed -n 's/^toc-depth: *//p' "$src/metadata.yaml")"
  echo "== $book: web edition"
  pandoc "$src/metadata.yaml" "${parts[@]}" \
    --from markdown+fenced_divs+raw_tex+tex_math_dollars \
    --to html5 --standalone --template site/book.html --wrap=none \
    --mathml --section-divs --number-sections \
    --toc --toc-depth "$(( ${depth:-1} + 1 ))" \
    --syntax-definition syntax/verse.xml --syntax-definition syntax/lean4.xml \
    --highlight-style tex/code.theme \
    --lua-filter filters/headings.lua --lua-filter filters/qa.lua \
    --lua-filter filters/boxes.lua --lua-filter filters/web.lua \
    --fail-if-warnings \
    -M date="$date_str" -V book="$book" \
    -V openverse_commit="$openverse_commit" -V openverse_short="${openverse_commit:0:7}" \
    -o "$out/index.html"
done

if [[ "$demo_dist" != none ]]; then
  mkdir -p "$site/demo"
  cp -R "$demo_dist"/. "$site/demo/"
  demo_commit="$(git -C "$demo_dist/.." rev-parse HEAD)"
else
  demo_commit="$(git rev-parse HEAD:demo)"   # CI builds the pinned submodule
fi

if [[ "$sim_dist" != none ]]; then
  mkdir -p "$site/sim"
  cp -R "$sim_dist"/. "$site/sim/"
  sim_commit="$(git -C "$sim_dist/.." rev-parse HEAD)"
else
  sim_commit="$(git rev-parse HEAD:sim 2>/dev/null || git rev-parse :sim)"
fi

sed -i \
  -e "s/@BUILD_DATE@/$(date -u +'%Y-%m-%d')/g" \
  -e "s/@DOCS_COMMIT@/$docs_commit/g" -e "s/@DOCS_SHORT@/${docs_commit:0:7}/g" \
  -e "s/@OPENVERSE_COMMIT@/$openverse_commit/g" -e "s/@OPENVERSE_SHORT@/${openverse_commit:0:7}/g" \
  -e "s/@DEMO_COMMIT@/$demo_commit/g" -e "s/@DEMO_SHORT@/${demo_commit:0:7}/g" \
  -e "s/@SIM_COMMIT@/$sim_commit/g" -e "s/@SIM_SHORT@/${sim_commit:0:7}/g" \
  "$site/index.html"

check_args=("$site")
if [[ "$demo_dist" == none ]]; then check_args+=(--without demo/); fi
if [[ "$sim_dist" == none ]]; then check_args+=(--without sim/); fi
python3 scripts/check-site.py "${check_args[@]}"
echo "== site: $site ($(du -sh "$site" | cut -f1))"
