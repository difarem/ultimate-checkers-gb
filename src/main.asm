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
_cursor_pos:
    DS 2
_animation_timer:
    DS 1
_board:         ; 8 columns 4 rows
    DS 8*4      ; contains pointers to OAM ($FE00+x, $FF is empty)
_turn:
    DS 1

; joypad state on the last vblank period
_last_button_keys:
    DS 1
_last_direction_keys:
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

    call init_board

    ; set the cursor to the lower left corner
    ld  hl,_cursor_pos
    ld  [hl],0      ; x position
    inc hl
    ld  [hl],7      ; y position

    ; init cursor
    ld  hl,$FE90
    ld  [hl],24+112
    inc hl
    ld  [hl],24
    inc hl
    ld  [hl],11
    inc hl
    ld  [hl],%00000000

    inc hl
    ld  [hl],24+112
    inc hl
    ld  [hl],32
    inc hl
    ld  [hl],11
    inc hl
    ld  [hl],%00100000

    inc hl
    ld  [hl],32+112
    inc hl
    ld  [hl],24
    inc hl
    ld  [hl],11
    inc hl
    ld  [hl],%01000000

    inc hl
    ld  [hl],32+112
    inc hl
    ld  [hl],32
    inc hl
    ld  [hl],11
    inc hl
    ld  [hl],%01100000

	ld	a,%10010011
	ldh	[rLCDC],a	;turn on the LCD, BG, sprites, etc

    ; init joypad state
    ld  a,%00010000
    ldh [rP1],a   ; request button keys
    ldh a,[rP1]   ; read button keys
    ld  hl,_last_button_keys
    ld  [hl],a      ; write to memory
    
    ld  a,%00100000
    ldh [rP1],a   ; same for direction keys
    ldh a,[rP1]   ; read direction keys
    inc hl
    ld  [hl],a      ; again, write to memory

    ; init turn counter
    ld  hl,_turn
    ld  [hl],0
    ; bottom player moves first
    ld  hl,_SCRN0+(17*32)+18
    ld  [hl],14

; MAIN LOOP
Loop::
    ; wait for v-blank, ensuring the main loop runs 60 times each second
    call WAIT_VBLANK

    ; read input
    ; first, request direction keys
    ld  a,%00100000
    ldh [rP1],a
    ldh a,[rP1]
    ld  hl,_last_direction_keys
    ld  b,[hl]
    ld  [hl],a
    ;get newly pressed keys in B
    xor a,$ff
    and a,b
    ld  b,a

    bit 3,b ; down
    call nz,cursor_down
    bit 2,b ; up
    call nz,cursor_up
    bit 1,b ; left
    call nz,cursor_left
    bit 0,b ; right
    call nz,cursor_right

    ; now, handle button keys
    ld  a,%00010000
    ldh [rP1],a
    ldh a,[rP1]
    ld  hl,_last_direction_keys+1
    ld  b,[hl]
    ld  [hl],a
    xor a,$ff
    and a,b
    ld  b,a

    ;bit 3,b ; start
    ;bit 2,b ; select
    bit 1,b ; B
    call nz,cursor_cancel
    bit 0,b ; A
    call nz,cursor_press

    ; update animation timer
    ld hl,_animation_timer
    inc [hl]
    ld  a,[hl]
    swap a
    and a,%00000011
    ; handle animations
    ld  b,11 ; blink up
    call z,cursor_blink
    cp  2
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

cursor_down:
    ld  hl,_cursor_pos+1
    inc [hl]
    ld  a,8
    cp  a,[hl]
    jr  nz,cursor_update
    ld  [hl],0
    jr  cursor_update

cursor_up:
    ld  hl,_cursor_pos+1
    ld  a,[hl]
    dec [hl]
    and a,a
    jr  nz,cursor_update
    ld  [hl],7
    jr  cursor_update

cursor_right:
    ld  hl,_cursor_pos
    inc [hl]
    ld  a,8
    cp  a,[hl]
    jr  nz,cursor_update
    ld  [hl],0
    jr  cursor_update

cursor_left:
    ld  hl,_cursor_pos
    ld  a,[hl]
    dec [hl]
    and a,a
    jr  nz,cursor_update
    ld  [hl],7

cursor_update:
    ld  hl,_cursor_pos
    ld  b,[hl]          ; load x position to B
    inc hl
    ld  c,[hl]          ; load y position to C

    rlc b
    rlc b
    rlc b
    rlc b
    rlc c
    rlc c
    rlc c
    rlc c       ; multiply the positions by 16

    ld  hl,$FE90        ; update upper left corner, y position
    ld  a,c
    add a,24
    ld  [hl],a          ; write update

    inc hl              ; upper left corner, x position
    ld  a,b
    add a,24
    ld  [hl],a          ; write update

    inc hl              ; upper right corner, y position
    inc hl
    inc hl
    ld  a,c
    add a,24
    ld  [hl],a          ; write update

    inc hl              ; upper right corner, x position
    ld  a,b
    add a,32
    ld  [hl],a          ; write update

    inc hl              ; lower left corner, y position
    inc hl
    inc hl
    ld  a,c
    add a,32
    ld  [hl],a          ; write update

    inc hl              ; lower left corner, x position
    ld  a,b
    add a,24
    ld  [hl],a          ; write update

    inc hl              ; lower right corner, y position
    inc hl
    inc hl
    ld  a,c
    add a,32
    ld  [hl],a          ; write update

    inc hl              ; lower right corner, x position
    ld  a,b
    add a,32
    ld  [hl],a          ; you get the idea

    ret

cursor_cancel:
    ret

cursor_press:
    ld  hl,_cursor_pos
    ld  b,[hl]  ; store the cursor x on B
    inc hl
    ld  c,[hl]  ; and the cursor y on C
    ld  hl,$fe60

    ; are we aligned (cursor on a black tile)?
    ld  a,b
    add c
    bit 0,a
    ret z

    ; we are aligned
    ; divide x by two so we can index _board
    sra b
    ; i = x + 4y
    ld  a,c
    sla a
    sla a
    add a,b
    ; actually index _board
    ld  d,0
    ld  e,a
    ld  hl,_board
    add hl,de
    ; is the tile empty?
    ld  a,255
    cp  [hl]
    ; if it is, return
    ret z
    ; load the piece's sprite offset
    ld  d,0
    ld  e,[hl]
    ld  hl,$fe00
    add hl,de
    inc hl
    inc hl
    ld  a,[hl]
    
    push hl
    ; check our team
    cp  a,9
    jr  z,cp_top

cp_bottom:
    ld  hl,_turn
    bit 0,[hl]  ; is it our turn?
    pop hl
    ret nz

    ; D: piece x coordinates
    ; E: piece y coordinates
    dec hl
    ld  d,[hl]
    dec hl
    ld  e,[hl]

    ; it is bottom's turn
    ; check where we can move to
    ; are we on the right side of the board? (B == 0 and C%2 == 1)
    ld  a,b
    cp  0
    call nz,cpb_left
    bit 0,c
    call z,cpb_left
    ; are we on the left side of the board?
    ld  a,3
    cp  b
    call nz,cpb_right
    bit 0,c
    call nz,cpb_right

    ret

cpb_left:
    ; draw left piece target
    ld  hl,$fe60    ; y position
    ld  a,e
    sub a,16
    ld  [hl],a
    inc hl          ; x position
    ld  a,d
    sub a,16
    ld  [hl],a
    inc hl          ; sprite offset
    ld  [hl],15
    inc hl          ; sprite flags
    ld  [hl],0
    ret

cpb_right:
    ; draw right piece target
    ld  hl,$fe64    ; y position
    ld  a,e
    sub a,16
    ld  [hl],a
    inc hl          ; x position
    ld  a,d
    add a,16
    ld  [hl],a
    inc hl          ; sprite offset
    ld  [hl],15
    inc hl          ; sprite flags
    ld  [hl],0
    ret

cp_top:
    ld  hl,_turn
    bit 0,[hl]  ; is it our turn?
    pop hl
    ret z

    ; it is top's turn
    halt

    ret

init_board:
    ; first, set the board memory
    ld  hl,_board
    ld  de,INITIAL_BOARD_RAM
    ld  b,32
ib_ram:
    ld  a,[de]
    ld  [hl+],a
    inc de
    dec b
    jr  nz,ib_ram

    ; now initialize the piece attributes
    ld  hl,$FE00
    ld  b,24*4
ib_oam:
    ld  a,[de]
    ld  [hl+],a
    inc de
    dec b
    jr  nz,ib_oam

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
    
    ; draw additional tiles
    ld  hl,_SCRN0   ; top player indicator
    ld  [hl],9

    ld  hl,_SCRN0+(32*17)+19
    ld  [hl],10     ; bottom player indicator

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

SECTION "Initial Board",ROM0
INITIAL_BOARD_RAM::
DB  $00,$04,$08,$0C,$10,$14,$18,$1C,$20,$24,$28,$2C
DB  255,255,255,255,255,255,255,255
DB  $30,$34,$38,$3C,$40,$44,$48,$4C,$50,$54,$58,$5C
INITIAL_BOARD_OAM::
DB  28,44,9,0
DB  28,76,9,0
DB  28,108,9,0
DB  28,140,9,0

DB  44,28,9,0
DB  44,60,9,0
DB  44,92,9,0
DB  44,124,9,0

DB  60,44,9,0
DB  60,76,9,0
DB  60,108,9,0
DB  60,140,9,0


DB  108,28,10,0
DB  108,60,10,0
DB  108,92,10,0
DB  108,124,10,0

DB  124,44,10,0
DB  124,76,10,0
DB  124,108,10,0
DB  124,140,10,0

DB  140,28,10,0
DB  140,60,10,0
DB  140,92,10,0
DB  140,124,10,0
