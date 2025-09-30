Features:

Creates a simple 16x16 pixel sprite (a white square) Displays the sprite at position (100, 100) Animates it by moving it across the screen horizontally Uses the VERA video chip's sprite system

Key Components:

BASIC stub - Allows you to run it with LOAD "PROGRAM.PRG" and RUN init_sprite_data - Writes sprite pixel data to VERA memory setup_sprite - Configures sprite 0's attributes (position, size, mode) move_sprite - Animates the sprite by updating its X position

To use this program:

Assemble it with ca65 or another 65C02 assembler Load it into the X16 emulator or hardware Type SYS 2064 or just RUN to execute

The sprite uses 8bpp (8 bits per pixel) mode for a 16x16 sprite. You can modify the sprite data in init_sprite_data to create different patterns, or adjust the movement code to change the animation!

