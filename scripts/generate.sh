#!/usr/bin/env bash
# Write or revise a book with an agent CLI — Claude Code (`claude`) or Codex (`codex`).
#
#   scripts/generate.sh --agent claude --book little-verser
#   scripts/generate.sh --agent codex  --book verse-logic --chapter 3
#   scripts/generate.sh --agent claude --book all --task "Update for the new heap theorems"
#   scripts/generate.sh --agent codex  --book verse-logic --dry-run     # print the command only
#
# Options
#   --agent claude|codex   which CLI runs the prompt (default: claude, or $PROMODOC_AGENT)
#   --book NAME|all        verse-logic, little-verser, or all (one agent session per book)
#   --chapter N            limit the session to chapter N (01-08) of the book
#   --task TEXT            an extra instruction appended to the prompt
#   --model MODEL          passed to the CLI (claude: --model; codex: -m)
#   --openverse DIR        the openverse checkout (default: $OPENVERSE or ../openverse)
#   --unsafe               no sandbox and no permission checks (only in a throwaway checkout)
#   --no-verify            skip the final `make <book>` that this script runs itself
#   --dry-run              print the prompt file and the command, run nothing
#
# The prompt is prompts/common.md + prompts/<book>.md + a "This run" section;
# the composed prompt is saved in build/prompts/, the transcript in build/logs/.
# After the agent stops, the script checks and builds the book itself, so a
# run only succeeds when every program in the book runs and the PDF builds.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

agent="${PROMODOC_AGENT:-claude}"
book="all"; chapter=""; task=""; model=""; unsafe=0; verify=1; dry=0
openverse="${OPENVERSE:-$root/../openverse}"

usage() { sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent) agent="$2"; shift 2 ;;
    --book) book="$2"; shift 2 ;;
    --chapter) chapter="$2"; shift 2 ;;
    --task) task="$2"; shift 2 ;;
    --model) model="$2"; shift 2 ;;
    --openverse) openverse="$2"; shift 2 ;;
    --unsafe) unsafe=1; shift ;;
    --no-verify) verify=0; shift ;;
    --dry-run) dry=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "generate.sh: unknown option $1" >&2; usage 2 ;;
  esac
done

case "$agent" in claude|codex) ;; *) echo "generate.sh: --agent must be claude or codex" >&2; exit 2 ;; esac
openverse="$(cd "$openverse" && pwd)" || { echo "generate.sh: no openverse checkout at $openverse" >&2; exit 2; }
export OPENVERSE="$openverse"
ov_bin="$openverse/.lake/build/bin/openverse"
[[ -x "$ov_bin" ]] || { echo "generate.sh: build openverse first: (cd $openverse && lake build)" >&2; exit 2; }
if [[ -n "$chapter" ]]; then chapter="$(printf '%02d' "$((10#$chapter))")"; fi

books=()
if [[ "$book" == "all" ]]; then books=(verse-logic little-verser); else books=("$book"); fi
for b in "${books[@]}"; do
  [[ -f "prompts/$b.md" ]] || { echo "generate.sh: no prompt prompts/$b.md" >&2; exit 2; }
done
[[ "$dry" -eq 1 ]] || command -v "$agent" >/dev/null || { echo "generate.sh: $agent is not on PATH" >&2; exit 2; }

stamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p build/prompts build/logs

compose() {  # compose BOOK OUTFILE
  local b="$1" f="$2" scope
  if [[ -n "$chapter" ]]; then
    scope="Work only on chapter $chapter of this book (books/$b/$chapter-*.md; create it if it does not exist, following the chapter plan). Do not change other chapters, except to fix a cross-reference that your change breaks."
  else
    scope="Work on the whole book: write every file of the chapter plan that is missing, and improve the ones that exist."
  fi
  {
    cat prompts/common.md
    printf '\n\n'
    cat "prompts/$b.md"
    printf '\n\n## This run\n\n'
    printf -- '- Book: `%s` (sources in `books/%s/`).\n' "$b" "$b"
    printf -- '- Scope: %s\n' "$scope"
    printf -- '- The openverse checkout is `%s`; its binary is `%s`.\n' "$openverse" "$ov_bin"
    [[ -n "$task" ]] && printf -- '- Extra instruction from the maintainer: %s\n' "$task"
    printf -- '- Finish only when `make %s` succeeds (it runs `scripts/check-books.py %s` and `scripts/build.sh %s`).\n' "$b" "$b" "$b"
    printf -- '- End with a short report: what you changed, and the last lines of `make %s`.\n' "$b"
  } >"$f"
}

status=0
for b in "${books[@]}"; do
  pf="build/prompts/$b-$stamp.md"
  log="build/logs/$b-$agent-$stamp.log"
  compose "$b" "$pf"

  if [[ "$agent" == "claude" ]]; then
    cmd=(claude -p --output-format text --add-dir "$openverse")
    [[ -n "$model" ]] && cmd+=(--model "$model")
    if [[ "$unsafe" -eq 1 ]]; then
      cmd+=(--dangerously-skip-permissions)
    else
      # edits are accepted; shell commands are limited to the ones the work needs
      cmd+=(--permission-mode acceptEdits --allowedTools
        "Read" "Edit" "Write" "Glob" "Grep"
        "Bash(make:*)" "Bash(python3 scripts/check-books.py:*)" "Bash(scripts/check-books.py:*)"
        "Bash(scripts/build.sh:*)" "Bash($ov_bin:*)" "Bash(pandoc:*)" "Bash(pdftotext:*)"
        "Bash(pdfinfo:*)" "Bash(ls:*)" "Bash(cat:*)" "Bash(head:*)" "Bash(tail:*)" "Bash(wc:*)"
        "Bash(grep:*)" "Bash(rg:*)" "Bash(sed -n:*)" "Bash(mkdir:*)" "Bash(mktemp:*)"
        "Bash(git status:*)" "Bash(git diff:*)" "Bash(git log:*)")
    fi
  else
    cmd=(codex exec -C "$root" --color never -o "build/logs/$b-$agent-$stamp.last.md")
    [[ -n "$model" ]] && cmd+=(-m "$model")
    if [[ "$unsafe" -eq 1 ]]; then
      cmd+=(--dangerously-bypass-approvals-and-sandbox)
    else
      # writes inside this repository only; openverse is read (and run) in place
      cmd+=(-s workspace-write)
    fi
    cmd+=(-)   # the prompt comes from stdin
  fi

  if [[ "$dry" -eq 1 ]]; then
    echo "# prompt: $pf ($(wc -l <"$pf") lines)"
    printf '%q ' "${cmd[@]}"; echo "< $pf"
    continue
  fi

  echo "== $b: $agent is working (transcript: $log)"
  if ! "${cmd[@]}" <"$pf" 2>&1 | tee "$log"; then
    echo "generate.sh: $agent exited with an error on $b" >&2
    status=1
  fi
  if [[ "$verify" -eq 1 ]]; then
    echo "== $b: verifying"
    if ! make --no-print-directory "$b" 2>&1 | tee -a "$log"; then
      echo "generate.sh: $b does not pass make $b after the agent's run" >&2
      status=1
    fi
  fi
done
exit "$status"
