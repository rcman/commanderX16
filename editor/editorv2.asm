; Commander X16 Text Editor
; Full-featured editor with mouse support, menus, and customization
; Assemble with: cl65 -t cx16 -o EDITOR.PRG editor.asm

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

; Colors (using actual color values 0-15)
COL_TITLE_BG = 6        ; Blue
COL_TITLE_FG = 1        ; White
COL_EDIT_BG = 0         ; Black
COL_EDIT_FG = 5         ; Green
COL_STATUS_BG = 6       ; Blue
COL_STATUS_FG = 1       ; White
COL_MENU_BG = 7         ; Yellow
COL_MENU_FG = 0         ; Black

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
SCREEN = $FF5F
CHROUT = $FFD2
SETLFS = $FFBA
SETNAM = $FFBD
LOAD = $FFD5
SAVE = $FFD8
CLRCHN = $FFCC
SCREEN_SET_CHARSET = $FF62

; Mouse
MOUSE_CONFIG = $FF68
MOUSE_GET = $FF6B

; PETSCII control codes
KEY_DOWN = $11
KEY_UP = $91
KEY_RIGHT = $1D
KEY_LEFT = $9D
KEY_RETURN = $0D
KEY_DEL = $14
KEY_HOME = $13
KEY_F1 = $85

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
mouse_btn_prev: .res 1

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
    jsr init_screen
    jsr init_mouse
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
    
    ; Set default shortcuts (using PETSCII control codes)
    lda #$93        ; Clear screen (Ctrl+Home) for save
    sta key_save
    lda #$8C        ; Ctrl+L is actually shift+Commodore+L
    sta key_load
    lda #$91        ; Cursor up as quit placeholder
    sta key_quit
    lda #KEY_F1     ; F1 for menu
    sta key_menu
    
    ; Clear other vars
    lda #0
    sta cursor_x
    lda #EDIT_START_Y
    sta cursor_y
    lda #0
    sta scroll_offset
    sta scroll_offset+1
    sta file_length
    sta file_length+1
    sta dirty_flag
    sta menu_open
    sta filename_len
    sta mouse_btn_prev
    
    ; Clear text buffer with spaces (screen code $20)
    ldx #0
    lda #$20
@clear_loop:
    sta text_buffer,x
    sta text_buffer+$100,x
    sta text_buffer+$200,x
    sta text_buffer+$300,x
    sta text_buffer+$400,x
    sta text_buffer+$500,x
    sta text_buffer+$600,x
    sta text_buffer+$700,x
    sta text_buffer+$800,x
    sta text_buffer+$900,x
    sta text_buffer+$A00,x
    sta text_buffer+$B00,x
    sta text_buffer+$C00,x
    sta text_buffer+$D00,x
    sta text_buffer+$E00,x
    sta text_buffer+$F00,x
    inx
    bne @clear_loop
    
    rts

init_mouse:
    lda #1          ; Enable mouse
    ldx #0
    jsr MOUSE_CONFIG
    rts

init_screen:
    ; Use SCREEN kernal routine to set 80x60 mode
    ; Mode 0 = 80x60, charset = 0 (upper/lower)
    lda #$80        ; 128 = 80 column mode
    ldx #60         ; 60 rows
    ldy #0          ; Normal scale
    clc
    jsr SCREEN
    
    ; Set charset (using built-in charset)
    lda #0          ; Charset 0 (upper/lower)
    ldx #0          ; Bank
    ldy #0
    jsr SCREEN_SET_CHARSET
    
    ; Set VERA to bank 1, auto-increment 1 (this stays set)
    lda #$11
    sta VERA_ADDR_H
    
    rts

; ==================== UI Drawing ====================
draw_ui:
    jsr draw_title_bar
    jsr draw_edit_area
    jsr draw_status_bar
    jsr position_cursor
    rts

draw_title_bar:
    lda #0
    sta cursor_x
    lda #0
    sta cursor_y
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
@print_loop:
    lda title_text,y
    beq @fill_rest
    jsr petscii_to_screen
    jsr write_char_color
    iny
    cpy #SCREEN_W
    bcc @print_loop
    rts
    
@fill_rest:
    ; Fill rest of line with spaces
    cpy #SCREEN_W
    bcs @done
    lda #$20        ; Space screen code
    jsr write_char_color
    iny
    jmp @fill_rest
@done:
    rts

title_text:
    .byte "  X16 EDITOR  [F1=Menu]  [F2=Save]  [F3=Load]  [F8=Quit]",0

draw_edit_area:
    lda #EDIT_START_Y
@line_loop:
    sta cursor_y
    
    lda #0
    sta cursor_x
    jsr goto_xy
    
    ; Calculate buffer line offset
    lda cursor_y
    sec
    sbc #EDIT_START_Y
    clc
    adc scroll_offset
    tax                 ; X = actual line number in buffer
    
    ; Get colors for edit area
    lda color_edit_bg
    asl
    asl
    asl
    asl
    ora color_edit_fg
    pha                 ; Save color on stack
    
    ldy #0              ; Y = column counter
@char_loop:
    ; Calculate position in buffer (line * 80 + column)
    txa
    pha                 ; Save line number
    tya
    pha                 ; Save column
    
    ; Multiply line by 80
    txa
    sta @mult_temp
    lda #0
    sta @mult_temp+1
    
    ; Multiply by 16
    lda @mult_temp
    asl
    rol @mult_temp+1
    asl
    rol @mult_temp+1
    asl
    rol @mult_temp+1
    asl
    rol @mult_temp+1
    sta @mult_temp
    
    ; Multiply by 5 (now have * 80)
    lda @mult_temp
    sta @temp
    lda @mult_temp+1
    sta @temp+1
    
    asl @mult_temp
    rol @mult_temp+1
    asl @mult_temp
    rol @mult_temp+1
    
    lda @mult_temp
    clc
    adc @temp
    sta @mult_temp
    lda @mult_temp+1
    adc @temp+1
    sta @mult_temp+1
    
    ; Add column
    pla                 ; Get column back
    tay
    clc
    adc @mult_temp
    sta @mult_temp
    bcc :+
    inc @mult_temp+1
    
    ; Load character from buffer
:   ldx @mult_temp+1
    lda @mult_temp
    tax
    lda text_buffer,x
    
    pla                 ; Get line number back
    tax
    
    ; Write character with color
    pla                 ; Get color
    pha
    tax
    jsr write_char_color
    
    iny
    cpy #SCREEN_W
    bcc @char_loop
    
    pla                 ; Clean up color from stack
    
    lda cursor_y
    cmp #EDIT_END_Y
    bcc @line_loop
    
    rts

@mult_temp: .res 2
@temp: .res 2

draw_status_bar:
    lda #0
    sta cursor_x
    lda #STATUS_Y
    sta cursor_y
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
@print_loop:
    lda status_text,y
    beq @show_pos
    jsr petscii_to_screen
    jsr write_char_color
    iny
    jmp @print_loop
    
@show_pos:
    ; Show cursor position
    lda #$20        ; Space
    jsr write_char_color
    lda #$2C        ; 'L' screen code
    jsr write_char_color
    lda #$1A        ; ':' screen code
    jsr write_char_color
    
    ; Show line number
    lda cursor_y
    sec
    sbc #EDIT_START_Y
    clc
    adc scroll_offset
    jsr write_decimal
    
    lda #$20        ; Space
    jsr write_char_color
    lda #$23        ; 'C' screen code
    jsr write_char_color
    lda #$1A        ; ':' screen code
    jsr write_char_color
    
    ; Show column number
    lda cursor_x
    jsr write_decimal
    
    ; Show dirty indicator if needed
    lda dirty_flag
    beq @fill
    lda #$20
    jsr write_char_color
    lda #$0A        ; '*' screen code
    jsr write_char_color
    
@fill:
    ; Fill rest of line
    ldy #0
@count_loop:
    iny
    lda VERA_ADDR_L
    cmp #160        ; 80 * 2
    bcc @count_loop
    
    cpy #SCREEN_W
    bcs @done
    lda #$20
    jsr write_char_color
    jmp @fill
    
@done:
    rts

status_text:
    .byte "Ready",0

; ==================== Input Handling ====================
handle_key:
    ; Store key for comparison
    sta @key
    
    ; Check for function keys
    cmp #KEY_F1     ; F1 = Menu
    beq do_menu
    cmp #$86        ; F2 = Save
    beq do_save
    cmp #$87        ; F3 = Load
    beq do_load
    cmp #$8C        ; F8 = Quit
    beq do_quit
    
    ; Arrow keys
    cmp #KEY_DOWN
    beq cursor_down
    cmp #KEY_UP
    beq cursor_up
    cmp #KEY_RIGHT
    beq cursor_right
    cmp #KEY_LEFT
    beq cursor_left
    
    ; Return key
    cmp #KEY_RETURN
    beq handle_return
    
    ; Delete/Backspace
    cmp #KEY_DEL
    beq handle_backspace
    
    ; Home key
    cmp #KEY_HOME
    beq handle_home
    
    ; Regular character (printable PETSCII)
    lda @key
    cmp #$20
    bcc @done
    cmp #$80
    bcs @done
    
    jsr insert_char
    
@done:
    jsr draw_status_bar
    jsr position_cursor
    rts

@key: .res 1

insert_char:
    ; Insert character at cursor position (A = PETSCII)
    jsr petscii_to_screen
    pha
    
    ; Mark as dirty
    lda #1
    sta dirty_flag
    
    ; Calculate buffer position
    lda cursor_y
    sec
    sbc #EDIT_START_Y
    clc
    adc scroll_offset
    
    ; Multiply by 80
    sta @line
    lda #0
    sta @pos+1
    
    ; * 16
    lda @line
    asl
    rol @pos+1
    asl
    rol @pos+1
    asl
    rol @pos+1
    asl
    rol @pos+1
    sta @pos
    
    ; * 5 (total * 80)
    sta @temp
    lda @pos+1
    sta @temp+1
    
    asl @pos
    rol @pos+1
    asl @pos
    rol @pos+1
    
    lda @pos
    clc
    adc @temp
    sta @pos
    lda @pos+1
    adc @temp+1
    sta @pos+1
    
    ; Add cursor_x
    lda @pos
    clc
    adc cursor_x
    sta @pos
    bcc :+
    inc @pos+1
    
    ; Store character (screen code)
:   pla
    ldx @pos+1
    ldy @pos
    sta text_buffer,y
    
    ; Move cursor right
    jsr cursor_right
    jsr draw_edit_area
    jsr position_cursor
    
    rts

@key: .res 1
@line: .res 1
@pos: .res 2
@temp: .res 2

handle_return:
    jsr cursor_down
    lda #0
    sta cursor_x
    jsr position_cursor
    rts

handle_backspace:
    ; Move cursor left
    lda cursor_x
    bne @do_delete
    rts
    
@do_delete:
    dec cursor_x
    
    ; Replace with space
    lda #$20
    jsr insert_char
    dec cursor_x
    jsr draw_edit_area
    jsr position_cursor
    rts

handle_home:
    lda #0
    sta cursor_x
    jsr position_cursor
    rts

cursor_up:
    lda cursor_y
    cmp #EDIT_START_Y
    beq @done
    dec cursor_y
    jsr position_cursor
@done:
    rts

cursor_down:
    lda cursor_y
    cmp #EDIT_END_Y-1
    beq @done
    inc cursor_y
    jsr position_cursor
@done:
    rts

cursor_left:
    lda cursor_x
    beq @done
    dec cursor_x
    jsr position_cursor
@done:
    rts

cursor_right:
    lda cursor_x
    cmp #SCREEN_W-1
    beq @done
    inc cursor_x
    jsr position_cursor
@done:
    rts

; ==================== Mouse Handling ====================
check_mouse:
    jsr MOUSE_GET
    sta mouse_x
    stx mouse_x+1
    sty mouse_y
    
    ; Get button state
    jsr MOUSE_GET
    and #$01
    sta mouse_btn
    
    ; Check for new click (button just pressed)
    lda mouse_btn_prev
    bne @not_new
    
    lda mouse_btn
    beq @not_new
    
    ; New click detected
    jsr handle_mouse_click
    
@not_new:
    lda mouse_btn
    sta mouse_btn_prev
    rts

handle_mouse_click:
    ; Divide mouse_x by 8 to get column (640 pixels / 80 cols = 8 pixels per char)
    lda mouse_x+1
    lsr
    lsr
    lsr
    tax
    lda mouse_x
    ror
    ror
    ror
    lsr
    lsr
    lsr
    lsr
    lsr
    ora #0
    sta cursor_x
    
    ; Divide mouse_y by 8 to get row (480 pixels / 60 rows = 8 pixels per char)
    lda mouse_y
    lsr
    lsr
    lsr
    sta cursor_y
    
    ; Clamp to edit area
    lda cursor_y
    cmp #EDIT_START_Y
    bcs @check_max
    lda #EDIT_START_Y
    sta cursor_y
    
@check_max:
    lda cursor_y
    cmp #EDIT_END_Y
    bcc @check_menu
    lda #EDIT_END_Y-1
    sta cursor_y
    
@check_menu:
    ; Check if click in title bar
    lda mouse_y
    cmp #8          ; Top 8 pixels
    bcs @done
    
    jsr do_menu
    
@done:
    jsr position_cursor
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
    ; Draw menu popup
    lda #5
    sta cursor_x
    lda #3
    sta cursor_y
    jsr goto_xy
    
    ; Get menu colors
    lda color_status_bg
    asl
    asl
    asl
    asl
    ora color_status_fg
    tax
    
    ldy #0
@loop:
    lda menu_text,y
    beq @done
    jsr petscii_to_screen
    jsr write_char_color
    iny
    cpy #40
    bcc @loop
    
@done:
    rts

menu_text:
    .byte " MENU: 1=Theme 2=Keys ESC=Close ",0

; ==================== File Operations ====================
do_save:
    ; Use default filename if not set
    lda filename_len
    bne @have_name
    jsr set_default_filename
    
@have_name:
    ; Save file
    lda #1
    ldx #8
    ldy #0
    jsr SETLFS
    
    lda filename_len
    ldx #<filename
    ldy #>filename
    jsr SETNAM
    
    ; Calculate save size (simplified - save 4KB)
    lda #<text_buffer
    sta $30
    lda #>text_buffer
    sta $31
    
    ldx #<(text_buffer+4096)
    ldy #>(text_buffer+4096)
    lda #$30
    jsr SAVE
    
    bcs @error
    
    lda #0
    sta dirty_flag
    jsr draw_status_bar
    
@error:
    jsr CLRCHN
    rts

do_load:
    ; Use default filename if not set
    lda filename_len
    bne @have_name
    jsr set_default_filename
    
@have_name:
    ; Load file
    lda #1
    ldx #8
    ldy #1
    jsr SETLFS
    
    lda filename_len
    ldx #<filename
    ldy #>filename
    jsr SETNAM
    
    lda #0
    ldx #<text_buffer
    ldy #>text_buffer
    jsr LOAD
    
    jsr CLRCHN
    
    ; Reset cursor
    lda #0
    sta cursor_x
    lda #EDIT_START_Y
    sta cursor_y
    
    jsr draw_edit_area
    jsr position_cursor
    rts

set_default_filename:
    lda #8
    sta filename_len
    
    ldx #0
@copy:
    lda default_filename,x
    sta filename,x
    inx
    cpx #8
    bcc @copy
    rts

default_filename:
    .byte "TEXT.TXT"

do_quit:
    ; Check if dirty
    lda dirty_flag
    beq @quit
    
    ; TODO: Add save prompt
    
@quit:
    ; Clear screen and return to BASIC
    lda #$93
    jsr CHROUT
    rts

; ==================== Helper Functions ====================
goto_xy:
    ; Set VERA address for character at cursor_x, cursor_y
    ; Bank 1 and increment already set in init_screen
    
    ; Set column address (column * 2)
    lda cursor_x
    asl
    sta VERA_ADDR_L
    
    ; Set row address (row + $B0 for text buffer start)
    lda cursor_y
    clc
    adc #$B0
    sta VERA_ADDR_M
    
    rts

write_char_color:
    ; A = screen code, X = color byte
    sta VERA_DATA0
    stx VERA_DATA0
    rts

position_cursor:
    ; Position the hardware cursor
    ldx cursor_y
    ldy cursor_x
    clc
    jsr PLOT
    rts

petscii_to_screen:
    ; Convert PETSCII to screen code
    ; A = PETSCII, returns A = screen code
    cmp #$20
    bcc @done       ; Control chars stay same
    cmp #$40
    bcc @done       ; $20-$3F unchanged
    cmp #$60
    bcc @subtract   ; $40-$5F subtract $40
    cmp #$80
    bcc @done       ; $60-$7F unchanged
    cmp #$A0
    bcc @high       ; $80-$9F add $40
    cmp #$C0
    bcc @subtract2  ; $A0-$BF subtract $80
    cmp #$FF
    bcc @high2      ; $C0-$FE add $80
    
@done:
    rts
    
@subtract:
    sec
    sbc #$40
    rts
    
@subtract2:
    sec
    sbc #$80
    rts
    
@high:
    clc
    adc #$40
    rts
    
@high2:
    clc
    adc #$80
    and #$7F
    rts

write_decimal:
    ; Write A as decimal number (screen codes)
    pha
    
    ; Hundreds
    ldx #0
@hundreds:
    pla
    cmp #100
    bcc @tens_setup
    sec
    sbc #100
    pha
    inx
    jmp @hundreds
    
@tens_setup:
    pha
    txa
    beq @tens       ; Skip leading zero
    clc
    adc #$30        ; Convert to screen code digit
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
    
@tens:
    pla
    ldx #0
@tens_loop:
    cmp #10
    bcc @ones_setup
    sec
    sbc #10
    pha
    inx
    pla
    jmp @tens_loop
    
@ones_setup:
    pha
    txa
    clc
    adc #$30
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
    
@ones:
    pla
    clc
    adc #$30
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
