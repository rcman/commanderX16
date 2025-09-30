; Commander X16 Text Editor
; Full-featured editor with mouse support, menus, and customization
; Assemble with: cl65 -t cx16 -o EDITOR.PRG editor.asm
; Written my R-C-MAN
; https://github.com/rcman/commanderx16

.org $0801

; BASIC stub
.word $080b
.word 2024
.byte $9e
.byte "2061"
.byte 0,0,0

; Entry point
jmp main

; ==================== Constants ====================
SCREEN_W = 80
SCREEN_H = 60
EDIT_START_Y = 2
EDIT_END_Y = 58
STATUS_Y = 59

; Colors
COL_TITLE_BG = $16      ; Blue
COL_TITLE_FG = $01      ; White
COL_EDIT_BG = $10       ; Black
COL_EDIT_FG = $05       ; Green
COL_STATUS_BG = $16     ; Blue
COL_STATUS_FG = $01     ; White
COL_MENU_BG = $07       ; Yellow
COL_MENU_FG = $00       ; Black

; VERA registers
VERA_ADDR_L = $9F20
VERA_ADDR_M = $9F21
VERA_ADDR_H = $9F22
VERA_DATA0 = $9F23
VERA_DATA1 = $9F24
VERA_CTRL = $9F25

; Kernal routines
GETIN = $FFE4
PLOT = $FFF0
CHROUT = $FFD2
SETLFS = $FFBA
SETNAM = $FFBD
LOAD = $FFD5
SAVE = $FFD8
CLRCHN = $FFCC

; Mouse
MOUSE_CONFIG = $FF68
MOUSE_GET = $FF6B

; ==================== Variables ====================
.segment "BSS"

cursor_x: .res 1
cursor_y: .res 1
scroll_offset: .res 2
file_length: .res 2
dirty_flag: .res 1
menu_open: .res 1
menu_type: .res 1
mouse_x: .res 2
mouse_y: .res 1
mouse_btn: .res 1

; Configuration
color_title_bg: .res 1
color_title_fg: .res 1
color_edit_bg: .res 1
color_edit_fg: .res 1
color_status_bg: .res 1
color_status_fg: .res 1

; Shortcut keys (customizable)
key_save: .res 1
key_load: .res 1
key_quit: .res 1
key_menu: .res 1

filename: .res 16
filename_len: .res 1

; Text buffer (8KB)
text_buffer: .res 8192

; ==================== Main Code ====================
.segment "CODE"

main:
    ; Initialize
    jsr init_vars
    jsr init_mouse
    jsr init_screen
    jsr draw_ui
    
main_loop:
    ; Check mouse
    jsr check_mouse
    
    ; Check keyboard
    jsr GETIN
    beq main_loop
    
    ; Handle key
    jsr handle_key
    
    jmp main_loop

; ==================== Initialization ====================
init_vars:
    ; Set default colors
    lda #COL_TITLE_BG
    sta color_title_bg
    lda #COL_TITLE_FG
    sta color_title_fg
    lda #COL_EDIT_BG
    sta color_edit_bg
    lda #COL_EDIT_FG
    sta color_edit_fg
    lda #COL_STATUS_BG
    sta color_status_bg
    lda #COL_STATUS_FG
    sta color_status_fg
    
    ; Set default shortcuts
    lda #$13        ; CTRL+S
    sta key_save
    lda #$0c        ; CTRL+L
    sta key_load
    lda #$11        ; CTRL+Q
    sta key_quit
    lda #$0d        ; CTRL+M
    sta key_menu
    
    ; Clear other vars
    lda #0
    sta cursor_x
    sta cursor_y
    sta scroll_offset
    sta scroll_offset+1
    sta file_length
    sta file_length+1
    sta dirty_flag
    sta menu_open
    sta filename_len
    
    ; Clear text buffer
    ldx #0
    lda #$20
:   sta text_buffer,x
    sta text_buffer+$100,x
    sta text_buffer+$200,x
    sta text_buffer+$300,x
    inx
    bne :-
    
    rts

init_mouse:
    lda #1          ; Enable mouse
    ldx #0
    jsr MOUSE_CONFIG
    rts

init_screen:
    ; Set screen mode 80x60
    lda #$00
    sta VERA_CTRL
    lda #$40        ; 80x60 text mode
    sta VERA_DATA0
    rts

; ==================== UI Drawing ====================
draw_ui:
    jsr draw_title_bar
    jsr draw_edit_area
    jsr draw_status_bar
    rts

draw_title_bar:
    lda #0
    ldx #0
    jsr goto_xy
    
    ; Set colors for title bar
    lda color_title_bg
    asl
    asl
    asl
    asl
    ora color_title_fg
    tax
    
    ldy #0
:   lda title_text,y
    beq :+
    jsr write_char_color
    iny
    jmp :-
    
    ; Fill rest of line
:   cpy #SCREEN_W
    beq @done
    lda #$20
    jsr write_char_color
    iny
    jmp :-
@done:
    rts

title_text:
    .byte "  X16 EDITOR  [F1=Menu]  [Ctrl+S=Save]  [Ctrl+L=Load]  [Ctrl+Q=Quit]",0

draw_edit_area:
    lda #EDIT_START_Y
    sta cursor_y
    
@line_loop:
    lda #0
    sta cursor_x
    lda cursor_x
    ldx cursor_y
    jsr goto_xy
    
    ; Calculate buffer offset
    lda cursor_y
    sec
    sbc #EDIT_START_Y
    clc
    adc scroll_offset
    tax
    
    ; Get colors
    lda color_edit_bg
    asl
    asl
    asl
    asl
    ora color_edit_fg
    pha
    
    ldy #0
@char_loop:
    ; Get character from buffer
    txa
    pha
    
    ; Calculate position in buffer (x * 80 + y)
    lda #0
    sta @temp
    lda #0
    sta @temp+1
    
    ; Multiply line number by 80
    txa
    ldx #80
:   clc
    adc @temp
    bcc :+
    inc @temp+1
:   dex
    bne :--
    
    ; Add column
    clc
    adc cursor_x
    sta @temp
    bcc :+
    inc @temp+1
    
    ; Load character
:   ldy @temp
    lda text_buffer,y
    
    pla
    tax
    
    ; Write character
    pla
    pha
    tax
    jsr write_char_color
    
    iny
    sty cursor_x
    cpy #SCREEN_W
    bne @char_loop
    
    pla
    
    inc cursor_y
    lda cursor_y
    cmp #EDIT_END_Y
    bne @line_loop
    
    rts

@temp: .res 2

draw_status_bar:
    lda #0
    ldx #STATUS_Y
    jsr goto_xy
    
    ; Set colors for status bar
    lda color_status_bg
    asl
    asl
    asl
    asl
    ora color_status_fg
    tax
    
    ; Draw status text
    ldy #0
:   lda status_text,y
    beq :+
    jsr write_char_color
    iny
    jmp :-
    
    ; Show cursor position
:   lda #$20
    jsr write_char_color
    lda #'L'
    jsr write_char_color
    lda #':'
    jsr write_char_color
    
    ; Show line number
    lda cursor_y
    jsr write_decimal
    
    lda #$20
    jsr write_char_color
    lda #'C'
    jsr write_char_color
    lda #':'
    jsr write_char_color
    
    ; Show column number
    lda cursor_x
    jsr write_decimal
    
    ; Fill rest
@fill:
    lda #$20
    jsr write_char_color
    inx
    cpx #SCREEN_W
    bne @fill
    
    rts

status_text:
    .byte "Ready",0

; ==================== Input Handling ====================
handle_key:
    ; Check for shortcuts
    cmp key_save
    beq do_save
    cmp key_load
    beq do_load
    cmp key_quit
    beq do_quit
    cmp key_menu
    beq do_menu
    
    ; Check for F1 (menu)
    cmp #$85
    beq do_menu
    
    ; Arrow keys
    cmp #$11        ; Cursor down
    beq cursor_down
    cmp #$91        ; Cursor up
    beq cursor_up
    cmp #$1d        ; Cursor right
    beq cursor_right
    cmp #$9d        ; Cursor left
    beq cursor_left
    
    ; Return key
    cmp #$0d
    beq handle_return
    
    ; Backspace
    cmp #$14
    beq handle_backspace
    
    ; Regular character
    cmp #$20
    bcc @done
    cmp #$80
    bcs @done
    
    jsr insert_char
    
@done:
    rts

insert_char:
    ; Insert character at cursor position
    pha
    
    ; Mark as dirty
    lda #1
    sta dirty_flag
    
    ; Calculate buffer position
    lda cursor_y
    sec
    sbc #EDIT_START_Y
    tax
    
    lda #0
    sta @pos
    sta @pos+1
    
    ; Multiply by 80
:   lda @pos
    clc
    adc #80
    sta @pos
    bcc :+
    inc @pos+1
:   dex
    bpl :--
    
    ; Add cursor_x
    lda @pos
    clc
    adc cursor_x
    sta @pos
    bcc :+
    inc @pos+1
    
    ; Store character
:   pla
    ldy @pos
    sta text_buffer,y
    
    ; Move cursor right
    jsr cursor_right
    jsr draw_edit_area
    
    rts

@pos: .res 2

handle_return:
    jsr cursor_down
    lda #0
    sta cursor_x
    jsr draw_edit_area
    rts

handle_backspace:
    ; Move cursor left
    lda cursor_x
    beq @done
    dec cursor_x
    
    ; Delete character
    jsr insert_char_space
    jsr draw_edit_area
@done:
    rts

insert_char_space:
    lda #$20
    jmp insert_char

cursor_up:
    lda cursor_y
    cmp #EDIT_START_Y
    beq @done
    dec cursor_y
@done:
    rts

cursor_down:
    lda cursor_y
    cmp #EDIT_END_Y-1
    beq @done
    inc cursor_y
@done:
    rts

cursor_left:
    lda cursor_x
    beq @done
    dec cursor_x
@done:
    rts

cursor_right:
    lda cursor_x
    cmp #SCREEN_W-1
    beq @done
    inc cursor_x
@done:
    rts

; ==================== Mouse Handling ====================
check_mouse:
    jsr MOUSE_GET
    sta mouse_x
    stx mouse_x+1
    sty mouse_y
    
    ; Check buttons (in A after GET)
    and #$01
    beq @no_click
    
    ; Mouse clicked
    jsr handle_mouse_click
    
@no_click:
    rts

handle_mouse_click:
    ; Check if click in title bar (menu area)
    lda mouse_y
    cmp #1
    bcs @not_title
    
    ; Open menu
    jsr do_menu
    
@not_title:
    ; Check if in edit area
    cmp #EDIT_START_Y
    bcc @done
    cmp #EDIT_END_Y
    bcs @done
    
    ; Move cursor to click position
    lda mouse_x
    sta cursor_x
    lda mouse_y
    sta cursor_y
    
@done:
    rts

; ==================== Menu System ====================
do_menu:
    lda menu_open
    bne close_menu
    
    ; Open menu
    lda #1
    sta menu_open
    jsr draw_menu
    rts

close_menu:
    lda #0
    sta menu_open
    jsr draw_ui
    rts

draw_menu:
    ; Draw menu popup at top
    lda #2
    ldx #10
    jsr goto_xy
    
    ; Get menu colors
    lda #COL_MENU_BG
    asl
    asl
    asl
    asl
    ora #COL_MENU_FG
    tax
    
    ldy #0
:   lda menu_text,y
    beq @done
    jsr write_char_color
    iny
    cpy #30
    bne :-
    
@done:
    rts

menu_text:
    .byte " MENU: 1=Colors 2=Keys 3=Save 4=Load ",0

; ==================== File Operations ====================
do_save:
    ; Prompt for filename if not set
    lda filename_len
    bne @have_name
    
    jsr prompt_filename
    
@have_name:
    ; Save file
    lda #1          ; Logical file
    ldx #8          ; Device 8 (disk)
    ldy #0          ; Secondary address
    jsr SETLFS
    
    lda filename_len
    ldx #<filename
    ldy #>filename
    jsr SETNAM
    
    lda #<text_buffer
    sta $30
    lda #>text_buffer
    sta $31
    
    ldx #<text_buffer
    ldy #>text_buffer
    lda #$30
    jsr SAVE
    
    lda #0
    sta dirty_flag
    
    jsr CLRCHN
    rts

do_load:
    ; Prompt for filename
    jsr prompt_filename
    
    ; Load file
    lda #1
    ldx #8
    ldy #0
    jsr SETLFS
    
    lda filename_len
    ldx #<filename
    ldy #>filename
    jsr SETNAM
    
    lda #0          ; Load to specified address
    ldx #<text_buffer
    ldy #>text_buffer
    jsr LOAD
    
    jsr CLRCHN
    jsr draw_edit_area
    rts

prompt_filename:
    ; Simple filename prompt (simplified)
    ; In a real implementation, this would be more interactive
    lda #8
    sta filename_len
    
    ; Default filename
    lda #'T'
    sta filename
    lda #'E'
    sta filename+1
    lda #'X'
    sta filename+2
    lda #'T'
    sta filename+3
    lda #'.'
    sta filename+4
    lda #'T'
    sta filename+5
    lda #'X'
    sta filename+6
    lda #'T'
    sta filename+7
    
    rts

do_quit:
    ; Check if dirty
    lda dirty_flag
    beq @quit
    
    ; TODO: Prompt to save
    
@quit:
    ; Return to BASIC
    jmp ($FFFC)

; ==================== Helper Functions ====================
goto_xy:
    ; Set VERA address for character at X, Y
    ; A = x, X = y
    stx @y
    sta @x
    
    ; Calculate address: $00000 + (y * 160) + (x * 2)
    lda #0
    sta @addr
    sta @addr+1
    sta @addr+2
    
    ; Multiply y by 160
    lda @y
    asl
    rol @addr+1
    asl
    rol @addr+1
    asl
    rol @addr+1
    asl
    rol @addr+1
    asl
    rol @addr+1
    sta @addr
    
    ; Add x * 2
    lda @x
    asl
    clc
    adc @addr
    sta @addr
    bcc :+
    inc @addr+1
    
    ; Set VERA address
:   lda @addr
    sta VERA_ADDR_L
    lda @addr+1
    sta VERA_ADDR_M
    lda @addr+2
    ora #$10        ; Increment by 1
    sta VERA_ADDR_H
    
    rts

@x: .res 1
@y: .res 1
@addr: .res 3

write_char_color:
    ; A = character, X = color
    sta VERA_DATA0
    stx VERA_DATA0
    rts

write_decimal:
    ; Write A as decimal number
    ldx #0
    pha
    
    ; Get hundreds
    lda #0
:   pla
    sec
    sbc #100
    bcs :+
    adc #100
    pha
    txa
    beq @tens
    ora #$30
    pha
    lda color_status_bg
    asl
    asl
    asl
    asl
    ora color_status_fg
    tax
    pla
    jsr write_char_color
    pla
    pha
    jmp @tens
    
:   inx
    pha
    jmp :--
    
@tens:
    ldx #0
:   pla
    sec
    sbc #10
    bcs :+
    adc #10
    pha
    txa
    ora #$30
    pha
    lda color_status_bg
    asl
    asl
    asl
    asl
    ora color_status_fg
    tax
    pla
    jsr write_char_color
    pla
    jmp @ones
    
:   inx
    pha
    jmp :--
    
@ones:
    ora #$30
    pha
    lda color_status_bg
    asl
    asl
    asl
    asl
    ora color_status_fg
    tax
    pla
    jsr write_char_color
    rts
