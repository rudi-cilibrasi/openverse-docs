```{=latex}
\appendix
```

# The Rules

Every rule of the book, in the order we met them.

::: {.rule title="The Rule of the Braces"}
To show a value, put it in braces inside a string, and print the string.
:::

::: {.rule title="The Rule of Types"}
Every value has a type: `int`, `logic`, `char`, `string`, an array type
such as `[]int`, or a tuple type such as `tuple(int, string)`. An array's
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

::: {.rule title="The Rule of Loop"}
A `loop` repeats until a `break` (or a `return`) leaves it. A `for` needs
neither: it stops when it runs out of choices.
:::

::: {.rule title="The Rule of Recursion"}
A recipe may call itself, if each call is on a smaller problem and some
question finally stops it. In Verse, a failure is often that question.
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

::: {.rule title="The Rule of Promises"}
A recipe's effects are promises: `<decides>` may fail, `<computes>` touches
no changing thing, `<reads>` only looks, `<allocates>` only makes new
things, `<transacts>` may do it all. Verse refuses a recipe that breaks its
promise.
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
