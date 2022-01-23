# Webshells

This repository contains my webshells written due to my dissatisfaction with many existing webshells, which usually lack the one or another feature.
Feel free to use them during CTFs or pentests.

Often, a minimalist web shell would be sufficient and only be used to fire up a reverse shell.
But in uncomfortable environments, e.g. when network traffic is blocked, a feature-equipped webshell like this comes in handy to examine the situation.

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
