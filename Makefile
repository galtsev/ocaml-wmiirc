
SOURCES = wmiirc.ml
PACKS = unix
RESULT = ocaml-wmiirc
#THREADS = yes
DESTDIR = ~/.wmii
.DEFAULT_GOAL = byte-code

install:
	cp $(RESULT) $(DESTDIR)
	cp keys $(DESTDIR)
	cp wmiirc2 $(DESTDIR)

-include OCamlMakefile
