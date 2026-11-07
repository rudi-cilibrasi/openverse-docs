```{=latex}
\appendix
```

# Notation and the Grammar of Verse Core

This appendix collects the notation of the book. The authoritative
definitions are the Lean files named in each section, in the openverse
repository under `OpenVerse/Core/`.

## Values, outcomes, states (`Value.lean`, `Semantics.lean`)

Values $v$, outcomes $r$, error kinds $k$ and states $s$ (a frame, an
output and a heap):
$$
\begin{array}{rcl}
v & ::= & \kw{int}\ n \mid \kw{logic}\ b \mid \kw{char}\ c \mid \kw{arr}\ [\vec v] \mid \kw{tup}\ [\vec v]
          \mid \kw{none} \mid \kw{some}\ v \mid \kw{ref}\ a \\
r & ::= & \ok{v} \mid \fail \mid \brk \mid \ret{v} \mid \err{k} \\
k & ::= & \mathit{overflow} \mid \mathit{type} \mid \mathit{slot} \mid \mathit{call} \mid \mathit{control} \mid \mathit{user} \\
s & ::= & \langle \mathit{fr}, \langle o, h \rangle \rangle
\end{array}
$$

Integers satisfy $-2^{63} \leq n < 2^{63}$ (an invariant that `Res.ofInt`
maintains, not one the Lean type enforces); `void` is $\kw{tup}\ []$; a
`string` is an array of `char`s, each a UTF-8 code unit (below 256 in a
typed program: `hasTy` requires it); `false` as an empty option is
$\kw{none}$. A heap is an array of objects, each a class tag and a
list of field values.

## Expressions (`Syntax.lean`)

$$
\begin{array}{rcl}
e & ::= & \kw{lit}\ v \mid \kw{local}\ i \mid \kw{assign}\ i\ e \mid \kw{seq}\ e_1\ e_2
          \mid \kw{prim}\ p\ \vec{e} \mid \kw{call}\ f\ \vec{e} \\
  &  \mid & \kw{ite}\ c\ t\ e \mid \kw{for}\ i\ e_{\mathit{it}}\ e_{\mathit{filt}}\ e_{\mathit{body}}
          \mid \kw{loop}\ e \mid \kw{brk} \mid \kw{ret}\ e \mid \kw{print}\ e \mid \kw{heap}\ o\ \vec{e} \\
o & ::= & \mathit{new}\ t \mid \mathit{get}\ k \mid \mathit{set}\ k \mid \mathit{tag} \mid \mathit{isTag}\ \vec{t}
\end{array}
$$

Primitives $p$: arithmetic (`add`, `sub`, `mul`, `neg`, `abs`), the division
family (`floorDiv`, `ceilDiv`, `quotient`, `modulo`), comparisons (`lt`, `le`,
`gt`, `ge`, `eq`, `ne`), `query` ($X?$), construction (`mkArr`, `mkTup`,
`mkSome`), arrays (`concat`, `index`, `len`, `arrSet`, `flatten`, `range`),
`tupGet`, `toStr`, `fail`, `userErr`. A function has a name, an arity, a
number of slots, a `decides` flag, a `writes` flag and a body; a program is a
list of functions and the index of `Main`.

**Derived forms** (`Derived.lean`, Chapter 3):
$\kw{not}\ e$, $a\ \kw{or}_t\ b$, $a\ \kw{and}\ b$, $\kw{option}_t\{e\}$,
$\kw{logic}\{e\}$, all defined with $\kw{ite}$ and $\kw{seq}$.

## Judgments

| Notation | Lean | Meaning |
|---|---|---|
| $\evalj{P}{s}{e}{r}{s'}$ | `Eval P s e r s'` | evaluation (Chapter 1) |
| $\mathrm{eval}\ P\ n\ s\ e$ | `eval P n s e` | interpreter with fuel $n$ |
| $\Runs\ P\ r\ o$ | `Runs P r o` | a whole run: outcome, output |
| $S;\Gamma;\rho \vdash e : \tau$ | `Typed S Γ ρ e τ` | typing (Chapter 5) |
| $\Xi \models v : \tau$ | `hasTy Ξ v τ = true` | value typing |
| $\tau \leq \tau'$ | `τ.sub τ' = true` | subtyping |
| $\theta\tau$ | `τ.subst θ` | substitution (Chapter 6) |
| $\mathrm{mayFail}_P(e)$ | `e.mayFail P` | may fail (Chapter 4) |
| $\mathrm{writesHeap}_P(e)$ | `e.writesHeap P` | may write a field (Chapter 7) |
| $g \preceq g'$ | `g.keeps g'` | keeps every object (Chapter 7) |
| $\Xi \sqsubseteq \Xi'$ | `Ξ <+: Ξ'` | prefix of a heap typing |

Rule names in small caps correspond to Lean constructors:
\rulename{Ite-Fail} is `Eval.ite_fail`, \rulename{T-Call} is `Typed.call`.

## Index of theorems

| Theorem | File | Chapter |
|---|---|---|
| `eval_iff`, `eval_fuel_irrelevant` | `Adequacy.lean` | 1 |
| `Eval.det`, `Runs.det` | `Adequacy.lean` | 2 |
| `ite_rollback`, `notE_ok`, `notE_notE_ok`, `orE_right`, `optionE_none` | `Derived.lean` | 3 |
| `Eval.no_fail`, `Runs.no_fail` | `Effects.lean` | 4 |
| `Eval.typed`, `Runs.typed`, `hasTy_sub`, `tc_sound` | `TypeSafety.lean`, `TypeCheck.lean` | 5 |
| `Typed.subst` | `TypeSafety.lean` | 6 |
| `Eval.no_writes`, `Prog.accepted_no_writes` | `Writes.lean`, `Guarantees.lean` | 7 |
| `Prog.accepted`, `Eval.scoped_ok`, `Runs.no_control`, `apply_*` | `Guarantees.lean`, `Scoping.lean`, `Control.lean`, `Seams.lean` | 8 |

The full statements, as Lean prints them, with the axioms each proof uses,
are in openverse's `docs/CLAIMS.md`, which is generated from the sources and
checked by openverse's continuous integration. This book's build compares
each statement it quotes against that file.
