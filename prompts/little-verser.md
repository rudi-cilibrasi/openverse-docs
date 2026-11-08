# Book: The Little Verser

*A friendly dialogue about Verse, the language that knows how to fail.*

## Reader and aim

A curious beginner: a high-school student, a game maker, a programmer who
has never seen a logic language. No mathematics beyond arithmetic, no
programming experience required. By the end the reader can write small
Verse programs, and understands failure, failure contexts and rollback well
enough to *think* in Verse, which is what makes Verse different.

## Form: a dialogue

The book is written as questions and answers, in the manner of *The Little
Lisper*: the question on the left, the answer on the right, each step a
small one, and the reader invited to answer before looking. Imitate the
format only; never reuse that book's text, examples or rule names.

Write each chapter's dialogue inside a `::: qa` div. In it, a **block quote
is an answer**, and the blocks before it are its question:

````markdown
::: qa
Is `42` a value?

> Yes. It is an `int`.

What does this program print?

```{.verse .run}
Main():void = Print("Hi!")
```

> ```{.output}
> Hi!
> ```
:::
````

(Inside a block quote every line starts with `> `, also the lines of a code
block. An answer that has an output block *and* a sentence is one block
quote: join them with a line holding only `>`. A blank line would start a
second block quote, which the checker reports as an answer without a
question.) Keep answers short: a word, a sentence, a value, sometimes a short
output block. Code in a question is at most 46 characters a line, in an
answer 28. Close a dialogue (`:::`) to write a short paragraph or a rule box,
then open another.

## Rules

Each chapter distills its lesson into one to three **rules**, in
`::: {.rule title="The Rule of …"}` boxes: one or two sentences each, easy to
remember, named in the book's own words (for example "The Rule of the Safe
Guess" for rollback). A final appendix, `A1-rules.md`, collects every rule.

## No Lean, ever

The Little Verser shows no Lean: no Lean code blocks, no Lean names
(`Eval.det` and the like), and not the word "Lean". Where openverse proves a
promise (one answer per program; a failed guess leaves no trace; a function
without `<decides>` never fails; a well-typed program never hits a type
error; a `<reads>` function changes no object), say it in plain English:
"the people who built openverse proved, with a computer checking every step,
that …". The checker enforces this rule.

## Chapter plan (at most 8 chapters)

A playful, consistent world helps: a treasure hunt with coins, gems, chests,
keys and players. Keep examples tiny.

| # | File | Title | Teaches |
|---|---|---|---|
| — | `00-preface.md` | Before We Begin | how to read the dialogue; how to run a program (`openverse run FILE.verse`) |
| 1 | `01-values.md` | Plain Values | `int`, `logic`, `char`, `string`, arrays, tuples; `Main`, `Print`, interpolation |
| 2 | `02-names.md` | Names and Recipes | `X := …`, typed names, functions, recursion, `var` and `set`, no shadowing |
| 3 | `03-fail.md` | Yes, No, and Fail | comparisons that fail, `if`, failure contexts, `<decides>`, `F[…]` vs `F(…)`, indexing |
| 4 | `04-rollback.md` | Take It Back | rollback of `set` and `Print` in a failed condition; `not`, `or`, `and` |
| 5 | `05-again.md` | Again and Again | `for` over arrays and ranges, filters, several generators, `loop`, `break`, `return` |
| 6 | `06-maybe.md` | Maybe | options `?t`, `option{…}`, `?`, `false` as empty, maps `[k]v` |
| 7 | `07-shapes.md` | Shapes of Things | structs, enums and `case`, classes, methods, inheritance, casts, `var` fields |
| 8 | `08-promises.md` | Promises Kept | effects (`<decides>`; `<suspends>` with `Sleep`, `sync`, `race`, `spawn`, taking turns; `<computes>`, `<reads>`, `<transacts>`), runtime errors (overflow, `Err()`), and the promises openverse proves, in English |
| A | `A1-rules.md` | The Rules | every rule, in order |

Each numbered chapter: a one-paragraph opening outside the dialogue, then
roughly 45 to 90 question/answer pairs in a few `::: qa` dialogues, with its
rules in between, and a closing line that hints at the next chapter.

## Voice

Warm, patient, a little funny, never cute for its own sake. Questions build
on each other; sometimes the answer is "No", sometimes "Try it". Introduce
one idea at a time and repeat it with a variation before moving on. Use the
reader's own predictions: "What do you think this prints?" then show the
output. Mistakes are part of the lesson: show a program the compiler
rejects (```` ```{.verse .reject expect="…"} ````) and explain the message
kindly.

Every program in the book is real and is run by the checker; prefer whole
programs (`Main():void = …`) to fragments, even when they are tiny.
