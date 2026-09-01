# Contributing to CassetteCat Desktop

Thanks for helping improve CassetteCat Desktop.

## Before you start

For a new feature or a large change, open an issue first. This helps us agree on the goal before code is written.

Keep each pull request focused on one change. Do not mix refactors, new features, and unrelated formatting in the same pull request.

## Build locally

You need Qt 6.8 or newer, CMake 3.24 or newer, and Ninja.

```powershell
cmake --preset dev
cmake --build --preset dev
.\build\dev\CassetteCat.exe --self-check
```

## Pull requests

Before opening a pull request:

- Explain what changed and why.
- Build the app and run the self-check.
- Include screenshots for visible changes.
- Do not commit `build/`, local logs, editor files, or generated converter files.
- Keep third-party notices up to date when adding code, fonts, icons, or artwork.

## Reporting issues

Use the issue templates for bugs and feature requests. Do not post security issues publicly; read [the security policy](.github/SECURITY.md) instead.
