# Preface {.unnumbered}

Verse is the programming language Epic Games designed for Unreal Editor for
Fortnite and Unreal Engine. It is a *functional logic* language: besides
computing values, an expression may **fail**, and a failure is caught by the
nearest *failure context*, which rolls back everything the failed attempt did.
That one idea gives conditionals, pattern matching, search and transactions a
single meaning. It also invites the mathematician's question: what exactly
does a Verse program mean, and which of the language's promises can be
proved?

This book answers that question for **openverse**, a reference implementation
of a deterministic subset of Verse whose semantics is defined in the Lean 4
proof assistant and whose central properties are Lean theorems. Each chapter
takes one of those theorems, states it in the notation of logic, proves it in
outline, reads the Lean statement line by line, and runs Verse programs that
show it at work.

## Who this book is for

The book is written for advanced undergraduates and graduate students in
mathematics, logic and computer science. You should be at ease with sets,
relations and functions; with induction on the natural numbers and on
inductively defined relations; with propositional and first-order logic; and
with inference rules of the form
$$
\infer[\rulename{Name}]{\text{conclusion}}{\text{premise}_1 & \cdots & \text{premise}_n}
$$
A first course on programming languages or type theory helps but is not
required. No knowledge of Verse, Lean or games is assumed: Chapter 1
introduces the little of each that we need.

## How the book is organized

| Chapter | Theorem | The promise |
|---|---|---|
| 1. Meaning as a Relation | `eval_iff` | the interpreter computes exactly the semantics |
| 2. One Program, One Answer | `Eval.det` | evaluation is deterministic |
| 3. Failure Is Not False | `ite_rollback` | a failed condition leaves no trace |
| 4. Who May Fail | `Eval.no_fail` | only `<decides>` code fails |
| 5. Well-Typed Programs Do Not Go Wrong | `Eval.typed` | no type errors, ever |
| 6. Checked Once, Correct Everywhere | `Typed.subst` | generic code is checked once |
| 7. Look but Do Not Touch | `Eval.no_writes` | `<reads>` code changes no object |
| 8. Everything Accepted Is Guaranteed | `Prog.accepted` | the theorems, combined, for every program the compiler accepts |

Every chapter follows the same plan: an opening problem; the theorem, first
in mathematics and then in Lean; the definitions it rests on; the proof; code;
limits; and exercises. Starred exercises (*) are harder. Appendix A collects
the notation and the grammar of Verse Core.

## What is proved, and what is trusted

openverse compiles a Verse program in two steps. A *front end* (lexer, parser
and elaborator) translates surface Verse into **Verse Core**, a small
expression language with names resolved to slot and function numbers. The
meaning of Verse Core is an inductively defined big-step relation, and every
theorem in this book is a theorem about it.

The front end itself is not verified. Instead, each program it produces is
*checked* by functions written in Lean (`Prog.check`, `Prog.checkTypes`,
`Prog.checkControl`), and each check is proved to establish the hypotheses of
the theorems. This is **translation validation**: a bug in the front end can
make it reject a good program, but it cannot make an accepted program break
a promise. Chapter 8 assembles the pieces.

What remains trusted is small and explicit: Lean's kernel; the *statement* of
the semantics, which is the definition of what Verse Core means; and the
reading that this definition captures the language described by the Book of
Verse. openverse also contains a C runtime, which is checked against the Lean
interpreter by differential testing, and whose critical components are proved
separately with the QuickProof tool; we touch on that boundary only in
Chapter 8.

## The programs in this book are tested

Every Verse program in this book was run by openverse when the book was
built, and the output printed beneath it is the output openverse produced.
Programs shown as *rejected* were rejected by the front end with the message
quoted. Every Lean theorem statement was compared, symbol for symbol, with
the statement Lean prints for it in the openverse repository, and every
excerpt of Lean source with the source itself. If the book and openverse
disagree, the book does not build.

## Acknowledgments

The language is Epic Games'. openverse is an independent implementation
written from the public *Book of Verse* and from the paper on the Verse
Calculus by Augustsson et al. (ICFP 2023). Where the Book of Verse is silent or contradicts itself,
openverse takes a reading of its own, documented in its `docs/LANGUAGE.md`;
when this book relies on one, it says so. Verse, Unreal Engine and Fortnite
are trademarks of Epic Games.
