# Again and Again

A treasure map rarely says "dig here". It says "count ten paces, then ten
more, and check under every stone". Doing something again and again is what
computers are best at. Verse has three ways to repeat: `for`, `loop`, and
recipes that use themselves.

::: qa
What does this print?

```{.verse .run}
Main():void =
    Gems := array{"ruby", "opal", "jade"}
    for (Gem : Gems):
        Print("found: {Gem}")
```

> ```{.output}
> found: ruby
> found: opal
> found: jade
> ```

What does `for (Gem : Gems)` say?

> "For each element of `Gems`, call it `Gem`, and run the body."

In what order?

> From the first element to the last.

What does this print?

```{.verse .run}
Main():void =
    for (N := 1..4) { Print("{N}") }
```

> ```{.output}
> 1
> 2
> 3
> 4
> ```

What is `1..4`?

> A *range*: the numbers from `1` to `4`, both included.

Does a `for` give back a value?

```{.verse .run}
Main():void =
    Doubled := for (N : array{1, 2, 3}):
        N * 2
    Print("{Doubled.Length} values")
    if (Last := Doubled[2]):
        Print("last is {Last}")
```

> ```{.output}
> 3 values
> last is 6
> ```

What is `Doubled`?

> The array of the body's values: `array{2, 4, 6}`.

Can a `for` skip some elements?

```{.verse .run}
Main():void =
    Evens := for (N := 1..10, Mod[N, 2] = 0):
        N
    Print("{Evens.Length} even numbers")
```

> ```{.output}
> 5 even numbers
> ```

What is `Mod[N, 2] = 0` doing in there?

> It is a *filter*. When it fails, that `N` is skipped.

So the parentheses of a `for` are a failure context?

> Yes, like those of an `if`. A failure there just means "not this one".

What does this print?

```{.verse .run}
Main():void =
    Lucky := for (X := 1..20, Mod[X, 7] = 0):
        X * X
    for (L : Lucky) { Print("{L}") }
```

> ```{.output}
> 49
> 196
> ```

Why only two?

> Only `7` and `14` pass the filter, and the body squares them.

Can we know where each element is?

```{.verse .run}
Main():void =
    for (I -> Gem : array{"ruby", "opal"}):
        Print("{I}: {Gem}")
```

> ```{.output}
> 0: ruby
> 1: opal
> ```

What does `I -> Gem` say?

> Call the position `I` and the element `Gem`.

Can a `for` have two ranges?

```{.verse .run}
Main():void =
    for (Row := 1..2, Col := 1..3):
        Print("{Row},{Col}")
```

> ```{.output}
> 1,1
> 1,2
> 1,3
> 2,1
> 2,2
> 2,3
> ```

Which one changes faster?

> The last one, `Col`. For each `Row`, every `Col`.

How many times did the body run?

> Two times three: six.

Does a `for` like this always print in the same order?

> Always. Verse does not guess or shuffle: one program, one answer.

Can a name have several values at once?

```{.verse .run}
Main():void =
    for (Gem := 1 | 5 | 10):
        Print("a gem worth {Gem}")
```

> ```{.output}
> a gem worth 1
> a gem worth 5
> a gem worth 10
> ```
>
> Yes. `1 | 5 | 10` is a *choice*: one value, then the next. A `for` takes them all, left to right.

Will every Verse understand `|`?

> Not yet. Choice comes from the Verse Calculus, the paper that describes Verse's core, and the Book of Verse does not describe it yet. openverse has it already.

And two choices?

```{.verse .run}
Main():void =
    for (X := 1 | 2, Y := 10 | 20):
        Print("{X + Y}")
```

> ```{.output}
> 11
> 21
> 12
> 22
> ```
>
> Just like two ranges: the last one changes faster.

What does an `if` do with a choice?

```{.verse .run}
Main():void =
    if (Gem := 1 | 5 | 10, Gem > 3):
        Print("we keep {Gem}")
```

> ```{.output}
> we keep 5
> ```
>
> It takes the first value that makes its whole condition succeed. `1` fails `Gem > 3`, `5` passes, and `10` is never tried.

And if no value passes?

```{.verse .run}
Main():void =
    if (Gem := 1 | 2, Gem > 3):
        Print("we keep {Gem}")
    else:
        Print("none worth keeping")
```

> ```{.output}
> none worth keeping
> ```
>
> Then the condition fails, as any failed guess does.

Does a value that failed leave a trace?

```{.verse .run}
Main():void =
    var Tried:int = 0
    if (G := 1 | 5, set Tried += 1, G > 3):
        Print("{G}, Tried = {Tried}")
```

> ```{.output}
> 5, Tried = 1
> ```
>
> No. The try with `1` failed, so it was taken back. Only the try with `5` counts.

Can a recipe give several values?

```{.verse .run}
Gems():int = 1 | 5 | 10

Main():void =
    for (G := Gems(), G > 3):
        Print("a gem worth {G}")
```

> ```{.output}
> a gem worth 5
> a gem worth 10
> ```
>
> Yes. Its body is a choice, so a call of it is a choice too, and a `for` takes each value it gives.
:::

::: {.rule title="The Rule of For"}
A `for` visits each choice in order, skips the ones whose filters fail,
and gives back the array of its body's values.
:::

::: {.rule title="The Rule of Choices"}
A choice `a | b` has `a`'s values, then `b`'s, and so does a call of a
recipe whose body is one. A `for` takes every one; an `if` takes the
first that makes its condition succeed, and takes back the tries that
failed.
:::

::: qa
What if we do not know how many times to repeat?

> We use `loop`, and `break` when we are done.

What does this print?

```{.verse .run}
Main():void =
    var N:int = 1
    loop:
        set N *= 2
        if (N > 50) then break
    Print("{N}")
```

> ```{.output}
> 64
> ```

How many times did the body run?

> Six: `2`, `4`, `8`, `16`, `32`, `64`. Then `N > 50` held, and `break` left the loop.

What happens if we forget the `break`?

> The loop never ends. Be careful with `loop`.

Can we `break` out of a `for`?

```{.verse .reject expect="break is only allowed inside loop"}
Main():void =
    for (X := 1..3) { break }
```

> No. `break` belongs to `loop`. A `for` ends by itself.

Then how do we stop early in a `for`?

```{.verse .run}
FirstBig(A:[]int):int =
    for (X : A, X > 10) { return X }
    0

Main():void =
    Print("{FirstBig(array{3, 14, 25})}")
    Print("{FirstBig(array{1, 2})}")
```

> ```{.output}
> 14
> 0
> ```

What does `return X` do?

> It leaves the whole recipe at once, giving back `X`.

Why `0` the second time?

> No element passed the filter, so the `for` finished, and the last line, `0`, was the answer.
:::

::: {.rule title="The Rule of Loop"}
A `loop` repeats until a `break` (or a `return`) leaves it. A `for` needs
neither: it stops when it runs out of choices.
:::

::: qa
Can a recipe use itself?

```{.verse .run}
Countdown(N:int):void =
    if (N > 0):
        Print("{N}")
        Countdown(N - 1)
    else:
        Print("liftoff!")

Main():void = Countdown(3)
```

> ```{.output}
> 3
> 2
> 1
> liftoff!
> ```

What is that called?

> *Recursion*: a recipe that calls itself on a smaller problem.

What stops it?

> When `N > 0` fails, the `else` does not call `Countdown` again.

What does every recursive recipe need?

> A question that, sooner or later, stops it.

What is `Fact(4)` for this recipe?

```{.verse .run}
Fact(N:int):int =
    if (N <= 1) then 1 else N * Fact(N - 1)

Main():void = Print("{Fact(4)}")
```

> ```{.output}
> 24
> ```

How?

> `4 * Fact(3)`, which is `4 * 3 * Fact(2)`, which is `4 * 3 * 2 * 1`.

Can recursion walk through an array?

```{.verse .run}
Sum(A:[]int, I:int):int =
    if (X := A[I]):
        X + Sum(A, I + 1)
    else:
        0

Main():void =
    Print("{Sum(array{5, 10, 20}, 0)}")
```

> ```{.output}
> 35
> ```

What stops `Sum`?

> `A[I]` fails when `I` is past the end. Failure is the stopping question!

Could we have written `Sum` with a `for`?

```{.verse .run}
Sum(A:[]int):int =
    var Total:int = 0
    for (X : A) { set Total += X }
    Total

Main():void =
    Print("{Sum(array{5, 10, 20})}")
```

> ```{.output}
> 35
> ```

Which way is better?

> Whichever you find easier to read. Both give one answer.

Can a recipe that calls itself give endless values?

```{.verse .run}
From(N:int):int = N | From(N + 1)

Main():void =
    if (X := From(1), X * X > 50):
        Print("{X} squared is over 50")
```

> ```{.output}
> 8 squared is over 50
> ```
>
> Yes: `1`, then `2`, then `3`, and on without end. Nothing in `From` stops it. The `if` does: it asks for one value at a time and stops at the first that passes.
:::

::: {.rule title="The Rule of Recursion"}
A recipe may call itself, if each call is on a smaller problem and some
question finally stops it. In Verse, a failure is often that question.
A recipe whose choice calls itself may go on forever: whoever asks for
its values stops it.
:::

We can now search through any array. But what do we do when a search might
find *nothing*? We need a box that may be empty. That is the next chapter.
