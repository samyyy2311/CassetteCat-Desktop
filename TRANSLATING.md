# Translating CassetteCat Desktop

English is CassetteCat Desktop's source language. Translations use Qt's translation files in `translations/`, and the app picks the one for the system language when it starts. Anything not translated yet shows in English.

## Translate on Weblate

Translations are done on [Weblate](https://hosted.weblate.org/engage/cassettecat/), in your browser, alongside the Android app. Pick a language, or add yours, and Weblate sends your work here as a pull request.

## Guidelines

- Translate the way the app would naturally speak in your language, not word for word.
- Keep placeholders exactly as they are: `%1`, `%2` and `%n` are filled in with names and numbers.
- Fill in every plural form your language needs. `%n` is the count.
- Leave names of products and services unchanged, such as CassetteCat, Jellyfin, MusicBrainz or Last.fm.
- Keep labels short: buttons, the sidebar and the player bar have little room.

## Where translations live

- `translations/cassettecat_en.ts` lists every string, and holds the English plural forms.
- `translations/cassettecat_<language>.ts` holds each translation, for example `cassettecat_de.ts` or `cassettecat_pt_BR.ts`.

## Adding new interface text

Every string the user can see is marked for translation:

- In QML, `qsTr("Play")`. In a Qt class in C++, `tr("Play")`. In a plain C++ function, `QCoreApplication::translate("Context", "Play")`.
- Write whole sentences with placeholders, such as `qsTr("Connected to %1").arg(name)`, not pieces joined with `+`. Word order differs between languages.
- Write counts as plurals: `qsTr("%n song(s)", "", count)`, never `count === 1 ? "song" : "songs"`.
- Don't mark keys, settings names, file names, URLs, shortcut keys or log messages.

The `translatable-text` test, run by `ctest`, fails when a label, title or tooltip in the QML is plain text instead of `qsTr()`. Names of products and services are allowed; add a new one to the list in `tests/check_translatable.cmake`.

Then update the translation files from the code:

```bash
cmake --build build/dev --target update_translations
```

For a new plural, fill in its English forms in `translations/cassettecat_en.ts`, for example `%n song` and `%n songs` for `%n song(s)`. The update keeps them.

## Checking a translation

Build the app and run it with your system set to the language. Look for text that's cut off, and for anything still in English.
