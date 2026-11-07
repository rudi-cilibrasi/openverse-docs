# Who May Fail

## An opening problem

If any expression may fail, any function call may fail, and a programmer
would have to treat every call as a possible failure. Verse avoids this with
an *effect*: a function that may fail is marked `<decides>`, is called with
square brackets, and may be called only where failure is caught. Everything
else is guaranteed not to fail. Here is the discipline at work:

```{.verse .run}
Key(N:int)<decides>:int = N > 0

Safe(N:int):int =
    if (K := Key[N]) then K else 0

Main():void =
    Print("{Safe(5)} {Safe(-5)}")
```

```{.output}
5 0
```

`Key` fails for non-positive $N$; `Safe` calls it inside an `if` condition,
so `Safe` itself cannot fail, needs no `<decides>`, and is called with
parentheses. The front end enforces the discipline. The same call outside a
failure context is rejected:

```{.verse .reject expect="this expression can fail, but it is not in a failure context"}
First(A:[]int):int = A[0]

Main():void =
    Print("{First(array{4})}")
```

Indexing can fail (the index may be out of range), and `First` is not
`<decides>`. The programmer's question: is the check *sound*, so that a
function that passed it really never fails? The logician's: the check is a
syntactic predicate, and the property is semantic; what invariant connects
them, and why does it survive recursion? This chapter answers both.

## The analysis

The front end decides, for each expression, whether it *may fail*: whether
it contains a failable primitive, or a call to a `<decides>` function,
outside every failure context it contains. In Verse Core this is a recursive
function $\mathrm{mayFail}_P : \mathrm{Expr} \to \mathbb{B}$:

::: {.definition title="May fail"}
Write $M(e)$ for $\mathrm{mayFail}_P(e)$. Then $M(\kw{lit}\ v) = M(\kw{local}\ i) = M(\kw{brk}) = \bot$, and
$$
\begin{array}{rcl}
M(\kw{seq}\ a\ b) & = & M(a) \vee M(b) \\
M(\kw{prim}\ p\ \vec{e}) & = & \mathrm{failable}(p) \vee \textstyle\bigvee_i M(e_i) \\
M(\kw{call}\ f\ \vec{e}) & = & \mathrm{decides}(P.f) \vee \textstyle\bigvee_i M(e_i) \\
M(\kw{ite}\ c\ t\ e) & = & M(t) \vee M(e) \\
M(\kw{for}\ i\ a\ f\ b) & = & M(a) \vee M(b)
\end{array}
$$
where $a$, $f$ and $b$ are the iterated array, the filter and the body of
the `for`, and the remaining constructs (`assign`, `ret`, `print`, `loop`,
`heap`) pass their subexpressions' values up, a heap operation adding
$\mathrm{failable}(o)$, true only for a cast.
:::

The two lines that matter are the last two. The condition $c$ of an `ite`
**does not appear** on the right: it is a failure context, so its failure is
caught. Likewise the filter of a `for`, whose failure skips an element. In
Lean:

```{.lean .excerpt file="OpenVerse/Core/Effects.lean"}
  | .call f es =>
    (match P.fns[f]? with
      | some fn => fn.decides
      | none => false) || Expr.mayFailList P es
  -- the condition is a failure context: its failure is caught
  | .ite _ t e => t.mayFail P || e.mayFail P
  -- the filter is a failure context: its failure skips the element
  | .forE _ it _ body => it.mayFail P || body.mayFail P
```

The analysis of a call trusts the callee's *declaration* (`fn.decides`), not
its body. That is what makes it modular and cheap, and it is also why
soundness needs a global hypothesis: the declarations must be honest.

::: {.definition title="Effect soundness of a program"}
$$
\mathrm{EffectSound}(P) \quad :\Longleftrightarrow\quad
\forall \mathit{fn} \in P.\mathit{fns}.\ \ \neg\,\mathit{fn}.\mathit{decides}
\ \Rightarrow\ \neg\,\mathrm{mayFail}_P(\mathit{fn}.\mathit{body})
$$
Every function not declared `<decides>` has a body that may not fail.
:::

```{.lean .excerpt file="OpenVerse/Core/Effects.lean"}
def Prog.EffectSound (P : Prog) : Prop :=
  ∀ fn ∈ P.fns, fn.decides = false → fn.body.mayFail P = false
```

## The theorem

::: {.theorem title="`<decides>` soundness (`Eval.no_fail`, `Runs.no_fail`)"}
If $\mathrm{EffectSound}(P)$, then for all $s, e, r, s'$:
$$
\evalj{P}{s}{e}{r}{s'} \ \wedge\ \neg\,\mathrm{mayFail}_P(e) \ \Longrightarrow\ r \neq \fail .
$$
In particular, if $P$'s `Main` is not `<decides>`, then no run of $P$ fails:
$\Runs\ P\ r\ o \Rightarrow r \neq \fail$.
:::

```{.lean .claim name="Eval.no_fail"}
@Eval.no_fail : ∀ {P : Prog},
  P.EffectSound → ∀ {s : St} {e : Expr} {r : Res} {s' : St},
    Eval P s e r s' → Expr.mayFail P e = false → r ≠ Res.fail
```

```{.lean .claim name="Runs.no_fail"}
@Runs.no_fail : ∀ {P : Prog},
  P.EffectSound →
    ∀ {fn : Fn} {r : Res} {out : List Nat},
      P.fns[P.main]? = some fn → fn.decides = false → Runs P r out →
        r ≠ Res.fail
```

The structure of the statement is typical of *effect systems*: a syntactic
judgment ($\neg\mathrm{mayFail}$) implies a semantic property (no failure
outcome), under an invariant of the whole program (`EffectSound`). Note what
is *not* claimed: the expression may still raise a runtime error, `break`,
`return`, or diverge. Only failure is excluded. `P.fns[P.main]? = some fn`
says that `fn` is `Main`'s definition (`?` is safe indexing into the list of
functions, returning an `Option`).

## The proof

By induction on the derivation of $\evalj{P}{s}{e}{r}{s'}$, mutually with
the corresponding statements for `EvalList` and `EvalFor`. Assume
$\mathrm{EffectSound}(P)$ throughout. Most cases are immediate: a stop rule
propagates the outcome of a subexpression that, by the definition of
$\mathrm{mayFail}$, may not fail either, so the induction hypothesis
applies. Four cases carry the idea.

**Primitives.** A successful argument list leads to $p.\mathrm{apply}\
\vec{v}$, and a lemma, `Prim.apply_ne_fail`, says that a primitive that is
not failable never returns $\fail$. The failable ones are the comparisons,
indexing and indexed update, the division family, `?`, and `false?`.

**`ite`.** If the derivation ends in \rulename{Ite-Ok} or
\rulename{Ite-Fail}, the outcome is the outcome of $t$ or of $e$, and both
may not fail by hypothesis, so the induction hypothesis on that branch
concludes. The condition's failure, the one thing that $\mathrm{mayFail}$
ignored, is exactly what \rulename{Ite-Fail} consumes. If it ends in
\rulename{Ite-Stop}, the outcome is the condition's, and the side condition
of the rule says it is not $\fail$. Notice that this case uses no induction
hypothesis about the condition at all: soundness here is a property of the
*rules*, which do not let a failed condition escape.

**`for`.** The filter's failure is consumed by `EvalFor.skip`; the body's
failure would be propagated, but the body may not fail.

**Calls.** This is the case that seems to need more than induction. The
derivation ends in

$$
\infer[\rulename{Call-Ok}]{\evalj{P}{s}{\kw{call}\ f\ \vec{e}}{\mathrm{retOf}(r)}{\langle s_1.\mathit{fr}, s_2.g\rangle}}
      {\vec{e}\ \Downarrow\ \vec{v} & P.\mathrm{callable}\ f\ |\vec{v}| = \mathsf{some}\ \mathit{fn} &
       \evalj{P}{\langle \mathrm{frameOf}\ \mathit{fn}\ \vec{v}, s_1.g\rangle}{\mathit{fn}.\mathit{body}}{r}{s_2}}
$$

Since $\neg\mathrm{mayFail}(\kw{call}\ f\ \vec{e})$, the callee is not
`<decides>`. By $\mathrm{EffectSound}(P)$ its body may not fail. The
derivation of the body is a *premise* of this rule, hence a subderivation,
and the induction hypothesis applies to it: $r \neq \fail$. Finally
$\mathrm{retOf}$, which turns $\ret{v}$ into $\ok{v}$, maps non-failures to
non-failures (`retOf_ne_fail`).

The call case is where the global invariant earns its keep. A recursive
function's body contains calls to the function itself, so an induction on
the *syntax* of expressions would go round in circles. Induction on the
*derivation* does not: each call's body has its own, strictly smaller,
derivation. The price is the one we met in Chapter 1: the theorem speaks
only of evaluations that finish.

`Runs.no_fail` is the instance $e = \kw{call}\ \mathit{main}\ []$, with no
arguments to fail and $\mathrm{mayFail}$ reduced to $\mathit{main}$'s
`decides` flag.

Where does $\mathrm{EffectSound}(P)$ come from for a real program? The front
end does not prove it; Lean checks it. The Boolean function
`Prog.checkEffectSound` tests every function, and a two-line lemma shows
that it returning `true` implies the proposition:

```{.lean .excerpt file="OpenVerse/Core/Check.lean"}
def Prog.checkEffectSound (P : Prog) : Bool :=
  P.fns.all fun fn => fn.decides || !(fn.body.mayFail P)
```

Every program the front end emits passes this check (Chapter 8), so the
theorem applies to every accepted program.

## In code

A `<decides>` function propagates failure to its caller; a context catches
it. Here `Pick` fails out of range, and the `for` clause skips those
indices:

```{.verse .run}
Pick(A:[]int, I:int)<decides>:int = A[I]

Main():void =
    Scores := array{10, 20, 30}
    for (I := 0..5, S := Pick[Scores, I]):
        Print("score {I}: {S}")
```

```{.output}
score 0: 10
score 1: 20
score 2: 30
```

The two syntaxes of calls are part of the discipline. A `<decides>` function
called with parentheses is rejected, because the reader of the call could
not see that it may fail:

```{.verse .reject expect="Key is <decides>: call it with Key[…]"}
Key(N:int)<decides>:int = N > 0

Main():void =
    Print("{Key(3)}")
```

A `<decides>` `Main` may fail. Its failure is not caught by anything, so it
ends the program with exit code 1. The output printed before the failure
stays: it was not inside a failure context.

```{.verse .run exit="1"}
Key(N:int)<decides>:int = N > 0

Main()<decides>:void =
    Print("looking for the key")
    K := Key[-1]
    Print("found {K}")
```

```{.output}
looking for the key
```

The analysis is *conservative*. It is syntactic, so it rejects some programs
that could never fail. Index `0` of a three-element array literal always
exists, but indexing is failable, and the program is rejected anyway:

```{.verse .reject expect="this expression can fail, but it is not in a failure context"}
Main():void =
    X := array{1, 2, 3}[0]
    Print("{X}")
```

This is the usual trade of a static analysis: soundness and
predictability in exchange for completeness. A theorem cannot rescue
completeness here; deciding exactly which expressions can fail is as hard
as deciding termination.

## Limits and readings

- **Only failure is excluded.** A function without `<decides>` may still
  overflow, call `Err()`, or run forever. Runtime errors are discussed in
  Chapter 8.
- **Soundness is relative to the declarations.** `Eval.no_fail` assumes
  `EffectSound`, which is checked, not assumed, for programs from the front
  end. A Verse Core program built by hand could lie about a function, and
  then the theorem would not apply to it.
- **Failable primitives are fixed by the semantics** (`Prim.failable`):
  the comparisons, indexing and indexed update, the division family
  (`Floor`, `Ceil`, `Quotient`, `Mod`, which fail when the divisor is zero),
  `?`, and the always-failing `false?`; among heap operations, only casts.
  Array methods such as `Find` and `Slice` are elaborated into code built
  from these. That division by zero fails, rather than raising an error,
  follows the Book of Verse.

::: {.exercise title="Exercises"}
1. Compute $\mathrm{mayFail}$ for the Verse Core of `Safe` in the opening
   program. (Use `openverse core` to see it.) Which subterms are ignored?
2. The analysis ignores the condition of `ite`. Show that it would be
   *unsound* to ignore the `then` branch instead: give an expression $e$
   that may fail by the real definition, for which the modified analysis
   says it may not, and a derivation of $\fail$ for it.
3. Why does the call case of the proof not need `<decides>` callees to be
   handled at all? Write the case for a call to a `<decides>` function.
4. Prove that `Prog.checkEffectSound P = true` implies `P.EffectSound`, using
   the Lean lemma `List.all_eq_true`.
5. (*) Design an analysis $\mathrm{mustFail}_P(e)$ that is sound for the
   converse property: if $\mathrm{mustFail}(e)$ then every finished evaluation
   of $e$ fails. What is $\mathrm{mustFail}(\kw{ite}\ c\ t\ e)$?
6. (*) The theorem is proved by induction on derivations and so says nothing
   about diverging runs. Can a diverging run "fail"? Explain why the question
   does not arise in this semantics.
:::
