Features:

Creates a simple 16x16 pixel sprite (a white square) Displays the sprite at position (100, 100) Animates it by moving it across the screen horizontally Uses the VERA video chip's sprite system

Key Components:

BASIC stub - Allows you to run it with LOAD "PROGRAM.PRG" and RUN init_sprite_data - Writes sprite pixel data to VERA memory setup_sprite - Configures sprite 0's attributes (position, size, mode) move_sprite - Animates the sprite by updating its X position

To use this program:

Assemble it with ca65 or another 65C02 assembler Load it into the X16 emulator or hardware Type SYS 2064 or just RUN to execute

The sprite uses 8bpp (8 bits per pixel) mode for a 16x16 sprite. You can modify the sprite data in init_sprite_data to create different patterns, or adjust the movement code to change the animation!


For the Commander X16 VERA chip, here are the sprite capabilities: Maximum Number of Sprites:

128 sprites total can be defined All 128 can be displayed simultaneously (hardware permitting)

Sprite Color Modes:

4-bit (16 colors)

16 colors per sprite Can select from any 16-color palette offset in the 256-color palette More memory-efficient

8-bit (256 colors)

Full 256 colors per sprite Access to the entire palette Uses more VERA memory

Sprite Sizes Available:

8x8 pixels 16x16 pixels 32x32 pixels 64x64 pixels

Color Palette Details:

The VERA has a 256-color palette (512 bytes total) Each palette entry is 12-bit color (4 bits each for Red, Green, Blue) For 4bpp sprites, you specify a palette offset (0-15) to choose which 16 colors to use For 8bpp sprites (like in my example), you get all 256 colors

Memory Considerations:

Total sprite data memory: 128KB VRAM available 8bpp 16x16 sprite = 256 bytes 4bpp 16x16 sprite = 128 bytes 8bpp 64x64 sprite = 4,096 bytes

So you could theoretically have many colorful sprites on screen at once, with each one using up to 256 colors if using 8bpp mode!

********************************************************************************************************************

Sprites on the Commander X16 are typically saved and loaded in a few different ways:Common Sprite Data Formats:1. Raw Binary Files (.BIN) The most common approach - just the raw pixel data:

4bpp sprite: Each byte contains 2 pixels (4 bits each) 8bpp sprite: Each byte contains 1 pixel (8 bits) For a 16x16 8bpp sprite: 256 bytes of data Load directly into VERA memory with LOAD or VLOAD Example BASIC command:
