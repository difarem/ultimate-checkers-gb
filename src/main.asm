;*****************************************
;*  hello.asm - hello world source code  *
;*****************************************

;**************
;*  includes  *
;**************
INCLUDE "hardware.inc"

;***************************
;*  user data (constants)  *
;***************************


;***************************
;*  user data (variables)  *
;***************************

    SECTION "Variables",WRAM0
_timer:                 ; animation timer
    DS  1
_cursor_y:
    DS  1
_cursor_x:
    DS  1
_last_button_input:     ; these two locations store the input state of the previous tick
    DS  1
_last_direction_input:
    DS  1


;****************
;*  video data  *
;****************

;*************
;*  tileset  *
;*************

BOARD_tBLANK        EQU 0   ; blank tile
BOARD_tBG           EQU 1   ; background tile
BOARD_tTILE_WTL     EQU 2   ; white board tile, top left corner
BOARD_tTILE_WTR     EQU 3   ; white top right
BOARD_tTILE_WBL     EQU 4   ; white bottom left
BOARD_tTILE_WBR     EQU 5   ; white bottom right
BOARD_tTILE_BTL     EQU 6   ; black top left
BOARD_tTILE_BTR     EQU 7   ; black top right
BOARD_tTILE_BBL     EQU 8   ; black bottom left
BOARD_tTILE_BBR     EQU 9   ; black bottom right
BOARD_tPIECE_T      EQU 10  ; top player's piece
BOARD_tPIECE_B      EQU 11  ; bottom player's piece
BOARD_tCURSOR_1     EQU 12  ; cursor, animation state 1
BOARD_tCURSOR_2     EQU 13  ; cursor, animation state 2
BOARD_tINDICATOR_T  EQU 14  ; top player turn indicator
BOARD_tINDICATOR_B  EQU 15  ; bottom player turn indicator
BOARD_tPIECE_TARGET EQU 16  ; move target location indicator
BOARD_SIZE          EQU 17

    SECTION "Tiles", ROM0
BOARD_TILES::
    INCBIN "gfx/board.2bpp"


;*******************
;*  program start  *
;*******************

    SECTION "Program Start",ROM0[$0150]
Start::
    di                  ; disable interrupts
    ld  sp,$FFFE        ; set the stack to $FFFE
    call WaitVBlank     ; wait for v-blank

    ld  a,0             ;
    ldh [rLCDC],a       ; turn off LCD 

    call ClearMap       ; clear the BG map
    call LoadTiles      ; load up our tiles
    call DrawBoard      ; draw the board

    call InitCursor     ; initialize the cursor

    ld  a,%11100100     ; load a normal palette up 11 10 01 00 - dark->light
    ldh [rBGP],a        ; load the palette

    ld  a,%10010011     ; = $91 
    ldh [rLCDC],a       ; turn on the LCD, BG, sprites, etc

    ld  hl,_timer       ; initialize the animation timer
    ld  [hl],0

MainLoop:
    call WaitVBlank     ; wait for v-blank, ensuring this loop is executed around 60 times per second

    ;*  READ INPUT  *
    ; read the button keys first
    ; TODO

    ; and now for the direction keys
    ld  a,%00100000                 ; select the direction keys
    ld  [rP1],a
    ld  a,[rP1]                     ; and read them back
    ld  hl,_last_direction_input    ; compare them with last tick's
    ld  b,a                         ; save...
    xor a,$ff                       ; invert...
    and a,[hl]                      ; compare...
    ld  [hl],b                      ; and store
    ld  b,a

    ld  hl,_cursor_x
    bit 1,b         ; LEFT key
    call nz,MoveCursorDec
    bit 0,b         ; RIGHT key
    call nz,MoveCursorInc
    dec hl
    bit 3,b         ; DOWN key
    call nz,MoveCursorInc
    bit 2,b         ; UP key
    call nz,MoveCursorDec

    call UpdateCursor   ; update the cursor position

    ;*  ANIMATE SPRITES  *
    ld  hl,_timer       ; update the animation timer
    inc [hl]
    ld  a,[hl]

    and a,$7f           ; check the 7 lower bits
    ld  b,12            ; depending on its value, animate the cursor
    call z,AnimateCursor; is it zero?
    cp  a,$40           ; is it 64?
    ld  b,13
    call z,AnimateCursor

    jr MainLoop


;*****************
;*  subroutines  *
;*****************

    SECTION "Support Routines",ROM0

WaitVBlank::
    ldh a,[rLY]         ; get current scanline
    cp  $91             ; are we in v-blank yet?
    jr  nz,WaitVBlank   ; if A-91 != 0 then loop
    ret                 ; done


ClearMap::
    ld  hl,_SCRN0           ; load the address of the bg map ($9800) into HL

    ld  bc,32*32            ; we have 32x32 tiles to clear, so we'll need a counter
ClearMap_Loop:
    ld  a,BOARD_tBG         ; load our background tile offset into A...
    ld  [hl+],a             ; load A into the address at HL and increment HL
    dec bc                  ; decrement our counter
    ld  a,b                 ; to see if BC is zero, we check both B...
    or  c                   ; and C
    jr  nz,ClearMap_Loop    ; loop while we don't reach zero

    ret                     ; done!


LoadTiles::
    ld  hl,BOARD_TILES
    ld  de,_VRAM

    ld  bc,BOARD_SIZE*16
LoadTiles_Loop:
    ld  a,[hl+]             ; get a byte from our tiles, and increment.
    ld  [de],a              ; put that byte in VRAM and
    inc de                  ; increment.
    dec bc                  ; bc=bc-1.
    ld  a,b                 ; if b or c != 0,
    or  c                   ;
    jr  nz,LoadTiles_Loop   ; then loop.

    ret                     ; done


DrawBoard::
    ld  hl,_SCRN0+34            ; load the address of the bg map into HL, with an offset so it isn't draw directly from the corner
    ld  de,16                   ; offset between display rows

    ld  b,8                     ; set up the row counter (8 rows)
DrawBoard_Row:
    ld  c,8                     ; and for each row, the column counter (8 columns)
    ld  a,b
DrawBoard_Top:                  ; first, draw the top part of each board tile
    inc a                       ; A = B+(8-C)
    bit 0,a                     ; depending on the parity of A...
    jr  z,DBT_Black            ; ...draw the tile black
    ld  [hl],BOARD_tTILE_WTL    ; or white
    inc hl
    ld  [hl],BOARD_tTILE_WTR
    jr  DBT_Next                ; skip over the code dealing with black tiles
DBT_Black:
    ld  [hl],BOARD_tTILE_BTL
    inc hl
    ld  [hl],BOARD_tTILE_BTR
DBT_Next:
    inc hl
    dec c                       ; decrement our counter...
    jr  nz,DrawBoard_Top        ; ...and loop while it doesn't reach zero

    add hl,de                   ; move to the next display row
    ld  c,8                     ; set up the column counter again to draw the bottom part
    ld  a,b
DrawBoard_Bottom:
    inc a
    bit 0,a                     ; check the parity of A again
    jr  z,DBB_Black
    ld  [hl],BOARD_tTILE_WBL    ; draw the tile black
    inc hl
    ld  [hl],BOARD_tTILE_WBR
    jr  DBB_Next
DBB_Black:
    ld  [hl],BOARD_tTILE_BBL    ; or black
    inc hl
    ld  [hl],BOARD_tTILE_BBR
DBB_Next:
    inc hl
    dec c
    jr  nz,DrawBoard_Bottom

    add hl,de                   ; move to the next display row
    dec b                       ; decrement our row counter
    jr  nz,DrawBoard_Row        ; and loop

    ld  hl,_SCRN0               ; load into HL the address of the top left corner
    ld  [hl],BOARD_tPIECE_T     ; draw the top player's piece
    ld  hl,_SCRN0+(32*17)+19    ; same for the bottom player at the bottom right corner
    ld  [hl],BOARD_tPIECE_B

    ret     ; done

InitCursor:
    ld  hl,_cursor_y            ; reset the cursor position to the lower left corner of the board
    ld  [hl],7
    inc hl
    ld  [hl],0

    ld  hl,_OAMRAM+$90          ; draw the upper left corner of the cursor
    ld  [hl],136                ; y coordinate
    inc hl
    ld  [hl],24                 ; x coordinate
    inc hl
    ld  [hl],12                 ; sprite offset
    inc hl
    ld  [hl],%00000000          ; sprite flags

    inc hl                      ; upper right corner
    ld  [hl],136
    inc hl
    ld  [hl],32
    inc hl
    ld  [hl],12
    inc hl
    ld  [hl],%00100000          ; flip horizontally

    inc hl                      ; lower left corner
    ld  [hl],144
    inc hl
    ld  [hl],24
    inc hl
    ld  [hl],12
    inc hl
    ld  [hl],%01000000          ; flip vertically

    inc hl                      ; lower right corner
    ld  [hl],144
    inc hl
    ld  [hl],32
    inc hl
    ld  [hl],12
    inc hl
    ld  [hl],%01100000          ; flip vertically and horizontally

    ret

AnimateCursor:
    ld  de,4
    ld  hl,_OAMRAM+$92          ; animate the upper left corner
    ld  [hl],b
    add hl,de                   ; upper right corner
    ld  [hl],b
    add hl,de                   ; lower left corner
    ld  [hl],b
    add hl,de                   ; lower right corner
    ld  [hl],b

    ret

MoveCursorInc:
    inc [hl]
    ld  a,8
    cp  [hl]
    ret nz
    ld  [hl],0
    ret

MoveCursorDec:
    ld  a,[hl]
    or  a,a
    jr  z,MCD_Wrap
    dec [hl]
    ret
MCD_Wrap:
    ld  [hl],7
    ret

UpdateCursor:
    ld  a,[hl+]     ; convert the cursor y location to sprite y coordinates
    sla a
    sla a
    sla a
    sla a
    add a,24
    ld  b,a         ; store that in b

    ld  a,[hl]      ; do the same for x
    sla a
    sla a
    sla a
    sla a
    add a,24
    ld  c,a         ; and store it in c

    ld  de,_OAMRAM+$90      ; update the upper left corner of the cursor
    ld  a,b
    ld  [de],a
    inc de
    ld  a,c
    ld  [de],a

    inc de                  ; upper right
    inc de
    inc de
    ld  a,b
    ld  [de],a
    inc de
    ld  a,c
    add a,8
    ld  [de],a

    inc de                  ; lower left
    inc de
    inc de
    ld  a,b
    add a,8
    ld  [de],a
    inc de
    ld  a,c
    ld  [de],a

    inc de                  ; lower right
    inc de
    inc de
    ld  a,b
    add a,8
    ld  [de],a
    inc de
    ld  a,c
    add a,8
    ld  [de],a

    ret
