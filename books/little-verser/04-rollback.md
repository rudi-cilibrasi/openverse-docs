# Take It Back

Imagine trying a key in a lock, and, if it does not turn, finding the key
back in your pocket and the lock exactly as it was, as if you had never
tried. Verse works like that. When a question fails, everything it did on
the way is quietly undone.

::: qa
What does this program print?

```{.verse .run}
Main():void =
    var Coins:int = 10
    if (set Coins -= 25, Coins >= 0):
        Print("bought the map")
    else:
        Print("still have {Coins} coins")
```

> ```{.output}
> still have 10 coins
> ```

Didn't we spend `25` coins?

> We tried. `Coins` became `-15`, then `Coins >= 0` failed.

Then why is `Coins` still `10`?

> Because the question failed, Verse *took back* the `set`. This is *rollback*.

When is the taking back done?

> The moment the question fails, before the `else` begins.

What if the question succeeds?

```{.verse .run}
Main():void =
    var Coins:int = 30
    if (set Coins -= 25, Coins >= 0):
        Print("bought it; {Coins} left")
```

> ```{.output}
> bought it; 5 left
> ```

So a successful question keeps what it did?

> Yes. Success keeps; failure takes back.

What does this print?

```{.verse .run}
Main():void =
    var Torches:int = 3
    if (set Torches -= 1,
        Print("lighting a torch"),
        Torches > 5):
        Print("so bright")
    Print("torches: {Torches}")
```

> ```{.output}
> torches: 3
> ```

Where did `lighting a torch` go?

> It was taken back too. A failed question leaves no trace, not even a printed line.

Is that true of every language?

> No. Most languages cannot unprint. openverse treats printing like any other change.

How many steps can a question take back?

```{.verse .run}
Main():void =
    var X:int = 1
    if (set X = 2, set X = 3, X = 4):
        Print("never")
    Print("X = {X}")
```

> ```{.output}
> X = 1
> ```
>
> All of them. `X` was `2`, then `3`, and then it was `1` again.

Why is this useful?

> We can try something risky, and if it does not work out, we need not clean up.
:::

::: {.rule title="The Rule of the Safe Guess"}
When a question fails, everything it did is taken back: every `set` and
every `Print`. When it succeeds, everything it did is kept.
:::

::: qa
What does `not` do?

> It turns success into failure, and failure into success.

What does this print?

```{.verse .run}
IsEven(N:int)<decides>:int = Mod[N, 2] = 0

Main():void =
    if (not IsEven[7]) { Print("7 is odd") }
    if (not IsEven[8]) { Print("8 is odd") }
```

> ```{.output}
> 7 is odd
> ```

Why nothing about `8`?

> `IsEven[8]` succeeded, so `not IsEven[8]` failed.

What does this print?

```{.verse .run}
Main():void =
    var Steps:int = 0
    if (not (set Steps = 100; Steps > 50)):
        Print("never")
    else:
        Print("Steps = {Steps}")
```

> ```{.output}
> Steps = 0
> ```

What is the `;` doing?

> Inside parentheses it means "then": first `set`, then compare.

The inside succeeded. Why is `Steps` still `0`?

> `not` turned that success into a failure, and the whole question was taken back.

Does `not` ever keep what its inside did?

> Never. If the inside fails, the inside's work is taken back; if it succeeds, `not` fails and it is taken back anyway.

What does `or` do?

> It tries its left side; if that fails, it tries its right side.

What does this print?

```{.verse .run}
Half(N:int)<decides>:int =
    Mod[N, 2] = 0
    Quotient[N, 2]

Main():void =
    A := Half[7] or 0
    B := Half[8] or 0
    Print("{A} {B}")
```

> ```{.output}
> 0 4
> ```

Why is `A` zero?

> `Half[7]` failed, so `or` gave the right side, `0`.

Do we need an `if` around `Half[7] or 0`?

> No! The left side of `or` is a failure context. And `0` cannot fail, so the whole thing cannot fail.

Can we chain `or`?

```{.verse .run}
Half(N:int)<decides>:int =
    Mod[N, 2] = 0
    Quotient[N, 2]

Main():void =
    C := Half[7] or Half[9] or Half[12] or -1
    Print("{C}")
```

> ```{.output}
> 6
> ```
>
> It tries each in turn, and stops at the first success.

What happens to the left side's work when it fails?

```{.verse .run}
Main():void =
    var Tries:int = 0
    Prize := (set Tries += 1; Tries > 5) or 99
    Print("prize {Prize}, tries {Tries}")
```

> ```{.output}
> prize 99, tries 0
> ```
>
> Taken back, as always. The right side starts from a clean slate.

What does `and` do?

> It asks both sides, and fails if either fails.

What does this print?

```{.verse .run}
Main():void =
    Coins := 12
    Keys := 0
    if (Coins > 10 and Keys > 0):
        Print("both")
    else:
        Print("not both")
    if (Coins > 10 or Keys > 0):
        Print("at least one")
```

> ```{.output}
> not both
> at least one
> ```

Can the right side of `and` use a name made on its left?

```{.verse .reject expect="unknown identifier 'X'"}
Main():void =
    if ((X := 5) and X > 3):
        Print("x")
```

> No. Each side of `and` keeps its names to itself. A comma does share them.
:::

::: {.rule title="The Rule of Not, Or and And"}
`not` succeeds when its inside fails, and never keeps its inside's work.
`or` tries the left side, and if it fails, takes it back and tries the
right. `and` needs both sides to succeed.
:::

::: qa
Let us put it together. A chest opens with a gold key or a silver key. We have only silver. What does this print?

```{.verse .run}
HasGold(Keys:int)<decides>:void =
    Keys >= 100
HasSilver(Keys:int)<decides>:void =
    Mod[Keys, 10] = 5

Main():void =
    Keys := 5
    if (HasGold[Keys] or HasSilver[Keys]):
        Print("the chest opens")
```

> ```{.output}
> the chest opens
> ```

What is `<decides>:void`?

> A question with no answer to give back, only success or failure.

And now the chest costs a coin to open?

```{.verse .run}
Main():void =
    var Coins:int = 0
    if (set Coins -= 1, Coins >= 0):
        Print("opened")
    else:
        Print("no coin, no chest")
    Print("coins: {Coins}")
```

> ```{.output}
> no coin, no chest
> coins: 0
> ```

Did we go into debt?

> Only for a moment, inside a question that failed. Then it was taken back.

Is it still possible to lose coins forever?

> Yes: by succeeding. Rollback protects only guesses that fail.
:::

That is the heart of Verse: try, and if it fails, nothing happened. Next we
try things many times over, with loops that search through treasure for us.
