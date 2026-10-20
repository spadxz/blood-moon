# Swiftify add-ons

Swiftify add-ons are versioned QML packages. Add-ons can contribute components
to named extension points; the first built-in host is a separate floating
`miniPlayer` window. The package format keeps the install, enable, disable,
update, and remove flow stable as Swiftify gains more extension hosts.

## Install and manage add-ons

1. Open **Settings → Add-ons**.
2. To install Swiftify's bundled Lyrics Mini Player, choose **Install** under
   **Get Add-ons**.
3. To install a downloaded add-on, extract its archive, choose **Install from
   Folder…**, then select the extracted folder that contains `manifest.json`.
4. The package appears under **Installed Add-ons**. Use **Enabled** to turn it
   on or off. For an add-on with the `miniPlayer` extension, choose **Open** to
   show its floating window. The window's pin button keeps it above other
   windows; its close button hides it.
5. Choose **Remove** to uninstall a package. Reinstalling a package with the
   same ID replaces the installed version.

Swiftify copies installed packages into the directory shown at the bottom of
the Add-ons page. It stores each add-on's enabled state in Swiftify settings.
The app does not run add-on QML just because a package is installed; a component
loads when its host is opened.

## Package format

Each package has a `manifest.json`, one or more QML entry points, and any local
assets those QML files use. For example:

```text
lyrics-mini-player/
├── manifest.json
└── LyricsMiniPlayer.qml
```

```json
{
  "apiVersion": 1,
  "id": "lyrics-mini-player",
  "name": "Lyrics Mini Player",
  "version": "1.0.0",
  "description": "A floating player with lyrics and queue browsing.",
  "extensions": [
    {
      "slot": "miniPlayer",
      "entryPoint": "LyricsMiniPlayer.qml"
    }
  ]
}
```

The `id` uses lowercase letters, numbers, dots, and dashes. `version` follows
`major.minor.patch` with an optional prerelease or build suffix. Entry points
are relative `.qml` files inside the package. API version 1 permits up to 16
extensions per package. Swiftify validates the manifest, entry point paths,
package size (32 MB), file count (512), and symbolic links before installing.

The current `miniPlayer` entry point must create a QML `Item`. It runs in a
separate Swiftify window and can import the app module:

```qml
import QtQuick
import Swiftify

Item {
    // Player.currentSong, Player.lyrics, Player.upNext,
    // Player.togglePlayback(), Player.skipBackward(), and other QML APIs.
}
```

For lyrics, `Player.lyrics` exposes `words`, `startTimeMs`, and `endTimeMs` for
each line; `Player.activeLyricIndex` follows the current line, and
`Player.seekToLyricLine(index)` seeks synchronized lyrics. Playback controls
include `togglePlayback()`, `skipForward()`, `skipBackward()` (restart the
current song or go to the previous one), and `playFromQueue(song)`. `Player.upNext`
exposes the queue model.

The manifest already allows multiple named extension points. Swiftify must add
a host before a new slot can be displayed, and future integrations may require
new app APIs or a later `apiVersion`. Add-ons targeting an unsupported API
version are rejected with a settings message.

## Trust and compatibility

Add-ons are trusted QML code, not sandboxed scripts. An add-on can import
Swiftify's public QML module and use the same exposed app APIs as built-in QML.
Only install packages from sources you trust. Manifest checks reduce malformed
package and path risks; they do not make an add-on's code safe.

The app keeps the add-on enabled/disabled state across restarts. Removing a
package deletes its installed files. Keep a copy of a package if you want to
reinstall that version later.
