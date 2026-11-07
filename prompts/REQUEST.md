# The request behind these books

The documentation set was started from this request by the maintainer
(7 November 2026), quoted verbatim:

> add a documentation set into the repo that can build PDF versions at least
> of: 1. Verse Logic 2. Little Verser. VL will be aimed at Math/Logic/CS
> college or grad students and will feature symbolic logic heavily. Each
> chapter will focus on a single core Lean theorem or property and then show
> code examples and motivate it. Altogether aim for 8 or fewer chapters.
> 2. This will be a beginners guide to learning it similar to the famous
> Little Lisper. Note that 1 should be based on the Lean proofs and
> properties we have primarily with some code examples whereas 2 should not
> directly show any Lean and instead just take the friendlier approach in
> English. Make sure to include the prompt in the repo as well as the CLI
> commands for both codex and cli to run it properly from a script for
> either. (might be same script) use the promodoc repo to hold this stuff.
> it is private for now.

The repository was later renamed **openverse-docs** and made public, with the
online playground and openverse itself as submodules and a website built from
both books (see the README).

## How the request became prompts

- `common.md`: shared by both books: the sources of truth in openverse,
  the facts about Verse both books must get right, the Markdown conventions
  that `scripts/check-books.py` and the PDF build depend on, the required
  verification, and house style. It also records two constraints that are
  not in the request: write only from openverse's own documents, and
  imitate *The Little Lisper*'s format but never its text.
- `verse-logic.md`: the reader, the chapter plan (one core theorem per
  chapter, eight chapters), the shape of a chapter (theorem in mathematics,
  then in Lean, proof, code, limits, exercises) and the notation.
- `little-verser.md`: the dialogue format (questions left, answers right),
  rules, the "no Lean, ever" rule (enforced by the checker), the chapter
  plan and the voice.

`scripts/generate.sh` concatenates `common.md`, the book's prompt and a
"This run" section (scope, paths, the maintainer's extra instruction), and
runs it with Claude Code or Codex. See the README for the commands.
