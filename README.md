# Webshells

This repository contains my webshells written due to my dissatisfaction with many existing webshells, which usually lack the one or another feature.
Feel free to use them during CTFs or pentests.

## Features

- Large input field with autofocus
- Escapes HTML special characters in output when possible
- Shows exit code when possible
- Simple shell history with <kbd>&uarr;</kbd> / <kbd>&darr;</kbd> utilizing JavaScript's session storage
- File download
- Optionally, restrict access by setting a stealth password, will return 404 if not given
- No dependencies
- Aims to offer most useful features without being overly bloated (at least I tried...)

### PHP

- Supports multiple execution functions, in case some are disabled
- File upload
- Show `phpinfo()`

### JSP / WAR

- Detects OS and uses `cmd.exe /c` on Windows and `sh -c` on Unix-like
- Includes stderr in output
- `Makefile` creates WAR file out of JSP webshell
