---
title: "The Little Verser"
subtitle: "A friendly dialogue about Verse"
author: "The openverse project"
lang: en-US
documentclass: book
classoption:
  - openany
fontsize: 11pt
papersize: letter
geometry:
  - textwidth=5.8in
  - textheight=8.5in
  - headsep=18pt
  - footskip=30pt
mainfont: TeX Gyre Schola
mathfont: TeX Gyre Schola Math
monofont: DejaVu Sans Mono
monofontoptions:
  - Scale=0.80
toc: true
toc-depth: 0
colorlinks: true
linkcolor: "lvaccent"
urlcolor: "lvaccent"
toccolor: "black"
---

# Before We Begin {.unnumbered}

This little book is a conversation. On the left of each page is a question;
on the right, its answer. Cover the right side with a card, read a question,
and answer it yourself before you slide the card down. Some answers are a
single word. Some are a program's output. A few are "No!", and those are
usually the most interesting.

The language is **Verse**. Epic Games made it for building games, and it
has an idea at its heart that most languages do not: an expression can
*fail*. Failing is not crashing, and it is not the same as `false`. A
failure is a polite "no": the program notices it, steps back, and tries
something else, and anything the failed attempt did is quietly undone.
By the end of this book you will think in failures, and you will like it.

We use **openverse**, a small, careful implementation of Verse. It runs a
deterministic part of the language: the same program always gives the same
answer. The people who built openverse proved, with a computer checking
every step, that it keeps the promises we meet in the last chapter.

Every program in this book is real. Each one was run by openverse when the
book was made, and the output you see is what it printed. To run one
yourself, save it in a file, say `hunt.verse`, and type

```
openverse run hunt.verse
```

or paste it into the [openverse playground](https://rudi-cilibrasi.github.io/openverse-docs/demo/), which runs
openverse right in your web browser.

You need no mathematics beyond arithmetic, and no programming. You need a
little patience, a pencil, and the card.

Do not hurry. Each chapter builds on the one before. When a box with a
**Rule** appears, stop and read it twice: the rules are the whole book in
miniature, and the last pages collect them all.

This book shows the part of Verse that openverse runs, and Verse is bigger
than that. When you want the whole language, read the
[*Book of Verse*](https://dev.epicgames.com/documentation/en-us/fortnite/verse-language-book-of-verse-reference), Epic Games' own guide to it.
Thank you, Epic Games, for making Verse and for sharing it with everyone.
(openverse is an independent project: Epic Games did not make it and does
not endorse it. Verse and Fortnite are trademarks of Epic Games.)

Ready? Let's go treasure hunting.

# Plain Values

A treasure hunt needs treasure, and a program needs *values*: numbers,
words, true-or-false answers, and collections of them. In this chapter we
meet the values of Verse, and the one way a program shows them to us.

::: qa
Is `42` a value?

> Yes. It is a whole number. Verse calls whole numbers `int`.

Is `-7` an `int`?

> Yes. An `int` may be negative.

Is `0` an `int`?

> Yes, and a very useful one.

Is `3.5` an `int`?

> No. An `int` has no fraction.

What is `3 + 4`?

> `7`.

What is `2 * 3 + 1`?

> `7` again. Multiplication goes first, as in school.

What is `2 * (3 + 1)`?

> `8`. Parentheses go first of all.

What is `10 - 20`?

> `-10`.

How do we see a value?

> A program *prints* it.

What does this program print?

```{.verse .run}
Main():void =
    Print("Hello, treasure hunter!")
```

> ```{.output}
> Hello, treasure hunter!
> ```

What is `Main`?

> The place where a program starts. openverse runs `Main` first.

What is `Print`?

> It writes some text on a line of its own.

What is `"Hello, treasure hunter!"`?

> A *string*: text between double quotes.

Is `"42"` an `int`?

> No. It is a string with two characters in it, `4` and `2`.

Can we `Print` an `int`?

```{.verse .reject expect="expected string, found int"}
Main():void =
    Print(42)
```

> No. `Print` wants a string, and `42` is an `int`.

That is a kind message. What does it say?

> That `Print` *expected* a string but *found* an `int`.

When does openverse tell us this?

> Before the program runs at all. It reads the whole program first.

Then how do we print `42`?

```{.verse .run}
Main():void =
    Print("{42}")
```

> ```{.output}
> 42
> ```

What do the braces `{` and `}` do?

> They hold a value. Its text is put into the string at that spot.

What does this print?

```{.verse .run}
Main():void =
    Print("I have {3 + 4} coins.")
```

> ```{.output}
> I have 7 coins.
> ```

Was `3 + 4` printed?

> No. Its value, `7`, was.

What is `3.5`, if it is not an `int`?

> A `float`: a number with a point. `2.0` is one too.

What does this print?

```{.verse .run}
Main():void =
    Print("{1.5 + 1.5}")
```

> ```{.output}
> 3.0
> ```
>
> A `float` keeps its point, even when it is whole.

And this?

```{.verse .run}
Main():void =
    Print("{0.1 + 0.2}")
```

> ```{.output}
> 0.30000000000000004
> ```
>
> Almost `0.3`. A `float` is a close guess.

Then when do we use an `int`?

> For what we count: coins, gems, keys. A `float` is for what we measure.

What does this print?

```{.verse .run}
Main():void =
    Print("one")
    Print("two")
    Print("three")
```

> ```{.output}
> one
> two
> three
> ```

In what order?

> From top to bottom, one line each.

Why are the three `Print`s pushed to the right?

> They are the *body* of `Main`. Everything indented under `Main():void =` belongs to it.
:::

::: {.rule title="The Rule of the Braces"}
To show a value, put it in braces inside a string, and print the string.
:::

::: qa
Is `true` a value?

> Yes.

Is `false` a value?

> Yes. `true` and `false` are the two values of type `logic`.

Can we write `Print("{true}")`?

```{.verse .reject expect="no ToString for logic"}
Main():void =
    Print("{true}")
```

> No. openverse knows how to write numbers, characters and strings as text, but not `logic`.

So what is `logic` good for?

> For asking questions. We will ask a lot of them in Chapter 3.

Is `'g'` a value?

> Yes. It is a single *character*, between single quotes. Its type is `char`.

Is `'g'` the same as `"g"`?

> No. `"g"` is a string that holds one character.

What does this print?

```{.verse .run}
Main():void =
    Print("Found a {'g'}em!")
```

> ```{.output}
> Found a gem!
> ```

Can a string be empty?

> Yes: `""`.

What is `"gold" + "en"`?

> `"golden"`. `+` sticks strings together.

What does this print?

```{.verse .run}
Main():void =
    Print("treasure" + " " + "map")
```

> ```{.output}
> treasure map
> ```

What is `array{3, 1, 4}`?

> An *array*: three `int`s in a row.

What is its type?

> `[]int`, said "array of `int`".

What is `array{3, 1, 4}.Length`?

> `3`. It has three elements.

What does this print?

```{.verse .run}
Main():void =
    Coins := array{5, 10, 25}
    Print("{Coins.Length} coins")
```

> ```{.output}
> 3 coins
> ```

What is `Coins`?

> A *name* for the array. We will name many things in Chapter 2.

What is `"gem".Length`?

```{.verse .run}
Main():void =
    Print("{"gem".Length}")
```

> ```{.output}
> 3
> ```

Why does a string have a `Length`?

> Because a string *is* an array: an array of `char`s. Its type, `string`, is another name for `[]char`.

Can an array hold an `int` and a string?

```{.verse .run}
Main():void =
    Mixed := array{1, "two"}
    Print("{Mixed.Length}")
```

> ```{.output}
> 2
> ```
>
> Yes, but only as things of type `any`, the type every value has.

What can we do with an `any`?

```{.verse .reject expect="no operator '+' for any and int"}
Main():void =
    Mixed := array{1, "two"}
    if (X := Mixed[0]):
        Print("{X + 1}")
```

> Almost nothing. Verse no longer knows that `Mixed[0]` is the `int` `1`. Keep one kind of thing in an array.

Is `array{}` an array?

> Yes, the empty one. Its `Length` is `0`.

What if we want an `int` and a string together?

> We use a *tuple*: `(1, "two")`.

What is the type of `(1, "two")`?

> `tuple(int, string)`.

How do we take a tuple apart?

```{.verse .run}
Main():void =
    Prize := (100, "gold")
    Print("{Prize(0)} pieces of {Prize(1)}")
```

> ```{.output}
> 100 pieces of gold
> ```

Why `Prize(0)` and not `Prize(1)` for the first part?

> Counting starts at zero: the first part is part `0`.

Is a tuple an array?

> No. A tuple has a fixed number of parts, each with its own type.
:::

::: {.rule title="The Rule of Types"}
Every value has a type: `int`, `float`, `logic`, `char`, `string`, an array
type such as `[]int`, or a tuple type such as `tuple(int, string)`. An array's
elements all share one type; a tuple's parts each have their own.
:::

::: qa
What is `void`?

> The type of "nothing worth giving back".

What does `Main():void` say?

> `Main` takes nothing (the empty parentheses) and gives back nothing of interest (`void`).

Then what does `Main` do?

> It does things, such as printing.

Can we leave notes in a program?

```{.verse .run}
Main():void =
    # This line is a comment.
    Print("Notes are for people.")
```

> ```{.output}
> Notes are for people.
> ```

What happened to the line that starts with `#`?

> openverse skipped it. Everything after `#` on a line is a *comment*.

What does this print?

```{.verse .run}
Main():void =
    Gems := array{'r', 'u', 'b', 'y'}
    Print("{Gems.Length} letters")
    Print("a " + "ruby")
```

> ```{.output}
> 4 letters
> a ruby
> ```

Is `Gems` a string?

> Yes! An array of `char`s *is* a string.

Can we print `Gems` itself, then?

```{.verse .run}
Main():void =
    Gems := array{'r', 'u', 'b', 'y'}
    Print(Gems)
```

> ```{.output}
> ruby
> ```

What does `Abs(-5)` give?

> `5`: the size of a number, without its sign.

And `Min(3, 9)` and `Max(3, 9)`?

```{.verse .run}
Main():void =
    Print("{Min(3, 9)} and {Max(3, 9)}")
```

> ```{.output}
> 3 and 9
> ```

Have we met every kind of value?

> No. Options, maps, structs and objects are still ahead. But these are the plain ones.
:::

That is enough treasure for one chapter. We have values; next we give them
names, and teach Verse some recipes of our own.

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

Can we hand a recipe to another recipe?

```{.verse .run}
Double(N:int):int = N * 2
Twice(F:int->int, N:int):int = F(F(N))

Main():void =
    Print("{Twice(Double, 5)}")
```

> ```{.output}
> 20
> ```

What is `int->int`?

> The type of a recipe that takes an `int` and gives back an `int`. `Double` is one, so `Twice` may take it, and calls it twice.

Why is there nothing after `Double` in `Twice(Double, 5)`?

> `Double(5)` would be a call, and give `10`. `Double` alone is the recipe itself, handed over to be used later.

Can a name hold a recipe?

```{.verse .run}
Double(N:int):int = N * 2
AddOne(N:int):int = N + 1

Main():void =
    var Step:int->int = Double
    Print("{Step(10)}")
    set Step = AddOne
    Print("{Step(10)}")
```

> ```{.output}
> 20
> 11
> ```
>
> Yes. A recipe is a value like any other.

May we hand `Twice` any recipe at all?

```{.verse .reject expect="expected type{_(:int):int}, found type{_(:string):string}"}
Shout(S:string):string = "{S}!"
Twice(F:int->int, N:int):int = F(F(N))

Main():void =
    Print("{Twice(Shout, 5)}")
```

> No. `Shout` takes a string, and `Twice` wants a recipe that takes an `int`. openverse writes `int->int` the long way, as `type{_(:int):int}`.

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

What is `7 / 2`, then?

> Exactly seven halves: a `rational`. Dividing `int`s never rounds.

How do we see a `rational`?

```{.verse .run}
Main():void =
    if (H := 7 / 2):
        Print("{Floor(H)} to {Ceil(H)}")
```

> ```{.output}
> 3 to 4
> ```
>
> `Floor` and `Ceil` give the whole numbers on either side of it.

Why is `7 / 2` inside an `if`?

> Because a division may fail: `7 / 0` has no answer.

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

# Shapes of Things

Numbers and strings are fine, but a treasure hunt is full of *things*: coins
with a metal and a worth, doors that are open or locked, players with names
and scores. In this chapter we give things a shape of our own.

::: qa
What is this?

```{.verse .check}
coin := struct:
    Metal:string = "gold"
    Worth:int

Main():void = {}
```

> A *struct*: a new type, `coin`, whose values have two *fields*, `Metal` and `Worth`.

What is `= "gold"` after `Metal:string`?

> A *default*: a coin is gold unless we say otherwise.

How do we make a coin?

```{.verse .run}
coin := struct:
    Metal:string = "gold"
    Worth:int

Main():void =
    A := coin{Worth := 10}
    B := coin{Metal := "silver", Worth := 2}
    Print("{A.Metal}, worth {A.Worth}")
    Print("{B.Metal}, worth {B.Worth}")
```

> ```{.output}
> gold, worth 10
> silver, worth 2
> ```

What is `A.Worth`?

> The `Worth` field of the coin `A`.

Can we leave out `Worth`?

> No. It has no default, so every coin must say its worth.

Are two coins with the same fields the same coin?

```{.verse .run}
coin := struct:
    Metal:string = "gold"
    Worth:int

Main():void =
    A := coin{Worth := 10}
    if (A = coin{Worth := 10}):
        Print("same coin")
```

> ```{.output}
> same coin
> ```
>
> Yes. A struct is a value, like a number. Equal fields, equal structs.

Can a struct change?

```{.verse .run}
coin := struct:
    Worth:int

Main():void =
    var C:coin = coin{Worth := 1}
    D := C
    set C.Worth = 9
    Print("{C.Worth} {D.Worth}")
```

> ```{.output}
> 9 1
> ```

Why is `D.Worth` still `1`?

> `set C.Worth = 9` made a new coin for the `var` `C`. `D` still names the old one.

What is this?

```{.verse .check}
door := enum:
    Open
    Locked
    Stuck

Main():void = {}
```

> An *enum*: a type with exactly three values, `door.Open`, `door.Locked` and `door.Stuck`.

How do we act on each kind of door?

```{.verse .run}
door := enum:
    Open
    Locked
    Stuck

Say(D:door):string =
    case (D):
        door.Open => "come in"
        door.Locked => "find the key"
        door.Stuck => "push harder"

Main():void =
    Print(Say(door.Locked))
    Print(Say(door.Stuck))
```

> ```{.output}
> find the key
> push harder
> ```

What does `case` do?

> It picks the line whose value matches `D`.

What if we forget a kind of door?

```{.verse .reject expect="a case without _"}
door := enum:
    Open
    Locked

Say(D:door):string =
    case (D):
        door.Open => "come in"

Main():void = Print(Say(door.Open))
```

> Verse refuses: a locked door would have no answer. We must name every value, or add `_ => …` for "anything else".
:::

::: {.rule title="The Rule of Shapes"}
A `struct` is a value made of named fields; two structs with equal fields
are equal. An `enum` is a type with a fixed list of values, and a `case`
must say what to do with each of them.
:::

::: qa
What is a `class`?

```{.verse .check}
player := class:
    Name:string
    var Score:int = 0

Main():void = {}
```

> A shape for *objects*: things that can change and that can be shared.

How is that different from a struct?

> A struct is a value. An object is a *thing*: every name for it sees the same thing.

What does this print?

```{.verse .run}
player := class:
    Name:string
    var Score:int = 0
    Win(Points:int)<transacts>:void =
        set Score += Points
    Show()<reads>:string =
        "{Name} has {Score}"

Main():void =
    P := player{Name := "Ada"}
    Same := P
    P.Win(5)
    Same.Win(3)
    Print(P.Show())
```

> ```{.output}
> Ada has 8
> ```

Why `8`?

> `P` and `Same` are two names for one player. Both wins went to Ada.

What are `Win` and `Show`?

> *Methods*: recipes that belong to the class. Inside them, `Score` means this player's score.

What are `<transacts>` and `<reads>`?

> Promises about what a method may do. We meet them properly in the next chapter.

Is a change to an object taken back when a question fails?

```{.verse .run}
chest := class:
    var Gold:int = 0

Main():void =
    C := chest{}
    if (set C.Gold = 100, C.Gold > 500):
        Print("rich")
    Print("{C.Gold}")
```

> ```{.output}
> 0
> ```
>
> Of course. Failure takes back everything, even inside objects.

Can one class build on another?

```{.verse .run}
hero := class<abstract>:
    Name:string
    Cheer():string

knight := class(hero):
    Cheer<override>():string = "For honor!"

wizard := class(hero):
    Cheer<override>():string = "Ta-da!"

Main():void =
    Party:[]hero = array{
        knight{Name := "Ada"},
        wizard{Name := "Lin"}}
    for (H : Party):
        Print("{H.Name}: {H.Cheer()}")
```

> ```{.output}
> Ada: For honor!
> Lin: Ta-da!
> ```

What does `class(hero)` say?

> A `knight` is a kind of `hero`: it has everything a hero has.

What is `<abstract>`?

> `hero` is only an idea: there are knights and wizards, but no plain heroes.

What does `<override>` say?

> This class gives its own `Cheer`, in place of the one it was promised.

How did each hero know its own cheer?

> Each object remembers its class. A knight cheers like a knight, even in an array of heroes.

How do we ask whether a hero is a knight?

```{.verse .run}
hero := class<abstract>:
    Name:string
knight := class(hero):
    Sword:int = 1
wizard := class(hero):
    Spells:int = 3

Main():void =
    Party:[]hero = array{
        knight{Name := "Ada"},
        wizard{Name := "Lin"}}
    for (H : Party, K := knight[H]):
        Print("{K.Name} is a knight")
```

> ```{.output}
> Ada is a knight
> ```

What does `knight[H]` do?

> It succeeds with `H` as a knight if `H` is one, and fails otherwise.

Square brackets again!

> Yes: asking "is this a knight?" may fail, so it uses brackets.
:::

::: {.rule title="The Rule of Objects"}
A `class` makes objects. Every name for an object sees the same object,
and its `var` fields may change. An object always knows its own class,
and `T[X]` asks whether `X` is a `T`.
:::

We have shapes, and things that change. The last chapter is about trust:
what a recipe promises it will, and will not, do, and which promises Verse
keeps for every program.

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

```{=latex}
\appendix
```

# The Rules

Every rule of the book, in the order we met them.

::: {.rule title="The Rule of the Braces"}
To show a value, put it in braces inside a string, and print the string.
:::

::: {.rule title="The Rule of Types"}
Every value has a type: `int`, `float`, `logic`, `char`, `string`, an array
type such as `[]int`, or a tuple type such as `tuple(int, string)`. An array's
elements all share one type; a tuple's parts each have their own.
:::

::: {.rule title="The Rule of Names"}
A name stands for one value for as long as it lives. Only a `var` may
change, and only by `set`.
:::

::: {.rule title="The Rule of Recipes"}
A function names its parameters, says what type it gives back, and gives
back the value of its last line. A `void` function is used for what it does.
:::

::: {.rule title="The Rule of Failure"}
A question in Verse succeeds or fails. Anything that might fail must sit
in a failure context, such as the condition of an `if`.
:::

::: {.rule title="The Rule of the Question Mark"}
`false` is a value, not a failure. To turn a `logic` into a question, add
`?`: `X?` succeeds when `X` is `true` and fails when it is `false`.
:::

::: {.rule title="The Rule of Brackets"}
A function that may fail is marked `<decides>` and is called with square
brackets, `F[X]`. A function without `<decides>` is called with
parentheses, `F(X)`, and never fails.
:::

::: {.rule title="The Rule of the Safe Guess"}
When a question fails, everything it did is taken back: every `set` and
every `Print`. When it succeeds, everything it did is kept.
:::

::: {.rule title="The Rule of Not, Or and And"}
`not` succeeds when its inside fails, and never keeps its inside's work.
`or` tries the left side, and if it fails, takes it back and tries the
right. `and` needs both sides to succeed.
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

::: {.rule title="The Rule of Loop"}
A `loop` repeats until a `break` (or a `return`) leaves it. A `for` needs
neither: it stops when it runs out of choices.
:::

::: {.rule title="The Rule of Recursion"}
A recipe may call itself, if each call is on a smaller problem and some
question finally stops it. In Verse, a failure is often that question.
A recipe whose choice calls itself may go on forever: whoever asks for
its values stops it.
:::

::: {.rule title="The Rule of the Box"}
An option `?t` is a box: `option{X}` holds `X`, `false` is empty. `Box?`
opens it, and fails when it is empty. `option{…}` turns success into a
full box and failure into an empty one.
:::

::: {.rule title="The Rule of the Map"}
A map `[k]v` finds a value by its key, and fails when the key is missing.
`set M[K] = V` adds or replaces; `set M[K] += V` needs the key to be there.
:::

::: {.rule title="The Rule of Shapes"}
A `struct` is a value made of named fields; two structs with equal fields
are equal. An `enum` is a type with a fixed list of values, and a `case`
must say what to do with each of them.
:::

::: {.rule title="The Rule of Objects"}
A `class` makes objects. Every name for an object sees the same object,
and its `var` fields may change. An object always knows its own class,
and `T[X]` asks whether `X` is a `T`.
:::

::: {.rule title="The Rule of Turns"}
A `<suspends>` recipe may wait. A `sync` waits for all its arms, a `race`
for the first, and `spawn` starts a task to `Await` later. Tasks take
turns on a clock of ticks, always in the same order, so a program with
tasks still has one answer.
:::

::: {.rule title="The Rule of Promises"}
A recipe's effects are promises: `<decides>` may fail, `<suspends>` may
wait, `<computes>` touches no changing thing, `<reads>` only looks,
`<allocates>` only makes new things, `<transacts>` may do it all. Verse
refuses a recipe that breaks its promise.
:::

::: {.rule title="The Rule of Errors"}
Failure is a polite "no" that a question can catch. An error, such as an
overflow or `Err()`, is a real mistake: nothing catches it, and the program
stops.
:::

::: {.rule title="The Rule of Trust"}
If Verse accepts your program, it has one answer, its failed guesses leave
no trace, its recipes without `<decides>` never fail, its types are kept,
and its promises about objects hold. Only overflow, `Err()` and endless
loops are left to watch for.
:::
