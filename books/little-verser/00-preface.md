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

You need no mathematics beyond arithmetic, and no programming. You need a
little patience, a pencil, and the card.

Do not hurry. Each chapter builds on the one before. When a box with a
**Rule** appears, stop and read it twice: the rules are the whole book in
miniature, and the last pages collect them all.

Ready? Let's go treasure hunting.
