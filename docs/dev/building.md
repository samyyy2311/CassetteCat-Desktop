# Building and testing

CassetteCat Desktop is C++20 and QML on Qt 6.

## Requirements

- **Qt 6.10 or newer** with Quick, Quick Controls 2, Multimedia, Concurrent, Quick Effects, Network and Widgets, plus DBus on Linux. The [Qt online installer](https://www.qt.io/download-qt-installer) or [aqtinstall](https://github.com/miurahr/aqtinstall) both work.
- **CMake 3.24 or newer** and **Ninja**.
- **OpenSSL 3** (libcrypto), for the phone remote's certificate.
- A C++20 compiler: MSVC 2022 or MinGW on Windows, Clang from the Xcode command line tools on macOS, and GCC or Clang on Linux.
- **Linux only**: `libsecret-1-dev` for the credential store.

TagLib is downloaded and built by CMake at a pinned version, so you don't need to install it.

| System | OpenSSL |
| :--- | :--- |
| Windows | Qt's OpenSSL package: `aqt install-tool windows desktop tools_opensslv3_x64 qt.tools.opensslv3.win_x64`, or the **OpenSSL 3** entry under Developer and Designer Tools in the Qt installer. Pass its folder as `-DOPENSSL_ROOT_DIR`. |
| macOS | `brew install openssl@3`, and pass `-DOPENSSL_ROOT_DIR="$(brew --prefix openssl@3)"`. Releases use a universal static build from `packaging/macos/build-openssl.sh`. |
| Linux | `libssl-dev` (Debian, Ubuntu) or `openssl-devel` (Fedora). |

## Building

```bash
cmake -S . -B build/dev -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x/<platform>
cmake --build build/dev
```

The app is `build/dev/CassetteCat` (`CassetteCat.exe` on Windows, `CassetteCat.app` on macOS).

On Windows with Qt's MinGW kit installed under `C:\Qt`, the `dev` and `release` presets set the compiler, Qt and OpenSSL paths for you:

```bash
cmake --preset dev
cmake --build --preset dev
```

Edit the paths in `CMakePresets.json` if your Qt version or folder differs. The `release` preset also runs `windeployqt` to copy the Qt libraries next to the executable.

### Last.fm

Last.fm needs the project's API account. Builds pick up its key and secret from the `LASTFM_API_KEY` and `LASTFM_API_SECRET` environment variables when you configure. Without them the build works, and Last.fm is left out of **Settings > Scrobbling**.

## Testing

The app has self-checks built in, and CTest runs them along with the QML tests:

```bash
ctest --test-dir build/dev --output-on-failure
```

Or run a self-check directly:

| Flag | Checks |
| :--- | :--- |
| `--self-check` | Everything below, plus settings, shortcuts, media controls, Discord status and the phone remote |
| `--library-self-check` | Library scanning and tag reading |
| `--streaming-self-check` | Subsonic and Jellyfin request handling |
| `--vault-self-check` | The same, plus saving a login in the system's credential store |
| `--services-self-check` | Online lookups, scrobbling and release notes |
| `--player-self-check` | Audio levels and playback |

Configure with `-DCASSETTECAT_BUILD_TESTING=OFF` to leave the tests out.

CI also builds with AddressSanitizer and UndefinedBehaviorSanitizer on Linux and runs the self-checks there, and runs `clang-tidy` and CodeQL. See [CI and releasing](releasing.md).

## Formatting

C++ follows `.clang-format`. Format with clang-format 18 before committing:

```bash
clang-format -i src/*.cpp src/*.h
```

CI checks formatting and fails on changes.

## Next

- [Architecture](../../ARCHITECTURE.md)
- [Design](../../DESIGN.md)
- [CI and releasing](releasing.md)
