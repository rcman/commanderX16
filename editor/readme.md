# Editor

<BR>
<BR>

Features Implemented: User Interface:<BR>
<BR>
Title Bar - Shows program name and quick key hints Edit Area - Main text editing area (lines 2-58) Status Bar - Shows line/column position and status<BR>

Mouse Support:<BR>

Click in edit area to move cursor Click title bar to open menu Full mouse integration via X16 Kernal<BR>

Keyboard Controls:<BR>

Ctrl+S - Save file (customizable) Ctrl+L - Load file (customizable) Ctrl+Q - Quit editor (customizable) Ctrl+M or F1 - Open menu (customizable) Arrow keys for cursor movement Return, Backspace, and character input<BR>

Customization:<BR>

All colors are stored in variables and can be changed Shortcut keys are configurable Menu system framework for settings<BR>

File Operations:<BR>

Save to disk with filename Load from disk Dirty flag tracking for unsaved changes 8KB text buffer<BR>

Architecture:<BR>

Modular design with separate functions VERA register access for screen control 80x60 text mode support Mouse and keyboard input handling<BR>

