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
