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
Every value has a type: `int`, `logic`, `char`, `string`, an array type
such as `[]int`, or a tuple type such as `tuple(int, string)`. An array's
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
