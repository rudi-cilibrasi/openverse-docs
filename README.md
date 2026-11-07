# openverse-docs: the openverse books and playgrounds

Two books about Verse as implemented by
[openverse](https://github.com/rudi-cilibrasi/openverse), and two browser
playgrounds that run it, published together at **<https://rudi-cilibrasi.github.io/openverse-docs/>**.
Every program and every Lean statement in the books is checked against
openverse each time the site is built.

| | For | Read | Sources |
|---|---|---|---|
| **Verse Logic**: *Eight Theorems about a Functional Logic Language* | college and graduate students of mathematics, logic and CS | [web](https://rudi-cilibrasi.github.io/openverse-docs/verse-logic/) · [PDF](https://rudi-cilibrasi.github.io/openverse-docs/verse-logic/verse-logic.pdf) · [Markdown](https://rudi-cilibrasi.github.io/openverse-docs/verse-logic/verse-logic.md) | `books/verse-logic/` |
| **The Little Verser**: *A friendly dialogue about Verse* | beginners; no Lean, no mathematics | [web](https://rudi-cilibrasi.github.io/openverse-docs/little-verser/) · [PDF](https://rudi-cilibrasi.github.io/openverse-docs/little-verser/little-verser.pdf) · [Markdown](https://rudi-cilibrasi.github.io/openverse-docs/little-verser/little-verser.md) | `books/little-verser/` |
| **The text playground** | write Verse and inspect printed output | [open](https://rudi-cilibrasi.github.io/openverse-docs/demo/) | `demo/`, a submodule: [openverse-online-demo](https://github.com/rudi-cilibrasi/openverse-online-demo) |
| **Openfort Sim** | write Verse, change a 3D island, and explore its reactions | [play](https://rudi-cilibrasi.github.io/openverse-docs/sim/) | `sim/`, a submodule: [openfort-sim](https://github.com/rudi-cilibrasi/openfort-sim) |

The two toys use the same language concepts in different contexts: for example,
print a reward value in the text playground, or use it to award points in the
simulator. Each provides its own examples and API, with links to switch between
them. Both compile and execute locally in the browser through WebAssembly.

*Verse Logic* has one chapter per core Lean theorem of openverse
(adequacy, determinism, rollback, `<decides>` soundness, type safety, the
substitution lemma, heap effects, and `Prog.accepted`), each stated in
symbolic logic, read in Lean, proved in outline and shown at work in Verse
programs. *The Little Verser* teaches the same language as a question and
answer dialogue in the manner of *The Little Lisper*, and states openverse's
proved promises in plain English.

## Getting the sources

```sh
git clone --recurse-submodules https://github.com/rudi-cilibrasi/openverse-docs.git
```

Three submodules are pinned to exact commits:

- `openverse/`: [rudi-cilibrasi/openverse](https://github.com/rudi-cilibrasi/openverse),
  the implementation the books are checked against. Bump it with
  `git -C openverse checkout <commit> && git add openverse` once `make check` passes.
- `demo/`: [rudi-cilibrasi/openverse-online-demo](https://github.com/rudi-cilibrasi/openverse-online-demo),
  the playground. It pins its own openverse and Lean in `demo/sources.json`.
  Bump it the same way.
- `sim/`: [rudi-cilibrasi/openfort-sim](https://github.com/rudi-cilibrasi/openfort-sim),
  the 3D island simulator. It includes pinned compiler and runtime WASM assets.
  Build it with `cd sim && npm ci && npm run build`, then bump its pin the same way.

Dependabot (`.github/dependabot.yml`) opens a pull request when a
submodule's repository moves, and CI decides whether the books still hold.

## Building

Requirements: `pandoc` (3.1 or later), `xelatex` with the TeX Gyre fonts,
`tcolorbox`, `titlesec` and `lkproof` (all in TeX Live), DejaVu Sans Mono,
`python3`, and a built openverse: the submodule (`cd openverse && lake build`)
or a sibling checkout `../openverse`, or one named by `OPENVERSE`. On Ubuntu
24.04 the packages are those `.github/workflows/site.yml` installs.

```sh
make                 # check both books, then build both PDFs
make check           # run every program, compare every output and Lean claim
make pdf             # build/verse-logic/verse-logic.pdf, build/little-verser/little-verser.pdf
make verse-logic     # one book: check + pdf
make site            # check + pdf, then the whole website in build/site/
make OPENVERSE=/path/to/openverse check
```

`make site` also needs a built playground: `demo/dist/` (see `demo/README.md`;
building it takes Emscripten and several minutes), or another one named by
`DEMO_DIST`. `DEMO_DIST=none scripts/build-site.sh` builds the books' part
alone when paired with `SIM_DIST=none`. A full site also needs `sim/dist/`
(run `cd sim && npm ci && npm run build`) or another build named by `SIM_DIST`.
To look at the result, serve `build/site/` over HTTP (the playground's
service worker needs `http://localhost` or HTTPS), for example with
`python3 -m http.server -d build/site`.

The website (`scripts/build-site.sh`) has, for each book, a **web edition**
(the Markdown as one HTML page: math as MathML, made when the site is built,
with no scripts and no third-party requests), the **PDF**, and the **Markdown
edition** (the metadata and chapters as one file), beside a landing page
(`site/`) and both playgrounds. Every whole program in a web edition ends with a
*Run in the playground* link (`demo/#code=…`, made by `filters/boxes.lua`) that
opens it in the playground's editor. It fails on any pandoc warning and on any broken
link or anchor (`scripts/check-site.py`).

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

## Continuous integration and deployment

`.github/workflows/site.yml` runs on every pull request and every push to
`main`:

1. **books**: builds the pinned openverse, runs `make check` and `make pdf`,
   and builds the web and Markdown editions;
2. **demo**: builds the playground from source (the Lean compiler and the C
   runtime as WebAssembly, with cached objects) and runs its browser tests;
3. **simulator**: builds the pinned 3D simulator and runs its browser tests;
4. **site**: assembles the books, text playground, and simulator and checks every link;
5. **deploy** (pushes to `main` only): force-pushes the site, as a single
   commit, to the `gh-pages` branch, which GitHub Pages serves.
6. **accessibility**: runs axe-core (WCAG A/AA and best practices) on every
   page of the assembled site at 1360px and 390px (`scripts/check-a11y.mjs`;
   locally `npm ci && npm run check-a11y` after `make site`). It reports
   violations but does not hold back the deployment.

A pull request's assembled site is its `site` artifact. GitHub Pages must be
set, once, to serve the `gh-pages` branch (Settings → Pages → Deploy from a
branch → `gh-pages`, `/ (root)`).

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
scripts/build-site.sh        the website: web and Markdown editions, PDFs, landing page, playground
scripts/check-site.py        the website's link checker
scripts/generate.sh          run a prompt with Claude Code or Codex
filters/headings.lua         sections of an unnumbered chapter are unnumbered (PDF and web)
filters/qa.lua               ::: qa dialogues -> two columns (The Little Verser)
filters/boxes.lua            ::: theorem/definition/note/exercise/rule boxes; output panels (PDF and web)
filters/web.lua              the web edition: tex/common.tex macros and \infer in MathML, raw LaTeX
tex/                         LaTeX styling: common.tex, one file per book, code.theme
syntax/                      Verse and Lean highlighting for pandoc
site/                        the landing page, the web edition's template and style
demo/                        submodule: the playground (openverse-online-demo)
sim/                         submodule: the 3D island simulator (openfort-sim)
openverse/                   submodule: the openverse the books are checked against
.github/workflows/site.yml   CI: check, build, test; deploy to GitHub Pages
```

## More about Verse

These books describe the part of Verse that openverse implements. For the
language itself:

- [The Book of Verse](https://dev.epicgames.com/documentation/en-us/fortnite/verse-language-book-of-verse-reference), Epic Games' in-depth reference to Verse
  (also at [verselang.github.io/book](https://verselang.github.io/book/), from
  [a public repository](https://github.com/verselang/book));
- [Programming with Verse in Unreal Editor for Fortnite](https://dev.epicgames.com/documentation/en-us/fortnite/learn-programming-with-verse-in-unreal-editor-for-fortnite),
  Epic's guides and tutorials;
- [The Verse Calculus: A Core Calculus for Deterministic Functional Logic Programming](https://doi.org/10.1145/3607845),
  Augustsson, Breitner, Claessen, Jhala, Peyton Jones, Shivers, Steele and
  Sweeney, ICFP 2023;
- openverse's [docs/LANGUAGE.md](https://github.com/rudi-cilibrasi/openverse/blob/main/docs/LANGUAGE.md),
  the subset it supports.

## Thanks, and a disclaimer

Verse is [Epic Games](https://www.epicgames.com/)' language. Thank you to Epic
Games for creating it and for publishing the Book of Verse for everyone to
read, and to the authors of the Verse Calculus. openverse and these books
build on that work.

openverse is an independent project. It is not affiliated with, sponsored by
or endorsed by Epic Games, Inc. It implements a subset of Verse and may differ
from Epic's implementation: where they differ, Epic's documentation describes
the language and these books describe openverse. Verse, Epic Games, Unreal,
Unreal Engine, Unreal Editor for Fortnite and Fortnite are trademarks or
registered trademarks of Epic Games, Inc. in the United States of America and
elsewhere, used here only to name the language and its platform. The books and
the playground are provided as is, without warranty of any kind.
