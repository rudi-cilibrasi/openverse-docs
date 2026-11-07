# promodoc: the openverse books

Two books about Verse as implemented by
[openverse](https://github.com/rudi-cilibrasi/openverse), built into PDFs
from Markdown, with every program and every Lean statement checked against
openverse at build time.

| Book | For | Sources | PDF |
|---|---|---|---|
| **Verse Logic**: *Eight Theorems about a Functional Logic Language* | college and graduate students of mathematics, logic and CS | `books/verse-logic/` | `build/verse-logic/verse-logic.pdf` |
| **The Little Verser**: *A friendly dialogue about Verse* | beginners; no Lean, no mathematics | `books/little-verser/` | `build/little-verser/little-verser.pdf` |

*Verse Logic* has one chapter per core Lean theorem of openverse
(adequacy, determinism, rollback, `<decides>` soundness, type safety, the
substitution lemma, heap effects, and `Prog.accepted`), each stated in
symbolic logic, read in Lean, proved in outline and shown at work in Verse
programs. *The Little Verser* teaches the same language as a question and
answer dialogue in the manner of *The Little Lisper*, and states openverse's
proved promises in plain English.

## Building

Requirements: `pandoc` (3.1 or later), `xelatex` with the TeX Gyre fonts,
`tcolorbox`, `titlesec` and `lkproof` (all in TeX Live), DejaVu Sans Mono,
`python3`, and a built openverse checkout next to this one
(`../openverse`, with `lake build` done), or pointed to by `OPENVERSE`.

```sh
make                 # check both books, then build both PDFs
make check           # run every program, compare every output and Lean claim
make pdf             # build/verse-logic/verse-logic.pdf, build/little-verser/little-verser.pdf
make verse-logic     # one book: check + pdf
make OPENVERSE=/path/to/openverse check
```

`make check` (`scripts/check-books.py`) fails when any of these breaks:

- a ```` ```{.verse .run} ```` program's output differs from the ```` ```{.output} ````
  block under it, or its exit code from `exit=`;
- a ```` ```{.verse .reject expect="…"} ```` program is accepted, or rejected with a
  different message; a ```` ```{.verse .check} ```` program is rejected;
- a ```` ```{.lean .claim name="…"} ```` statement differs (up to white space) from
  the one Lean prints in openverse's `docs/CLAIMS.md`, or an
  ```` ```{.lean .excerpt file="…"} ```` is not in that source file;
- a book has more than 8 numbered chapters; a Verse Logic chapter lacks a
  theorem box, a Lean claim or a runnable program; The Little Verser shows
  Lean (a Lean block, a Lean name, or the word "Lean"); a dialogue is
  malformed; the rules appendix does not repeat the chapters' rules;
- a code line is too wide for its place on the page.

`scripts/build.sh` fails on LaTeX errors and on glyphs missing from the
fonts.

## Writing and regenerating with an agent

The prompts that define the books are in `prompts/`: `common.md` (shared),
`verse-logic.md`, `little-verser.md`, and `REQUEST.md` (the request they came
from). `scripts/generate.sh` runs them with either agent CLI, then checks and
builds the book itself, so a run only succeeds if `make <book>` passes.

```sh
# Claude Code
scripts/generate.sh --agent claude --book little-verser
scripts/generate.sh --agent claude --book verse-logic --chapter 3
scripts/generate.sh --agent claude --book all --model opus --task "Update for the new heap theorems"

# Codex
scripts/generate.sh --agent codex --book verse-logic
scripts/generate.sh --agent codex --book little-verser --chapter 6

# print the composed prompt file and the exact command, run nothing
scripts/generate.sh --agent codex --book verse-logic --dry-run

# the same through make
make generate AGENT=codex BOOK=verse-logic CHAPTER=2 TASK="Add an exercise on Runs.det"
make generate AGENT=claude BOOK=all DRY=1      # show the commands only
```

What the script runs (the prompt file is composed in `build/prompts/`, the
transcript goes to `build/logs/`):

```sh
# Claude Code: non-interactive; edits accepted; shell limited to the tools the work needs
claude -p --output-format text --add-dir ../openverse --permission-mode acceptEdits \
  --allowedTools Read Edit Write Glob Grep "Bash(make:*)" "Bash(scripts/build.sh:*)" \
                 "Bash(python3 scripts/check-books.py:*)" "Bash(../openverse/.lake/build/bin/openverse:*)" \
                 "Bash(pandoc:*)" "Bash(pdftotext:*)" … \
  < build/prompts/<book>-<stamp>.md

# Codex: non-interactive; writes confined to this repository by the sandbox
codex exec -C . --color never -s workspace-write -o build/logs/<book>-codex-<stamp>.last.md - \
  < build/prompts/<book>-<stamp>.md
```

`--unsafe` replaces the permission settings with
`--dangerously-skip-permissions` (Claude) or
`--dangerously-bypass-approvals-and-sandbox` (Codex); use it only in a
throwaway checkout. Agents are told not to commit and not to touch
openverse; review the diff, then commit.

## Layout

```
books/<book>/metadata.yaml   title, fonts, page geometry (pandoc metadata)
books/<book>/00-preface.md   unnumbered preface
books/<book>/NN-*.md         chapters (at most 8), assembled in file-name order
books/<book>/A1-*.md         appendices (the first starts with \appendix)
prompts/                     the prompts that define the books, and the request
scripts/check-books.py       the checker (programs, Lean claims, book rules)
scripts/build.sh             Markdown -> LaTeX -> PDF
scripts/generate.sh          run a prompt with Claude Code or Codex
filters/qa.lua               ::: qa dialogues -> two columns (The Little Verser)
filters/boxes.lua            ::: theorem/definition/note/exercise/rule boxes; output panels
tex/                         LaTeX styling: common.tex, one file per book, code.theme
syntax/                      Verse and Lean highlighting for pandoc
```

This repository is private for now.
