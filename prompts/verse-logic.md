# Book: Verse Logic

*Eight Theorems about a Functional Logic Language.*

## Reader and aim

Advanced undergraduates and graduate students in mathematics, logic and
computer science. Assume comfort with sets, functions, relations, induction
(on numbers and on derivations), propositional and first-order logic,
inference rules, and a first course in programming languages or type
theory. Do not assume Verse, Lean or any knowledge of games.

The book teaches what Verse programs *mean* through what openverse *proves*
about them. Each chapter takes **one** core theorem (or one tightly knit
family) from `docs/CLAIMS.md` and makes it understood: what it says, why a
language designer wants it, how it is proved, and what it means for code
you can run. The symbolic presentation is primary: judgments, inference
rules, quantifiers and connectives, read the way a logician reads them. Lean
appears as the authoritative statement, and the student learns to read it
against the mathematics.

## Chapter plan (at most 8 chapters)

Keep this plan unless the maintainer's instruction changes it. Each chapter
is one file, `books/verse-logic/NN-slug.md`.

| # | File | Title | Core theorem(s) |
|---|---|---|---|
| — | `00-preface.md` | Preface | (how to read the book; what is proved and what is trusted) |
| 1 | `01-meaning.md` | Meaning as a Relation | `eval_iff`, with `eval_fuel_irrelevant` |
| 2 | `02-determinism.md` | One Program, One Answer | `Eval.det`, `Runs.det` |
| 3 | `03-rollback.md` | Failure Is Not False | `ite_rollback`; the derived-form laws `notE_ok`, `notE_notE_ok`, `orE_right`, `optionE_none` |
| 4 | `04-decides.md` | Who May Fail | `Eval.no_fail`, `Runs.no_fail` (`<decides>` soundness) |
| 5 | `05-types.md` | Well-Typed Programs Do Not Go Wrong | `Eval.typed`, `Runs.typed`, with `hasTy_sub` and `tc_sound` |
| 6 | `06-generics.md` | Checked Once, Correct Everywhere | `Typed.subst` (the substitution lemma) |
| 7 | `07-heap.md` | Look but Do Not Touch | `Eval.no_writes`, `Prog.accepted_no_writes` |
| 8 | `08-accepted.md` | Everything Accepted Is Guaranteed | `Prog.accepted`, with `Prog.check_ok`, `Eval.scoped_ok`, `Runs.no_control`, the arithmetic seams, and the trust boundary |
| A | `A1-notation.md` | Notation and the Grammar of Verse Core | (appendix: grammar of `Expr`, `Value`, `Res`; the judgments; a theorem index) |

## The shape of a chapter

Every numbered chapter has these parts, in this order (the headings may be
phrased to suit the chapter):

1. **An opening problem**: a short Verse program, or a question about one,
   that the theorem answers. One paragraph of motivation for programmers
   *and* one for logicians.
2. **The theorem, in mathematics**: a `::: {.theorem title="…"}` box stating
   it symbolically, with quantifiers and the evaluation judgment
   $\evalj{P}{s}{e}{r}{s'}$; then the same statement as Lean, as a
   ```` ```{.lean .claim name="…"} ```` block copied from `docs/CLAIMS.md`. Walk
   through the Lean line by line, mapping each hypothesis to the mathematics.
3. **The definitions it rests on**: the inference rules (`\infer`) or
   recursive definitions it needs, as display math, each with a short Lean
   excerpt (```` ```{.lean .excerpt file="…"} ````) where seeing the source helps.
   Introduce notation once and reuse it; the appendix collects it.
4. **The proof**: the structure of the Lean proof in mathematical prose:
   which induction, which cases matter and why, which lemmas it uses. Show
   the decisive case in full. Do not paste long tactic scripts; a few lines
   of excerpt are fine when they make a point.
5. **In code**: at least two runnable programs (```` ```{.verse .run} ```` with
   ```` ```{.output} ````) that show the theorem at work, and, where it fits,
   a program the front end rejects (```` ```{.verse .reject} ````) because the
   check behind the theorem fails. Connect each program back to the symbols.
   `openverse core FILE` shows the Verse Core of a program; quote it when the
   elaboration is the point.
6. **Limits and readings**: what the theorem does *not* say (hypotheses,
   divergence, what is tested rather than proved, readings openverse takes
   where the Book of Verse is silent: see the table in `docs/LANGUAGE.md`).
7. **Exercises**: three to six, in a `::: {.exercise title="Exercises"}` box,
   mixing proofs on paper, small Lean statements (```` ```{.lean .fragment} ````),
   and programs to predict. Mark harder ones with a star (*).

Aim for 1,800 to 4,000 words per chapter, about 6 to 10 pages.

## Mathematical conventions

- The judgment of Verse Core is $\evalj{P}{s}{e}{r}{s'}$: in program $P$, from
  state $s$, expression $e$ has outcome $r$ and leaves state $s'$. Outcomes are
  $\ok{v}$, $\fail$, $\brk$, $\ret{v}$, $\err{k}$. A state is a frame (the slots of
  the current call) and a global part (the output and the heap).
- Rule names in small caps, matching the Lean constructors:
  `Eval.ite_fail` is \rulename{Ite-Fail}, `Eval.seq_ok` is \rulename{Seq-Ok}.
- $\Runs\,P\,r\,o$ for a whole program run with outcome $r$ and output $o$.
- Typing: $S;\Gamma;\rho \vdash e : \tau$ for `Typed S Γ ρ e τ`, and
  $\Xi \models v : \tau$ for `hasTy Ξ v τ = true`.
- State the *exact* hypotheses of each theorem; when you simplify for
  exposition, say what you dropped.

## Tone

A careful, friendly textbook (Pierce's *Types and Programming Languages*
and Harper's *Practical Foundations* are the register, not the content).
Explain every symbol before it is used. Prefer one precise sentence to three
loose ones. Credit the Book of Verse and the Verse Calculus paper
(Augustsson et al., ICFP 2023) for the language; openverse's readings are its
own.
