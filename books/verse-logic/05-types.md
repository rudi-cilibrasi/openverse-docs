# Well-Typed Programs Do Not Go Wrong

## An opening problem

A value of a subclass can stand wherever its superclass is expected, and
so can an array of them:

```{.verse .run}
shape := class<abstract>:
    Area():int

square := class(shape):
    Side:int
    Area<override>():int = Side * Side

rect := class(shape):
    W:int
    H:int
    Area<override>():int = W * H

Total(Shapes:[]shape):int =
    var Sum:int = 0
    for (S : Shapes) { set Sum += S.Area() }
    Sum

Main():void =
    Squares:[]square = array{square{Side := 2}, square{Side := 3}}
    Print("{Total(Squares)}")
    Mixed:[]shape = array{square{Side := 1}, rect{W := 2, H := 5}}
    Print("{Total(Mixed)}")
    for (S : Mixed, Sq := square[S]) { Print("a square of side {Sq.Side}") }
```

```{.output}
13
11
a square of side 1
```

`Total` expects a `[]shape` and receives a `[]square`, with no conversion at
run time. The last line *casts* each shape to `square`; the cast fails for the
rectangle, and the `for` clause skips it. Is this safe? In Java, array
covariance is famously unsound: storing a `rect` into a `square[]` seen as a
`shape[]` fails only at run time, with an `ArrayStoreException`. Here, does
any typed program ever apply an operation to a value of the wrong shape?

Milner's slogan, "well-typed programs do not go wrong", is a theorem about a
particular language. This chapter states and proves it for Verse Core, with
classes, subtyping, a heap and generic functions, and explains why Verse's
covariant arrays are sound where Java's are not.

## Types, values, heaps

Verse Core types are

$$
\tau \ ::=\ \mathit{int} \mid \mathit{logic} \mid \mathit{char} \mid \mathit{float} \mid [\,]\tau \mid
\mathit{tuple}(\tau_1, \ldots, \tau_n) \mid {?}\tau \mid \alpha_j \mid
\mathit{ref}\ C\ \vec{\tau}
$$

where `void` is the empty tuple, `string` is $[\,]\mathit{char}$, $\alpha_j$
is the $j$-th type parameter of a generic function (Chapter 6), and
$\mathit{ref}\ C\ \vec{\tau}$ is a reference to an object whose class is one of
the set $C$ of class tags, with type arguments $\vec{\tau}$. A surface class
type such as `shape` elaborates to the set of the *concrete* classes at or
below it, so `shape` is $\mathit{ref}\ \{\mathit{square}, \mathit{rect}\}\ []$
(a tag is a class's index in definition order).

**Subtyping** $\tau \leq \tau'$ is a decidable relation (`VTy.sub`):
references are ordered by inclusion of class sets (and prefixes of type
arguments), arrays, options and tuples are covariant, and otherwise a type
is below only itself.

$$
\frac{C \subseteq C' \quad \vec{\tau'} \text{ prefix of } \vec{\tau}}{\mathit{ref}\ C\ \vec{\tau} \leq \mathit{ref}\ C'\ \vec{\tau'}}
\qquad
\frac{\tau \leq \tau'}{[\,]\tau \leq [\,]\tau'}
\qquad
\frac{\tau \leq \tau'}{{?}\tau \leq {?}\tau'}
$$

**Values are typed relative to a heap typing** $\Xi$, a list assigning each
heap address a class tag and type arguments. We write
$\Xi \models v : \tau$ for `hasTy Ξ v τ = true`. Integers have type
$\mathit{int}$, an array has type $[\,]\tau$ when all its elements have type
$\tau$, and a reference $\kw{ref}\ a$ has type $\mathit{ref}\ C\ \vec{\tau}$
when $\Xi(a)$ is a class in $C$ whose type arguments extend $\vec{\tau}$:

```{.lean .excerpt file="OpenVerse/Core/Typing.lean"}
def hasTy (Ξ : HeapTy) : Value → VTy → Bool
  | .int _, .int => true
  | .logic _, .logic => true
  | .char c, .char => decide (c < 256)
  | .float _, .float => true
  | .arr vs, .arr t => allTy Ξ vs.toList t
...
  | .ref a, .ref ts args => match Ξ[a]? with
    | some (t, args') => ts.contains t && args.isPrefixOf args'
    | none => false
  | _, _ => false
```

A heap $h$ is **well typed** under $\Xi$, written $\mathrm{HeapOK}\ S\ \Xi\ h$,
when $\Xi$ has one entry per object, and each object's fields have the types
that its class declares in the signature $S$, instantiated at its type
arguments. A frame is well typed, $\mathrm{FrameOK}\ \Xi\ \Gamma\ \mathit{fr}$,
when slot $i$ holds a value of type $\Gamma_i$.

## The typing judgment

Expressions are typed by $S;\Gamma;\rho \vdash e : \tau$ (`Typed S Γ ρ e τ`):
in a program with signatures $S$, in a function whose slots have types
$\Gamma$ and whose result type is $\rho$, expression $e$ has type $\tau$. A
selection of the rules:

$$
\infer[\rulename{T-Local}]{S;\Gamma;\rho \vdash \kw{local}\ i : \tau}{\Gamma_i = \tau}
\qquad
\infer[\rulename{T-Sub}]{S;\Gamma;\rho \vdash e : \tau'}{S;\Gamma;\rho \vdash e : \tau & \tau \leq \tau'}
$$

$$
\infer[\rulename{T-Ite}]{S;\Gamma;\rho \vdash \kw{ite}\ c\ t\ e : \tau}
      {S;\Gamma;\rho \vdash c : \sigma & S;\Gamma;\rho \vdash t : \tau & S;\Gamma;\rho \vdash e : \tau}
$$

$$
\infer[\rulename{T-Ret}]{S;\Gamma;\rho \vdash \kw{ret}\ e : \tau}{S;\Gamma;\rho \vdash e : \rho}
\qquad
\infer[\rulename{T-Brk}]{S;\Gamma;\rho \vdash \kw{brk} : \tau}{}
$$

$$
\infer[\rulename{T-Get}]{S;\Gamma;\rho \vdash \kw{heap}\ (\mathit{get}\ k)\ [e] : \tau}
      {S;\Gamma;\rho \vdash e : \mathit{ref}\ C\ \vec{\tau} & \text{field } k \text{ has type } \tau \text{ in every class of } C}
$$

Two features stand out. In \rulename{T-Ite} the condition may have *any* type
$\sigma$: in Verse a condition is not a Boolean, it is anything that may
fail. And `return` and `break` have every type, since they never produce a
value where they stand; $\rho$ records what `return` must deliver.

## The theorem

The outcome of a typed expression is described by a predicate
$\mathrm{ResOK}\ \Xi\ \tau\ \rho\ r$:

```{.lean .excerpt file="OpenVerse/Core/Typing.lean"}
def ResOK (Ξ : HeapTy) (τ ρ : VTy) : Res → Prop
  | .ok v => hasTy Ξ v τ = true
  | .ret v => hasTy Ξ v ρ = true
  | .err k => k ≠ .type
  | .fail => True
  | .brk => True
```

A success has the expression's type; a `return` carries the function's
result type; an error is *not a type error*; failure and `break` are
unconstrained. The third line is where "does not go wrong" lives.

::: {.theorem title="Type safety (`Eval.typed`, `Runs.typed`)"}
Let $P$ be typed with signatures $S$ ($\mathrm{ProgTyped}\ P\ S$). If
$$
\evalj{P}{s}{e}{r}{s'}, \qquad S;\Gamma;\rho \vdash e : \tau,
$$
$$
\mathrm{FrameOK}\ \Xi\ \Gamma\ s.\mathit{fr}, \qquad \mathrm{HeapOK}\ S\ \Xi\ s.\mathit{heap},
$$
then there is a heap typing $\Xi' \sqsupseteq \Xi$ (an extension: $\Xi$ is a prefix of $\Xi'$) with
$$
\mathrm{FrameOK}\ \Xi'\ \Gamma\ s'.\mathit{fr}, \qquad \mathrm{ResOK}\ \Xi'\ \tau\ \rho\ r, \qquad
\mathrm{HeapOK}\ S\ \Xi'\ s'.\mathit{heap}.
$$
For whole programs: if `Main` has type $() \to \tau$, then every run has
$r \neq \err{\mathit{type}}$, ends in a well-typed heap, and a successful run
returns a value of type $\tau$.
:::

```{.lean .claim name="Eval.typed"}
@Eval.typed : ∀ {P : Prog} {S : Sigs},
  ProgTyped P S →
    ∀ {s : St} {e : Expr} {r : Res} {s' : St} {Γ : List VTy} {ρ τ : VTy}
        {Ξ : HeapTy},
      Eval P s e r s' →
        Typed S Γ ρ e τ →
          FrameOK Ξ Γ s.fr →
            HeapOK S Ξ s.g.heap →
              ∃ Ξ', FrameOK Ξ' Γ s'.fr ∧ ResOK Ξ' τ ρ r ∧
                HeapOK S Ξ' s'.g.heap ∧ Ξ <+: Ξ'
```

`Ξ <+: Ξ'` is Lean's notation for "is a prefix of". The theorem is
*preservation* in big-step form, and here it also does the work of
*progress*. In a small-step semantics, progress says a typed term is a value
or can step. In big-step form that is not implied by preservation in
general, because a stuck configuration simply has no derivation. It is in
this semantics because, as Chapter 1 noted, there are no stuck
configurations: every ill-shaped step derives an explicit error, so "goes
wrong" means "derives $\err{\mathit{type}}$", which $\mathrm{ResOK}$ excludes.

```{.lean .claim name="Runs.typed"}
@Runs.typed : ∀ {P : Prog} {S : Sigs},
  ProgTyped P S →
    ∀ {τ : VTy} {r : Res} {out : List Nat},
      S.fns[P.main]? = some ([], τ) →
        Runs P r out →
          r ≠ Res.err ErrKind.type ∧
            ∃ fr heap,
              Eval P Prog.initSt (Expr.call P.main []) r
                  { fr := fr, g := { out := out, heap := heap } } ∧
                ∃ Ξ, HeapOK S Ξ heap ∧
                  ∀ (v : Value), r = Res.ok v → hasTy Ξ v τ = true
```

Supporting it is the soundness of subsumption:

```{.lean .claim name="hasTy_sub"}
@hasTy_sub : ∀ {Ξ : HeapTy} (t u : VTy) (v : Value),
  t.sub u = true → hasTy Ξ v t = true → hasTy Ξ v u = true
```

## The proof

**Subsumption is sound** (`hasTy_sub`), by induction on $t$. For references:
if $\Xi(a) \in C$ and $C \subseteq C'$ then $\Xi(a) \in C'$, and a prefix of a
prefix is a prefix. For arrays: if every element has type $\tau$ and
$\tau \leq \tau'$, every element has type $\tau'$ by the induction hypothesis.
This is the whole reason covariant arrays are sound in Verse: a Verse array
is an immutable *value*. `set A[i] = x` does not write into a shared array;
it builds a new array and assigns it to the variable `A`, whose declared type
$\Gamma_A$ the assignment rule checks $x$ against. Java's unsoundness needs an
array *object* that two variables of different static types share; Verse
has no such thing. (Objects are shared, and their fields are typed
invariantly: `set` on a field checks the field's declared type.)

**Preservation.** openverse does not prove `Eval.typed` by induction on the
derivation but, as in Chapter 2, through the interpreter: by strong
induction on the *fuel*, for the statement "if `eval P n s e = some (r, s')`
and the hypotheses hold, then the conclusion holds", and then transports the
result to `Eval` with `eval_iff`. The reason is the call case. A callee's
body is an initialization prefix followed by the user's code $b$; the
frame satisfies $\Gamma$ only *after* the prefix has run, so the induction
hypothesis is needed for $b$ evaluated from that later state, at whatever
smaller fuel remains (`eval_initPrefixE`). That evaluation is not a
subderivation of anything in hand, so structural induction on derivations
does not reach it, while strong induction on fuel does. The ingredients:

1. **Inversion up to subsumption.** A typing derivation may end with any
   number of \rulename{T-Sub} steps. The proof peels them off: if
   $e : \tau$ then $e : \tau_0$ by a non-subsumption rule, for some
   $\tau_0 \leq \tau$; it proves the conclusion at $\tau_0$, then lifts it
   with `hasTy_sub` (`ResOK_sub`).
2. **Heap typings only grow.** Allocation appends an object, and the proof
   appends its class and type arguments to $\Xi$. A field write replaces a
   field with a value of the field's type, leaving $\Xi$ unchanged. Values
   typed under $\Xi$ remain typed under any extension (`hasTy_mono`), which
   is why the conclusion is stated with $\Xi \sqsubseteq \Xi'$.
3. **Primitives are type safe** (`prim_typed`): a primitive applied to values
   of its argument types returns $\mathrm{ResOK}$ of its result type. This is
   a finite case analysis over the primitive table.
4. **Calls** instantiate the callee's signature with a substitution $\theta$
   for its type parameters (Chapter 6), and the callee's body is typed with
   its own $\Gamma$, which the new frame satisfies because the arguments
   have the parameter types and the other slots are initialized first (the
   elaborator emits an initialization prefix; `initPrefixE`).
5. **Rollback is harmless.** In \rulename{Ite-Fail} the `else` branch runs
   from the original state $s$, typed under the original $\Xi$; whatever
   $\Xi$ the failed condition reached is discarded with its state.

`Runs.typed` instantiates preservation at the call of `Main`, from the
initial state, whose frame and heap are empty. When the program has
classes, there is one more step. Class-typed variables start as *prototype*
objects (one per non-parametric concrete class), so the Verse Core `Main` is
a prelude that allocates the prototypes and then calls the user's `Main`.
`Runs.typed` evaluates the prelude (`Eval.of_protoPrelude`) and applies
preservation to that inner call, from the heap of prototypes, which
$\mathrm{ProgTyped}$ requires to be well typed (`PreludeOK`).

**The type checker is sound.** Where does $\mathrm{ProgTyped}\ P\ S$ come
from? openverse runs a bidirectional type checker, `tc`, on every program the
front end emits, together with a certificate of each function's slot types.
`tc` either returns a type or fails, and `tc_sound` proves that a returned
type is derivable:

```{.lean .claim name="tc_sound"}
@tc_sound : ∀ {S : Sigs} {Γ : List VTy} {ρ : VTy} {e : Expr} {m : Option VTy}
    {τ : VTy},
  tc S Γ ρ e m = some τ → Typed S Γ ρ e τ
```

`m` is the optional *expected* type that bidirectional checking pushes down.
A corollary, `Prog.checkTypes_sound`, lifts the result to whole programs. Only soundness is
proved: a correct program that `tc` cannot type is rejected, which is safe.

## In code

The front end reports type errors before anything runs:

```{.verse .reject expect="expected int, found string"}
Main():void =
    X:int = "five"
```

Options are not their contents; a `?string` must be taken apart in a
failure context:

```{.verse .reject expect="expected int, found ?string"}
Main():void =
    Name:?string = option{"Ada"}
    N:int = Name
```

And updating an array element rebuilds the variable's value rather than
writing into a shared array, which is why the array types can be covariant:

```{.verse .run}
Main():void =
    var A:[]int = array{1, 2, 3}
    if (set A[1] = 20) { Print("{A.Length}") }
    if (V := A[1]) { Print("{V}") }
```

```{.output}
3
20
```

(`set A[1] = …` fails when the index is out of range, so it, too, must stand
in a failure context.)

## Limits and readings

- **Type errors are excluded; other errors are not.** Overflow and `Err()`
  remain possible, and so do slot, call and control errors unless the program
  also passes `checkWellScoped` and `checkControl`, which Chapter 8 adds.
- **The trusted part is the statement.** The typing rules and $\mathrm{hasTy}$
  are definitions. That they match Verse's surface type system is the
  elaborator's business, and it is not proved: what is proved is that
  whatever the elaborator emits, if it passes `checkTypes`, does not go
  wrong.
- **Prototypes.** Class-typed slots start as shared prototype objects rather
  than as an uninitialized value. Verse code always assigns such a variable
  before reading it, so the prototypes are never observed; they exist to
  make every slot hold a value of its type from the start.
- **Comparability.** `=` on values of different surface types that coincide
  in Verse Core (an enum and an `int`, say) is rejected by the front end, a
  reading documented in `docs/LANGUAGE.md`; the Core rule types `=` at the
  type of its left operand.

::: {.exercise title="Exercises"}
1. Prove `hasTy_sub` for the option case on paper.
2. Show that the rule \rulename{T-Ite} with a *Boolean* condition would make
   no sense in Verse Core: which Verse Core conditions in this book have type
   `void`? Which have type `int`?
3. Write the case of preservation for $\kw{assign}\ i\ e$. Where is
   `FrameOK` used? Why does the slot write itself not extend the heap typing
   (take $\Xi'$ from the induction hypothesis for $e$, which may allocate)?
4. Java's array store check exists because arrays are mutable and shared.
   Suppose Verse Core gained a primitive $\mathit{arrWrite}$ that mutates an
   array *in place*, visible through every alias. Give a typed program that
   goes wrong, and say which step of the proof breaks.
5. (*) State the fuel-indexed version of preservation: for every $n$, if
   `eval P n s e = some (r, s')` and the hypotheses hold, then … Show that,
   by `eval_iff`, it is equivalent to `Eval.typed`, so it says nothing more
   about diverging programs. Why is it nonetheless the version openverse
   proves first? What would a statement about diverging runs need (for
   example, an interpreter that returns its state when the fuel runs out)?
:::
