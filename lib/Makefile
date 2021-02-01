SJASMPLUS = sjasmplus
SJASMPLUSFLAGS = --msg=war --nologo
INCLUDE_FILES = $(wildcard *.i.asm)
CP = cp

marbles.bin: marbles-grid.asm $(INCLUDE_FILES) Makefile
	$(SJASMPLUS) --zxnext $(SJASMPLUSFLAGS) --lst --lstlab marbles-grid.asm

marbles.sna: marbles-grid.asm $(INCLUDE_FILES) Makefile
	$(SJASMPLUS) --zxnext=cspect -Dtesting $(SJASMPLUSFLAGS) marbles-grid.asm

copy:
	$(CP) marbles.bin ../src/assets/marbles.bin

.PHONY: clean all copy

all: marbles.bin marbles.sna

test: marbles.sna

clean:
	$(RM) -f marbles.bin marbles.sna marbles-grid.lst marbles-grid.sld marbles-grid.labels

