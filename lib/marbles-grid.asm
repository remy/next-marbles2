	DEVICE ZXSPECTRUM48
	SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

	INCLUDE "./rom.inc.asm"

PROGRAM_START:

;	DEFINE testing
	IFDEF testing				; if testing, call the we jump to main
	ORG $c000-3
Start:
	jp Main

	ENDIF

	ORG $c000				; we're expecting/hoping the bank is loaded here

	IFNDEF testing
Start:
	ENDIF

GRID_SIMPLIFIED:
	BLOCK 100, EMPTY			; block out 16x16 grid (but we only use 10x10)
	ALIGN 128, $ff
GRID_INDEX_LOOKUP:
	INCLUDE "./marbles-grid-memory.inc.asm"

	ALIGN 128, $ff				; pad up to the next $ff with ee - so I can spot it in memory

GRID_START:
	BLOCK 16*11, EMPTY			; block out 16x16 grid (but we only use 10x10) aligned to $c100

HAS_MOVES_LEFT EQU 1
HAS_NO_MOVES EQU 0
HAS_WON_GAME EQU $ff

CAN_MOVE:
	DEFB HAS_MOVES_LEFT


RANDOM_SEED EQU Random+1

; 16-bit xorshift pseudorandom number generator
; HL <- a random number
; Modifies: AF
Random
	ld hl, 1				; initial seed value 1
	ld a, h
	rra
	ld a, l
	rra
	xor h
	ld h, a
	ld a, l
	rra
	ld a, h
	rra
	xor l
	ld l, a
	xor h
	ld h, a

	ld (Random+1), hl			; now update the seed
	ret


;
; NextBASIC public API - Populate the 100x100 grid with initial values
;
; NextBASIC Usage:
;  BANK n POKE randomSeed, %r			:; set the seed to %r
;  %a=% BANK %n USR NBPopulateGrid		:; call the populate api
;
;  FOR %i=0 TO 99
;    PRINT % BANK n PEEK i	:; prints the block value to do something with it
;  NEXT %i
NBPopulateGrid:
	; populate grid is expected to be found at $c200
	; populate the grid with 100 random values between 0-3
	ld b, 0					; loop through the entire grid

.loop:
	ld a, b
	call IndexToMemoryOffset
	ld e, a					; DE will eventually point to this memory location

	and 15					; mod 16
	cp 10					; if A >= 10 then
	jp nc, .empty 				; 	we're out of bounds on x axis so make empty

	ld a, e					; now check if we're out of bounds
	cp $a0					; on the y axis
	jp nc, .empty

	call Random				; load HL with random value
	ld a, l					; load L into A so we can do bit op
	and 3					; mod 4
	jp .cont
.empty
	ld a, EMPTY
.cont
	ld d, HIGH GRID_START			; point to the start of the grid data
	ld (de), a				; load 0-3 random value into grid memory at (DE)

	inc b
	ld a, b
	cp 100
	jr nz, .loop				; loop while B for 256
	call StoreSimplifyGrid			; commit the data to the simple structure
	ret

;
; NextBASIC public API - Tag the given block index
;
; NextBASIC Usage:
;  BANK %n POKE NBTagIndex, blockIndexValue	:; sets the block to clear
;  %a = % BANK n USR NBTag			:; %a = BC = tag_count address
;  %c = % BANK n PEEK a				:; %c = number of blocks
;  FOR %i=1 TO %c
;    PRINT % BANK n PEEK i	:; prints the block index to do something with it
;  NEXT %i
;
; BC <- TAG_COUNT address (remember it will be offset by $c000)
NBTag:
	ld a, 0
	call IndexToMemoryOffset
	jp Tag					; note: no ret required as Tag has a ret

NBTagIndex EQU NBTag+1				; address of byte to modify from NextBASIC

;
; Translates block index to memory location (when memory is rotated and padded)
;
; A = index of block
; A <- memory location offset
; Modifies: AF, DE
IndexToMemoryOffset:
	ld d, HIGH GRID_INDEX_LOOKUP
	or 128
	ld e, a
	ld a, (de)
	ret

;
; Tags the given block index and surrounding matching types
; A = index of block
; BC <- location of tagged blocks
; Modifies: AF, BC, DE, HL
Tag:
	ld l, a
	call ResetTagCount
	ld d, HIGH GRID_START
	ld e, l
	ld a, (de)				; get the block at grid index A

	or TAGGED
	ld h, a					; H = value of block + tag mask
	ld a, l					; L, A = index of block in memory
	call TagBlock

	ld a, (bc)				; A = tagged count
	cp 1
	jr nz, .fall				; if tagged > 1 then we're good

	call ResetTagCount			; otherwise reset the tag count
	ld a, (NBTagIndex)			; get the original tagged block
	call Untag				; and untag it in the grid memory

	jr .done

.fall
	;; now fall, then shift columns and then store the simplfied grid
	;; for NextBASIC to pick up a $c000
	call Fall
	call ShiftColumns
	call StoreSimplifyGrid
	call MovesLeft

.done
	ld bc, TAG_COUNT			; and reset BC as it's modified
	ld a, HIGH TAG_COUNT
	ld b, $c0
	sub b
	ld b, a
	ret

; Runs through the grid searching for at least two of the same block touching
; and stores a flag state to be collected by NextBASIC
;
; Modifies: AF, BC, DE, HL
MovesLeft:
	ld b, 10
	ld h, HIGH GRID_START			; HL points to the column

.columnLoop
	;; set L to the base of the column, and the column is selected based
	;; on the value of B. Following code basically does memory = (B-1) * 16
	ld a, b
	dec a					; so A is in range of 0-9
	or a					; ensure the carry bit is cleared before we do a rotate left
	rla					; then A * 16 (A << 4)
	rla
	rla
	rla
	ld l, a					; now HL points to column

.rowLoop
	;; now we need to check the block up (HL+1) and then the block below (HL+16)
	;; if the match, then we've got remaining blocks
	or 1					; reset Z flag
	ld e, l					; backup L for
	ld a, (hl)
	ld c, a					; put root block in C
	ld a, EMPTY
	cp c
	jr z, .nextColumn
	inc l
	ld a, (hl)				; look right
	cp c
	jr z, .match				; if they're equal bail

	;; now look at the memory row above - but first check if we're on the
	;; edge of the memory boundary
	ld a, l
	and $f0
	jr z, .skipDownCheck
	ld a, l
	ld l, 17
	sub l
	ld l, a
	ld a, (hl)
	cp c
	jr z, .match				; test again
.skipDownCheck
	;; no match, let's look at the next row
	ld l, e
	inc l
	jr .rowLoop


.nextColumn
	djnz .columnLoop

	ld a, l
	ld hl, CAN_MOVE
	and a					; set Z flag if zero
	jr z, .wonGrid
	ld a, HAS_NO_MOVES
	ld (hl), a
	ret

.wonGrid
	ld a, HAS_WON_GAME
	ld (hl), a
	ret

.match
	ld hl, CAN_MOVE
	ld (hl), HAS_MOVES_LEFT
	ret

; Collapses empty columns all to the left updating the grid memory.
; Process moves through the grid (which is rotated 90deg in memory)
; by cycling through each x,9 coordinate from x=0-9 and when an empty
; block is found in the base of the column, the entire column is
; swapped with the column to the right (in memory this is $c100 to $c110)
;
; Modifies: AF, BC, DE, HL
ShiftColumns:
	ld h, $c1
	ld l, $00				; we don't need to check the last column
.loop
	ld a, l
	cp $90
	jr z, .exit
	ld a, (hl)
	cp EMPTY				; if the block is empty then swap with next col
	jr z, .emptyColumn

	ld a, l					; increment to next column
	add 16
	ld l, a
	jr .loop

.emptyColumn
	ld b, 10				; load B with 10 rows to cycle through

	ld d, h					; now select the next column
	ld a, l
	add a, 16
	ld e, a					; by loading DE with HL+16

	ld c, e					; create a backup of L in C

.findNextColumn					; now find the next column that has content
	ld a, (de)
	cp EMPTY
	jr nz, .emptyColumnLoop			; if the block has a non empty value, swap DE with HL

	ld a, e					; otherwise start looking at the next column
	add a, 16
	cp $a0					; if we went past the last column, bail out
	jr z, .exit
	ld e, a
	jr .findNextColumn

.emptyColumnLoop
	;; copy from DE to HL 10 times incrementing E and L
	ld a, (de)
	ld (hl), a
	ld a, EMPTY
	ld (de), a

	inc e					; move to next row in both DE and HL
	inc l

	djnz .emptyColumnLoop			; next iteration on B

	ld l, c					; restore L to the previous column for next main loop
	jr .loop

.exit
	ret

;
; Updates the grid memory to move all the tagged blocks up through
; the column and marks them as empty
;
; Modifies: AF, BC, HL
Fall:
	ld b, 10
	ld h, HIGH GRID_START			; HL points to the column

.columnLoop
	ld a, b
	dec a					; so A is in range of 0-9
	or a					; ensure the carry bit is cleared before we do a rotate left
	rla					; then A * 16 (A << 4)
	rla
	rla
	rla
	ld l, a					; now HL points to column

.rowLoop
	ld a, (hl)

	cp TAGGED				; if A >= N, then C flag is reset
	jr c, .skip				; if not tagged (or empty), then skip
	ld c, a
.move
	ld d, h
	ld e, l					; point DE to the starting point
.checkNext
	ld a, l
	inc a
	and 15
	jr z, .rowEnd

	inc l
	ld a, (hl)				; first collect the next block above

	cp TAGGED				; the target block ALSO tagged?
	jr nc, .makeEmptyAndKeepSearching			; if the block is tagged, then check the next block
	ld c, a					; C contains the block value
	ld a, e					; A is now our end target memory position for memory move comparison

.moveCurrent
	cp l
	jr z, .finishMoving

	ld (hl), EMPTY
	dec l
	jr .moveCurrent

.makeEmptyAndKeepSearching
	ld (hl), EMPTY
	jr .checkNext

.finishMoving
	ld (hl), c				; put the target block in the starting position
.skip
	inc l
	ld a, l
	inc a
	and 15
	jr nz, .rowLoop
.rowEnd
	;; before we jump to the next column, first check if the block that
	;; we originated on is tagged and *not* marked as EMPTY. If that's
	;; the case, then it's because the entire column was tagged and empty
	ld a, (de)
	cp EMPTY
	jr z, .rowEndDoLoop
	ld a, EMPTY
	ld (de), a
.rowEndDoLoop
	djnz .columnLoop
	ret

; Tags all blocks with the matching value of H
; During execution, A is the result of the next block
; whilst L is the origin position of the block that
; we're looking around. The whole time H refers to the
; matching block value.
;
; A = block index to tag
; H = block value with TAGGED applied (i.e. +8)
; Modifies: AF, DE, HL
TagBlock:
	push hl
	ld l, a					; store A in L for restore in each tag call

	;; first tag the current block, then run tests for surrounding blocks
.tagHandler:
	ld d, HIGH GRID_START			; get the block at grid index A
	ld e, a					; which is referenced by DE
	ld a, (de)				; and load back in to A

	cp TAGGED				; if A >= N, then C flag is reset
						; thus if block >= 8 then it's tagged and we can bail
	jr nc, .tagBlockExit			; if so, bail

	or TAGGED
	cp h					; compare the current block value to H
	jr nz, .tagBlockExit
	ld (de), a				; save new block value as EMPTY

	;; track the block position in the tagged list
	ld bc, TAG_COUNT
	ld a, (bc)
	inc a
	ld (bc), a				; update the total tag count
	add a, c
	ld c, a

	ld d, HIGH REVERSE_INDEX_LOOKUP		; E is already loaded with the correct position
	ld a, (de)				; get the memory to index value
	ld (bc), a

	;; now search around this block - though it's fast(ish), this does waste
	;; time reading the position it just came from
	call TagLeft
	call TagRight
	call TagUp
	call TagDown
.tagBlockExit
	pop hl
	ld bc, TAG_COUNT
	ret

TagLeft:
	ld a, l					; A mod 16
	and 15
	ret z					; if zero we're on an edge, so nothing left

	ld a, l					; else restore A and subtract 1
	sub 1
	jr TagBlock

TagRight:
	ld a, l
	and 15					; mod 16
	cp 9					; if A > 9 then we're on the edge
	ret nc

	ld a, l
	add a, 1
	jr TagBlock

TagUp:
	ld a, l
	sub 16					; subtract 10
	ret c					; if there's a carry, we went negative, so return empty
	jr TagBlock

TagDown:
	ld a, l
	cp $a0					; compare to 90, if we're below that value
	ret nc 					; (and there's no carry), then jump to the `add a, 10`
	add a, $10
	jr TagBlock

; A = block index
; Modifies: DE
Untag:
	call IndexToMemoryOffset		; get the memory offset so we can reset the value
	;; now update the grid memory and untag the block
	ld d, HIGH GRID_START
	ld e, a
	ld a, (de)
	xor TAGGED				; remove the tagged flag
	ld (de), a
	ret


; Modifies: AF, BC
ResetTagCount:
	ld bc, TAG_COUNT			; capture the original block index so we can reset it
	xor a					; set A to zero and then put that in the  TAG_COUNT
	ld (bc), a
	ret

;
; Modifies: AF, BC, DE, L
StoreSimplifyGrid:
	ld b, $a
	ld l, $ff
.outer
	ld c, b
	dec c
.inner
	inc l
	ld a, c
	ld d, HIGH GRID_START
	ld e, a
	ld a, (de)				; get the block at grid index A

	ld d, HIGH GRID_SIMPLIFIED
	ld e, l
	ld (de), a				; copy to simplified position

	;; now move to the next memory spot
	ld a, c					; increment by 16
	add a, 16
	ld c, a
	and $f0					; check if we're at the upper bound
	cp 160
	jr c, .inner				; if not, keep looping inner
	djnz .outer
	ret

; block types/state
EMPTY	EQU -1
TAGGED	EQU 8					; used as a mask

	ALIGN 256				; following 3 blocks need to be on an aligned by in memory
						; specifically as I use `ld bc, TAGGED_LIST : dec c` to get
						; to TAG_COUNT in places
REVERSE_INDEX_LOOKUP:
	INCLUDE "./marbles-grid-index.inc.asm"

TAG_COUNT
	DEFB 0
TAGGED_LIST:
	DEFB $ff				; note that this MUST be at the end as it can grow (not huge, but possible)
	BLOCK 99, $ff


; **************************************************************
; * testing code
; **************************************************************
	IFDEF testing

Main:						; note that main is sitting on 0xA0 in the memory bank
	ei
.reset
	ld hl, (SEQUENCE_INIT)
	ld (RANDOM_SEED), hl

	call NBPopulateGrid
	call InitGraphics

	call ResetTagCount
	call RunSequence
	call RenderGrid

.readInput
	call ReadInputAndWait
	jr z, .reset
	call NBTag
	call RenderGrid

	jp .readInput
	ret					; we never get here

RunSequence:
	ld hl, SEQUENCE+2
.loop
	ld a, (hl)
	cp $ff
	jr z, .exit

	inc hl
	ld b, (hl)

	push hl
	ld (NBTagIndex), a
	call NBTag
	call RenderGrid
	pop hl
	jr .loop
.exit

	ret


SEQUENCE_INIT EQU $

	;; sequence holds: <seed 2 bytes> <block index n bytes> <$FF end marker>
SEQUENCE:
	;INCBIN "./FAIL-WIN2.BIN"
	DEFB $ff

USER_PRESS_VALUES:
	DEFB '0','0'				; two zeros
USER_SELECTED_BLOCK:
	DEFW 0

;
; Read user key presses from LASTK by putting null in there and checking for
; changes.
;
; Modifies: <nothing> (uses exx)
; A <- selected block
ReadInputAndWait:
	exx

	;; print the X Y place holders
	ld a, AT				; print the keypress
	rst 16
	ld a, 16
	rst 16
	ld a, 2					; col=2
	rst 16
	ld a, 'X'
	rst 16
	ld a, ':'				; col=3
	rst 16
	ld a, ' '				; col=4 (where first value goes)
	rst 16
	ld a, ' '				; col=5
	rst 16
	ld a, 'Y'				; col=6
	rst 16
	ld a, ':'				; col=7
	rst 16
	ld a, ' '				; col=8
	rst 16
	ld a, '='				; col=9
	rst 16

	ld a, '0'
	call PrintUserSelection

	ld bc, LASTK				; LAST K system var
	xor a					; set A to zero
	ld (bc), a				; put null in there
.loop
	ld a, (bc)				; is new value of LAST_K
	cp 0					; is it zero?
	jr z, .loop				; yes, then no key pressed

	cp 13					; return was pressed, calculate the value and exit
	jr z, .ready

	;; if key value < $40 then we don't need to tweak the case
	cp $40					;  if A < N, then C flag is set
	jr c, .skipCaseChange
	or 32
.skipCaseChange

	cp 'r'
	jr z, .exit

	;; now test that it's in a valid range: 0-9 ($30-$39)
	cp '0'					; if A < N then too small, loop
	jr c, .clearAndLoop

	cp ':'					; if A < ':' (9 comes before :) then we're a number
	jr c, .print

.clearAndLoop
	xor a					; put null back into LAST_K
	ld (bc), a
	jr .loop
.print
	call PrintUserSelection

	xor a					; set A to zero (null)
	ld (bc), a				; put null back into LAST_K

	;; now check if there's a flashing attribute, and if so, turn it off
	ld hl, (USER_SELECTED_BLOCK)		; points to screen attr data
	ld a, h
	cp 0
	jr z, .nothingSelected
	ld a, (hl)
	sub 128					; remove the blink bit
	ld (hl), a

.nothingSelected:

	push bc					; going to use BC for addattr

	;; now put the _real_ values in memory
	ld hl, USER_PRESS_VALUES+1
	ld a, (hl)
	call KeyPressToInt

	ld c, a

	// 10 * x
	rlca
	ld e, a					; B = A * 2
	rlca
	rlca					; A = A * 8
	add a, e				; = A + B = A * 10

	ld e, a
	ld hl, USER_PRESS_VALUES
	ld a, (hl)
	call KeyPressToInt

	ld b, a

	add a, e				; A = 10 * y + x

	ld (NBTagIndex), a

	push bc
	ld e, a
	ld c, a
	ld b, 0

	ld a, AT				; print the keypress
	rst 16
	ld a, 16
	rst 16
	ld a, 10					; col=Y
	rst 16

	call ROM_LINE_NUMBER_PRINTING
	ld a, e
	cp 10
	jr nc, .finishPrintingCoords
	ld a, ' '
	rst 16
.finishPrintingCoords
	pop bc


	push de

	call atadd
	;; A now contains the attribute we need to `and` 128 to blink
	;; and store the attribute value in USER_SELECTED_BLOCK
	add a, 128
	ld (de), a				; put the attribute back
	ld hl, USER_SELECTED_BLOCK
	ld (hl), e
	inc hl
	ld (hl), d				; load DE into HL

	pop de
	pop bc

	jr .loop

.ready

	;; clear out the selected block (as the ROM_CLS will reset attr flags)
	ld hl, USER_SELECTED_BLOCK		; points to screen attr data
	ld (hl), 0
	inc hl
	ld (hl), 0

	exx					; return registers to what they were before
	or 1					; ensure Z flag is unset
	ret

.exit
	exx
	cp a					; set Z flag
	ret

; Test for key press
; A = key value
; Modifies: AF, BC
; NC <- set if key is pressed
KeyTest
	ld c, a					; load key in to c
	and 7					; mask bits d0-d2 for now
	inc a					; in range of 1-8
	ld b, a					; copy to b
	srl c					; divide c by 8
	srl c					; to find position within row
	srl c
	ld a, 5					; only 5 keys per row
	sub c					; subtract position
	ld c, a
	ld a, 254				; high byte of port to read
.loop1
	rrca					; rotate into position
	djnz .loop1				; repeat until we find relevant row
	in a, (254)				; read port (a=high, 254=low)

.loop2
	rra					; rotate bit out of result
	dec c					; loop counter
	jp nz, .loop2				; repeat until bit for position in carry

	;; no carry if the key is pressed
	ret

	;; includes `atadd`
	INCLUDE "./attr_address.asm"

; A = new character selection
; Modifies: AF, E, HL
PrintUserSelection:
	ld e, a					; tmp copy of A

	;; print most recent character
	ld a, AT				; print the keypress
	rst 16
	ld a, 16
	rst 16
	ld a, 8					; col=Y
	rst 16
	ld a, e
	rst 16					; now print

	ld hl, USER_PRESS_VALUES+1		; copy the last pressed value across
	ld a, (hl)
	ld (hl), e				; put current keypress as "last" key
	dec hl
	ld (hl), a				; now put the old key as previous key
	ld e, a					; copy the old character

	;; print old character
	ld a, AT				; print the keypress
	rst 16
	ld a, 16
	rst 16
	ld a, 4					; col=X
	rst 16
	ld a, e
	rst 16					; now print
	ret


; Converts ASCII key code to numeric for range of 0-$A
;
; A = char code
; A <- integer value
KeyPressToInt:
	sub $30
	cp 10					; if A < n then we have carry and it's already numeric
	jr c, .skipAdjust
	ld a, 10
.skipAdjust
	ret


; C <- count of tagged blocks (marked as EMPTY)
; Modifies: DE
CountTagged:
	ld de, TAG_COUNT
	ld a, (de)
	ret

InitGraphics:
	ld hl, GRAPHICS
	ld (23675), hl			; set up the udg variables - this should work on a computer
	ret

; A = block index
; A <- value of block
; Modifies: DE
GetBlockValue:
	ld d, HIGH GRID_START
	ld e, a
	ld a, (de)				; get the block at grid index A
	ret


; First calls StoreSimplifyGrid, then renders the grid based on that data
; printing an X when EMPTY is encountered
;
; Does not modify any registers
RenderGrid:
	exx
	call StoreSimplifyGrid
	call ROM_CLS
	ld c, $a
	ld h, HIGH GRID_SIMPLIFIED
	ld l, $ff
.outer						; outer loop that helps us know when to print a new line
	ld b, $0a
.inner						; inner loop that prints each block
	inc l					; HL now points to GRID_SIMPLIFIED
	ld a, (hl)				; A contains block value

	cp TAGGED				; if the block value is >= TAGGED (8) then
	jr nc, .setToEmpty			; ... then jump to just printing the empty block
	add a, 144				; otherwise start adjust A to point to a UDG
	jr .print
.setToEmpty
	ld a, ' '
.print
	rst 16					; print

	djnz .inner				; loop .inner until B = 0

.newLine
	ld a, "\r"
	rst 16

	dec c
	jr nz, .outer

	exx
	ret


GRAPHICS EQU $
	DEFB 1,125,125,125,125,125,1,255
	DEFB 171,85,171,85,171,85,171,255
	DEFB 239,199,147,57,147,199,239,255
	DEFB 17,57,125,255,125,57,17,255


	ENDIF
; **************************************************************

PROGRAM_END:

	DISPLAY "Public API:"

	DISPLAY " "
	DISPLAY "  #define M_CANMOVE=",/D,CAN_MOVE-Start,""
	DISPLAY "  #define M_RANDOMSEED=",/D,RANDOM_SEED-Start,""
	DISPLAY "  #define M_FN_POPULATEGRID=",/D,NBPopulateGrid-Start,""
	DISPLAY "  #define M_TAGINDEX=",/D,NBTagIndex-Start,""
	DISPLAY "  #define M_FN_TAG=",/D,NBTag-Start,""

	DISPLAY " "
        DISPLAY "Size:                 ",/D,PROGRAM_END-Start," bytes"
	DISPLAY " "

	IFDEF testing
	DISPLAY " --- TEST BUILD ---"

	SAVESNA "marbles-grid.sna", Start
	ELSE

	SAVEBIN "marbles.bin", Start, PROGRAM_END - Start

	ENDIF
