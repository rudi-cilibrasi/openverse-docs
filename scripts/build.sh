#!/usr/bin/env bash
# Build the PDF of each book: Markdown --pandoc--> LaTeX --xelatex--> PDF.
#
#   scripts/build.sh                  # every book in books/
#   scripts/build.sh verse-logic      # one book
#
# Output: build/<book>/<book>.pdf (and the .tex and .log beside it).
# The build fails when LaTeX fails, or when a glyph is missing from a font,
# because that is how Unicode in Lean code silently turns into blanks.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

for tool in pandoc xelatex; do
  command -v "$tool" >/dev/null || { echo "build.sh: $tool is not installed" >&2; exit 2; }
done

books=("$@")
if [[ ${#books[@]} -eq 0 ]]; then
  for d in books/*/; do books+=("$(basename "$d")"); done
fi

date_str="${PROMODOC_DATE:-$(date +'%B %Y')}"

for book in "${books[@]}"; do
  src="books/$book"
  [[ -f "$src/metadata.yaml" ]] || { echo "build.sh: no $src/metadata.yaml" >&2; exit 2; }
  out="build/$book"
  mkdir -p "$out"
  # chapters in file-name order: 00-preface, 01-…, then appendices A1-…
  mapfile -t parts < <(ls "$src"/*.md | sort)
  filters=(--lua-filter filters/boxes.lua)
  [[ -f "filters/qa.lua" ]] && filters=(--lua-filter filters/qa.lua "${filters[@]}")
  headers=(-H tex/common.tex)
  [[ -f "tex/$book.tex" ]] && headers+=(-H "tex/$book.tex")

  echo "== $book: pandoc (${#parts[@]} files)"
  pandoc "$src/metadata.yaml" "${parts[@]}" \
    --from markdown+fenced_divs+raw_tex+tex_math_dollars \
    --to latex --standalone \
    --top-level-division=chapter --number-sections \
    --syntax-definition syntax/verse.xml --syntax-definition syntax/lean4.xml \
    --highlight-style tex/code.theme \
    "${filters[@]}" "${headers[@]}" \
    -M date="$date_str" \
    -o "$out/$book.tex"

  echo "== $book: xelatex"
  for pass in 1 2 3; do
    if ! (cd "$out" && xelatex -interaction=nonstopmode -halt-on-error "$book.tex" >/dev/null 2>&1); then
      echo "build.sh: xelatex failed on $book (pass $pass); the end of $out/$book.log:" >&2
      grep -n -A3 '^!' "$out/$book.log" | head -30 >&2 || tail -30 "$out/$book.log" >&2
      exit 1
    fi
    # stop early once the cross-references have settled
    grep -q 'Rerun to get' "$out/$book.log" || [[ $pass -lt 2 ]] || break
  done

  if grep -q 'Missing character' "$out/$book.log"; then
    echo "build.sh: $book uses characters its fonts do not have:" >&2
    grep 'Missing character' "$out/$book.log" | sort | uniq -c | head -20 >&2
    exit 1
  fi
  pages="$(pdfinfo "$out/$book.pdf" 2>/dev/null | sed -n 's/^Pages: *//p' || true)"
  echo "== $book: $out/$book.pdf${pages:+ ($pages pages)}"
done
