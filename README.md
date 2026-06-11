# EM-Marine Reader

**Version:** 0.0.3.2

EM-Marine Reader is a small desktop utility for working with an EM-Marine card reader connected over Ethernet (TCP/IP).

The program runs quietly in the system tray, listens to the configured reader, receives the card code, and types it into the active window as keyboard input. It is useful when an access card code needs to be entered into another program, form, terminal, accounting system, or database application without manual typing.

## What the program does

- Connects to an EM-Marine reader over TCP/IP.
- Receives card codes from the reader.
- Types the received code into the currently active window.
- Can optionally press **Enter** after the card code.
- Shows connection status using the tray icon.
- Keeps simple log files for troubleshooting.
- Works from the tray and does not require the main window to stay open.

## First start

On the first launch the program creates a settings file automatically.

On Linux the settings file is stored here:

```text
~/.config/em-marine/options.ini
```

Default settings:

```ini
[Options]
IP=192.168.1.191
Port=9761
PressEnter=No
```

Open **Settings** from the tray menu and enter the IP address and port of your reader.

## Settings

### IP address

The network address of the EM-Marine reader.

Example:

```text
192.168.1.191
```

### Port

The TCP port used by the reader.

Default:

```text
9761
```

### Press Enter

When enabled, the program presses **Enter** after typing the card code.

This is useful when the target program expects the code to be submitted immediately.

## Tray icon

The program works mainly from the system tray.

The tray icon shows the current connection state:

- connected to the reader;
- not connected to the reader.

Right-click the tray icon to open the menu:

- **Settings** — open connection settings;
- **About** — show program information;
- **Exit** — close the program.

## Images and icons

The program first looks for icons in the system directory:

```text
/usr/share/pixmaps/em-marine/
```

If that directory does not exist, it uses the `images` directory next to the program file:

```text
./images/
```

This makes it possible to run the program without installing image files system-wide.

## Logs

On Linux log files are stored in:

```text
~/.local/share/em-marine/
```

Logs can help diagnose connection problems, missing image files, or card reading errors.

## Typical use

1. Start the program.
2. Open the tray menu and choose **Settings**.
3. Enter the reader IP address and port.
4. Save the settings.
5. Open the target program or input field.
6. Present a card to the reader.
7. The card code will be typed into the active window automatically.

## Notes

- The program sends the card code as keyboard input, so the correct target window must be active.
- If the reader is unavailable, the program keeps trying to reconnect.
- If **Press Enter** is enabled, the target application may immediately submit the entered code.

## Developer

Developer: **Khomenko V.V.**

GitHub: <https://github.com/khvalera/em-marine>

Email: <khvalera@ukr.net>

## Version 0.0.3.2

- Switched the Linux package build to the Qt6 LCL widgetset.
- Added single-instance protection: a second copy of the application will not start while one instance is already running.
- Added cross-platform single-instance implementation: Windows mutex and Unix lock file.
- Added a simple Windows build script: `build-windows.bat`.
