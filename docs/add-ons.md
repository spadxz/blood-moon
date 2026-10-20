# Blood Moon add-ons

Blood Moon add-ons are small, versioned QML packages. The host supplies the
window chrome and app APIs; a package supplies the content for one or more
extension points. Packages are installed from folders and run only when their
host is shown.

## Use the bundled add-ons

Open **Settings → Add-ons**. Under **Get Add-ons**, install the add-ons you
want, then leave **Enabled** on:

- **Lyrics Mini Player** opens a pinned, floating lyrics and queue player.
- **Blood Moon Liquid Lyrics** replaces the lyrics inspector with synchronized
  lyrics, the Blood Moon background, and an optional live spectrum.
- **Oniko Cursor Companion** follows the mouse inside the app window. It uses
  vector QML artwork, not an animated image or a background polling loop.

The liquid lyrics panel loads only while the lyrics inspector is open. The
cursor companion loads only while enabled. Turn either package off under
**Installed Add-ons** to unload it.

To install a community package, extract it, choose **Install from Folder…**, and
select the folder containing `manifest.json`. Reinstalling the same ID replaces
the package. Removing it deletes its installed copy.

## Extension points

An extension's entry point creates an `Item`, except for `miniPlayer`, which is
shown inside a separate native window.

| Slot | Host behavior |
| --- | --- |
| `miniPlayer` | Separate, optionally pinned mini-player window. Open from the add-on's settings row. |
| `lyricsPanel` | Replaces the lyrics inspector while it is open. If the component fails to load, the built-in lyrics panel is shown. |
| `windowOverlay` | Draws over the app window. Use passive handlers such as `HoverHandler` so app controls remain clickable. |

Each package can provide one component per slot and up to 16 slots. When
multiple enabled packages provide the same slot, the host selects them in
stable alphabetical order by package name and ID.

## Package format

Keep each package self-contained:

```text
my-addon/
├── manifest.json
├── Main.qml
└── assets/                 # optional, package-local files
```

```json
{
  "apiVersion": 1,
  "id": "my-addon",
  "name": "My Add-on",
  "version": "1.0.0",
  "description": "A short explanation of what it adds.",
  "extensions": [
    { "slot": "lyricsPanel", "entryPoint": "Main.qml" }
  ]
}
```

The ID uses lowercase letters, numbers, dots, and dashes. Versions use
`major.minor.patch`, with an optional prerelease or build suffix. Entry points
must be relative QML files inside the package. The installer checks the
manifest, entry-point paths, symbolic links, package size (32 MB), and file
count (512). It does not evaluate QML while installing.

The optional `requires` list currently accepts `spectrum`. Declaring it asks
the host to enable audio analysis only while the add-on's lyrics panel is
visible. Add-ons that do not need the spectrum should omit the field.

The current public QML module import remains `Swiftify` for compatibility with
the existing app and add-ons. This is an internal module identifier; the
product and user-facing name is Blood Moon (BM).

```qml
pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

Item {
    // Player.currentSong, Player.lyrics, Player.activeLyricIndex,
    // Player.togglePlayback(), Player.skipBackward(), and other app APIs.
}
```

`Player.lyrics` exposes `words`, `startTimeMs`, and `endTimeMs` for each line.
`Player.activeLyricIndex` follows synchronized lyrics, and
`Player.seekToLyricLine(index)` seeks to a line. Playback controls include
`togglePlayback()`, `skipForward()`, `skipBackward()` (restart or previous
track), and `playFromQueue(song)`. `Player.upNext` exposes the queue model.
`SpectrumView` is available for custom visualizers; set its `active` property
only while it is visible and wanted so the shared analyzer can sleep otherwise.

The API version is independent of the app version. Add-ons targeting an
unsupported API version are rejected with a settings message. A new host or
new app API may require a future API version.

## Trust, permissions, and performance

Add-ons are trusted QML code running in the app process; they are **not
sandboxed**. A package can use the public QML APIs available to built-in views.
Only install packages from people you trust. Path and size checks prevent
malformed package installs; they do not make the code safe.

There is no remote add-on store or automatic downloader. The app keeps the
enabled state across restarts and does not load add-on QML merely because it is
installed. Keep your own copy if you remove a package and want it later.

## Build a community package

Start by copying one of the folders under `addons/`, changing its ID, metadata,
and QML. Use one supported extension point above. Test it by installing the
package from its folder through **Settings → Add-ons**. No Node, browser engine,
or extra runtime is required.
