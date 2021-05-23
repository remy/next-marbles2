INCLUDE_FILES = $(wildcard src/assets/*)
FILESIZE = stat -f %z marbles.bas
SIZE = stat -f %z
SUM = awk '{s+=$$0} END {print s}'

marbles.bas: src/marbles.bas.txt $(INCLUDE_FILES) Makefile
	@cat src/marbles.bas.txt | sed 's/TESTING=1/TESTING=0/' | sed 's/^\s*;.*$$//g' | txt2bas -define -o marbles.bas

	@truncate -s %256 marbles.bas
	@echo "9900 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/marbles.pal) -mb 15 : ; pal"
	@cat src/assets/marbles.pal >> marbles.bas
	@echo "9901 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/font*.bin | $(SUM)) -mb 29 : ; font"
	@cat src/assets/font-computing-60s.bin >> marbles.bas
	@cat src/assets/font-coal.bin >> marbles.bas
	@echo "9902 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/controls.nxi src/assets/new-game.nxi src/assets/next-level-small.nxi | $(SUM)) -mb 22 : ; gfx A"
	@cat src/assets/controls.nxi >> marbles.bas
	@cat src/assets/new-game.nxi >> marbles.bas
	@cat src/assets/next-level-small.nxi >> marbles.bas
	@echo "9903 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/game-over.nxi src/assets/title.nxi | $(SUM)) -mb 23 : ; gfx B"
	@cat src/assets/game-over.nxi >> marbles.bas
	@cat src/assets/title.nxi >> marbles.bas
	@echo "9904 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/controls-alt.nxi src/assets/alert.nxi | $(SUM)) -mb 28 : ; gfx C"
	@cat src/assets/controls-alt.nxi >> marbles.bas
	@cat src/assets/alert.nxi >> marbles.bas
	@echo "9905 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/marbles.bin) -mb 20 : ; lib"
	@cat src/assets/marbles.bin >> marbles.bas
	@echo "9906 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/marbles.spr) -mb 16 : ; sprites"
	@cat src/assets/marbles.spr >> marbles.bas
	@echo "9907 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/marbles.afb) -mb 24 : ; fx"
	@cat src/assets/marbles.afb >> marbles.bas
	@echo ".extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/welcome.nxi) -mb 9 : ; welcome"
	@cat src/assets/welcome.nxi >> marbles.bas

	@echo "9909 ON ERROR GOTO 9911"
	@echo "9910 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/http) -o /dot/http : ; .http"
	@cat src/assets/http >> marbles.bas

	@echo "9911 ON ERROR GOTO 9913"
	@echo "9912 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/ayfx.drv) -o /nextzxos/ayfx.drv : ; ayfx.drv"
	@cat src/assets/ayfx.drv >> marbles.bas

	@echo "9913 ON ERROR GOTO 9915"
	@echo "9914 .extract MARBLES.BAS +$$($(FILESIZE)) $$($(SIZE) src/assets/input.drv) -o /nextzxos/input.drv : ; input.drv"
	@cat src/assets/input.drv >> marbles.bas

	@echo "9990 ON ERROR: RETURN"

.PHONY: all clean

all: marbles.bas
