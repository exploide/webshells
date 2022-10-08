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
- Optionally, restrict access by setting a stealth password (`?pw=...`), will return 404 if not given
- No external dependencies
- Aims to offer most useful features without being overly bloated (at least I tried...)

### PHP / PHAR

- Supports multiple execution functions, in case some are disabled
- Multi file upload
- Show `phpinfo()`
- `Makefile` creates PHAR file out of PHP webshell

### JSP / WAR

- Detects OS and uses `cmd.exe /c` on Windows and `/bin/sh -c` on Unix-like
- Includes stderr in output
- On Windows, detects codepage and decodes output accordingly
- Multi file upload
- `Makefile` creates WAR file out of JSP webshell

### ASP

- Passes commands to `cmd.exe /c`
- Also shows stderr
