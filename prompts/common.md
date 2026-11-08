# openverse-docs: writing the openverse books

You are writing a book in the `openverse-docs` repository, the documentation set of
**openverse**: a clean-room reference implementation of a deterministic subset
of Verse (Epic Games' functional logic language), with its semantics defined
and proved in Lean 4 and a C runtime checked against it. The repository builds
each book into a PDF with pandoc and xelatex.

There are two books, and they share this prompt:

- **Verse Logic** (`books/verse-logic/`): a text for college and graduate
  students in mathematics, logic and computer science. Each chapter is built
  around one core Lean theorem of openverse.
- **The Little Verser** (`books/little-verser/`): a beginner's dialogue in
  the style of *The Little Lisper*. It shows no Lean at all.

The book-specific prompt follows this one.

## Sources of truth

Read these before you write. Do not write from memory: every claim about
Verse or openverse has to be checkable against them.

- `$OPENVERSE/README.md`: what is proved, what is trusted, and how.
- `$OPENVERSE/docs/LANGUAGE.md`: the supported subset of Verse, and the reading
  openverse takes wherever the Book of Verse is silent or contradicts itself.
- `$OPENVERSE/docs/CLAIMS.md`: the headline theorems, each statement printed by
  Lean itself, with its axioms. This is the source for theorem statements.
- `$OPENVERSE/docs/DESIGN.md`, `docs/FORMAT.md` (exit codes), `docs/SEAMS.md`.
- `$OPENVERSE/OpenVerse/Core/*.lean`: the definitions and proofs
  (`Syntax.lean`, `Value.lean`, `Semantics.lean`, `Interp.lean`,
  `Adequacy.lean`, `Derived.lean`, `Effects.lean`, `Scoping.lean`,
  `Typing.lean`, `TypeSafety.lean`, `TypeCheck.lean`, `Control.lean`,
  `Writes.lean`, `Check.lean`, `Guarantees.lean`, `Seams.lean`).
- `$OPENVERSE/tests/verse/*.verse` with `.expected` outputs, and
  `$OPENVERSE/tests/errors/*.verse` (first line `# expect: <message>`): idiomatic,
  tested programs. Borrow from them freely.
- The binary `$OPENVERSE/.lake/build/bin/openverse`: `run FILE`, `check FILE`, and
  `core FILE` (prints the elaborated Verse Core). Try every program you write.

`$OPENVERSE` is the openverse checkout named in "This run" below (by default
`../openverse`). Treat it as read-only: never edit, build or commit there.

Write only from the sources above: openverse's own documents are enough.

One source you must **not** copy from: *The Little Lisper* and *The Little
Schemer* are copyrighted. Imitate the format (short questions, short answers,
rules that sum up a chapter), never their text, examples, jokes or the names
of their rules.

## The language, briefly

Things that surprise newcomers and that both books must get right:

- **Failure is not an error and not `false`.** An expression *succeeds* with a
  value or *fails*. Comparisons fail when false (`X > 0` fails, or succeeds
  with `X`, its left operand). Indexing `A[I]` fails out of range; `Floor(X / Y)`,
  `Quotient[X, Y]` and `Mod[X, Y]` fail when `Y = 0`; `X?` fails on `false`
  (`logic`) or an empty option.
- **Failure contexts** catch failure: `if` conditions, `for` clauses,
  `option{…}`, `logic{…}`, `not`, the left side of `or`, and the body of a
  `<decides>` function. A failable expression anywhere else is rejected at
  compile time ("this expression can fail, but it is not in a failure
  context").
- **Rollback.** When a failure context fails, every effect it had is undone:
  `set` of `var` variables, writes to `var` fields of objects, objects it
  constructed, **and output** printed by `Print` (openverse's transactional
  reading). `not e` always discards `e`'s effects.
- `<decides>` functions can fail and are called with brackets, `F[X]`; other
  functions are called with parentheses, `F(X)`, and never fail.
- openverse is **deterministic**: no `choice` (`|`); its concurrency
  (`<suspends>`, `Sleep`, `sync`, `race`, `spawn`) takes turns in a fixed
  order on a virtual clock of ticks, so it is deterministic too. `int` is
  64-bit; overflow is a runtime error (exit 2), not a failure. `Err()` is a
  runtime error too. A `<decides>` `Main` that fails exits with code 1.
- No shadowing: a name cannot be defined twice in one function, even in
  different blocks.
- Strings use `{expr}` interpolation, so a literal `{` or `}` in a string
  needs care; avoid braces in strings.

## Markdown conventions (the checker and the PDF build depend on them)

Each book is a directory of Markdown files, assembled in file-name order:
`00-preface.md`, `01-<slug>.md` … `08-<slug>.md` (at most **8** numbered
chapters), then optional appendices `A1-<slug>.md`, `A2-…`. Each file starts
with one level-1 heading (`# Title`); the preface heading has
`{.unnumbered}`. The first appendix file starts with a raw LaTeX block
`` ```{=latex} `` containing `\appendix`.

Code blocks are **checked** by `scripts/check-books.py`, so mark each one:

| Block | Meaning |
|---|---|
| ```` ```{.verse .run} ```` | a whole program, run by `openverse run`; the next ```` ```{.output} ```` block must equal its standard output exactly (an empty output block means "prints nothing"). Add `exit="N"` for a non-zero exit code (1: a `<decides>` `Main` failed; 2: runtime error; 3: resource limit), and `fuel="N"` to run with `--fuel N` (for a program that does not terminate). |
| ```` ```{.verse .check} ```` | a whole program that must compile (it is not run). |
| ```` ```{.verse .reject expect="…"} ```` | a whole program that must be rejected (exit 4) with a message containing the `expect` text. The PDF prints the expected text under the program. |
| ```` ```{.verse .fragment} ```` | part of a program, not checked. Use sparingly: prefer whole programs. |
| ```` ```{.lean .claim name="Eval.det"} ```` | (Verse Logic only) a theorem statement, which must equal, up to white space, its statement in `docs/CLAIMS.md`. Copy it from there. |
| ```` ```{.lean .excerpt file="OpenVerse/Core/Semantics.lean"} ```` | (Verse Logic only) lines copied from that file. Lines that are just `...` (or `…`) mark omissions; each run of lines between them must occur in the file, in order. |
| ```` ```{.lean .fragment} ```` | (Verse Logic only) Lean written for the book, such as an exercise statement. |

The standard output of a program (stdout) is only what it prints; failure and
error messages go to stderr and do not belong in the output block.

Boxes are fenced divs with a title: `::: {.theorem title="…"}`,
`::: {.definition title="…"}`, `::: {.note title="…"}`,
`::: {.exercise title="…"}`, `::: {.rule title="…"}`. Titles may contain
inline Markdown (`` `code` ``, `*emphasis*`).

Mathematics is LaTeX between `$…$` or `$$…$$`, typeset with unicode-math
(TeX Gyre fonts). These macros are defined in `tex/common.tex`:

- `\evalj{P}{s}{e}{r}{s'}` gives $P \vdash \langle s, e\rangle \Downarrow \langle r, s'\rangle$,
  and `\evalshort{s}{e}{r}{s'}` the same without $P \vdash$;
- outcomes `\ok{v}`, `\fail`, `\brk`, `\ret{v}`, `\err{k}`; syntax `\kw{ite}`;
- `\infer[\rulename{Ite-Fail}]{conclusion}{premise_1 & premise_2}` (proof.sty)
  for inference rules; `\Runs`, `\Typed`, `\hasTy`, `\lean{Name}`.

Keep code lines short: at most 78 characters in Verse Logic; in The Little
Verser at most 46 in a question, 28 in an answer and 64 elsewhere. The
checker enforces these limits.

## Verification (required)

1. Run `make check` (or `python3 scripts/check-books.py <book>`) after each
   chapter. It runs every program, compares every output block, checks every
   rejection message, compares every Lean claim and excerpt with openverse,
   counts chapters and enforces the book rules. Fix every problem it reports;
   never weaken the checker or mark a block `.fragment` to silence it.
2. Run `scripts/build.sh <book>`: it must produce `build/<book>/<book>.pdf`
   without LaTeX errors and without missing glyphs.
3. Read your chapter again as its reader would, in the PDF text
   (`pdftotext build/<book>/<book>.pdf - | less`), and fix what reads badly.

## House style

- American English, plain words, short sentences. Explain why before how.
- Never claim more than openverse proves. Say "openverse proves" for Lean
  theorems, "is checked by testing" for the C interpreter, and be precise
  about hypotheses (a theorem about Verse Core applies to surface Verse
  through the front end's checks: `Prog.accepted`).
- Keep the two books consistent with each other and with `docs/LANGUAGE.md`:
  the same names for things (failure context, rollback, `<decides>`, Verse Core).
- Do not edit `scripts/`, `filters/`, `tex/` or the Makefile unless the
  maintainer's instruction asks for it; if the build needs a fix there, make
  the smallest one and say so in your report.
- Do not commit; the maintainer reviews and commits.
