# promodoc — build and check the openverse books.
#
#   make            check every book, then build every PDF
#   make check      run every program and compare every Lean statement (needs openverse)
#   make pdf        build/verse-logic/verse-logic.pdf, build/little-verser/little-verser.pdf
#   make verse-logic | make little-verser    one book (check + pdf)
#   make generate AGENT=claude BOOK=little-verser [CHAPTER=3] [TASK="..."] [MODEL=...] [DRY=1]
#                   regenerate a book with an agent CLI (scripts/generate.sh)
#
# OPENVERSE is the openverse checkout whose Lean proofs and binary the books
# are checked against (default: ../openverse).

OPENVERSE ?= $(abspath ../openverse)
export OPENVERSE
BOOKS := verse-logic little-verser
AGENT ?= claude
BOOK ?= all

.PHONY: all check pdf clean generate $(BOOKS)

all: check pdf

check:
	python3 scripts/check-books.py $(BOOKS)

pdf:
	scripts/build.sh $(BOOKS)

$(BOOKS):
	python3 scripts/check-books.py $@
	scripts/build.sh $@

generate:
	scripts/generate.sh --agent $(AGENT) --book $(BOOK) \
	  $(if $(CHAPTER),--chapter $(CHAPTER)) $(if $(TASK),--task "$(TASK)") $(if $(MODEL),--model $(MODEL)) $(if $(DRY),--dry-run)

clean:
	rm -rf build
