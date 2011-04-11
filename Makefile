
export OCAMLMAKEFILE = OCamlMakefile

export PACKS = unix

define PROJ_eventloop
  SOURCES = wmiirc.ml
  RESULT = ocaml-wmiirc
endef
export PROJ_eventloop

define PROJ_sbar
  SOURCES = statusbar.ml
  RESULT = statusbar
endef
export PROJ_sbar

ifndef SUBPROJS
    export SUBPROJS = eventloop sbar
endif

DESTDIR = ~/.wmii

all: bc

install:
	cp ocaml-wmiirc statusbar keys wmiirc2 $(DESTDIR)

%:
	@make -f $(OCAMLMAKEFILE) subprojs SUBTARGET=$@

