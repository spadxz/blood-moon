#pragma once

#include <QString>

namespace scarlett::paths {

/// $XDG_DATA_HOME/Scarlett, created on first use: what the app keeps of the
/// person's, such as their local playlists.
QString dataDirectory();
/// $XDG_CACHE_HOME/Scarlett, for artwork and other things safe to delete.
QString cacheDirectory();

} // namespace scarlett::paths
