/*
 * the c interface to spotify-core, built with `--features capi`. it mirrors
 * the swift-bridge interface the apple apps use (src/swift_ffi.rs).
 *
 * strings are nul-terminated utf-8. a string returned from here is owned by the
 * caller and released with scarlett_string_free. functions returning an error
 * string return null on success.
 *
 * async calls return immediately. their result is queued as a completion and
 * the descriptor from scarlett_core_completion_fd becomes readable: drain it,
 * then call scarlett_core_take_completion until it returns false.
 */
#ifndef SCARLETT_CORE_H
#define SCARLETT_CORE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ScarlettCore ScarlettCore;

ScarlettCore *scarlett_core_new(void);
void scarlett_core_free(ScarlettCore *core);
void scarlett_string_free(char *value);

int scarlett_core_completion_fd(const ScarlettCore *core);
/* where there is no descriptor (windows: it is -1), callback(context) is
 * called from the finishing thread instead each time a completion is queued;
 * null takes it back. context lives until then. */
void scarlett_core_set_completion_callback(const ScarlettCore *core, void (*callback)(void *),
                                           void *context);
bool scarlett_core_take_completion(const ScarlettCore *core, uint64_t *request_id, bool *ok,
                                   char **payload);

/* async: each completes with `request_id`. lyrics and playlists complete
 * with json, as do both connects (the login to reconnect with), the rest
 * with an empty payload on success.
 *
 * a play call made while an earlier one is still running replaces it, as do
 * an output restart and a new connection: the earlier one then fails with
 * SCARLETT_CORE_SUPERSEDED, having started no sound. */
#define SCARLETT_CORE_SUPERSEDED "the request was replaced by a newer one"
/* a play call for a track spotify will not give this account fails with this */
#define SCARLETT_CORE_UNAVAILABLE "Spotify could not load this track."

void scarlett_core_connect(const ScarlettCore *core, uint64_t request_id, const char *access_token,
                           const char *client_id);
/* a login scarlett_core_connect (or this) completed with: librespot's reusable
 * credentials, which spend no oauth refresh token */
void scarlett_core_connect_stored(const ScarlettCore *core, uint64_t request_id, const char *login,
                                  const char *client_id);
void scarlett_core_play_track(const ScarlettCore *core, uint64_t request_id,
                              const char *spotify_uri);
/* prepares the next Spotify track on the standby player without starting it. */
char *scarlett_core_preload_track(const ScarlettCore *core, const char *spotify_uri,
                                  int preload_standby);
/* starts the preloaded track and overlaps it with the current one for duration_ms. */
void scarlett_core_crossfade_track(const ScarlettCore *core, uint64_t request_id,
                                   const char *spotify_uri, uint32_t duration_ms);
void scarlett_core_restart_audio_output(const ScarlettCore *core, uint64_t request_id);
void scarlett_core_lyrics_json(const ScarlettCore *core, uint64_t request_id,
                               const char *spotify_uri);
/* a playlist's songs read through the session, which still has them for a
 * playlist someone else made. completes with json shaped like the web api's
 * /v1/playlists/{id}/items page. */
void scarlett_core_playlist_json(const ScarlettCore *core, uint64_t request_id,
                                 const char *playlist_uri);
/* an artist's top songs, read through the session, since the web api no
 * longer has them. completes with json shaped like the web api's
 * /v1/artists/{id}/top-tracks response. */
void scarlett_core_artist_top_tracks_json(const ScarlettCore *core, uint64_t request_id,
                                          const char *artist_uri);
/* plays a music file of the person's own from anywhere on disk: mp3, flac,
 * ogg vorbis, wav, aiff, or aac or apple lossless in an m4a. */
void scarlett_core_play_file(const ScarlettCore *core, uint64_t request_id, const char *path);

/* what a music file's tags say, as json: title, artist, album, albumArtist,
 * trackNumber, discNumber, date, genre (each null when the file does not
 * say), durationMs and artworkPath (an embedded cover written into
 * artwork_dir under a name taken from its contents, or a cover image kept
 * beside the file, or null). null with *error set if it cannot be read.
 * needs no core and may be called from any thread. */
char *scarlett_read_local_tags(const char *path, const char *artwork_dir, char **error);
/* writes edits into a music file's tags: json with any of title, artist,
 * album, albumArtist, genre, date, trackNumber, discNumber (each set, or
 * cleared when empty; one left out is kept) and removeArtwork, with
 * `artwork` (artwork_len bytes of a jpeg or png, or null) as the front
 * cover. returns null, or an error to free; the file is left as it was if
 * anything fails. needs no core and may be called from any thread. */
char *scarlett_write_local_tags(const char *path, const char *edits, const uint8_t *artwork,
                                size_t artwork_len);

void scarlett_core_disconnect(const ScarlettCore *core);

char *scarlett_core_play(const ScarlettCore *core);
char *scarlett_core_pause(const ScarlettCore *core);
char *scarlett_core_seek(const ScarlettCore *core, uint32_t position_ms);
char *scarlett_core_set_volume(const ScarlettCore *core, float volume);
char *scarlett_core_set_stream_quality(const ScarlettCore *core, uint32_t kbps);
/* lists the audio outputs currently available to the app as [{id,name}, ...]. */
char *scarlett_core_audio_output_devices_json(const ScarlettCore *core);
/* chooses an output id from the list above; an empty id uses the system default. */
char *scarlett_core_set_audio_output_device(const ScarlettCore *core, const char *device_id);
/* keeps streamed songs in path (empty: none), up to limit_bytes; applies the
 * next time playback connects */
char *scarlett_core_set_audio_cache(const ScarlettCore *core, const char *path,
                                    uint64_t limit_bytes);
char *scarlett_core_set_playback_shaping(const ScarlettCore *core, float tempo,
                                         float pitch_semitones, bool preserves_pitch);
char *scarlett_core_set_equalizer(const ScarlettCore *core, const float *gains_db, size_t count);

bool scarlett_core_session_is_valid(const ScarlettCore *core);
bool scarlett_core_audio_output_stalled(const ScarlettCore *core);
uint32_t scarlett_core_playback_position_ms(const ScarlettCore *core);
uint32_t scarlett_core_playback_duration_ms(const ScarlettCore *core);
bool scarlett_core_take_end_of_track(const ScarlettCore *core);
float scarlett_core_volume(const ScarlettCore *core);
/* the rate the output for files and live audio runs at (opening it); 0 if none */
uint32_t scarlett_core_output_rate(const ScarlettCore *core);

void scarlett_core_set_spectrum_enabled(const ScarlettCore *core, bool enabled);
/* 48 bands in 0...1. allocates nothing; returns how many were written. */
size_t scarlett_core_spectrum_levels(const ScarlettCore *core, float *out, size_t capacity);

/* the equalizer's centre frequencies in hz; returns how many were written. */
size_t scarlett_equalizer_frequencies(float *out, size_t capacity);

/* audio another program plays, handed over as it plays: interleaved f32 at
 * the rate and channels it was made for. it outlives any core it plays
 * through. push may be called from any thread. */
typedef struct ScarlettLiveBuffer ScarlettLiveBuffer;
ScarlettLiveBuffer *scarlett_live_buffer_new(uint32_t rate, uint32_t channels);
void scarlett_live_buffer_free(ScarlettLiveBuffer *buffer);
void scarlett_live_buffer_push(const ScarlettLiveBuffer *buffer, const float *samples, size_t count);
/* plays the buffer through the equalizer and the spectrum in place of
 * whatever played; one already playing carries on */
char *scarlett_core_play_live(const ScarlettCore *core, const ScarlettLiveBuffer *buffer);
void scarlett_core_stop_live(const ScarlettCore *core);

#ifdef __cplusplus
}
#endif

#endif
