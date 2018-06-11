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

    ld  a,%11100100     ; load a normal palette up 11 10 01 00 - dark->light
    ldh [rBGP],a        ; load the palette

    ld  a,%10010001     ; = $91 
    ldh [rLCDC],a       ; turn on the LCD, BG, etc

MainLoop:
    call WaitVBlank     ; wait for v-blank, ensuring this loop is executed around 60 times per second
    halt                ; the actual main loop would go here

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
