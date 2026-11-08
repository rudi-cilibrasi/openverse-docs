# Promises Kept

A good treasure map makes promises: "the path is safe", "the chest is
under the oak". A good program does too. In this last chapter we see the
promises a Verse recipe can make about itself (that it may fail, that it
may wait its turn, what it may do to objects), the few ways a program can
still go wrong, and the promises openverse keeps for *every* program it
accepts.

::: qa
What did `<decides>` promise?

> That a recipe may fail. And a recipe *without* it promises never to fail.

Can a recipe promise to *wait*?

> Yes, with `<suspends>`. While one recipe waits, others go on, the way one
> hunter digs while another reads the map.

What does `Sleep(1.0)` do?

```{.verse .run}
Main()<suspends>:void =
    Print("dig")
    Sleep(1.0)
    Print("found it")
```

> ```{.output}
> dig
> found it
> ```
>
> It waits one second, then goes on.

Did we really wait a whole second?

> Not in openverse. Its clock is make-believe: it counts *ticks*, thirty to a
> second, and when everyone is asleep it skips straight to the next tick
> where someone wakes up. The program finishes at once.

Why does `Main` say `<suspends>`?

> Because it waits. A recipe that waits must say so.

May any recipe wait?

```{.verse .reject expect="it can only be called in a <suspends> function"}
Rest():void =
    Sleep(1.0)

Main():void = Rest()
```

> No! Only a recipe that promises `<suspends>` may call `Sleep`, or call
> another recipe that waits.

How do Ada and Lin dig at the same time?

```{.verse .run}
Dig(Name:string, Holes:int)<suspends>:void =
    for (I := 1..Holes):
        Print("{Name} digs hole {I}")
        Sleep(1.0)

Main()<suspends>:void =
    sync:
        Dig("Ada", 2)
        Dig("Lin", 3)
    Print("all dug")
```

> ```{.output}
> Ada digs hole 1
> Lin digs hole 1
> Ada digs hole 2
> Lin digs hole 2
> Lin digs hole 3
> all dug
> ```
>
> Each line of a `sync` is an *arm*, and the arms run side by side. The
> `sync` ends when every arm has ended.

Why does Ada always go before Lin?

> Each arm runs until it waits. Then the next arm has its turn. When a tick
> comes, the arms that wake up take their turns in the order they are
> written.

Could another run print the lines in another order?

> Never. The same program takes the same turns and prints the same lines.

What if we only care who finishes first?

```{.verse .run}
Search()<suspends>:string =
    Sleep(3.0)
    "treasure"

Storm()<suspends>:string =
    Sleep(2.0)
    "storm"

Main()<suspends>:void =
    First := race:
        Search()
        Storm()
    Print("first came the {First}")
```

> ```{.output}
> first came the storm
> ```
>
> A `race` ends as soon as one arm ends, with that arm's value.

What happened to the search?

> It was stopped. The arms that lose a race are cancelled.

Can a cancelled recipe tidy up?

```{.verse .run}
Search()<suspends>:string =
    defer:
        Print("pack up the shovel")
    Sleep(3.0)
    "treasure"

Storm()<suspends>:string =
    Sleep(2.0)
    "storm"

Main()<suspends>:void =
    First := race:
        Search()
        Storm()
    Print("first came the {First}")
```

> ```{.output}
> pack up the shovel
> first came the storm
> ```
>
> Yes. Its `defer:` block runs as it stops, before the race ends.

Can we start a job, do something else, and collect the answer later?

```{.verse .run}
Fetch(Who:string, T:float)<suspends>:string =
    Sleep(T)
    "{Who}'s map"

Main()<suspends>:void =
    A := spawn{Fetch("Ada", 2.0)}
    L := spawn{Fetch("Lin", 1.0)}
    Print(L.Await())
    Print(A.Await())
```

> ```{.output}
> Lin's map
> Ada's map
> ```
>
> `spawn` starts a *task* and gives it back at once. `Await()` waits for the
> task's answer.

What if everyone waits and nobody can ever wake up?

```{.verse .run exit="2"}
Main()<suspends>:void =
    Print("wait for a ship")
    Sleep(Inf)
    Print("never")
```

> ```{.output}
> wait for a ship
> ```
>
> `Sleep(Inf)` waits forever. openverse sees that nothing can ever happen
> again, and stops the program as `Err()` would.
:::

::: {.rule title="The Rule of Turns"}
A `<suspends>` recipe may wait. A `sync` waits for all its arms, a `race`
for the first, and `spawn` starts a task to `Await` later. Tasks take
turns on a clock of ticks, always in the same order, so a program with
tasks still has one answer.
:::

::: qa
Are there other promises a recipe can make?

> Yes. They say what a recipe may do to the objects around it.

What does `<computes>` promise?

```{.verse .run}
Worth(Gems:int)<computes>:int =
    Gems * 10

Main():void = Print("{Worth(4)}")
```

> ```{.output}
> 40
> ```
>
> That the recipe only computes: it neither looks at nor changes any `var` field of any object.

What does `<reads>` promise?

> That the recipe may *look* at `var` fields of objects, but never change them.

What if a `<reads>` recipe breaks its promise?

```{.verse .reject expect="Rob sets a var field, which its effects (<reads>) do not allow"}
chest := class:
    var Gold:int = 0

Rob(C:chest)<reads>:void =
    set C.Gold = 0

Main():void = Rob(chest{})
```

> Verse refuses the whole program, and says which promise was broken.

What if it calls a recipe that changes things?

> Also refused. A recipe can only promise what everything it calls can promise too.

What does `<transacts>` say?

> That the recipe may read, change and create objects. A recipe with no promise at all may do the same.

And `<allocates>`?

> That it may make new objects, but leaves the old ones alone.

Why make promises at all?

> So that a reader, and Verse, can trust a call without reading its recipe.
:::

::: {.rule title="The Rule of Promises"}
A recipe's effects are promises: `<decides>` may fail, `<suspends>` may
wait, `<computes>` touches no changing thing, `<reads>` only looks,
`<allocates>` only makes new things, `<transacts>` may do it all. Verse
refuses a recipe that breaks its promise.
:::

::: qa
Can a program still go wrong?

> In two ways, and only two.

What is the first?

```{.verse .run exit="2"}
Main():void =
    var Gold:int = 9223372036854775807
    Print("so much gold")
    set Gold += 1
    Print("even more")
```

> ```{.output}
> so much gold
> ```

What happened?

> `Gold` was the biggest `int` there is. Adding `1` *overflowed*: there is no bigger `int`.

Did it fail?

> No! Overflow is an *error*, not a failure. It stops the whole program.

Could an `if` have caught it?

> No. Only failures are caught. An error is a real mistake.

What is the second way?

```{.verse .run exit="2"}
Main():void =
    Print("the map is a fake")
    Err()
    Print("unreachable")
```

> ```{.output}
> the map is a fake
> ```
>
> `Err()`: the program itself asks to stop with an error.

How does openverse tell us how a program ended?

> With an *exit code*: `0` for a good ending, `2` for an error.

And `1`?

```{.verse .run exit="1"}
Unlock(Code:int)<decides>:void =
    Code = 1234

Main()<decides>:void =
    Print("trying the code")
    Unlock[1111]
    Print("unlocked!")
```

> ```{.output}
> trying the code
> ```
>
> `1` means `Main` itself failed. Only a `Main` marked `<decides>` can.

Why is `trying the code` still printed?

> It was not inside a failed question. The failure of `Main` ends the program; it does not take back what `Main` already printed.

What about a program that runs forever?

> It never gives an answer. When a program runs too long, or a recipe calls itself too deeply, openverse gives up on it. That is a limit, not an answer.
:::

::: {.rule title="The Rule of Errors"}
Failure is a polite "no" that a question can catch. An error, such as an
overflow or `Err()`, is a real mistake: nothing catches it, and the program
stops.
:::

::: qa
Now the promises that openverse keeps for *every* program it runs. Who checked them?

> The people who built openverse proved them, with a computer checking every step of every proof.

What is the first promise?

> *One program, one answer.* Run it again, and it prints the same thing and ends the same way.

Even with `for` and many choices?

> Yes. The choices are always tried in the same order.

What is the second?

> *A failed guess leaves no trace.* When a question fails, it is as if it never ran: no `set`, no `Print`, no change to any object survives.

What is the third?

> *A recipe without `<decides>` never fails.* We can call it with parentheses and trust it.

What is the fourth?

> *Types are kept.* A recipe that says it gives back an `int` gives back an `int`; Verse never applies a recipe to the wrong kind of value.

What is the fifth?

> *Promises about objects are kept.* A recipe that does not promise to change objects leaves every object exactly as it was.

So what can still surprise us at run time?

> Only overflow, `Err()`, and a program that never stops (or runs out of room).

Does Verse check these promises before the program runs?

> Yes. Verse reads the whole program first. If any check fails, the program never starts.

And if the checks pass?

> Then the promises hold, every time the program runs.
:::

::: {.rule title="The Rule of Trust"}
If Verse accepts your program, it has one answer, its failed guesses leave
no trace, its recipes without `<decides>` never fail, its types are kept,
and its promises about objects hold. Only overflow, `Err()` and endless
loops are left to watch for.
:::

That is the end of our hunt. You know values and names, questions that
fail, guesses that are taken back, loops, boxes, maps and objects, tasks
that take turns, and the promises that hold them together. The rest of Verse is more of the same
ideas. Go and find some treasure.
