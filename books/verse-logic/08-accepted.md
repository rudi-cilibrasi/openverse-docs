# Everything Accepted Is Guaranteed

## An opening problem

The theorems of Chapters 4 to 7 had a hypothesis about the program:
`EffectSound`, `ProgTyped`, `WriteSound`. The Verse programs in this book were not written
in Verse Core. They were written in surface Verse and translated by
openverse's front end, more than five thousand lines of lexer, parser
and elaborator that nobody has proved correct. Why should the theorems apply to
them?

Here is a program that uses most of what the earlier chapters proved
something about: failure, rollback (of a field write, inside `logic{…}`,
which commits on success and undoes on failure), a class with a `var`
field, a generic function and a `<reads>` function.

```{.verse .run}
chest := class:
    var Gold:int = 0

Peek(C:chest)<reads>:int = C.Gold

Count(Items:[]t, Target:t where t:subtype(comparable)):int =
    var N:int = 0
    for (X : Items, X = Target) { set N += 1 }
    N

Main():void =
    C := chest{}
    for (N : array{5, 12, 7}):
        Added := logic{set C.Gold += N; Peek(C) < 20}
        if (not Added?) { Print("too heavy at {N}") }
    Print("gold: {Peek(C)}")
    Print("rubies: {Count(array{"ruby", "opal", "ruby"}, "ruby")}")
```

The front end accepts it, and the guarantees of this chapter hold for it:
whatever happens, it has one outcome and one output, it raises no slot, call,
type or control error, its result has its declared type, it cannot fail
because `Main` is not `<decides>`, and `Peek` changes no object. The only
runtime errors it could raise are integer overflow and `Err()`.

```{.output}
too heavy at 7
gold: 17
rubies: 2
```

The design that makes this possible is called **translation validation**.
The front end is not trusted to be correct; each program it emits is checked,
by Lean functions, and each check is proved to establish the hypotheses of
the theorems. The capstone theorem `Prog.accepted` puts them together.

## The checks

An accepted Verse Core program passes three Boolean checks:

- $\mathrm{check}(P)$, the conjunction
  $$
  \begin{array}{l}
  \mathrm{checkEffectSound}(P) \wedge \mathrm{checkWellScoped}(P) \\
  \quad {}\wedge\ \mathrm{checkMain}(P) \wedge \mathrm{checkWriteSound}(P),
  \end{array}
  $$
  where $\mathrm{checkMain}$ says that `Main` exists and takes no arguments;
- $\mathrm{checkTypes}(P, S, \vec\Gamma)$, the type checker of Chapter 5, run
  with signatures $S$ and a certificate $\vec\Gamma$ of every function's slot
  types;
- $\mathrm{checkControl}(P)$, which holds when
  $\mathrm{brkSafe}_{\bot}(\mathit{fn}.\mathit{body})$ for every function
  $\mathit{fn}$ of $P$.

Each is a computable function, and each has a soundness lemma: Chapter 4's
`checkEffectSound` gives `EffectSound`, Chapter 7's `checkWriteSound` gives
`WriteSound`, `Prog.checkTypes_sound` gives `ProgTyped`. Two we have not met:

**Scoping.** $\mathrm{checkWellScoped}$ verifies that every slot index in a
function's body is below its frame size and every call names an existing
function with the right number of arguments. Under it, evaluation never
raises a slot or call error and never changes the size of a frame:

```{.lean .claim name="Eval.scoped_ok"}
@Eval.scoped_ok : ∀ {P : Prog},
  P.WellScoped →
    ∀ {s : St} {e : Expr} {r : Res} {s' : St},
      Eval P s e r s' → Expr.scoped P s.fr.length e = true →
        r.scopeErr = false ∧ s'.fr.length = s.fr.length
```

`WellScoped` is also exactly what openverse's C loader validates before it
runs a binary, so the C interpreter can use fixed-size frames with no
bounds checks of its own. That the C loader really establishes it, for every
input buffer up to 4 KiB, is a separate machine-checked proof in Rocq (formerly Coq)
(QuickProof's law `loader_wellscoped`).

**Control.** $\mathrm{brkSafe}_{b}(e)$, with $b$ recording whether we are
inside a `loop`, is true when every `break` is inside a `loop` of the same
function body; a `for` body does not count. Then no `break` escapes:

```{.lean .claim name="Runs.no_control"}
@Runs.no_control : ∀ {P : Prog},
  P.checkControl = true → ∀ {r : Res} {out : List Nat},
    Runs P r out → r ≠ Res.err ErrKind.control
```

## The theorem

::: {.theorem title="Accepted programs (`Prog.accepted`)"}
Let $P$ pass $\mathrm{check}$, $\mathrm{checkTypes}$ with signatures $S$, and
$\mathrm{checkControl}$, and let `Main` have type $() \to \tau$. If
$\Runs\ P\ r\ o$, then

1. $r$ is not a slot or call error;
2. $r$ is not a type error;
3. $r$ is not a control error;
4. the final heap is well typed under some $\Xi$, and if $r = \ok{v}$ then
   $\Xi \models v : \tau$;
5. if `Main` is not `<decides>`, then $r \neq \fail$;
6. every run of $P$ has outcome $r$ and output $o$.

So the only runtime errors left are $\err{\mathit{overflow}}$ and
$\err{\mathit{user}}$ (`Err()`).
:::

```{.lean .claim name="Prog.accepted"}
@Prog.accepted : ∀ {P : Prog} {S : Sigs} {Γs : List (List VTy)} {τ : VTy},
  P.check = true →
    P.checkTypes S Γs = true →
      P.checkControl = true →
        S.fns[P.main]? = some ([], τ) →
          ∀ {r : Res} {out : List Nat},
            Runs P r out →
              r.scopeErr = false ∧
                r ≠ Res.err ErrKind.type ∧
                  r ≠ Res.err ErrKind.control ∧
                    (∃ fr heap,
                        Eval P Prog.initSt (Expr.call P.main []) r
                            { fr := fr, g := { out := out, heap := heap } } ∧
                          ∃ Ξ, HeapOK S Ξ heap ∧
                            ∀ (v : Value), r = Res.ok v →
                              hasTy Ξ v τ = true) ∧
                      (∀ (fn : Fn), P.fns[P.main]? = some fn →
                          fn.decides = false → r ≠ Res.fail) ∧
                        ∀ (r' : Res) (out' : List Nat), Runs P r' out' →
                          r' = r ∧ out' = out
```

The statement is a long conjunction, and its proof is short, because each
conjunct is a theorem of an earlier chapter applied to the hypothesis its
check establishes:

```{.lean .excerpt file="OpenVerse/Core/Guarantees.lean"}
  obtain ⟨hs, hf⟩ := Prog.check_ok hc hr
  obtain ⟨hty, hv⟩ := Runs.typed (Prog.checkTypes_sound ht) hm hr
  exact ⟨hs, hty, Runs.no_control hctl hr, hv, hf,
    fun r' out' h' => Runs.det h' hr⟩
```

`Prog.check_ok` packages conjuncts 1 and 5 (scoping and `<decides>`
soundness, from `Eval.scoped_ok` and `Runs.no_fail`), `Runs.typed` gives 2
and 4, `Runs.no_control` gives 3, and `Runs.det` gives 6. The
heap-effect theorem of Chapter 7 is stated separately as
`Prog.accepted_no_writes`, because it is about individual calls rather than
whole runs.

## Why the front end need not be trusted

The front end runs `Prog.check`, `Prog.checkTypes` and `Prog.checkControl`
on its own output, and refuses to emit or run a program that fails them.
So for every program it accepts, the hypotheses of `Prog.accepted` hold *by
computation*, whatever bugs the elaborator has. A bug can show up in only two
ways:

- **The front end rejects a correct program.** An elaborator that emits
  ill-typed Core is caught by its own checker. This is an inconvenience,
  not a broken promise. (openverse's error messages name the function that
  failed `checkTypes` precisely so that such bugs can be found.)
- **The front end emits a program that means something else.** If the
  elaborator translated `X + 1` as `X + 2`, the result would still be
  checked, typed, deterministic and safe: just wrong. `Prog.accepted` does
  not say that the Core program is *the* meaning of the surface program; it
  says that whatever the meaning is, it is well behaved. Faithfulness of the
  elaboration is tested, against the Book of Verse and the test suite, not
  proved.

This is the general bargain of translation validation, and it is a good one:
the checkers are small and proved, the translator is large and free to
change.

## The remaining errors, and the seam to C

Overflow and `Err()` remain, by design. `Err()` is a program asking to stop.
Overflow is the reading openverse takes for `int`: 64-bit, with overflow an
error rather than a wrap-around or a failure. Neither is caught by a failure
context. The integer division family shows the fine print:

```{.verse .run exit="2"}
Main():void =
    Low:int = -9223372036854775807 - 1
    if (M := Mod[Low, -1]) { Print("Mod[Low, -1] = {M}") }
    if (Q := Quotient[Low, -1]) { Print("Quotient = {Q}") }
```

```{.output}
Mod[Low, -1] = 0
```

The remainder of $-2^{63}$ by $-1$ is $0$, representable; the quotient is
$2^{63}$, which is not, so `Quotient` raises an overflow error. The `if` does
not catch it, the program stops with exit code 2, and only the first line
was printed. Lean states this corner exactly:

```{.lean .claim name="apply_min_neg_one"}
apply_min_neg_one :
  Prim.floorDiv.apply [Value.int Int64.minV, Value.int (-1)] =
    Res.err ErrKind.overflow ∧
  Prim.ceilDiv.apply [Value.int Int64.minV, Value.int (-1)] =
      Res.err ErrKind.overflow ∧
    Prim.quotient.apply [Value.int Int64.minV, Value.int (-1)] =
        Res.err ErrKind.overflow ∧
      Prim.modulo.apply [Value.int Int64.minV, Value.int (-1)] =
        Res.ok (Value.int 0)
```

This theorem sits on a **seam**. openverse's C runtime implements the integer
operations in C, and a separate proof, in Rocq with the QuickProof tool under
CompCert's semantics of C, shows that each C function computes a reference
formula written with C99's truncating `/` and `%`. `Seams.lean` restates each
formula in Lean, symbol for symbol, and proves that it *is* the Lean
semantics of the primitive:

```{.lean .claim name="apply_floorDiv"}
@apply_floorDiv : ∀ {a b : Int},
  b ≠ 0 →
    Prim.floorDiv.apply [Value.int a, Value.int b] = Res.ofInt (cFloorDiv a b)
```

where `cFloorDiv a b` is "truncate, then subtract one if the remainder is
non-zero and its sign differs from the divisor's". The two proofs meet at
the formula; the one step no tool checks is that the C text and the Lean
text are the same formula, and openverse prints them side by side
(`docs/SEAMS.md`) for a human to compare. Here is the semantics they agree
on, for negative operands:

```{.verse .run}
Main():void =
    if (A := Floor(-7 / 2), B := Ceil(-7 / 2),
        Q := Quotient[-7, 2], M := Mod[-7, 2]):
        Print("Floor {A}, Ceil {B}, Quotient {Q}, Mod {M}")
    if (Q := Quotient[7, -2], M := Mod[7, -2]):
        Print("Quotient {Q}, Mod {M}")
    if (not Mod[1, 0]) { Print("Mod by zero fails") }
```

```{.output}
Floor -4, Ceil -3, Quotient -4, Mod 1
Quotient -3, Mod 1
Mod by zero fails
```

`Quotient` and `Mod` are Euclidean: the remainder is never negative, and
$a = b \cdot \mathrm{Quotient}[a, b] + \mathrm{Mod}[a, b]$.

## The whole argument

Put together, the chain from a Verse source file to a guarantee about the
bytes the C runtime prints has these links:

| Link | Evidence |
|---|---|
| surface Verse $\to$ Verse Core | front end: unverified, tested; output checked |
| checks $\Rightarrow$ hypotheses | Lean: `checkEffectSound_ok`, `checkTypes_sound`, … |
| hypotheses $\Rightarrow$ guarantees | Lean: Chapters 2–7, combined in `Prog.accepted` |
| relation $=$ reference interpreter | Lean: `eval_iff` (Chapter 1) |
| Verse Core $\to$ binary (OVBC, `Prog.encode`) | unverified; covered by differential testing |
| OVBC $\to$ C loader | loader proved (QuickProof, Rocq) to accept only `WellScoped` programs |
| reference interpreter $\approx$ C interpreter | differential testing and fuzzing, under sanitizers; not proved |
| C arithmetic $=$ `Prim.apply` | QuickProof law `arith_exact` + `Seams.lean`, meeting at a formula read by a human |
| C rollback store | QuickProof law `store_rollback_model`, against a naive snapshot model, bounded |

What is trusted is Lean's kernel, the statement of the semantics
(`Semantics.lean`, `Prims.lean`), QuickProof's own trusted base for the C
proofs (Rocq, VST, CompCert's C semantics), the reading of each seam, and the
gap between CompCert's C and the compiler that builds the runtime. That is
not nothing, but every item is named, and none of them is five thousand
lines of elaborator.

## Limits and readings

- **Divergence** is outside every theorem (Chapter 1): `Runs` describes
  finished runs. openverse reports running out of fuel, recursion depth or
  memory as a resource limit (exit 3).
- **The C interpreter is not proved.** It is a transcription of the Lean
  interpreter, tested against it on every test program and on random ones.
  Its slot-and-output rollback store (`store.c`), its loader and its
  integer arithmetic are proved, with bounds stated in their laws; its
  object store and its value heap are not.
- **Meaning is a definition.** All of this is relative to the semantics as
  defined, and that the definition is Verse, as the Book of Verse describes
  it, is a matter of reading, documented in openverse's `docs/LANGUAGE.md`.

::: {.exercise title="Exercises"}
1. List, for each conjunct of `Prog.accepted`, the chapter and the theorem it
   comes from, and the check that establishes that theorem's hypothesis.
2. `Runs.no_control` needs `checkControl`, but the front end also rejects
   `break` in a `for` body with a message. Why is the Lean check still
   needed? What would a bug in the front end's own check lead to without
   it?
   ```{.verse .reject expect="break is only allowed inside loop"}
   Main():void =
       for (X := 1..3) { break }
   ```
3. Give a Verse Core program, not produced by the front end, that passes
   `Prog.check` but raises a type error. Which check rejects it?
4. Prove $a = b \cdot \mathrm{Quotient}[a, b] + \mathrm{Mod}[a, b]$ and
   $0 \leq \mathrm{Mod}[a, b] < |b|$ for $b \neq 0$, from the definitions
   $\mathrm{Quotient} = \lfloor\cdot\rfloor$-or-$\lceil\cdot\rceil$ by the sign
   of $b$. Then check `Mod[-7, -2]` with openverse.
5. (*) Translation validation checks outputs, not the translator. Describe
   a check that would make "faithfulness" of the elaboration of `X + 1`
   machine-checkable for each program. What would you have to define first?
:::
