# Checked Once, Correct Everywhere

## An opening problem

A generic function is written once and used at many types:

```{.verse .run}
Find(Items:[]t, Target:t where t:subtype(comparable))<decides>:int =
    var Result:int = -1
    for (I -> X : Items, X = Target, Result < 0):
        set Result = I
    Result >= 0
    Result

Main():void =
    if (I := Find[array{"map", "key", "gem"}, "gem"]) { Print("gem at {I}") }
    if (J := Find[array{3, 1, 4}, 4]) { Print("4 at {J}") }
    if (not Find[array{3, 1, 4}, 9]) { Print("no 9") }
```

```{.output}
gem at 2
4 at 2
no 9
```

`Find` is used at `string` and at `int`. There are two classical ways to
make such code safe. A *template* system (C++) type-checks each
instantiation separately, after substituting the type: errors appear at use
sites, and code is duplicated. A *parametric* system (ML, Haskell, Java
generics) checks the definition once, with `t` opaque, and guarantees that
every instantiation is then fine. Verse is parametric: the body of `Find` is
checked once, and operations not valid for every `t` are rejected even if
`Find` is never called.

For a programmer, this means a library function that compiles cannot break
at a new type. For a logician, it is a statement about a typing judgment
under substitution, the *substitution lemma*, one of the workhorses of type
theory. openverse proves it for Verse Core, and its proof of type safety
uses it at every call.

## Type variables and substitutions

A generic function's types may mention **type variables** $\alpha_0,
\alpha_1, \ldots$ (`VTy.var j`): its $j$-th type parameter. A
**substitution** $\theta : \mathbb{N} \to \mathrm{VTy}$ replaces each
variable by a type, and acts on types homomorphically:

$$
\theta(\alpha_j) = \theta\,j, \qquad
\theta([\,]\tau) = [\,]\theta(\tau), \qquad
\theta(\mathit{tuple}(\vec\tau)) = \mathit{tuple}(\theta\vec\tau), \qquad
\theta(\mathit{int}) = \mathit{int}, \ \ldots
$$

We write $\theta\Gamma$ for the pointwise image of a list of slot types. The
typing rule for calls is where substitutions enter: a call may instantiate
the callee's signature $(\vec{p}, \tau)$ with *any* $\theta$, provided the
arguments have the instantiated parameter types.

$$
\infer[\rulename{T-Call}]{S;\Gamma;\rho \vdash \kw{call}\ f\ \vec{e} : \theta\tau}
      {S.\mathit{fns}_f = (\vec{p}, \tau) & S;\Gamma;\rho \vdash \vec{e} : \theta\vec{p}}
$$

```{.lean .excerpt file="OpenVerse/Core/Typing.lean"}
  /-- A call instantiates the callee's type variables with any `θ`. -/
  | call {f es ps τ} (θ : Nat → VTy) : S.fns[f]? = some (ps, τ) →
      TypedL S Γ ρ es (ps.map (VTy.subst θ)) →
      Typed S Γ ρ (.call f es) (τ.subst θ)
```

No *value* has a type variable as its type: $\Xi \models v : \alpha_j$ is
always false. A value can have a type *mentioning* a variable only where the
variable is not inhabited: the empty array has type $[\,]\alpha_j$, and the
empty option type ${?}\alpha_j$.

## The theorem

::: {.theorem title="The substitution lemma (`Typed.subst`)"}
If the signatures $S$ are closed ($\mathrm{Closed}\ S$: the prototype
objects' type arguments are closed, and so are the types that classes fix
their type arguments to), then for every substitution $\theta$:
$$
S;\Gamma;\rho \vdash e : \tau \ \Longrightarrow\
S;\theta\Gamma;\theta\rho \vdash e : \theta\tau .
$$
:::

```{.lean .claim name="Typed.subst"}
@Typed.subst : ∀ {S : Sigs} {Γ : List VTy} {ρ : VTy},
  S.Closed →
    ∀ (θ : Nat → VTy) {e : Expr} {τ : VTy},
      Typed S Γ ρ e τ →
        Typed S (List.map (VTy.subst θ) Γ) (VTy.subst θ ρ) e (VTy.subst θ τ)
```

The *same expression* $e$ is typed on both sides: nothing is recompiled or
re-elaborated. A typing derivation with variables is a proof schema, and
every instance of the schema is a proof. That is the logical content of
"checked once".

The hypothesis $\mathrm{Closed}$ looks technical, and it is. It has two
halves. $\mathrm{ClosedProtos}$: literals in Verse Core may be references to
the prototype objects that exist before `Main` (Chapter 5), and their types
must not mention variables, or a literal typed at $\alpha_j$-dependent
arguments could not be retyped. $\mathrm{ClosedPins}$: a class may fix its
parent's type arguments, as `int_box := class(box(int))` fixes `box`'s to
`int`; $S$ records these *pins*, and they must be closed types. The front end
always satisfies both.

## The proof

By induction on the typing derivation, mutually with the lemma for lists of
expressions (`TypedL.subst`). Most cases rebuild the same rule from the
induction hypotheses, because the rules are *uniform* in the types: they
never inspect whether a type is a variable. Three cases need a lemma, and
the classes that fix type arguments need an argument of their own.

**Literals.** \rulename{T-Lit} has the premise $\mathrm{hasTy}\ S.\mathit{protos}\
v\ \tau$. We need $\mathrm{hasTy}\ S.\mathit{protos}\ v\ (\theta\tau)$: typing of
values is stable under substitution (`hasTy_subst`). By induction on $v$ and
$\tau$: an integer has type $\mathit{int} = \theta(\mathit{int})$; the empty
array has every array type; a reference's type arguments are a prefix of a
prototype's, which are closed, so $\theta$ does not change them. A variable
itself is never the type of a value, so that case is vacuous.

**Subsumption.** \rulename{T-Sub} has the premise $\tau \leq \tau'$; we need
$\theta\tau \leq \theta\tau'$. Subtyping is stable under substitution
(`VTy.sub_subst`), by structural recursion on $\tau$ (subtyping is a
Boolean function, `VTy.sub`, not an inductive relation); a variable is below
only itself, and $\theta\alpha_j \leq \theta\alpha_j$ by reflexivity.

**Calls.** The derivation ends in \rulename{T-Call} with *its own*
substitution $\theta'$: the arguments have types $\theta'\vec{p}$ and the
call has type $\theta'\tau$. The induction hypothesis turns the argument
typings into typings at $\theta(\theta'\vec{p})$. Composition of
substitutions, $\theta \circ \theta' := \lambda j.\ \theta(\theta'\,j)$, satisfies

$$
\theta(\theta'\sigma) = (\theta \circ \theta')\,\sigma \qquad\text{for every type }\sigma
$$

(`VTy.subst_comp`), so the arguments have the types $(\theta\circ\theta')\vec{p}$,
and \rulename{T-Call} with the substitution $\theta\circ\theta'$ gives the call
the type $(\theta\circ\theta')\tau = \theta(\theta'\tau)$, as required:

```{.lean .excerpt file="OpenVerse/Core/TypeSafety.lean"}
  | _, _, .call θ' hs hes => by
    have h := TypedL.subst hS θ hes
    rw [List.map_map] at h
    have h' := Typed.call (fun j => (θ' j).subst θ) hs
      (by rw [← VTy.substL_comp]; simpa [Function.comp_def] using h)
    rwa [← VTy.subst_comp] at h'
```

This case is why the rule \rulename{T-Call} quantifies over *every* $\theta$,
rather than fixing one per call site: the set of typings must be closed under
composition. The class of substitutions being all functions $\mathbb{N} \to
\mathrm{VTy}$ makes it so.

**Pins.** Creating an object requires its type arguments to agree with its
class's pins. The pins are closed, so $\theta$ leaves them alone and the
agreement survives (`VTy.pinsOK_subst`); that is where $\mathrm{ClosedPins}$
is used. The call of an override in a class with pins goes further, and
looks at the types themselves: it is typed under a *refinement*
$\mu$, the most general substitution that makes the receiver's type
arguments agree with the pins (`int` for `box(t)`'s `t`). After $\theta$,
either some $\rho'$ makes the instance agree, so that $\rho' \circ \theta$
makes the original arguments agree and therefore factors through the most
general one, $(\rho' \circ \theta) \circ \mu = \rho' \circ \theta$
(`PinRefines.factor`), which carries the typing over to the instance's own
refinement; or none does, and the call is typed as unreachable
(`Typed.dispatch_none`), as it then is at every instance.

## How type safety uses it

The proof of `Eval.typed` (Chapter 5) reaches a call of a generic function
$f$ at instance $\theta$. The callee's body was typed once, generically,
with slot types $\Gamma_f$ and result type $\rho_f$ mentioning variables. The
substitution lemma retypes it with $\theta\Gamma_f$ and $\theta\rho_f$. The
new frame holds the actual arguments and `void` in the other slots; after
the body's initialization prefix has run (`eval_initPrefixE`), it satisfies
$\theta\Gamma_f$, and the induction hypothesis applies to the rest of the
body at the instance. No step of the
proof ever looks inside a type variable.

There is one more obstacle, and it is a design problem rather than a proof
problem. Every slot of a Verse Core frame must hold a value of its type from
the start (`FrameOK`), and the elaborator initializes local slots before the
body runs. But a slot of type $\alpha_j$ has no default value: there is no
value of an unknown type. openverse's solution is to pass **one hidden
argument per type parameter**, a value of that type, chosen by the caller,
and initialize such slots from it. For

```{.verse .run}
Keep(X:t where t:type):t =
    var Y:t = X
    Y

Main():void =
    A := Keep(5)
    Print("{A}")
```

```{.output}
5
```

`openverse core` shows that `Keep` has arity 2, and that the call is
$\kw{call}\ 1\ [\kw{lit}\ 5,\ \kw{lit}\ 0]$: the second argument, $0$, is the
witness for $t = \mathit{int}$. The body begins with
$\kw{assign}\ 2\ (\kw{local}\ 1)$, initializing `Y`'s slot from the witness,
before the user's $\kw{assign}\ 2\ (\kw{local}\ 0)$. The witness is never
observed: Verse code assigns every variable before reading it. The typing
rules allow exactly such initializers (`DefaultE`: a literal, a parameter, a
tuple of these, or a new object), and the semantics needs no change at all:
hidden arguments are ordinary arguments.

## In code

Parametric structs work the same way. `pair(t, u)` is a family of struct
types, and `Swap` is checked once:

```{.verse .run}
pair(t:type, u:type) := struct:
    First:t
    Second:u

Swap(P:pair(t, u) where t:type, u:type):pair(u, t) =
    pair(u, t){First := P.Second, Second := P.First}

Main():void =
    P := pair(int, string){First := 7, Second := "seven"}
    Q := Swap(P)
    Print("{Q.First} is {Q.Second}")
```

```{.output}
seven is 7
```

Checking once means rejecting operations that are not valid at *every*
type, even when every actual use would be fine:

```{.verse .reject expect="no operator '+' for t and t"}
Twice(X:t where t:type):t = X + X

Main():void = Print("{Twice(2)}")
```

Equality is available only under the constraint `t:subtype(comparable)`,
which restricts the instances to types with a decidable equality:

```{.verse .reject expect="an operand of '=' must be comparable"}
Same(A:t, B:t where t:type)<decides>:void = A = B

Main():void = Print("unused")
```

Because a generic function is a single Verse Core function, it can call
itself at a *larger* type, which template expansion cannot do (it would
generate infinitely many instances). Here `Depth` calls itself at
`tuple(t, t)`:

```{.verse .run}
Depth(X:t, N:int where t:type):int =
    if (N <= 0) then 0 else 1 + Depth((X, X), N - 1)

Main():void = Print("{Depth(1, 5)}")
```

```{.output}
5
```

The fifth recursive call has `t` $=$ a tuple nested five deep. Each call
instantiates \rulename{T-Call} with a different $\theta$; the substitution
lemma does not care.

Classes can be parametric too, and a class may fix its parent's type
argument and override the parent's methods at that type. This is where the
pins of the theorem come from:

```{.verse .run}
box(t:type) := class:
    V:t
    Get():t = V

int_box := class(box(int)):
    Get<override>():int = V + 1

GetAny(B:box(t) where t:type):t = B.Get()

Main():void =
    Print("{GetAny(box(int){V := 41})}")
    Print("{GetAny(int_box{V := 41})}")
    Print(GetAny(box(string){V := "s"}))
```

```{.output}
41
42
s
```

`GetAny` is checked once, with `t` opaque, yet on an `int_box` it runs
`int_box`'s `Get`, whose body `V + 1` makes sense only at `int`. Verse Core
has no method tables: the call tests the receiver's class tag, one
$\mathit{isTag}$ per class, and calls the matching implementation
(`openverse core` shows the chain). The branch that calls `int_box`'s `Get`,
which returns an `int` where `GetAny` promises a `t`, is typed under the
refinement $\mu = [t \mapsto \mathit{int}]$, the most general substitution
that agrees with the pin. At the instance $t = \mathit{string}$ no
substitution agrees with it, and the branch is typed as unreachable
(`Typed.dispatch_none`). It is: a `box(string)` is never an `int_box`,
because an object's type arguments must agree with its class's pins.

The refinement binds variables to closed types and nothing else. A class
that repeats an argument, `dup(t) := class(pair(t, t))`, would need a
refinement that makes two variables equal, and its overrides are refused:

```{.verse .reject expect="so it cannot override Get"}
pair(t:type, u:type) := class:
    A:t
    B:u
    Get():t = A

dup(t:type) := class(pair(t, t)):
    Get<override>():t = B

Main():void = Print("unused")
```

## Limits and readings

- **The lemma is about typing, not about behavior.** It does not say that a
  generic function *behaves* uniformly at all types (Reynolds'
  parametricity, the "theorems for free"). openverse's hidden witnesses are
  never observed, so uniform behavior is plausible, but it is not a theorem
  here.
- **Inference is unverified.** The front end infers each call's type
  arguments by first-order matching against the expected result type and
  then the arguments (`docs/LANGUAGE.md`). It need not be complete or even
  correct: the checker re-checks each call against the instantiated
  signature, and only that check is part of the trusted argument.
- **Restrictions of the subset**: no named parameters, generic `Main`, or
  explicit type arguments for generic functions; several constraints on one
  type parameter are not supported (nor, at the time of writing, in the Book).
  A class may override only where it fixes type arguments to closed types:
  not where it repeats them, as `dup` does, or adds type parameters of its own.

::: {.exercise title="Exercises"}
1. Prove `VTy.subst_comp`, $\theta(\theta'\sigma) = (\theta\circ\theta')\sigma$,
   by induction on $\sigma$. Which case uses the definition of $\circ$?
2. Show by an example why the lemma needs $\mathrm{ClosedProtos}$: give a
   prototype with an open type argument and a literal whose typing does not
   survive a substitution.
3. Where in the proof of `Eval.typed` would *monomorphization* (copying each
   generic function once per instance) replace the substitution lemma? What
   does it cost, and why can it not handle `Depth`?
4. The identity substitution is $\lambda j.\ \alpha_j$ (`VTy.var`). Prove that
   it acts as the identity on types (`VTy.subst_id`), and use it to derive
   the non-generic case of \rulename{T-Call} from the generic one.
5. Predict whether the front end accepts this function, then check:
   ```{.verse .check}
   Second(Items:[]t, Fallback:t where t:type):t =
       if (X := Items[1]) then X else Fallback

   Main():void = Print(Second(array{"a", "b"}, "none"))
   ```
6. Give `GetAny` the receiver type `box(string)` in place of `box(t)` and read
   `openverse core`: which class has no $\mathit{isTag}$ test any more? Why may
   the front end leave it out, and which rule would type its branch if it
   were there?
7. (*) State Reynolds' parametricity for a function of type
   $\forall\alpha.\ \alpha \to \alpha$ in Verse Core, and explain what the
   hidden witness argument would have to satisfy for it to hold.
:::
