# Names and Recipes

A treasure hunter keeps notes: how many coins, which chest, what the map
said. In Verse we write notes by giving values *names*. Then we write
*recipes*, called functions, that turn values into other values.

::: qa
What does this program print?

```{.verse .run}
Main():void =
    Coins := 5
    Print("{Coins} coins")
```

> ```{.output}
> 5 coins
> ```

What is `Coins`?

> A *name*. Here it stands for the value `5`.

What does `:=` say?

> "From now on, this name stands for this value."

Can we use a name in arithmetic?

```{.verse .run}
Main():void =
    Coins := 5
    Gems := 2
    Print("{Coins + Gems * 10} points")
```

> ```{.output}
> 25 points
> ```

Can we say which type a name has?

```{.verse .run}
Main():void =
    Coins:int = 5
    Print("{Coins + 1} coins")
```

> ```{.output}
> 6 coins
> ```

How is `Coins:int = 5` different from `Coins := 5`?

> Only in that we wrote the type, `int`, ourselves. With `:=`, Verse works it out.

What if the type we write is wrong?

```{.verse .reject expect="expected int, found string"}
Main():void =
    Coins:int = "five"
```

> Verse refuses: it expected an `int` and found a string.

Can `Coins` stand for `5` and later for `6`?

```{.verse .reject expect="'Coins' is already defined"}
Main():void =
    Coins := 5
    Coins := 6
```

> No. A name, once given, keeps its value.

Why is that a good idea?

> When we read `Coins` anywhere, we know what it means. No surprises.

But a hunter's purse changes. What then?

> We ask for a name that may change: a `var`.

What does this print?

```{.verse .run}
Main():void =
    var Coins:int = 5
    set Coins = 6
    Print("{Coins} coins")
```

> ```{.output}
> 6 coins
> ```

What does `var` say?

> That `Coins` is a *variable*: its value may change.

What does `set` do?

> It gives a `var` a new value.

Can we `set` a name that is not a `var`?

```{.verse .reject expect="'Coins' is not a var"}
Main():void =
    Coins := 5
    set Coins = 6
```

> No. The message even tells us how to fix it.

Must a `var` have its type written?

> Yes: `var Coins:int = 5`, never `var Coins := 5`.

What does `set Coins += 10` do?

> The same as `set Coins = Coins + 10`.

What does this print?

```{.verse .run}
Main():void =
    var Coins:int = 5
    set Coins += 10
    set Coins -= 3
    set Coins *= 2
    Print("{Coins}")
```

> ```{.output}
> 24
> ```

Why `24`?

> `5 + 10` is `15`, minus `3` is `12`, times `2` is `24`.
:::

::: {.rule title="The Rule of Names"}
A name stands for one value for as long as it lives. Only a `var` may
change, and only by `set`.
:::

::: qa
Now a recipe. What does this print?

```{.verse .run}
Double(N:int):int = N * 2

Main():void =
    Print("{Double(21)}")
```

> ```{.output}
> 42
> ```

What is `Double`?

> A *function*: a recipe that takes an `int` and gives back an `int`.

What is `N`?

> A *parameter*: the name the recipe uses for whatever it is given.

What is `N` when we write `Double(21)`?

> `21`.

What does `:int` after `(N:int)` say?

> That `Double` gives back an `int`.

What is `Double(Double(3))`?

> `12`. First `Double(3)` is `6`, then `Double(6)` is `12`.

Can a recipe take two things?

```{.verse .run}
Score(Coins:int, Gems:int):int =
    Coins + Gems * 10

Main():void =
    Print("{Score(5, 2)}")
```

> ```{.output}
> 25
> ```

Which value is `Coins`, and which is `Gems`?

> They go in order: `Coins` is `5`, `Gems` is `2`.

Can we hand `Score` a tuple instead?

```{.verse .run}
Score(Coins:int, Gems:int):int =
    Coins + Gems * 10

Main():void =
    Loot := (5, 2)
    Print("{Score(Loot)}")
```

> ```{.output}
> 25
> ```
>
> Yes. A tuple's parts fill the parameters in order.

Why is the body of `Score` on its own line?

> It could be on the first line too. When a body is long, we indent it under the `=`.

Can a body have several lines?

```{.verse .run}
Score(Coins:int, Gems:int):int =
    GemPoints := Gems * 10
    Bonus := 3
    Coins + GemPoints + Bonus

Main():void =
    Print("{Score(5, 2)}")
```

> ```{.output}
> 28
> ```

Which line gives the answer?

> The last one. A recipe's answer is the value of its last line.

Can a recipe give back a string?

```{.verse .run}
Greet(Name:string):string =
    "Welcome, {Name}!"

Main():void =
    Print(Greet("Ada"))
    Print(Greet("Lin"))
```

> ```{.output}
> Welcome, Ada!
> Welcome, Lin!
> ```

Can a recipe give back nothing?

```{.verse .run}
Shout(Word:string):void =
    Print(Word + "!")

Main():void =
    Shout("Treasure")
```

> ```{.output}
> Treasure!
> ```

So a `void` recipe is for its effect?

> Yes, like `Main`. It does something, here printing, instead of giving back a value.

May a recipe use a `var` of its own?

```{.verse .run}
Countdown(From:int):void =
    var N:int = From
    Print("{N}")
    set N -= 1
    Print("{N}")
    set N -= 1
    Print("{N}")

Main():void =
    Countdown(3)
```

> ```{.output}
> 3
> 2
> 1
> ```

Can we change `From` itself?

> No. A parameter is a name, not a `var`. That is why we copied it into `N`.

Can a name live outside every function?

```{.verse .run}
GemValue:int = 10

Worth(Gems:int):int = Gems * GemValue

Main():void =
    Print("{Worth(3)}")
```

> ```{.output}
> 30
> ```

What is `GemValue`?

> A *constant*: a name that every function can see.

Can a recipe use a name from inside another recipe?

> No. `GemPoints` lived only inside `Score`. Each recipe has its own names.

Can two names in one recipe share a name if they are far apart?

```{.verse .reject expect="already defined"}
Main():void =
    Prize := 5
    if (Prize > 3):
        Prize := 9
        Print("{Prize}")
```

> No. Verse does not let a name hide another one, not even inside a block.

What is that `if` doing there?

> Asking a question. It is the next chapter's business.

Can two recipes share a name, then?

```{.verse .run}
Describe(N:int):string = "{N} coins"
Describe(S:string):string = "a {S}"

Main():void =
    Print(Describe(3))
    Print(Describe("gem"))
```

> ```{.output}
> 3 coins
> a gem
> ```
>
> Yes, if they take different kinds of things.

How does Verse choose?

> By what we give it: an `int` goes to the first `Describe`, a string to the second.

And if both take an `int`?

```{.verse .reject expect="a call cannot tell apart"}
Describe(N:int):string = "{N} coins"
Describe(K:int):string = "{K} keys"

Main():void =
    Print(Describe(3))
```

> Then a call could not tell them apart, and openverse says so before the program runs.

Can we keep names and recipes in a box of their own?

```{.verse .run}
treasure := module:
    Gems<public>:int = 3
    Show<public>(N:int):string = "{N} gems"

Main():void =
    Print(treasure.Show(treasure.Gems))
```

> ```{.output}
> 3 gems
> ```
>
> Yes: a *module*. Outside it, we write `treasure.` before its names.

What does `<public>` do?

```{.verse .reject expect="is internal to treasure"}
treasure := module:
    Gems:int = 3

Main():void =
    Print("{treasure.Gems}")
```

> It lets a name out of its module. Without it, the name stays inside, and openverse says how to share it.

Must we always write `treasure.`?

```{.verse .run}
treasure := module:
    Gems<public>:int = 3

using{treasure}

Main():void =
    Print("{Gems} gems")
```

> ```{.output}
> 3 gems
> ```
>
> No. `using{treasure}` brings its public names in.
:::

::: {.rule title="The Rule of Recipes"}
A function names its parameters, says what type it gives back, and gives
back the value of its last line. A `void` function is used for what it does.
:::

We can name values and write recipes. But every recipe so far had only one
road through it. A treasure hunt is full of forks: is the chest locked? Is
the bridge safe? Next we learn how Verse asks questions, and why its answer
is sometimes neither yes nor no.
