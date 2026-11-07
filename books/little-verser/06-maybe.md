# Maybe

Some boxes hold treasure and some are empty. A search may find something
or nothing. Verse has a value for "maybe": an *option*, a box that holds one
value or is empty. And it has *maps*, which look things up by name, and fail
politely when the name is not there.

::: qa
What is `option{42}`?

> A box with `42` inside.

What is its type?

> `?int`, said "option of `int`", or "maybe an `int`".

How do we take `42` out of the box?

```{.verse .run}
Main():void =
    Box:?int = option{42}
    if (X := Box?):
        Print("the box holds {X}")
```

> ```{.output}
> the box holds 42
> ```

What does `Box?` do?

> It gives back what is in the box, or fails if the box is empty.

How do we make an empty box?

> We write `false`.

What does this print?

```{.verse .run}
Main():void =
    Empty:?int = false
    if (Y := Empty?):
        Print("{Y}")
    else:
        Print("empty box")
```

> ```{.output}
> empty box
> ```

Isn't `false` a `logic`?

> It is both: `false` is also the empty box of every option type.

Can we use a box as if it were its contents?

```{.verse .reject expect="expected int, found ?int"}
Main():void =
    Box:?int = option{42}
    X:int = Box
```

> No. A `?int` is a box, not an `int`. Open it with `?`, in a failure context.

What is inside `option{…}` allowed to do?

> To fail! `option{…}` is a failure context. If its inside fails, the box is empty.

What does this print?

```{.verse .run}
Find(L:[]string, Want:string)<decides>:int =
    var Where:int = -1
    for (I -> G : L, G = Want, Where < 0):
        set Where = I
    Where >= 0
    Where

Main():void =
    Gems := array{"ruby", "opal"}
    Spot:?int = option{Find[Gems, "opal"]}
    None:?int = option{Find[Gems, "jade"]}
    if (S := Spot?) { Print("opal at {S}") }
    if (not None?) { Print("no jade") }
```

> ```{.output}
> opal at 1
> no jade
> ```

What does `Find` do?

> It looks for `Want` in the list `L` and gives back its position, or fails if it is not there.

Why put `Find[…]` in a box?

> To keep the answer for later, success or failure, without asking again.

Is the work inside a failed `option{…}` taken back?

> Yes, like every failure. An empty box comes with a clean slate.

Can a `var` hold a box?

```{.verse .run}
Main():void =
    var Pocket:?string = false
    set Pocket = option{"key"}
    if (K := Pocket?) { Print("a {K}") }
```

> ```{.output}
> a key
> ```

What does `Pocket? or "nothing"` give?

```{.verse .run}
Main():void =
    var Pocket:?string = false
    Print(Pocket? or "nothing")
    set Pocket = option{"key"}
    Print(Pocket? or "nothing")
```

> ```{.output}
> nothing
> key
> ```

So `or` is a good way to open a box?

> Yes, when we have something to use instead.
:::

::: {.rule title="The Rule of the Box"}
An option `?t` is a box: `option{X}` holds `X`, `false` is empty. `Box?`
opens it, and fails when it is empty. `option{…}` turns success into a
full box and failure into an empty one.
:::

::: qa
What is a *map*?

> A table that finds a value by its *key*, like a price list.

What does this print?

```{.verse .run}
Main():void =
    Prices:[string]int =
        map{"map" => 30, "key" => 5}
    if (P := Prices["key"]):
        Print("a key costs {P}")
    if (P := Prices["boat"]):
        Print("{P}")
    else:
        Print("no boats here")
```

> ```{.output}
> a key costs 5
> no boats here
> ```

What is `[string]int`?

> The type of a map with `string` keys and `int` values.

What does `Prices["boat"]` do?

> It fails, because there is no key `"boat"`.

So looking something up must be in a failure context?

> Yes, like taking an element from an array.

Can a map change?

```{.verse .run}
Main():void =
    var Bag:[string]int = map{}
    set Bag["coin"] = 3
    set Bag["gem"] = 1
    set Bag["coin"] = 4
    for (Thing -> Count : Bag):
        Print("{Thing}: {Count}")
```

> ```{.output}
> coin: 4
> gem: 1
> ```

What did `set Bag["coin"] = 4` do?

> It changed the value of `"coin"`. Setting a key that is not there adds it.

In what order does the `for` visit the map?

> In the order the keys were first added.

Can we add to a value with `+=`?

```{.verse .run}
Main():void =
    var Bag:[string]int = map{"coin" => 3}
    if (set Bag["coin"] += 1,
        C := Bag["coin"]):
        Print("now {C}")
    if (set Bag["gem"] += 1):
        Print("?")
    else:
        Print("no gems to add to")
```

> ```{.output}
> now 4
> no gems to add to
> ```

Why did the second one fail?

> `+=` must read the old value first, and there is no `"gem"` to read.

How many keys does `Bag` have at the end?

> Still one. The failed `set` was taken back, as always.

What is `Prices.Length`?

```{.verse .run}
Main():void =
    Prices:[string]int =
        map{"map" => 30, "key" => 5}
    Print("{Prices.Length} things for sale")
```

> ```{.output}
> 2 things for sale
> ```
:::

::: {.rule title="The Rule of the Map"}
A map `[k]v` finds a value by its key, and fails when the key is missing.
`set M[K] = V` adds or replaces; `set M[K] += V` needs the key to be there.
:::

Options and maps hold values. Next we build our own kinds of values: coins
with a worth, players with names, and chests that remember what is in them.
