#!/usr/bin/env python3
"""Check the books against openverse: every program, every Lean statement.

    scripts/check-books.py                 # every book
    scripts/check-books.py verse-logic     # one book
    OPENVERSE=/path/to/openverse scripts/check-books.py

The Markdown is parsed by pandoc (``pandoc -t json``), so block quotes and
fenced divs are seen exactly as the PDF build sees them.

Code blocks
  ```{.verse .run}        a whole program; it is run with ``openverse run``.
                          The next ```{.output} block (before the next program)
                          must equal its standard output. Attribute exit="N"
                          gives the expected exit code (default 0), and
                          fuel="N" runs it with ``--fuel N`` (for programs
                          that do not terminate: exit 3).
  ```{.verse .check}      a whole program that must be accepted (not run).
  ```{.verse .reject expect="text"}
                          a whole program that ``openverse check`` must reject
                          (exit 4) with a message containing "text".
  ```{.verse .fragment}   part of a program; not checked.
  ```{.lean .claim name="Eval.det"}
                          a theorem statement; must equal, up to white space,
                          the statement of that theorem in docs/CLAIMS.md.
  ```{.lean .excerpt file="OpenVerse/Core/Semantics.lean"}
                          lines copied from that file; each run of lines
                          between elision lines ("..." or "…") must occur in
                          the file, up to white space, in order.
  ```{.lean .fragment}    Lean written for the book (an exercise); not checked.

Book rules
  * at most 8 numbered chapters (files NN-*.md with NN >= 01);
  * verse-logic: every numbered chapter has a ::: theorem box, a .claim and
    a .verse .run block;
  * little-verser: no Lean at all (no lean blocks, no Lean names, the word
    "Lean" does not occur), every chapter has a ::: qa dialogue and a ::: rule;
  * code lines fit the page (see WIDTH below).
"""
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OPENVERSE = Path(os.environ.get("OPENVERSE", ROOT.parent / "openverse")).resolve()
OV_BIN = OPENVERSE / ".lake/build/bin/openverse"
CLAIMS = OPENVERSE / "docs/CLAIMS.md"
MAX_CHAPTERS = 8
TIMEOUT = 20

# maximum code line length, by book and by place
WIDTH = {
    "verse-logic": {"body": 78, "q": 78, "a": 78},
    "little-verser": {"body": 64, "q": 46, "a": 28},
}

LEAN_NAMES = re.compile(
    r"\b(Eval|EvalList|EvalFor|Runs|Prog|Expr|Typed|VTy|Res|St|Glob|HeapOp|Prim)\.[a-z_]\w*"
)


class Problems:
    def __init__(self):
        self.items = []

    def add(self, where, msg):
        self.items.append(f"{where}: {msg}")


def pandoc_json(path):
    out = subprocess.run(
        ["pandoc", "-f", "markdown+fenced_divs+raw_tex+tex_math_dollars", "-t", "json", str(path)],
        check=True, capture_output=True, text=True,
    ).stdout
    return json.loads(out)


def stringify(node):
    """Plain text of a pandoc JSON node (roughly what pandoc.utils.stringify does)."""
    if isinstance(node, list):
        return "".join(stringify(n) for n in node)
    if not isinstance(node, dict):
        return ""
    t, c = node.get("t"), node.get("c")
    if t == "Str":
        return c
    if t in ("Space", "SoftBreak", "LineBreak"):
        return " "
    if t in ("Code", "Math"):
        return c[1]
    if t == "CodeBlock":
        return c[1]
    if t == "RawInline" or t == "RawBlock":
        return ""
    return stringify(c)


def walk(blocks, ctx, visit):
    """Visit blocks in document order; ctx records enclosing div classes and q/a."""
    for b in blocks:
        t, c = b.get("t"), b.get("c")
        visit(b, ctx)
        if t == "Div":
            (_, classes, _), inner = c
            if "qa" in classes:
                # questions are the non-quote blocks, answers the block quotes
                for x in inner:
                    if x.get("t") == "BlockQuote":
                        visit(x, ctx + ["a"])
                        walk(x["c"], ctx + ["a"], visit)
                    else:
                        walk([x], ctx + ["q"], visit)
            else:
                walk(inner, ctx + list(classes), visit)
        elif t == "BlockQuote":
            walk(c, ctx, visit)
        elif t in ("BulletList", "OrderedList"):
            items = c if t == "BulletList" else c[1]
            for item in items:
                walk(item, ctx, visit)
        elif t == "DefinitionList":
            for _, defs in c:
                for d in defs:
                    walk(d, ctx, visit)


def norm(s):
    return " ".join(s.split())


def load_claims():
    """name -> statement, from the ```lean blocks of docs/CLAIMS.md."""
    text = CLAIMS.read_text()
    claims = {}
    for m in re.finditer(r"^## `([^`]+)`.*?```lean\n(.*?)```", text, re.S | re.M):
        claims[m.group(1)] = m.group(2)
    return claims


def run(cmd, timeout=TIMEOUT):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired:
        return None, "", f"timed out after {timeout}s"


def check_book(book, problems, stats):
    src = ROOT / "books" / book
    files = sorted(p for p in src.glob("*.md"))
    chapters = [p for p in files if re.match(r"^\d\d-", p.name) and not p.name.startswith("00-")]
    if len(chapters) > MAX_CHAPTERS:
        problems.add(book, f"{len(chapters)} numbered chapters; at most {MAX_CHAPTERS}")
    claims = load_claims()
    width = WIDTH.get(book, WIDTH["verse-logic"])
    tmp = Path(tempfile.mkdtemp(prefix="promodoc-"))

    for path in files:
        rel = path.relative_to(ROOT)
        doc = pandoc_json(path)
        found = {"theorem": 0, "claim": 0, "run": 0, "qa": 0, "rule": 0}
        pending = []  # [(where, expected exit, stdout)] programs awaiting an output block
        codeblocks = []

        def visit(b, ctx):
            t, c = b.get("t"), b.get("c")
            if t == "Div":
                classes = c[0][1]
                for k in ("theorem", "qa", "rule"):
                    if k in classes:
                        found[k] += 1
                if "qa" in classes:
                    # the shape filters/qa.lua needs: question blocks, then one block quote
                    asked = False
                    for x in c[1]:
                        if x.get("t") == "BlockQuote":
                            if not asked:
                                problems.add(rel, "a ::: qa answer (block quote) without a question before it: "
                                             + stringify(x)[:60])
                            asked = False
                        else:
                            asked = True
                    if asked:
                        problems.add(rel, "a ::: qa dialogue ends with a question that has no answer")
            if t == "CodeBlock":
                codeblocks.append((b, ctx))

        walk(doc["blocks"], [], visit)

        # prose checks for the Little Verser: no Lean, not even by name
        if book == "little-verser":
            text = stringify(doc["blocks"])
            if re.search(r"\bLean\b", text):
                problems.add(rel, 'mentions "Lean"; The Little Verser shows no Lean')
            for m in LEAN_NAMES.finditer(text):
                problems.add(rel, f"uses the Lean name {m.group(0)}")

        for idx, (b, ctx) in enumerate(codeblocks, 1):
            (ident, classes, kv), text = b["c"]
            attrs = dict(kv)
            first = next((ln.strip() for ln in text.split("\n") if ln.strip()), "")
            where = f"{rel} [code block {idx}: {first[:48]}]"
            place = "a" if "a" in ctx else ("q" if "q" in ctx else "body")
            limit = width[place]
            for i, line in enumerate(text.split("\n"), 1):
                if len(line) > limit:
                    problems.add(where, f"line {i} has {len(line)} characters; at most {limit} here ({place})")

            if "output" in classes:
                if not pending:
                    problems.add(where, "an output block with no program before it")
                    continue
                pwhere, _, stdout = pending.pop()
                if stdout is not None and stdout.rstrip("\n") != text.rstrip("\n"):
                    problems.add(pwhere, "output differs from the book:\n--- book\n" + text
                                 + "\n--- openverse\n" + stdout.rstrip("\n"))
                continue

            if "lean" in classes:
                if book == "little-verser":
                    problems.add(where, "a Lean block in The Little Verser")
                    continue
                if "claim" in classes:
                    name = attrs.get("name")
                    found["claim"] += 1
                    stats["claims"] += 1
                    if name not in claims:
                        problems.add(where, f"claim {name!r} is not in {CLAIMS}")
                    elif norm(claims[name]) != norm(text):
                        problems.add(where, f"claim {name} differs from docs/CLAIMS.md:\n{claims[name]}")
                elif "excerpt" in classes:
                    stats["excerpts"] += 1
                    f = OPENVERSE / attrs.get("file", "")
                    if not f.is_file():
                        problems.add(where, f"excerpt file {attrs.get('file')!r} does not exist")
                        continue
                    hay = norm(f.read_text())
                    pos = 0
                    for seg in re.split(r"^\s*(?:\.\.\.|…|-- …|-- \.\.\.)\s*$", text, flags=re.M):
                        s = norm(seg)
                        if not s:
                            continue
                        k = hay.find(s, pos)
                        if k < 0:
                            problems.add(where, f"excerpt not found in {attrs.get('file')}:\n{seg.strip()[:300]}")
                            break
                        pos = k + len(s)
                elif "fragment" not in classes:
                    problems.add(where, "a lean block must be .claim, .excerpt or .fragment")
                continue

            if "verse" not in classes:
                continue
            kinds = [k for k in ("run", "check", "reject", "fragment") if k in classes]
            if len(kinds) != 1:
                problems.add(where, "a verse block needs exactly one of .run .check .reject .fragment")
                continue
            kind = kinds[0]
            if kind == "fragment":
                stats["fragments"] += 1
                continue
            # a program left without its output block: only its exit code matters
            if pending:
                pending.clear()
            f = tmp / f"p{stats['programs'] + stats['rejects'] + stats['checks']}.verse"
            f.write_text(text + "\n")
            if kind == "run":
                stats["programs"] += 1
                found["run"] += 1
                want = int(attrs.get("exit", "0"))
                fuel = ["--fuel", attrs["fuel"]] if "fuel" in attrs else []
                code, out, err = run([str(OV_BIN), "run", str(f)] + fuel)
                if code != want:
                    problems.add(where, f"exit {code}, wanted {want}; stderr: {err.strip()[:400]}")
                    pending.append((where, want, None))
                else:
                    pending.append((where, want, out))
            elif kind == "check":
                stats["checks"] += 1
                code, out, err = run([str(OV_BIN), "check", str(f)])
                if code != 0:
                    problems.add(where, f"openverse check: exit {code}: {err.strip()[:400]}")
            else:
                stats["rejects"] += 1
                expect = attrs.get("expect", "")
                if not expect:
                    problems.add(where, 'a .reject block needs expect="part of the message"')
                code, out, err = run([str(OV_BIN), "check", str(f)])
                if code != 4 or expect not in err:
                    problems.add(where, f"wanted rejection (exit 4) with {expect!r}; got exit {code}: {err.strip()[:400]}")

        is_chapter = path in chapters
        if is_chapter and book == "verse-logic":
            for k in ("theorem", "claim", "run"):
                if found[k] == 0:
                    problems.add(rel, f"a Verse Logic chapter needs at least one {k} "
                                 + {"theorem": "box (::: theorem)", "claim": "(```{.lean .claim})",
                                    "run": "program (```{.verse .run})"}[k])
        if is_chapter and book == "little-verser":
            for k in ("qa", "rule"):
                if found[k] == 0:
                    problems.add(rel, f"a Little Verser chapter needs a ::: {k} block")
    # an appendix that collects the rules must repeat them exactly, in order
    rules = {"chapters": [], "appendix": []}
    def collect(path, into):
        def v(b, ctx):
            if b.get("t") == "Div" and "rule" in b["c"][0][1]:
                into.append((dict(b["c"][0][2]).get("title", ""), " ".join(stringify(b["c"][1]).split())))
        walk(pandoc_json(path)["blocks"], [], v)
    for path in files:
        if path in chapters:
            collect(path, rules["chapters"])
        elif re.match(r"^A\d", path.name):
            collect(path, rules["appendix"])
    if rules["appendix"] and rules["appendix"] != rules["chapters"]:
        have = {t for t, _ in rules["appendix"]}
        want = {t for t, _ in rules["chapters"]}
        detail = [f"missing: {t}" for t in sorted(want - have)] + [f"extra: {t}" for t in sorted(have - want)]
        if not detail:
            detail = [f"differs: {a[0]}" for a, b in zip(rules["appendix"], rules["chapters"]) if a != b] or ["order differs"]
        problems.add(book, "the rules appendix does not repeat the chapters' rules: " + "; ".join(detail))
    stats["chapters"] += len(chapters)


def main():
    if not OV_BIN.is_file():
        sys.exit(f"check-books.py: no openverse binary at {OV_BIN}\n"
                 f"  build it with: (cd {OPENVERSE} && lake build), or set OPENVERSE=")
    books = sys.argv[1:] or sorted(p.name for p in (ROOT / "books").iterdir() if p.is_dir())
    problems = Problems()
    for book in books:
        stats = dict(chapters=0, programs=0, checks=0, rejects=0, fragments=0, claims=0, excerpts=0)
        check_book(book, problems, stats)
        print(f"{book}: {stats['chapters']} chapters, {stats['programs']} programs run, "
              f"{stats['checks']} checked, {stats['rejects']} rejections, {stats['fragments']} fragments, "
              f"{stats['claims']} Lean claims, {stats['excerpts']} Lean excerpts")
    if problems.items:
        print(f"\n{len(problems.items)} problem(s):", file=sys.stderr)
        for p in problems.items:
            print("  " + p.replace("\n", "\n    "), file=sys.stderr)
        sys.exit(1)
    print("all checks passed")


if __name__ == "__main__":
    main()
