# One Program, One Answer

## An opening problem

Logic programming usually means search. A Prolog query may have many
answers, produced in an order that depends on the search strategy, and the
Verse Calculus, the core calculus behind Verse, has an operator of *choice*,
$e_1 \mid e_2$, under which one expression has several values. Yet a Verse
program run by openverse prints the same thing every time:

```{.verse .run}
Main():void =
    Pairs := for (X := 1..3, Y := 1..3, X < Y) { X * 10 + Y }
    for (P : Pairs) { Print("{P}") }
```

```{.output}
12
13
23
```

The `for` explores a search space (all pairs with $X < Y$), but in a fixed
order: generators left to right, each in ascending order, filters pruning as
they go. Is this an accident of the implementation, or a property of the
language that openverse implements? For the programmer, the question is
whether a test that passed once will pass again, and whether the Lean
interpreter and the C runtime *can* disagree on a correct program. For the
logician, it is whether the relation of Chapter 1 is the graph of a partial
function. The theorem of this chapter says that it is.

## The theorem

::: {.theorem title="Determinism (`Eval.det`, `Runs.det`)"}
For every program $P$, state $s$ and expression $e$:
$$
\evalj{P}{s}{e}{r_1}{s_1} \ \wedge\ \evalj{P}{s}{e}{r_2}{s_2}
\ \Longrightarrow\ r_1 = r_2 \ \wedge\ s_1 = s_2 .
$$
Consequently a program has at most one run:
$$
\Runs\ P\ r_1\ o_1 \ \wedge\ \Runs\ P\ r_2\ o_2 \ \Longrightarrow\ r_1 = r_2 \ \wedge\ o_1 = o_2 .
$$
:::

Equivalently, with the uniqueness quantifier $\exists^{\leq 1}$ ("at most
one"):
$$
\forall P\, s\, e.\ \ \exists^{\leq 1} (r, s').\ \ \evalj{P}{s}{e}{r}{s'} .
$$
Note "at most": a program that runs forever has *no* outcome, and the theorem
says nothing about it.

```{.lean .claim name="Eval.det"}
@Eval.det : ∀ {P : Prog} {s : St} {e : Expr} {r₁ : Res} {s₁ : St} {r₂ : Res}
    {s₂ : St},
  Eval P s e r₁ s₁ → Eval P s e r₂ s₂ → r₁ = r₂ ∧ s₁ = s₂
```

```{.lean .claim name="Runs.det"}
@Runs.det : ∀ {P : Prog} {r₁ : Res} {o₁ : List Nat} {r₂ : Res}
    {o₂ : List Nat},
  Runs P r₁ o₁ → Runs P r₂ o₂ → r₁ = r₂ ∧ o₁ = o₂
```

The output $o$ is a `List Nat`: the bytes printed (in a typed program, each
a number below 256; the type `Nat` does not enforce it).
The states $s_1, s_2$ in `Eval.det` include the frame *and* the heap, so
determinism covers more than printed output: the values of all variables,
every object, and even the addresses at which objects were allocated.

## Why it could fail

A relation defined by inference rules is deterministic only if the rules are
designed for it. Two things could go wrong.

**Overlapping rules.** If two rules can conclude about the same expression,
with compatible premises, there may be two derivations with different
outcomes. Look again at the three `ite` rules of Chapter 1. Their first
premises are about the same condition $c$, from the same state $s$, with
outcomes $\ok{v}$, $\fail$, and "anything else":

$$
\infer[\rulename{Ite-Stop}]{\evalj{P}{s}{\kw{ite}\ c\ t\ e}{r}{s_1}}
      {\evalj{P}{s}{c}{r}{s_1} & r \neq \ok{\_} & r \neq \fail}
$$

The side conditions $r \neq \ok{\_}$ and $r \neq \fail$ are what keep
\rulename{Ite-Stop} from overlapping the other two. Every construct of Verse
Core follows the same discipline: its rules are told apart by the outcome
of the subexpression evaluated first (a success, a failure where that
matters, or anything else), and, where a successful value can still be
ill-shaped, by a side condition on that value (\rulename{Assign-Bad} for a
slot outside the frame, \rulename{Call-Bad} for a missing function, …). (In
Lean the side condition "not a success" is written `r.isOk = false`.)

**Nondeterministic primitives.** A rule whose conclusion is not a function of
its premises would break determinism even without overlaps: a rule for
choice, say, with conclusions $\ok{v_1}$ and $\ok{v_2}$ for $e_1 \mid e_2$, or
an allocation rule that picks *some* fresh address. openverse has neither.
Choice is in the subset (from the Verse Calculus; the Book of Verse does not
describe it yet), but ordered: `e₁ | e₂` gives `e₁`'s values, then `e₂`'s,
and it adds no rule to Verse Core, because the front end compiles it
into iteration over the alternatives. Concurrency (`spawn`, `race`, `sync`,
`Sleep`) adds no rule either: the front end compiles it into ordinary Core
code. The next section shows both. And allocation takes the *next* address,
the current size of the heap:

```{.lean .excerpt file="OpenVerse/Core/Semantics.lean"}
  | .new t, vs, ⟨out, heap⟩ =>
      (.ok (.ref heap.size), ⟨out, heap.push ⟨t, vs⟩⟩)
```

Primitive operations are functions too (`Prim.apply`, `HeapOp.apply`), so
each rule's conclusion is determined by its premises.

## The proof

There are two proofs, and it is instructive to see both.

**The textbook proof** is by induction on the first derivation, inverting the
second. Suppose $\mathcal{D}_1$ derives $\evalj{P}{s}{e}{r_1}{s_1}$ and
$\mathcal{D}_2$ derives $\evalj{P}{s}{e}{r_2}{s_2}$; we show $r_1 = r_2$ and
$s_1 = s_2$ by induction on $\mathcal{D}_1$. The last rule of $\mathcal{D}_2$
must be a rule for the same construct. Take $e = \kw{ite}\ c\ t\ e'$ and
$\mathcal{D}_1$ ending in \rulename{Ite-Ok}, with premises
$\evalj{P}{s}{c}{\ok{v}}{s'_1}$ and $\evalj{P}{s'_1}{t}{r_1}{s_1}$.

- If $\mathcal{D}_2$ ends in \rulename{Ite-Fail}, its first premise is
  $\evalj{P}{s}{c}{\fail}{s''}$. The induction hypothesis for the first
  premise of $\mathcal{D}_1$ gives $\ok{v} = \fail$: impossible.
- If $\mathcal{D}_2$ ends in \rulename{Ite-Stop}, its first premise gives an
  outcome $r \neq \ok{\_}$; again the hypothesis gives $\ok{v} = r$, a
  contradiction.
- If $\mathcal{D}_2$ ends in \rulename{Ite-Ok}, with premises
  $\evalj{P}{s}{c}{\ok{v'}}{s''}$ and $\evalj{P}{s''}{t}{r_2}{s_2}$, the
  hypothesis gives $v = v'$ and $s'_1 = s''$; so the second premises start in
  the same state, and the hypothesis for them gives $r_1 = r_2$ and
  $s_1 = s_2$.

Every case of every construct is like one of these: an "ok" rule against a
"stop" rule is a contradiction through the side condition, and two rules of
the same kind agree by the hypotheses applied left to right, each premise
starting where the previous one ended. For `call`, the hypothesis for the
argument list gives the same arguments, hence the same callee and frame,
and the hypothesis for the body gives the same result.

**openverse's proof** is three lines long, because Chapter 1 already did the
work:

```{.lean .excerpt file="OpenVerse/Core/Adequacy.lean"}
theorem Eval.det {P : Prog} {s e r₁ s₁ r₂ s₂}
    (h₁ : Eval P s e r₁ s₁) (h₂ : Eval P s e r₂ s₂) :
    r₁ = r₂ ∧ s₁ = s₂ := by
  obtain ⟨n₁, H₁⟩ := eval_iff.mp h₁
  obtain ⟨n₂, H₂⟩ := eval_iff.mp h₂
  have := eval_fuel_irrelevant H₁ H₂
  simp only [Prod.mk.injEq] at this
  exact this
```

In words: by adequacy, the interpreter returns $(r_1, s_1)$ at some fuel
$n_1$ and $(r_2, s_2)$ at some fuel $n_2$; by fuel irrelevance these results
are equal; equality of pairs is equality of components. The `obtain` lines
destructure the existentials that `eval_iff.mp` (the left-to-right direction
of the biconditional) produces.

The logic behind the short proof is worth stating as a principle.

::: {.note title="Determinism for free"}
If a relation $R \subseteq A \times B$ satisfies
$R\,a\,b \iff \exists n.\ f\ n\ a = \mathsf{some}\ b$ for a family of partial
functions $f\ n$ that agree wherever they are defined, then $R$ is the graph
of a partial function, hence deterministic. Defining an interpreter and
proving it adequate yields determinism without a separate induction.
:::

The textbook induction is not needed at all, but its work is done
elsewhere. Fuel irrelevance came from the `Eventually` form of completeness,
an induction on a *single* derivation; it never compares two rules. The
exclusivity that the textbook proof checks case by case is built into
`eval`: a Lean function defined by pattern matching has one clause for each
shape of input, so it cannot return two answers. Adequacy transfers that
property from the function to the relation.

`Runs.det` follows from `Eval.det`: two runs are two derivations from the
same initial state for the same expression, $\kw{call}\ \mathit{main}\ []$,
so their final states are equal, hence so are their outputs
(`congrArg (fun s : St => s.g.out)`).

## In code

Determinism is what makes the order of a `for` meaningful. Generators run
left to right, the leftmost slowest, like nested loops; the result array
lists the body's values in that order, as in the opening program.

Maps iterate in insertion order. Updating a key keeps its place; a new key
goes at the end:

```{.verse .run}
Main():void =
    var Loot:[string]int = map{"ruby" => 3, "coin" => 50}
    set Loot["amber"] = 7
    set Loot["ruby"] = 4
    for (Name -> Count : Loot) { Print("{Name}: {Count}") }
```

```{.output}
ruby: 4
coin: 50
amber: 7
```

In Verse Core a map is simply the array of its key-value pairs, so map
iteration inherits the determinism of array iteration. (This is also why
openverse's map equality is order-sensitive, a reading documented in its
`LANGUAGE.md`.)

Allocation is deterministic too, and identity is observable. Instances of a
`<unique>` class compare by identity, so two objects with equal fields
differ:

```{.verse .run}
gem := class<unique>:
    Name:string

Main():void =
    A := gem{Name := "opal"}
    B := gem{Name := "opal"}
    if (A = B) then Print("same gem") else Print("two gems")
    if (A = A) then Print("A is A") else Print("?")
```

```{.output}
two gems
A is A
```

Here `A` and `B` are references $\kw{ref}\ a$ and $\kw{ref}\ b$ to the objects
allocated at addresses $a$ and $b = a + 1$, the sizes of the heap at the two
allocations. A semantics that allocated at an arbitrary fresh address would
still give `two gems` (the addresses differ either way) but would not be
deterministic in the sense of `Eval.det`, because the final states would
differ in their addresses. Such a semantics would need determinism *up to
renaming of addresses*, a weaker and much harder theorem.

Concurrent programs are deterministic for the same reason. Here two calls
of `Worker` run as the arms of a `sync`:

```{.verse .run}
Worker(Name:string, Steps:int)<suspends>:void =
    var I:int = 0
    loop:
        if (I >= Steps) then break
        Print("{Name} {I}")
        Sleep(0.0)
        set I += 1

Main()<suspends>:void =
    sync:
        Worker("a", 2)
        Worker("b", 3)
    Print("both done")
```

```{.output}
a 0
b 0
a 1
b 1
b 2
both done
```

Each arm runs until it waits. `Sleep(0.0)` waits for the next tick of a
virtual clock, and in each tick the arms go on in source order, so the lines
interleave the same way on every run. None of this is new to Verse Core: the
front end compiles `Worker` into a frame object and a function that resumes
it from one wait to the next, and the scheduler is a helper written in Verse
(`docs/DESIGN.md`). The whole program is an ordinary Core program, and
`Eval.det` applies to it as it is. (That the lowering keeps the meaning of
the surface program is tested, not proved, like the rest of the front end:
Chapter 8.)

Choice is compiled the same way. Its values come in *spatial* order, fixed
by where each choice is written: the leftmost varies slowest, as the
generators of a `for` do. A `for` takes every value, and an `if` takes the
first that makes its condition succeed:

```{.verse .run}
Main():void =
    for (X := 1 | 2, Y := 10 | 20):
        Print("{X + Y}")
    if (X := 1 | 2 | 3, X > 1):
        Print("first success: {X}")
```

```{.output}
11
21
12
22
first success: 2
```

In Verse Core each choice is a loop over its alternatives' indices
(`Expr.altE`, `Expr.chooseFirst` and `Expr.firstE` in `Core/Derived.lean`),
so `Eval.det` applies here too. `Core/Derived.lean` also proves sufficient
conditions about those forms for the first success (`chooseFirst_brk`,
`chooseFirst_none`). That the front end emits them as described, and the
reading of a choice in a `for`, are tested, not proved
(`docs/LANGUAGE.md`, "Choice").

Finally, determinism is what makes openverse's testing strategy sound. Its C
interpreter is compared with the Lean interpreter on every test program and
on random programs, byte for byte, output and exit code. Without
determinism, a disagreement would not show a bug: both could be right.

## Limits and readings

- **Determinism by fixing orders.** The theorem is about openverse's
  subset, and the subset fixes every order that could vary. Choice gives
  its values in spatial order, the reading the Verse Calculus paper takes
  to keep choice deterministic. The places a choice may appear are listed
  in `docs/LANGUAGE.md`. Concurrency fixes the order in which tasks go on
  and counts time in ticks. Both are compiled into Core code, so they add
  no rule for `Eval.det` to cover.
- **At most one, not exactly one.** `Eval.det` gives uniqueness, not
  existence. A diverging program has no outcome; Chapter 1 explained why
  that is the only way to have none.
- **The C runtime is deterministic by testing.** Lean proves determinism of
  the definition and the reference interpreter. The C interpreter is a
  transcription checked by differential testing, under sanitizers. Its
  rollback store and loader have separate machine-checked proofs (Chapter 8).
- **Readings.** Several of the orders above are openverse's choices where the
  Book of Verse is silent: output inside a failed failure context is rolled
  back, a failing `for` body makes the whole `for` fail (as in the Verse
  Calculus), and maps compare in order. Determinism holds *given* these
  readings, which the rules fix.

::: {.exercise title="Exercises"}
1. Remove the side condition $r \neq \fail$ from \rulename{Ite-Stop}. Give a
   Verse Core expression with two derivations and different outcomes.
2. Prove `Runs.det` from `Eval.det` on paper, using the definition of
   $\Runs$ from Chapter 1. Where is the output in the final state?
3. Write the textbook proof's case for $\kw{seq}$ in full: \rulename{Seq-Ok}
   against \rulename{Seq-Ok}, and \rulename{Seq-Ok} against
   \rulename{Seq-Stop}.
4. Predict the output, then run it:
   ```{.verse .check}
   Main():void =
       for (X := 1..2, Y := 1..2) { Print("{X}{Y}") }
   ```
   Which generator varies fastest? How would you get the other order?
5. (*) Suppose allocation chose an arbitrary address not in use. State a
   determinism theorem "up to renaming of heap addresses" in the notation of
   this chapter. Which rules would its proof have to treat specially?
6. Prove the principle *Determinism for free* in Lean:
   ```{.lean .fragment}
   theorem det_of_graph {α β} (R : α → β → Prop) (f : Nat → α → Option β)
       (hR : ∀ a b, R a b ↔ ∃ n, f n a = some b)
       (hf : ∀ n₁ n₂ a b₁ b₂, f n₁ a = some b₁ → f n₂ a = some b₂ → b₁ = b₂) :
       ∀ a b₁ b₂, R a b₁ → R a b₂ → b₁ = b₂ := by
     sorry
   ```
:::
