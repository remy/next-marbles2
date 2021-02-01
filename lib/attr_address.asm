; (y <0-23>, x <0-31>) - (y * 32 + x) + 22528 = memory position
; remember that y is vertical (b) and x is horizontal (c)
;
; B=vertical position (0-23)
; C=horizontal position (0-31)
; Modifies: A, C, DE
; A <- attribute for coordinate
atadd:
	ld a, c					; x position
	rrca					; multiply by 32
	rrca
	rrca
	ld e, a					; store A in E
	and %00000011				; mask bits for high byte
	add a, 88				; 88 * 256 = 22528, start of attribs
	ld d, a					; high byte done
	ld a, e					; get x * 32 again
	and %11100000				; mask low byte
	ld e, a					; put A in E
	ld a, b					; get y displacement
	add a, e				; add to low byte
	ld e, a					; hl=address of attribute
	ld a, (de)				; store value in a
	ret
