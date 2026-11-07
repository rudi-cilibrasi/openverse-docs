# Meaning as a Relation

## An opening problem

Here is a small Verse program. Read it before you read its output.

```{.verse .run}
Main():void =
    var Coins:int = 10
    if (set Coins = Coins - 25, Coins >= 0):
        Print("bought the map")
    else:
        Print("cannot afford it: {Coins} coins")
```

```{.output}
cannot afford it: 10 coins
```

The condition of the `if` *assigns* to `Coins`, setting it to $-15$, and then
*fails*, because $-15 \geq 0$ is false and a comparison that does not hold
fails in Verse. The `else` branch then sees `Coins` as $10$: the assignment
has been undone. Verse calls this **rollback**, and the `if` condition is a
**failure context**.

What licenses that answer? A programmer would say "run it and see". A
logician would ask for the *definition* of what the program means, and then
derive the answer from it. openverse provides both, and the first theorem of
this book says that they agree. The definition is an inductively defined
relation, a big-step operational semantics. The procedure is an interpreter,
a total Lean function that may run out of "fuel". The adequacy theorem
`eval_iff` states that the relation holds exactly when the interpreter, given
enough fuel, returns the same outcome. Every later chapter proves things about
the relation, and gets for free that they hold of the interpreter, and so of
`openverse run`.

## Verse Core

openverse does not give meaning to surface Verse directly. Its front end
*elaborates* the program into **Verse Core**: a small language whose names
are resolved, so that a local variable is a slot number in the frame of the
current call and a function is an index into the program. The grammar of
Verse Core expressions is

$$
\begin{array}{rcl}
e & ::= & \kw{lit}\ v \mid \kw{local}\ i \mid \kw{assign}\ i\ e \mid \kw{seq}\ e_1\ e_2
          \mid \kw{prim}\ p\ \vec{e} \mid \kw{call}\ f\ \vec{e} \\
  &  \mid & \kw{ite}\ c\ t\ e \mid \kw{for}\ i\ e_{\mathit{it}}\ e_{\mathit{filt}}\ e_{\mathit{body}}
          \mid \kw{loop}\ e \mid \kw{brk} \mid \kw{ret}\ e \mid \kw{print}\ e \mid \kw{heap}\ o\ \vec{e}
\end{array}
$$

where $v$ ranges over values, $i$ over slot numbers, $f$ over function
numbers, $p$ over primitive operations ($+$, comparisons, indexing, …) and
$o$ over heap operations (allocation, field reads and writes, class tests).
Surface constructs such as `not`, `or`, `option{…}` and `and` are *not*
primitive: they are derived forms, defined as Verse Core expressions in
Chapter 3.

The opening program becomes, after elaboration (abbreviating string literals
and the initialization of `Coins`),

$$
\begin{array}{l}
\kw{seq}\ (\kw{assign}\ 0\ (\kw{lit}\ 10))\ \big(\kw{ite}\ c\ e_{\mathit{then}}\ e_{\mathit{else}}\big)
\quad\text{where} \\[2pt]
\qquad c \;=\; \kw{seq}\ (\kw{assign}\ 0\ (\kw{prim}\ {-}\ [\kw{local}\ 0, \kw{lit}\ 25]))\
                    (\kw{prim}\ {\geq}\ [\kw{local}\ 0, \kw{lit}\ 0])
\end{array}
$$

The command `openverse core FILE` prints this term for any program.

An evaluation has one of five **outcomes**:

$$
r \ ::=\ \ok{v} \mid \fail \mid \brk \mid \ret{v} \mid \err{k}
$$

Success with a value; Verse failure; a `break` on its way to the nearest
`loop`; a `return` on its way to the function boundary; and a runtime error of
kind $k$ (overflow, a type error, a slot or call error, a control error, or
an explicit `Err()`). In Lean:

```{.lean .excerpt file="OpenVerse/Core/Value.lean"}
inductive Res where
  /-- Success with a value. -/
  | ok   : Value → Res
  /-- Verse failure: caught by the nearest failure context, which rolls
      back. -/
  | fail : Res
  /-- `break` travelling to the nearest `loop`. -/
  | brk  : Res
  /-- `return v` travelling to the function boundary. -/
  | ret  : Value → Res
  /-- A runtime error: ends the program. -/
  | err  : ErrKind → Res
```

A **state** $s$ has two parts: the *frame* $s.\mathit{fr}$, the list of values
in the slots of the current call, and the *global* part $s.g$, which holds the
output printed so far and the heap of objects. Both parts are restored on
rollback; that the output is too is openverse's *transactional* reading of
`Print`.

## The judgment

The meaning of Verse Core is the relation

$$
\evalj{P}{s}{e}{r}{s'}
$$

read: *in program $P$, from state $s$, expression $e$ has outcome $r$ and
leaves state $s'$.* It is written `Eval P s e r s'` in Lean, and it is the
least relation closed under a set of inference rules, one per Lean
constructor. Here are the rules for literals, sequencing and `if`; the
others follow the same pattern.

$$
\infer[\rulename{Lit}]{\evalj{P}{s}{\kw{lit}\ v}{\ok{v}}{s}}{}
\qquad
\infer[\rulename{Seq-Ok}]{\evalj{P}{s}{\kw{seq}\ a\ b}{r}{s_2}}
      {\evalj{P}{s}{a}{\ok{v}}{s_1} & \evalj{P}{s_1}{b}{r}{s_2}}
$$

$$
\infer[\rulename{Seq-Stop}]{\evalj{P}{s}{\kw{seq}\ a\ b}{r}{s_1}}
      {\evalj{P}{s}{a}{r}{s_1} & r \neq \ok{\_}}
$$

$$
\infer[\rulename{Ite-Ok}]{\evalj{P}{s}{\kw{ite}\ c\ t\ e}{r}{s_2}}
      {\evalj{P}{s}{c}{\ok{v}}{s_1} & \evalj{P}{s_1}{t}{r}{s_2}}
$$

$$
\infer[\rulename{Ite-Fail}]{\evalj{P}{s}{\kw{ite}\ c\ t\ e}{r}{s_2}}
      {\evalj{P}{s}{c}{\fail}{s_1} & \evalj{P}{s}{e}{r}{s_2}}
$$

$$
\infer[\rulename{Ite-Stop}]{\evalj{P}{s}{\kw{ite}\ c\ t\ e}{r}{s_1}}
      {\evalj{P}{s}{c}{r}{s_1} & r \neq \ok{\_} & r \neq \fail}
$$

Three features deserve attention.

**Abrupt outcomes propagate.** A "stop" rule such as \rulename{Seq-Stop}
passes on any outcome other than success: failure, `break`, `return` or an
error stops the sequence and becomes its outcome. There is one such rule for
every construct with subexpressions, and they are what make failure travel
outward until something catches it.

**Failure contexts catch failure, and roll back.** In \rulename{Ite-Fail} the
condition fails in state $s_1$, but the `else` branch starts from $s$, the
state *before* the condition ran. The intermediate state $s_1$ is simply
dropped. That is the whole of rollback, at the level of the definition: no
undo log, no snapshot, just a premise that mentions $s$ and not $s_1$. (The
interpreter and the C runtime implement the same thing with copy-on-write
and an undo journal; that they agree with the definition is the point of
this chapter and of openverse's tests.) Note that \rulename{Ite-Stop} does
*not* catch a runtime error or a `return`: only $\fail$ is caught.

**The relation is the definition.** There is nothing behind it. A Verse Core
program means what the rules derive, and the Lean source is the
authoritative statement of the rules:

```{.lean .excerpt file="OpenVerse/Core/Semantics.lean"}
  | ite_ok {s s₁ s₂ c t e v r} :
      Eval P s c (.ok v) s₁ → Eval P s₁ t r s₂ →
      Eval P s (.ite c t e) r s₂
  /-- Rollback: the `else` branch starts from `s`, not from where `c`
      failed. -/
  | ite_fail {s s₁ s₂ c t e r} :
      Eval P s c .fail s₁ → Eval P s e r s₂ →
      Eval P s (.ite c t e) r s₂
```

Each constructor is an inference rule: the arrows separate premises, the
last line is the conclusion, and the variables in braces are universally
quantified. The relation is defined mutually with `EvalList`, for argument
lists evaluated left to right, and `EvalFor`, for the iterations of a `for`.

A whole program **runs** to outcome $r$ with output $o$ when calling `Main`
from the initial state (an empty frame, no output, an empty heap) derives
$r$ and leaves output $o$:

$$
\Runs\ P\ r\ o \quad :\Longleftrightarrow\quad
\exists\, \mathit{fr}\ \mathit{h}.\ \
\evalj{P}{s_0}{\kw{call}\ \mathit{main}\ []}{r}{\langle \mathit{fr}, \langle o, h\rangle\rangle}
$$

## The interpreter

A relation is a definition, not a program. To *run* Verse Core, openverse has
a reference interpreter, `eval`, a Lean function of type

$$
\mathrm{eval} : \mathrm{Prog} \to \mathbb{N} \to \mathrm{St} \to \mathrm{Expr}
\to \mathrm{Option}(\mathrm{Res} \times \mathrm{St}).
$$

The natural number is **fuel**. Every recursive call spends one unit, so
`eval` is defined by structural recursion on the fuel and Lean accepts it as
a total function, even though Verse programs need not terminate. When the
fuel runs out, `eval` returns `none`; otherwise it returns the outcome and
the final state. Its `if` case mirrors the three rules:

```{.lean .excerpt file="OpenVerse/Core/Interp.lean"}
  | n+1, s, .ite c t e => match eval P n s c with
      | none => none
      | some (.ok _, s₁) => eval P n s₁ t
      | some (.fail, _) => eval P n s e
```

On failure the interpreter, like \rulename{Ite-Fail}, discards the state the
condition left and continues from `s`. This is the function that
`openverse run` executes, and the C runtime is a transcription of it.

## The theorem

::: {.theorem title="Adequacy (`eval_iff`) and fuel irrelevance (`eval_fuel_irrelevant`)"}
For every program $P$, states $s, s'$, expression $e$ and outcome $r$:
$$
\evalj{P}{s}{e}{r}{s'} \iff \exists n \in \mathbb{N}.\ \ \mathrm{eval}\ P\ n\ s\ e = \mathsf{some}\,(r, s').
$$
Moreover, for all fuels $n_1, n_2$ and results $x_1, x_2$:
$$
\mathrm{eval}\ P\ n_1\ s\ e = \mathsf{some}\ x_1 \ \wedge\ \mathrm{eval}\ P\ n_2\ s\ e = \mathsf{some}\ x_2
\ \Longrightarrow\ x_1 = x_2 .
$$
:::

In Lean, as printed by `#check`:

```{.lean .claim name="eval_iff"}
@eval_iff : ∀ {P : Prog} {s : St} {e : Expr} {r : Res} {s' : St},
  Eval P s e r s' ↔ ∃ n, eval P n s e = some (r, s')
```

```{.lean .claim name="eval_fuel_irrelevant"}
@eval_fuel_irrelevant : ∀ {P : Prog} {n₁ n₂ : Nat} {s : St} {e : Expr}
    {x₁ x₂ : Res × St},
  eval P n₁ s e = some x₁ → eval P n₂ s e = some x₂ → x₁ = x₂
```

Read the first line left to right. The `@` and the braces mark *implicit*
arguments, which Lean infers at each use; logically they are universal
quantifiers, $\forall P\, s\, e\, r\, s'$. `Eval P s e r s'` is our judgment.
`↔` is $\iff$, and `∃ n, eval P n s e = some (r, s')` is the right-hand side,
with `some` the constructor of `Option`. The second statement uses
right-nested implications, `A → B → C`, which is Lean's curried spelling of
$A \wedge B \Rightarrow C$. The axioms Lean reports for both proofs are
`propext` and `Quot.sound`, the standard ones; there is no `sorry`.

Fuel irrelevance says that fuel decides *whether* the interpreter finishes,
never *what* it returns. Adequacy says that what it returns is exactly what
the rules derive.

## The proof

The two directions are proved separately, as `eval_sound` and
`eval_complete`, each mutually with its counterparts for argument lists and
`for` loops.

**Soundness** ($\Leftarrow$): *if $\mathrm{eval}\ P\ n\ s\ e = \mathsf{some}\,(r,
s')$ then $\evalj{P}{s}{e}{r}{s'}$.* By induction on $n$. With $n = 0$ the
interpreter returns `none`, so there is nothing to prove. With $n + 1$, case
on $e$: each clause of `eval` makes recursive calls with fuel $n$, whose
results the induction hypothesis turns into derivations, and these are
exactly the premises of the rule that matches the clause. For example, if
the condition of an `ite` returns $\mathsf{some}(\fail, s_1)$ and the else
branch $\mathsf{some}(r, s_2)$, the hypothesis gives
$\evalj{P}{s}{c}{\fail}{s_1}$ and $\evalj{P}{s}{e}{r}{s_2}$, and
\rulename{Ite-Fail} concludes. Small lemmas about the interpreter's "bind"
combinators (`bindR_some`, `bindR_stop`) do the bookkeeping of the stop
rules.

**Completeness** ($\Rightarrow$) is the subtler direction, and the proof
strengthens the statement before proving it. The naive induction fails in
the \rulename{Seq-Ok} case: the hypotheses give fuel $n_1$ that suffices for
$a$ and fuel $n_2$ that suffices for $b$, but the interpreter runs both $a$
and $b$ with the *same* fuel. One needs to know that more fuel does not hurt.
Rather than proving monotonicity separately, openverse builds it into the
induction:

::: {.definition title="Eventually"}
$$
\mathrm{Eventually}\ f\ y \quad :\Longleftrightarrow\quad \exists N.\ \forall m \geq N.\ f\ m = \mathsf{some}\ y
$$
:::

```{.lean .excerpt file="OpenVerse/Core/Adequacy.lean"}
def Eventually (f : Nat → Option α) (y : α) : Prop :=
  ∃ n, ∀ m, n ≤ m → f m = some y
```

The completeness lemma proves, by induction on the *derivation*, that

$$
\evalj{P}{s}{e}{r}{s'} \ \Longrightarrow\ \mathrm{Eventually}\ (\lambda n.\ \mathrm{eval}\ P\ n\ s\ e)\ (r, s').
$$

Now the \rulename{Seq-Ok} case is easy. The hypotheses give thresholds $N_1$
for $a$ and $N_2$ for $b$; take $N = \max(N_1, N_2) + 1$. For any $m \geq N$
write $m = k + 1$; then $k \geq N_1$ and $k \geq N_2$, so the interpreter's
two recursive calls with fuel $k$ return the right results, and the
`seq` clause combines them. Every case has this shape: the threshold of a
rule is one more than the maximum of its premises' thresholds. The
`call_ok` case, where the derivation of the callee's body is a premise, is
no different, which is why recursive functions need no special treatment:
a derivation is a finite tree, even when the program it describes calls
itself.

Adequacy follows by taking $m = N$, and fuel irrelevance is now a corollary
rather than a lemma. Suppose the interpreter returns $x_1$ with fuel $n_1$ and
$x_2$ with fuel $n_2$. By soundness both are derivable; by completeness, each
is *eventually* the interpreter's answer, from thresholds $N_1$ and $N_2$. At
fuel $\max(N_1, N_2)$ the interpreter returns both, so $\mathsf{some}\ x_1 =
\mathsf{some}\ x_2$ and $x_1 = x_2$. The same three lines will prove
determinism in Chapter 2.

## In code

The opening program is a derivation. Its `if` condition, a sequence, derives
$\fail$ by \rulename{Seq-Ok} (the assignment succeeds) and then the
comparison's own failure; \rulename{Ite-Fail} discards the state in which
`Coins` is $-15$ and evaluates the `else` branch from the state in which it
is $10$.

The output is part of the state, so it is rolled back too:

```{.verse .run}
Main():void =
    if (Print("checking the vault"), 1 > 2):
        Print("impossible")
    Print("done")
```

```{.output}
done
```

The first `Print` succeeded inside the condition, but the condition as a
whole failed, so its output belongs to the dropped state $s_1$.

What does adequacy say about a program that does not terminate? Nothing
directly: such a program has no derivation, because a derivation is finite,
and by adequacy the interpreter returns `none` at every fuel. openverse
reports this as a resource limit (exit code 3) when its fuel runs out:

```{.verse .run exit="3" fuel="40"}
Main():void =
    Print("searching")
    loop:
        Print("still searching")
```

```{.output}
```

Notice that *nothing* is printed, not even the first line. The reference
interpreter computes a final state, output included; when the fuel runs out,
there is no final state, and so there is no output. A run either has an
outcome and an output, or neither.

When a program *does* terminate, the reference interpreter and the
definition give the same answer by `eval_iff`, and the C runtime gives the
same bytes again by openverse's differential tests. Here is a program whose
answer needs some fuel, a recursion of depth 20:

```{.verse .run}
Fib(N:int):int =
    if (N < 2) then N else Fib(N - 1) + Fib(N - 2)

Main():void =
    Print("Fib(20) = {Fib(20)}")
```

```{.output}
Fib(20) = 6765
```

## Limits and readings

- **Big-step semantics cannot see divergence.** A non-terminating program has
  no derivation. By adequacy, a configuration has no derivation exactly when
  the interpreter returns `none` at every fuel, that is, when the
  interpreter runs forever: there are no *stuck* configurations. Ill-shaped
  ones (a slot out of range, a call with the wrong number of arguments, an
  operation on values of the wrong type) derive an *error* outcome rather
  than no outcome, and Chapters 5 and 8 show that checked programs never
  produce those errors.
- **The interpreter is total only because of fuel.** `eval` is a function in
  Lean's logic, so it must terminate on every input; fuel is the price. The
  theorem shows that the price is paid only in time, never in meaning.
- **The definition is trusted.** Adequacy relates two Lean objects. That
  the rules capture the language described by the Book of Verse is not a
  theorem; it is the reading openverse documents and tests.

::: {.exercise title="Exercises"}
1. Write the rules \rulename{Assign-Ok} and \rulename{Assign-Stop} for
   $\kw{assign}\ i\ e$ in the notation of this chapter, using
   $\mathrm{writeSlot}\ s\ i\ v = \mathsf{some}\ s'$ for the state with slot $i$
   set to $v$. Compare with `Eval.assign_ok` in `Semantics.lean`.
2. Derive the outcome of the opening program step by step, naming each rule.
   How many uses of \rulename{Seq-Ok} does the derivation contain?
3. Using only the two theorems of this chapter, prove: if
   $\mathrm{eval}\ P\ n\ s\ e = \mathsf{some}\ x$, $n \leq m$, and
   $\mathrm{eval}\ P\ m\ s\ e \neq \mathsf{none}$, then
   $\mathrm{eval}\ P\ m\ s\ e = \mathsf{some}\ x$ (this is openverse's
   `eval_mono`). Then (*) drop the third hypothesis: prove, by induction on
   $n$ and directly from the definition of `eval`, that more fuel never turns
   a result into `none`. Why do the theorems alone not suffice?
4. State in Lean, without proof, the claim that the program `Main():void =
   loop: Print("x")` has no run:
   ```{.lean .fragment}
   theorem spin_no_run (P : Prog) (hP : SpinsForever P) :
       ∀ r out, ¬ Runs P r out := sorry
   ```
   What would `SpinsForever` have to say about `P`? Why is this statement
   about `Runs` and not about the interpreter?
5. (*) Suppose the rule \rulename{Ite-Fail} were changed so that the `else`
   branch starts from $s_1$ instead of $s$. Which programs of this chapter
   change their output? Is adequacy still provable, if the interpreter is
   changed to match?
:::
