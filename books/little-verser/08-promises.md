# Promises Kept

A good treasure map makes promises: "the path is safe", "the chest is
under the oak". A good program does too. In this last chapter we see the
promises a Verse recipe can make about itself, the few ways a program can
still go wrong, and the promises openverse keeps for *every* program it
accepts.

::: qa
What did `<decides>` promise?

> That a recipe may fail. And a recipe *without* it promises never to fail.

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
A recipe's effects are promises: `<decides>` may fail, `<computes>` touches
no changing thing, `<reads>` only looks, `<allocates>` only makes new
things, `<transacts>` may do it all. Verse refuses a recipe that breaks its
promise.
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
fail, guesses that are taken back, loops, boxes, maps and objects, and the
promises that hold them together. The rest of Verse is more of the same
ideas. Go and find some treasure.
