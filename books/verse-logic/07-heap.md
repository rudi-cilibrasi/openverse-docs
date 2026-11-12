# Look but Do Not Touch

## An opening problem

Values in Verse are immutable, but objects are not: a class may have `var`
fields, an object is shared by every reference to it, and a write through
one reference is seen through all the others. Rollback extends to the heap:

```{.verse .run}
chest := class:
    var Gold:int = 0

Deposit(C:chest, N:int)<transacts>:void =
    set C.Gold += N

Peek(C:chest)<reads>:int = C.Gold

Main():void =
    Mine := chest{}
    Alias := Mine
    Deposit(Mine, 5)
    Print("Alias sees {Peek(Alias)}")
    if (Deposit(Mine, 100), Peek(Mine) > 1000):
        Print("rich")
    Print("after the failed attempt: {Peek(Mine)}")
```

```{.output}
Alias sees 5
after the failed attempt: 5
```

Mutation makes reasoning harder: to know what a call does, one must know
which objects it may change. Verse answers with **heap effects**, specifiers
on a function's signature: `<computes>` (no access to mutable state),
`<reads>` (may read `var` fields), `<allocates>` (may construct objects with
mutable state), `<writes>` (may set `var` fields), and `<transacts>` (all of
these). `Peek` above is `<reads>`. The programmer wants to know that calling
`Peek` cannot change the chest. The logician recognizes a *frame property*:
an analysis on the syntax implies that a whole region of the state is
untouched. This chapter proves it.

## The analysis

The front end checks each body against its function's declared effects, and
records in Verse Core, for each function, a single bit: whether it may
`writes`. A function declared `<computes>`, `<reads>` or `<allocates>` (or a
combination without `<writes>`) has $\mathit{writes} = \bot$. In Verse Core
the only operation that changes an existing object is the field write
$\kw{heap}\ (\mathit{set}\ k)\ [r, v]$, and the analysis is:

::: {.definition title="Writes the heap"}
Write $W(e)$ for $\mathrm{writesHeap}_P(e)$. Then
$$
\begin{array}{rcl}
W(\kw{heap}\ o\ \vec{e}) & = & [o = \mathit{set}\ k] \vee \textstyle\bigvee_i W(e_i) \\
W(\kw{call}\ f\ \vec{e}) & = & \mathit{writes}(P.f) \vee \textstyle\bigvee_i W(e_i) \\
W(\kw{ite}\ c\ t\ e) & = & W(c) \vee W(t) \vee W(e) \\
W(\kw{for}\ i\ a\ f\ b) & = & W(a) \vee W(f) \vee W(b)
\end{array}
$$
where $a$, $f$, $b$ are the array, filter and body of the `for`, and the
other constructs pass their subexpressions' values up.
:::

Compare the `ite` line with Chapter 4's $\mathrm{mayFail}$, which *ignored*
the condition. Here the condition counts. The two analyses look at the same
construct from opposite sides: a failure inside the condition never
escapes it, so it cannot make the `if` fail; but a write inside the
condition escapes whenever the condition *succeeds*, since success commits.
Rollback undoes writes only on failure.

```{.lean .excerpt file="OpenVerse/Core/Writes.lean"}
  | .heap op es => op.writes || Expr.writesHeapList P es
  | .call f es =>
    (match P.fns[f]? with
      | some fn => fn.writes
      | none => false) || Expr.writesHeapList P es
  | .ite c t e => c.writesHeap P || t.writesHeap P || e.writesHeap P
```

As with `<decides>`, the analysis of a call trusts the callee's declaration,
and soundness needs the declarations to be honest:

$$
\mathrm{WriteSound}(P) \ :\Longleftrightarrow\
\forall \mathit{fn} \in P.\mathit{fns}.\ \neg\,\mathit{fn}.\mathit{writes}
\Rightarrow \neg\,\mathrm{writesHeap}_P(\mathit{fn}.\mathit{body}).
$$

## What "untouched" means

A function that does not write may still *allocate*, so its heap may grow.
The right relation between the global state before and after is that every
object that existed is still there, at the same address, with the same
fields:

::: {.definition title="Keeps"}
$$
g \preceq g' \ :\Longleftrightarrow\ \forall a\, o.\ \ g.\mathit{heap}[a] = \mathsf{some}\ o
\ \Rightarrow\ g'.\mathit{heap}[a] = \mathsf{some}\ o
$$
(`Glob.keeps g g'`). It is reflexive and transitive: a preorder.
:::

```{.lean .excerpt file="OpenVerse/Core/Writes.lean"}
def Glob.keeps (g g' : Glob) : Prop :=
  ∀ (a : Nat) (o : Obj), g.heap.toList[a]? = some o →
    g'.heap.toList[a]? = some o
```

Note what $\preceq$ does *not* constrain: the output (a non-writing function
may print), new objects, and the frame.

## The theorem

::: {.theorem title="Heap frame property (`Eval.no_writes`, `Prog.accepted_no_writes`)"}
If $\mathrm{WriteSound}(P)$, then for all $s, e, r, s'$:
$$
\evalj{P}{s}{e}{r}{s'} \ \wedge\ \neg\,\mathrm{writesHeap}_P(e) \ \Longrightarrow\ s.g \preceq s'.g .
$$
For a program accepted by the front end, a call of a function $f$ declared
without `writes`, whose arguments do not write, keeps every existing object.
:::

```{.lean .claim name="Eval.no_writes"}
@Eval.no_writes : ∀ {P : Prog},
  P.WriteSound →
    ∀ {s : St} {e : Expr} {r : Res} {s' : St},
      Eval P s e r s' → Expr.writesHeap P e = false → s.g.keeps s'.g
```

```{.lean .claim name="Prog.accepted_no_writes"}
@Prog.accepted_no_writes : ∀ {P : Prog},
  P.check = true →
    ∀ {s : St} {f : Nat} {es : List Expr} {r : Res} {s' : St} {fn : Fn},
      P.fns[f]? = some fn →
        fn.writes = false → Expr.writesHeapList P es = false →
          Eval P s (Expr.call f es) r s' → s.g.keeps s'.g
```

The second theorem has no `WriteSound` hypothesis: it takes `P.check = true`,
the Boolean check every accepted program passes (Chapter 8), and derives
`WriteSound` from it (`Prog.check_writeSound`). The theorem holds whatever
the outcome $r$: even if the call fails, raises an error or returns early,
no existing object has changed.

## The proof

By induction on the derivation, mutually for lists and `for` iterations,
assuming $\mathrm{WriteSound}(P)$. The global state threads through
evaluation, and each case composes the steps with the transitivity of
$\preceq$.

- **Leaves** (\rulename{Lit}, \rulename{Local}, \rulename{Brk}) do not change
  the state: reflexivity.
- **Sequencing and arguments**: $s.g \preceq s_1.g \preceq s_2.g$ by the
  hypotheses, then transitivity. The same for every rule with several
  premises evaluated in order.
- **Heap operations.** Since $\neg\,\mathrm{writesHeap}$, the operation is not
  a field write. Allocation *pushes* an object at the end of the heap, which
  keeps every existing address; reads, class tests and casts leave the heap
  as it is.
- **`print`** changes the output, which $\preceq$ ignores.
- **Calls.** The arguments keep the heap by the hypothesis. The callee does
  not write, so by $\mathrm{WriteSound}$ its body does not write, and the
  hypothesis for the body's derivation, a premise of \rulename{Call-Ok},
  gives that the body keeps the heap. The call's final state takes the
  caller's frame and the body's global part, so the global part is kept.
- **`ite`.** With \rulename{Ite-Ok}, the condition and then the branch keep
  the heap (both are analyzed): transitivity. With \rulename{Ite-Fail}, the
  else branch runs from $s$, so the hypothesis for it gives $s.g \preceq
  s'.g$ directly. The failed condition's state is discarded, and the
  proof never needs to know what it did.

The last case shows rollback and the frame property cooperating: the proof
would go through even if $\mathrm{writesHeap}$ ignored conditions *in the
\rulename{Ite-Fail} case*. What forces the analysis to count them are
\rulename{Ite-Ok}, where success commits the condition's writes, and
\rulename{Ite-Stop}, where a `return`, `break` or error inside the condition
leaves the `if` without rollback, in the condition's final state.

## In code

Rollback of field writes is the opening program. The effect checks are the
compile-time half of the story; each forbidden step is named:

```{.verse .reject expect="Steal sets a var field, which its effects (<reads>) do not allow"}
chest := class:
    var Gold:int = 0

Steal(C:chest)<reads>:void = set C.Gold = 0

Main():void = Steal(chest{})
```

Calling a writing method from a `<reads>` function is just as forbidden:
the analysis of a call uses the callee's declared effects.

```{.verse .reject expect="which its effects (<reads>) do not allow"}
counter := class:
    var Count:int = 0
    Bump()<transacts>:void = set Count += 1

Look(C:counter)<reads>:void = C.Bump()

Main():void = Look(counter{})
```

`<computes>` is stricter than `<reads>`: it may not even *read* a `var`
field, since the result would then depend on mutable state.

```{.verse .reject expect="Peek reads a var field, which its effects (<computes>) do not allow"}
chest := class:
    var Gold:int = 0

Peek(C:chest)<computes>:int = C.Gold

Main():void = Print("{Peek(chest{})}")
```

Reading an *immutable* field is not an effect: immutable objects are
values as far as effects are concerned, so this `<computes>` function is
accepted.

```{.verse .run}
point := class:
    X:int
    Y:int

Norm(P:point)<computes>:int = Abs(P.X) + Abs(P.Y)

Main():void = Print("{Norm(point{X := 3, Y := -4})}")
```

```{.output}
7
```

An `<allocates>` function may construct objects with `var` fields, which is
compatible with $\preceq$ because new objects go to new addresses. The
class has to allow it: constructing an object has its own effect budget,
declared on the class, and `class<allocates>` says that construction only
allocates:

```{.verse .run}
chest := class<allocates>:
    var Gold:int = 0

Fresh(N:int)<allocates>:chest = chest{Gold := N}

Main():void =
    C := Fresh(3)
    Print("{C.Gold}")
```

```{.output}
3
```

A class without that annotation has the default budget `<transacts>`, so
the same `Fresh` is refused:

```{.verse .reject expect="which its effects (<allocates>) do not allow"}
chest := class:
    var Gold:int = 0

Fresh(N:int)<allocates>:chest = chest{Gold := N}

Main():void = Print("{Fresh(3).Gold}")
```

## Limits and readings

- **Only `writes` has a theorem.** openverse checks `<computes>` and
  `<reads>` as the front end's discipline, but the proved property is about
  the `writes` bit: a function without it keeps every existing object. A
  theorem that a `<computes>` function's result does not depend on the heap
  would need a relational (two-run) statement; it is an exercise.
- **The frame and the output are not covered.** `var` local variables live in
  the frame and are not "the heap": a `<computes>` function may use them
  freely. Printing is not a heap effect either (openverse accepts Verse's
  other effect specifiers, such as `<converges>`, without checking them).
- **Field writes, constructions and rollback.** A failed failure context
  undoes the field writes and the constructions it made, as the opening
  program shows; this is the heap half of the transactional state of
  Chapter 3. The reference interpreter implements it by copying the heap on
  the first write or allocation inside a context. The C runtime rolls back
  slots and output with the journal of `store.c`, which has a bounded
  machine-checked proof (Chapter 8), and object writes and allocations with
  a field log in its object store (`objects.c`), which is tested but not
  proved.

::: {.exercise title="Exercises"}
1. Prove that $\preceq$ is a preorder. Is it antisymmetric? (Hint: which
   part of a `Glob` does $\preceq$ not look at? Is it antisymmetric on heaps
   alone? See `Glob.keeps.prefix`.)
2. Write the \rulename{Heap-Ok} case of the proof for allocation in full,
   using `Array.push`. Which property of arrays do you need?
3. Explain why $\mathrm{writesHeap}$ must count the *filter* of a `for`.
   Give a program whose filter writes a field and succeeds.
4. Suppose a function is declared `<reads>` and calls a `<decides>`
   function that writes a field and then fails. Write the program and check
   it: the front end rejects it. Semantically, the write would be rolled back
   by the failure, so the call could not change any object. Why is it
   rejected anyway, and what would an analysis that accepted it have to
   know?
5. (*) State a *non-interference* theorem for `<computes>`: two runs of a
   `<computes>` function from states that differ only in `var` fields of
   existing objects return the same outcome. What analysis would its proof
   need, beyond $\mathrm{writesHeap}$?
:::
