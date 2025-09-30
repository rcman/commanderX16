; Commander X16 Basic Sprite Demo
; Displays a single 16x16 sprite and moves it across the screen

; VERA registers
VERA_ADDR_LO    = $9F20
VERA_ADDR_MID   = $9F21
VERA_ADDR_HI    = $9F22
VERA_DATA0      = $9F23
VERA_DATA1      = $9F24
VERA_CTRL       = $9F25

; Sprite attribute base in VERA memory: $1FC00
SPRITE_ATTRS    = $1FC00

; Start address
    .org $0801
    
; BASIC stub: 10 SYS 2064
    .byte $0C, $08, $0A, $00, $9E, $20
    .byte $32, $30, $36, $34, $00, $00, $00

; Main program starts here
start:
    jsr init_sprite_data
    jsr setup_sprite
    jsr move_sprite
    rts

; Initialize sprite pixel data (simple 16x16 pattern)
init_sprite_data:
    ; Set VERA address to sprite data area ($00000)
    ; Using auto-increment of 1
    lda #$00
    sta VERA_CTRL       ; Select DATA0
    lda #$00
    sta VERA_ADDR_LO
    sta VERA_ADDR_MID
    lda #$10            ; Auto-increment 1
    sta VERA_ADDR_HI
    
    ; Write simple sprite data (a filled square)
    ldx #0
@loop:
    lda #$11            ; Color index 1 (white on default palette)
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    inx
    cpx #64             ; 16x16 = 256 pixels, 4 pixels per byte at 8bpp
    bne @loop
    rts

; Setup sprite 0 attributes
setup_sprite:
    ; Set VERA address to sprite 0 attributes ($1FC00)
    lda #$00
    sta VERA_CTRL
    lda #$00
    sta VERA_ADDR_LO
    lda #$FC
    sta VERA_ADDR_MID
    lda #$11            ; Auto-increment 1
    sta VERA_ADDR_HI
    
    ; Sprite attributes (8 bytes per sprite)
    ; Byte 0-1: Address of sprite data (bits 12:5 of address)
    lda #$00            ; Low byte of address >> 5
    sta VERA_DATA0
    lda #$00            ; High byte
    sta VERA_DATA0
    
    ; Byte 2-3: X position (bits 9:0)
    lda #$64            ; X = 100
    sta VERA_DATA0
    lda #$00
    sta VERA_DATA0
    
    ; Byte 4-5: Y position (bits 9:0)
    lda #$64            ; Y = 100
    sta VERA_DATA0
    lda #$00
    sta VERA_DATA0
    
    ; Byte 6: Z-depth and flip bits
    lda #$0C            ; Z-depth = 3 (in front of layer 1)
    sta VERA_DATA0
    
    ; Byte 7: Sprite size and palette offset
    lda #$50            ; 16x16 sprite, 8bpp mode
    sta VERA_DATA0
    
    rts

; Move sprite across screen
move_sprite:
    ldx #0              ; X position counter
@move_loop:
    ; Set address to sprite X position
    lda #$00
    sta VERA_CTRL
    lda #$04            ; Offset to X position
    sta VERA_ADDR_LO
    lda #$FC
    sta VERA_ADDR_MID
    lda #$11
    sta VERA_ADDR_HI
    
    ; Update X position
    txa
    sta VERA_DATA0
    lda #$00
    sta VERA_DATA0
    
    ; Small delay
    jsr delay
    
    inx
    cpx #200            ; Move until X = 200
    bne @move_loop
    rts

; Simple delay routine
delay:
    ldy #$04
@outer:
    ldx #$00
@inner:
    nop
    dex
    bne @inner
    dey
    bne @outer
    rts
