# Yes, No, and Fail

Most languages answer questions with `true` or `false`. Verse does something
bolder: a question either *succeeds*, or it *fails*. Failing is not an
error, and it is not `false`. It is a quiet "that did not work", and Verse is
built to listen for it.

::: qa
Is `3 > 2`?

> Yes.

What is the value of `3 > 2` in Verse?

> `3`. A comparison that holds *succeeds*, and gives back its left side.

Is `2 > 3`?

> No.

What is the value of `2 > 3`?

> It has none. It *fails*.

What does it mean to fail?

> To say "no" by giving back nothing at all.

Where can something fail?

> Only where Verse is ready to catch the failure. The easiest place is the parentheses of an `if`.

What does this print?

```{.verse .run}
Main():void =
    Coins := 12
    if (Coins > 10):
        Print("we can buy the map")
```

> ```{.output}
> we can buy the map
> ```

And this?

```{.verse .run}
Main():void =
    Coins := 7
    if (Coins > 10):
        Print("we can buy the map")
    Print("done")
```

> ```{.output}
> done
> ```

Why was the first `Print` skipped?

> `Coins > 10` failed, so the `if` did not run its body.

Can an `if` do something else when it fails?

```{.verse .run}
Main():void =
    Coins := 7
    if (Coins > 10):
        Print("we can buy the map")
    else:
        Print("we need more coins")
```

> ```{.output}
> we need more coins
> ```

Can we write the same thing on one line?

```{.verse .run}
Main():void =
    Coins := 7
    if (Coins > 10) then Print("buy")
    else Print("save")
```

> ```{.output}
> save
> ```

What are the comparisons?

> `<`, `<=`, `>`, `>=`, `=` (equal) and `<>` (not equal).

Is `=` how we give a name a value?

> No. In a question, `=` asks "are these equal?". Names get values with `:=`.

What does this print?

```{.verse .run}
Main():void =
    if (3 = 3) { Print("equal") }
    if (3 <> 4) { Print("not equal") }
    if ("gem" = "gem") { Print("same word") }
```

> ```{.output}
> equal
> not equal
> same word
> ```

What are the braces after the `if`?

> Another way to write the body, on the same line.

Can a comparison stand on its own, outside an `if`?

```{.verse .reject expect="this expression can fail, but it is not in a failure context"}
Main():void =
    Coins := 7
    Coins > 10
    Print("ok")
```

> No. If it failed, nothing would be ready to catch it.

What is a *failure context*?

> A place that catches failure, like the parentheses of an `if`.

Are there others?

> Yes, and we will meet them all. The message lists them.
:::

::: {.rule title="The Rule of Failure"}
A question in Verse succeeds or fails. Anything that might fail must sit
in a failure context, such as the condition of an `if`.
:::

::: qa
What is the value of `0 <= X <= 9` when `X` is `5`?

```{.verse .run}
Main():void =
    X := 5
    if (0 <= X <= 9) { Print("a digit") }
```

> ```{.output}
> a digit
> ```

How does `0 <= X <= 9` work?

> It checks `0 <= X` and `X <= 9`, and fails if either fails.

What can we do with the left side that a comparison gives back?

```{.verse .run}
Main():void =
    X := 5
    if (Y := (X > 3)) { Print("Y is {Y}") }
```

> ```{.output}
> Y is 5
> ```

Can an `if` condition make a name?

> Yes, and the body can use it. `Y` lives only there.

Can an `if` have several questions?

```{.verse .run}
Main():void =
    Coins := 12
    Keys := 1
    if (Coins > 10, Keys > 0):
        Print("map bought, gate open")
```

> ```{.output}
> map bought, gate open
> ```

What does the comma mean?

> "And then". Each question is asked in turn; if any fails, the whole condition fails.

What about `true` and `false`?

> They are values of type `logic`. They do not fail by themselves.

How do we ask whether a `logic` is `true`?

```{.verse .run}
Main():void =
    Lit:logic = true
    if (Lit?) { Print("the torch is lit") }
    Dark:logic = false
    if (Dark?):
        Print("dark?")
    else:
        Print("not dark")
```

> ```{.output}
> the torch is lit
> not dark
> ```

What does `?` do?

> `Lit?` succeeds when `Lit` is `true`, and fails when it is `false`.

So `false` is not failure?

> Right. `false` is a value. `false?` is a failure.

Can an `if` be a value?

```{.verse .run}
Main():void =
    Coins := 12
    Size := if (Coins > 10):
        "rich"
    else:
        "poor"
    Print(Size)
```

> ```{.output}
> rich
> ```

What must every `if` condition be able to do?

```{.verse .reject expect="cannot fail"}
Main():void =
    if (1 + 1) { Print("two") }
```

> Fail! A question that can never fail is not a question.
:::

::: {.rule title="The Rule of the Question Mark"}
`false` is a value, not a failure. To turn a `logic` into a question, add
`?`: `X?` succeeds when `X` is `true` and fails when it is `false`.
:::

::: qa
What other things can fail?

> Many. Here is one: asking an array for an element it does not have.

What does this print?

```{.verse .run}
Main():void =
    Chests := array{10, 20, 30}
    if (A := Chests[1]):
        Print("chest 1 holds {A}")
    if (B := Chests[3]):
        Print("chest 3 holds {B}")
    else:
        Print("there is no chest 3")
```

> ```{.output}
> chest 1 holds 20
> there is no chest 3
> ```

Why is there no chest 3?

> Counting starts at `0`: the chests are `0`, `1` and `2`.

So `Chests[3]` fails?

> Yes. That is why indexing must be in a failure context too.

What else fails?

> Dividing by zero. `Mod[7, 0]` fails, and so does `Floor(7 / 0)`.

Can we write our own recipe that fails?

```{.verse .run}
IsEven(N:int)<decides>:int = Mod[N, 2] = 0

Main():void =
    if (IsEven[4]) { Print("4 is even") }
    if (IsEven[7]):
        Print("7 is even?")
    else:
        Print("7 is odd")
```

> ```{.output}
> 4 is even
> 7 is odd
> ```

What does `<decides>` say?

> That `IsEven` may fail. It *decides*: success means yes, failure means no.

Why `IsEven[4]` with square brackets?

> Because it may fail. Square brackets warn the reader: this call is a question.

What if we use parentheses?

```{.verse .reject expect="call it with IsEven["}
IsEven(N:int)<decides>:int = Mod[N, 2] = 0

Main():void =
    if (IsEven(4)) { Print("even") }
```

> Verse says to call it with `IsEven[…]`.

What is `Mod[7, 2]`?

> `1`, the remainder when `7` is divided by `2`. It uses brackets because it may fail.

Can a `<decides>` recipe have several lines?

```{.verse .run}
Half(N:int)<decides>:int =
    Mod[N, 2] = 0
    Quotient[N, 2]

Main():void =
    if (H := Half[10]):
        Print("half of 10 is {H}")
    if (H := Half[7]):
        Print("{H}")
    else:
        Print("7 has no half")
```

> ```{.output}
> half of 10 is 5
> 7 has no half
> ```

What happens on the first line of `Half` when `N` is `7`?

> `Mod[7, 2] = 0` fails, so `Half` fails right there, and the rest is skipped.

Where can a recipe *without* `<decides>` call `Half`?

> Only inside a failure context of its own, such as an `if`.

Then can a recipe without `<decides>` ever fail?

> Never. Whatever it asks, it catches. That is a promise, and it is kept.
:::

::: {.rule title="The Rule of Brackets"}
A function that may fail is marked `<decides>` and is called with square
brackets, `F[X]`. A function without `<decides>` is called with
parentheses, `F(X)`, and never fails.
:::

Questions that fail are only half of the story. The other half is what
happens to everything a failed question *did* before it failed. That is the
best part of Verse, and the next chapter is all about it.
