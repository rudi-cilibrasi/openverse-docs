# Failure Is Not False

## An opening problem

In most languages a condition is a Boolean expression: it evaluates to
`true` or `false`, and evaluating it may have side effects that persist
whichever way it goes. In Verse a condition is an expression that either
*succeeds* or *fails*, and when it fails, its side effects disappear:

```{.verse .run}
Main():void =
    var X:int = 1
    if (set X = 2, X = 2, set X = 3, X = 4):
        Print("never")
    Print("X = {X}")
    if (set X = 2, X = 2, set X = 3):
        Print("committed: X = {X}")
```

```{.output}
X = 1
committed: X = 3
```

The first condition makes two assignments and passes one test before the
last test fails, and then it is as if none of it had happened. The second
succeeds, and its assignments stay. A condition is a *transaction*: it
commits on success and aborts on failure.

For a programmer this is the feature that makes Verse conditions safe to
write as searches ("find a key, take it, open the chest") without cleanup
code for the paths that do not work out. For a logician it raises a
question about connectives. If failure plays the role of falsity, what are
`not`, `or` and `and`, and how do they interact with effects? This chapter
proves the rollback law for `if`, then derives the others from it.

## The theorem

::: {.theorem title="Rollback (`ite_rollback`)"}
If the condition $c$ fails from state $s$, then for every outcome $r$ and state $s'$
$$
\evalj{P}{s}{c}{\fail}{s_1}
\ \Longrightarrow\
\Big(\evalj{P}{s}{\kw{ite}\ c\ t\ e}{r}{s'} \iff \evalj{P}{s}{e}{r}{s'}\Big).
$$
:::

Once the condition has failed, the whole `if` is *indistinguishable* from its
`else` branch run from the original state: the same outcomes, the same final
states. Nothing that $c$ did, and nothing in $s_1$, can be observed.

```{.lean .claim name="ite_rollback"}
@ite_rollback : ∀ {P : Prog} {s s₁ : St} {c t e : Expr} {r : Res} {s' : St},
  Eval P s c Res.fail s₁ → (Eval P s (c.ite t e) r s' ↔ Eval P s e r s')
```

`c.ite t e` is Lean's dot notation for `Expr.ite c t e`. The hypothesis
names the failed run of the condition, and the conclusion is a biconditional
for *all* $r$ and $s'$: an equivalence of the two expressions, from $s$.

## The derived forms

Verse Core has one failure context, `ite` (with the filter of `for`). The
book's other failure contexts are *defined* from it, in
`OpenVerse/Core/Derived.lean`:

::: {.definition title="Derived forms"}
$$
\begin{array}{rcl}
\kw{not}\ e & := & \kw{ite}\ e\ (\kw{prim}\ \mathit{fail}\ [])\ (\kw{lit}\ \mathit{void}) \\
a\ \kw{or}_t\ b & := & \kw{ite}\ (\kw{assign}\ t\ a)\ (\kw{local}\ t)\ b \\
\kw{option}_t\{e\} & := & \kw{ite}\ (\kw{assign}\ t\ e)\ (\kw{prim}\ \mathit{mkSome}\ [\kw{local}\ t])\ (\kw{lit}\ \mathit{none}) \\
\kw{logic}\{e\} & := & \kw{ite}\ e\ (\kw{lit}\ \mathit{true})\ (\kw{lit}\ \mathit{false}) \\
a\ \kw{and}\ b & := & \kw{seq}\ a\ b
\end{array}
$$
Here $t$ is a fresh slot chosen by the elaborator, to carry the value of $a$
(or $e$) from the condition into the `then` branch.
:::

```{.lean .excerpt file="OpenVerse/Core/Derived.lean"}
def Expr.notE (e : Expr) : Expr := .ite e (.prim .fail []) (.lit .void)
/-- `a or b`; slot `t` is a fresh temporary of the elaborator. -/
def Expr.orE (t : Nat) (a b : Expr) : Expr := .ite (.assign t a) (.local t) b
```

Read the definitions as logic. `not e` succeeds (with `void`) exactly when
$e$ fails: it is *negation as failure*, Prolog's `\+`. `a or b` tries $a$,
and only if $a$ fails tries $b$: a left-biased disjunction. `a and b` is
sequencing: it fails if either fails, and its value is $b$'s. `option{e}`
reifies success or failure as a value of type `?t`, and `logic{e}` as a
`logic`. The laws below say that each behaves as the Book of Verse
describes, *including* what happens to effects.

::: {.theorem title="Laws of the derived forms"}
For all $P$, $s$, $e$, $a$, $b$, $t$:

1. (`notE_ok`) If $\evalj{P}{s}{\kw{not}\ e}{\ok{v}}{s'}$, then $v = \mathit{void}$,
   $s' = s$, and $\exists s_1.\ \evalj{P}{s}{e}{\fail}{s_1}$.
2. (`notE_notE_ok`) If $\evalj{P}{s}{\kw{not}\ (\kw{not}\ e)}{\ok{v}}{s'}$, then
   $s' = s$ and $\exists u\, s_1.\ \evalj{P}{s}{e}{\ok{u}}{s_1}$.
3. (`orE_right`) If $\evalj{P}{s}{a}{\fail}{s_1}$, then for all $r, s'$:
   $\evalj{P}{s}{a\ \kw{or}_t\ b}{r}{s'} \iff \evalj{P}{s}{b}{r}{s'}$.
4. (`optionE_none`) If $\evalj{P}{s}{\kw{option}_t\{e\}}{\ok{\mathit{none}}}{s'}$,
   then $s' = s$.
:::

```{.lean .claim name="notE_ok"}
@notE_ok : ∀ {P : Prog} {s : St} {e : Expr} {v : Value} {s' : St},
  Eval P s e.notE (Res.ok v) s' →
    v = Value.void ∧ s' = s ∧ ∃ s₁, Eval P s e Res.fail s₁
```

```{.lean .claim name="notE_notE_ok"}
@notE_notE_ok : ∀ {P : Prog} {s : St} {e : Expr} {v : Value} {s' : St},
  Eval P s e.notE.notE (Res.ok v) s' →
    s' = s ∧ ∃ u s₁, Eval P s e (Res.ok u) s₁
```

```{.lean .claim name="orE_right"}
@orE_right : ∀ {P : Prog} {s s₁ : St} {t : Nat} {a b : Expr} {r : Res}
    {s' : St},
  Eval P s a Res.fail s₁ → (Eval P s (Expr.orE t a b) r s' ↔ Eval P s b r s')
```

```{.lean .claim name="optionE_none"}
@optionE_none : ∀ {P : Prog} {s : St} {t : Nat} {e : Expr} {s' : St},
  Eval P s (Expr.optionE t e) (Res.ok Value.none) s' → s' = s
```

Law 2 is the surprising one, and it deserves a logician's reading. In
classical logic $\neg\neg A \leftrightarrow A$. Here `not not e` succeeds
exactly when `e` succeeds, but it is *not* `e`: it returns `void` instead of
$e$'s value, and it leaves the state exactly as it found it, discarding every
effect of $e$ (and, at the surface, every name $e$ binds). It is a pure *test*
of whether $e$ would succeed. The analogy with intuitionistic logic is apt:
there, $\neg\neg A$ asserts that $A$ cannot be refuted without supplying a
witness for $A$; here, `not not e` asserts that $e$ succeeds without
supplying its value or keeping its effects.

## The proof

**Rollback.** The direction $\Leftarrow$ is the rule \rulename{Ite-Fail}
itself, applied to the hypothesis $\evalj{P}{s}{c}{\fail}{s_1}$ and the
given derivation for $e$. For $\Rightarrow$, invert the derivation of the
`ite`: its last rule is one of the three.

- \rulename{Ite-Ok} would need $\evalj{P}{s}{c}{\ok{v}}{s''}$ for some
  $v, s''$. With the hypothesis, `Eval.det` gives $\ok{v} = \fail$, which is
  false.
- \rulename{Ite-Stop} would need $\evalj{P}{s}{c}{r''}{s''}$ with
  $r'' \neq \fail$; determinism gives $r'' = \fail$, a contradiction.
- \rulename{Ite-Fail} has the premise $\evalj{P}{s}{e}{r}{s'}$, which is what
  we want.

```{.lean .excerpt file="OpenVerse/Core/Derived.lean"}
theorem ite_rollback {P s s₁ c t e r s'} (hc : Eval P s c .fail s₁) :
    Eval P s (.ite c t e) r s' ↔ Eval P s e r s' := by
  constructor
  · intro h
    cases h with
    | ite_ok h1 _ => exact absurd (Eval.det h1 hc).1 (by simp)
    | ite_fail _ h2 => exact h2
    | ite_stop h1 _ hf => exact absurd (Eval.det h1 hc).1 hf
  · intro h; exact .ite_fail hc h
```

Notice the dependency: rollback, a statement about *one* branch, needs
determinism, a statement about *all* derivations. Without Chapter 2, the
`if` could have a second derivation in which the same condition succeeds,
and the equivalence would fail. The tactic `cases h with` is exactly the
inversion above, one line per rule; `absurd` closes a case from a
contradiction.

**`not`.** Unfold $\kw{not}\ e$ to $\kw{ite}\ e\ (\kw{prim}\ \mathit{fail}\
[])\ (\kw{lit}\ \mathit{void})$ and invert a successful derivation. If the
last rule is \rulename{Ite-Ok}, the `then` branch $\kw{prim}\ \mathit{fail}\
[]$ must have succeeded, but it always fails. If it is \rulename{Ite-Stop},
the outcome is not $\ok{\_}$, contradicting the hypothesis. So it is
\rulename{Ite-Fail}: $e$ failed from $s$, and the `else` branch, the literal
`void`, succeeded *from $s$* without changing it (rule \rulename{Lit}). Hence
$v = \mathit{void}$ and $s' = s$.

**`not not`.** Apply the law for `not` to the outer negation: $s' = s$, and
the inner $\kw{not}\ e$ *failed* from $s$. Invert that failure: it cannot
come from \rulename{Ite-Fail}, whose `else` branch succeeds; nor from
\rulename{Ite-Stop}, whose outcome is not $\fail$; so it is
\rulename{Ite-Ok}, whose first premise is a success of $e$ from $s$.

**`or`** is rollback again: $a\ \kw{or}_t\ b$ is an `ite` whose condition
$\kw{assign}\ t\ a$ fails when $a$ does (by \rulename{Assign-Stop}), so
`ite_rollback` applies. **`option{}`** is like `not`: an empty result can
only come from the `else` branch, a literal, evaluated from $s$.

These are the laws a programmer relies on without thinking: an `or`
fallback never sees a half-finished left side; `option{…}` of a failure has
no effect; `not` never leaks.

## In code

The double negation is a test that leaves no trace, and a single negation
is too:

```{.verse .run}
IsPositive(X:int)<decides>:int = X > 0

Main():void =
    var Count:int = 0
    if (not not (set Count = 99; IsPositive[1])):
        Print("the test passed; Count = {Count}")
    if (not (set Count = 7; IsPositive[-1])):
        Print("the negation passed; Count = {Count}")
```

```{.output}
the test passed; Count = 0
the negation passed; Count = 0
```

In the first `if`, `e` succeeded, assigning $99$; the outer `not` discarded
that. In the second, `e` failed, so its assignment was rolled back by the
inner `ite`. (Inside parentheses, `;` sequences expressions; a comma would
build a tuple.) `openverse core` confirms the elaboration: the first
condition is $\kw{ite}\ (\kw{ite}\ e\ \mathit{fail}\ \mathit{void})\
\mathit{fail}\ \mathit{void}$, which is `Expr.notE (Expr.notE e)`.

`or`, `option{}` and the rollback of their left sides:

```{.verse .run}
Halve(N:int)<decides>:int =
    Mod[N, 2] = 0
    Quotient[N, 2]

Main():void =
    var Log:int = 0
    A := (set Log += 1; Halve[7]) or 100
    Print("A = {A}, Log = {Log}")
    B:?int = option{set Log += 10; Halve[8]}
    if (V := B?) { Print("B holds {V}, Log = {Log}") }
    C:?int = option{set Log += 100; Halve[9]}
    if (not C?) { Print("C is empty, Log = {Log}") }
```

```{.output}
A = 100, Log = 0
B holds 4, Log = 10
C is empty, Log = 10
```

`Halve` is a `<decides>` function: its first line *fails* unless $N$ is
even. `A` takes the fallback $100$ and the increment is undone (law 3).
`B` succeeds and keeps its effect. `C` is empty and has none (law 4).

Because a condition that cannot fail would make the `else` branch dead
code, and is usually a mistake (a Boolean where a test was meant), the
front end rejects it:

```{.verse .reject expect="the condition of this if cannot fail"}
Main():void =
    if (1 + 1) { Print("two") }
```

Rollback catches *failure* only. A runtime error, such as overflow, is not a
failure and is not caught by the `if`; it ends the program, with exit code 2.
That is rule \rulename{Ite-Stop}, which propagates every outcome of the
condition other than success and failure:

```{.verse .run exit="2"}
Main():void =
    Print("before")
    var Big:int = 9223372036854775807
    if (set Big += 1, Big < 0):
        Print("wrapped around")
    else:
        Print("rolled back")
```

```{.output}
before
```

The `int` of openverse is 64-bit, and an overflow is an error, never a
wrap-around (the BPVM reading; see `docs/LANGUAGE.md`).

## Limits and readings

- **Effects inside the condition of a successful `if` are kept**, and so are
  the bindings, which the `then` branch can see. Rollback is about failure
  only.
- **Output is rolled back** because openverse makes `Print` transactional:
  the output is part of the state. The Book of Verse does not say what
  happens to output in a failed context; this is openverse's reading. The
  heap is rolled back too: object writes and allocations (Chapter 7).
- **`return` inside a failure context** leaves the function without rolling
  back what the condition did (another openverse reading): a $\ret{v}$
  outcome is propagated by \rulename{Ite-Stop}, not caught.
- **The laws are about Verse Core.** The front end elaborates surface `not`,
  `or` and `option{}` into exactly these definitions, which `openverse core`
  lets you check on any program; the scoping rule that names defined in
  the operands of `and`, `or` and `not` do not escape is enforced by the
  front end.

::: {.exercise title="Exercises"}
1. Prove `logicE_ne_fail`: $\kw{logic}\{e\}$ never fails. Which rules can end
   a derivation of $\evalj{P}{s}{\kw{logic}\{e\}}{\fail}{s'}$?
2. Is $\kw{not}\ (\kw{not}\ (\kw{not}\ e))$ equivalent to $\kw{not}\ e$, in the
   sense of `ite_rollback` (same outcomes and final states from every $s$)?
   Prove it or give a counterexample.
3. State and prove the dual of law 3: if $\evalj{P}{s}{a}{\ok{v}}{s_1}$ and
   $\mathrm{writeSlot}\ s_1\ t\ v = \mathsf{some}\ s_2$, then
   $a\ \kw{or}_t\ b$ succeeds with $v$ in state $s_2$. Why is the hypothesis
   about `writeSlot` needed? (Compare `optionE_some`, and what happens when
   $t$ is outside the frame.)
4. Is `and` commutative? Give two expressions $a, b$ such that
   $a\ \kw{and}\ b$ and $b\ \kw{and}\ a$ have different outcomes from the same
   state, or prove that none exist. What if both are effect-free?
5. Predict, then check with `openverse run`:
   ```{.verse .check}
   Main():void =
       var N:int = 0
       if (set N += 1; not (set N += 10; N > 100)):
           Print("N = {N}")
   ```
6. (*) Formulate a theorem "a failed `for` filter leaves no trace", the
   analogue of `ite_rollback` for rule `EvalFor.skip`, and prove it on paper.
:::
