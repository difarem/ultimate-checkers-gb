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

HELLO_BLANK     EQU 0
HELLO_H         EQU 1
HELLO_E         EQU 2
HELLO_L         EQU 3
HELLO_O         EQU 4
HELLO_W         EQU 5
HELLO_R         EQU 6
HELLO_D         EQU 7
HELLO_BANG      EQU 8
HELLO_SIZE      EQU 9

    SECTION "Tiles", ROM0
HELLO_TILES::
    INCBIN "gfx/hello_world.2bpp"


;*************
;*  tilemap  *
;*************

    SECTION "Map",ROM0
HELLO_MAP::
    DB  HELLO_H
    DB  HELLO_E
    DB  HELLO_L
    DB  HELLO_L
    DB  HELLO_O
    DB  HELLO_BLANK
    DB  HELLO_W
    DB  HELLO_O
    DB  HELLO_R
    DB  HELLO_L
    DB  HELLO_D
    DB  HELLO_BANG


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
    call LoadMap        ; load up our map

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
    ld  a,HELLO_BLANK       ; load our blank tile offset into A...
    ld  [hl+],a             ; load A into the address at HL and increment HL
    dec bc                  ; decrement our counter
    ld  a,b                 ; to see if BC is zero, we check both B...
    or  c                   ; and C
    jr  nz,ClearMap_Loop    ; loop while we don't reach zero

    ret                     ; done!


LoadTiles::
    ld  hl,HELLO_TILES
    ld  de,_VRAM

    ld  bc,HELLO_SIZE*16     ; we have 9 tiles and each tile takes 16 bytes
LoadTiles_Loop:
    ld  a,[hl+]             ; get a byte from our tiles, and increment.
    ld  [de],a              ; put that byte in VRAM and
    inc de                  ; increment.
    dec bc                  ; bc=bc-1.
    ld  a,b                 ; if b or c != 0,
    or  c                   ;
    jr  nz,LoadTiles_Loop   ; then loop.

    ret                     ; done


LoadMap::
    ld  hl,HELLO_MAP    ; our little map
    ld  de,_SCRN0       ; where our map goes

    ld  c,12            ; since we are only loading 12 tiles
LoadMap_Loop:
    ld  a,[hl+]             ; get a byte of the map and inc hl
    ld  [de],a              ; put the byte at de
    inc de                  ; duh...
    dec c                   ; decrement our counter
    jr  nz,LoadMap_Loop     ; and of the counter != 0 then loop

    ret                     ; done
