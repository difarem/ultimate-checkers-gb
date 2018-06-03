;****************************************************************************************************************************************************
;*	HELLO.ASM - Hello World Source Code
;*
;****************************************************************************************************************************************************
;*
;*
;****************************************************************************************************************************************************

;****************************************************************************************************************************************************
;*	Includes
;****************************************************************************************************************************************************
	; system includes
	INCLUDE	"hardware.inc"

	; project includes

	
;****************************************************************************************************************************************************
;*	user data (constants)
;****************************************************************************************************************************************************


;****************************************************************************************************************************************************
;*	equates
;****************************************************************************************************************************************************

; global state
    SECTION "Global State",WRAM0
_cursor_pos: ; %xxxxyyyy
    DS 1
_animation_timer:
    DS 1


;****************************************************************************************************************************************************
;*	Program Start
;****************************************************************************************************************************************************

	SECTION "Program Start",ROM0[$0150]
Start::
	di			;disable interrupts
	ld	sp,$FFFE	;set the stack to $FFFE

	call WAIT_VBLANK	;wait for v-blank

	ld	a,0		;
	ldh	[rLCDC],a	;turn off LCD 

	call LOAD_TILES	;load up our tiles
    ; FIXME: bg map clearing routine actually creates artifacts???? for some reason
	;call CLEAR_MAP	;clear the BG map
	call LOAD_BOARD	;load up our map

	ld	a,%11100100	;load a normal palette up 11 10 01 00 - dark->light
	ldh	[rBGP],a	;load the palette

    ld  hl,$FF48
    ld  [hl],%11100100 ; load sprite palette
    ; draws a single white piece
    ld  hl,$FE00
    ld  [hl],44      ; sprite y position
    inc hl
    ld  [hl],28     ; sprite x position
    inc hl
    ld  [hl],9      ; sprite tile offset
    inc hl
    ld  [hl],0      ; sprite attributes

    ; set the cursor to the upper left corner
    ld  hl,_cursor_pos
    ld  [hl],0

    ; init cursor
    ld  hl,$FE90
    ld  [hl],24
    inc hl
    ld  [hl],24
    inc hl
    ld  [hl],11
    inc hl
    ld  [hl],%00000000

    inc hl
    ld  [hl],24
    inc hl
    ld  [hl],32
    inc hl
    ld  [hl],11
    inc hl
    ld  [hl],%00100000

    inc hl
    ld  [hl],32
    inc hl
    ld  [hl],24
    inc hl
    ld  [hl],11
    inc hl
    ld  [hl],%01000000

    inc hl
    ld  [hl],32
    inc hl
    ld  [hl],32
    inc hl
    ld  [hl],11
    inc hl
    ld  [hl],%01100000

	ld	a,%10010011
	ldh	[rLCDC],a	;turn on the LCD, BG, sprites, etc

; MAIN LOOP
Loop::
    ; waits for v-blank, ensuring the main loop runs 60 times each second
    call WAIT_VBLANK

    ; update animation timer
    ld hl,_animation_timer
    inc [hl]
    ; handle animations
    ld  a,0
    cp  [hl]
    push hl
    ld  b,11 ; blink up
    call z,cursor_blink
    pop hl
    ld  a,128
    cp  [hl]
    ld  b,12 ; blink down
    call z,cursor_blink

	jr Loop

cursor_blink:
    ld  hl,$FE92
    ld  [hl],b
    ld  hl,$FE96
    ld  [hl],b
    ld  hl,$FE9A
    ld  [hl],b
    ld  hl,$FE9E
    ld  [hl],b
    ret

;***************************************************************
;* Subroutines
;***************************************************************

	SECTION "Support Routines",ROM0

WAIT_VBLANK::
	ldh	a,[rLY]		;get current scanline
	cp	$91			;Are we in v-blank yet?
	jr	nz,WAIT_VBLANK	;if A-91 != 0 then loop
	ret				;done
	
CLEAR_MAP::
	ld	hl,_SCRN0		;loads the address of the bg map ($9800) into HL
	ld	bc,32*32		;since we have 32x32 tiles, we'll need a counter so we can clear all of them
	ld	a,0			;load 0 into A (since our tile 0 is blank)
CLEAR_MAP_LOOP::
	ld	[hl+],a		;load A into HL, then increment HL (the HL+)
	dec	bc			;decrement our counter
	ld	a,b			;load B into A
	or	c			;if B or C != 0
	jr	nz,CLEAR_MAP_LOOP	;then loop
	ret				;done
	

LOAD_TILES::
	ld	hl,BOARD_TILES
	ld	de,_VRAM
	ld	bc,20*16 ;each tile takes 16 bytes
LOAD_TILES_LOOP::
	ld	a,[hl+]	;get a byte from our tiles, and increment.
	ld	[de],a	;put that byte in VRAM and
	inc	de		;increment.
	dec	bc		;bc=bc-1.
	ld	a,b		;if b or c != 0,
	or	c		;
	jr	nz,LOAD_TILES_LOOP	;then loop.
	ret			;done

LOAD_BOARD::
    ld  hl,_SCRN0+34
    ld  bc,16
    ld  d,8      ; 8 rows
LOAD_BOARD_ROW::
    ld  e,8      ; 8 columns
    call LOAD_BOARD_UPPER_LOOP
    add hl,bc
    ld  e,8
    call LOAD_BOARD_LOWER_LOOP
    add hl,bc
    dec d
    jr  nz,LOAD_BOARD_ROW
    ret
LOAD_BOARD_UPPER_LOOP::
    ld a,d
    add a,e
    bit 0,a
    jr  nz,lbul_black
    ; white tile
    ld  [hl],1
    inc hl
    ld  [hl],2
    inc hl
    jr  lbul_loop
lbul_black:
    ; black tile
    ld  [hl],5
    inc hl
    ld  [hl],6
    inc hl
lbul_loop:
    dec e
    jr  nz,LOAD_BOARD_UPPER_LOOP
    ret
LOAD_BOARD_LOWER_LOOP::
    ld a,d
    add a,e
    bit 0,a
    jr nz,lbll_black
    ; white tile
    ld  [hl],3
    inc hl
    ld  [hl],4
    inc hl
    jr  lbll_loop
lbll_black:
    ; black tile
    ld  [hl],7
    inc hl
    ld  [hl],8
    inc hl
lbll_loop:
    dec e
    jr  nz,LOAD_BOARD_LOWER_LOOP
    ret

;********************************************************************
; This section was generated by GBTD v2.2


    SECTION "Tiles",ROM0
; Start of tile array.
BOARD_TILES::
INCBIN "gfx/board.2bpp"

;************************************************************
;* tile map

SECTION "Map",ROM0

HELLO_MAP::
INCBIN "gfx/hello_world.tilemap"
