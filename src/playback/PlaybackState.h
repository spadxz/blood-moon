#pragma once

#include "spotify/SpotifyTypes.h"
#include <QByteArray>
#include <optional>

namespace scarlett::playbackstate {

constexpr int maximumQueue = 2000;

struct Snapshot {
    QList<Song> queue;
    QList<Song> shuffled;
    QList<Song> history;
    int currentIndex = -1;
    quint32 positionMs = 0;
    quint32 durationMs = 0;
    bool shuffle = false;
    int repeat = 0;
};

// The index identifies an occurrence, not a URI: duplicates are legitimate.
QByteArray encode(const QList<Song> &queue, const QList<Song> &shuffled,
                  const QList<Song> &history, const Song &current,
                  quint32 positionMs, quint32 durationMs, bool shuffle, int repeat);
std::optional<Snapshot> decode(const QByteArray &bytes);

} // namespace scarlett::playbackstate
