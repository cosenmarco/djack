/*
   Copyright (c) 2014 Marco Cosentino

   This file is part of djack. 

   djack is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   djack is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with Nome-Programma.  If not, see <http://www.gnu.org/licenses/>.
 */


// NOTE: Those marked as deprecated in the jack's .h files were not included !!

module jack_c;

import std.stdint;
import core.sys.posix.pthread;

// jack/systemdeps.h

alias pthread_t jack_native_thread_t;


// jack/types.h

const int JACK_MAX_FRAMES = 4294967295U;
const int JACK_LOAD_INIT_LIMIT = 1024;

alias int32_t jack_shmsize_t;
alias uint32_t jack_nframes_t;
alias uint64_t jack_time_t;
alias uint64_t jack_intclient_t;

struct _jack_port;
struct _jack_client;

alias _jack_port jack_port_t;
alias _jack_client jack_client_t;
alias uint32_t jack_port_id_t;
alias uint32_t jack_port_type_id_t;

enum jack_options_t {
    JackNullOption = 0x00,
    JackNoStartServer = 0x01,
    JackUseExactName = 0x02,
    JackServerName = 0x04,
    JackLoadName = 0x08,
    JackLoadInit = 0x10,
    JackSessionID = 0x20
};

const jack_options_t JackOpenOptions = ( jack_options_t.JackSessionID | 
    jack_options_t.JackServerName | jack_options_t.JackNoStartServer | 
    jack_options_t.JackUseExactName );

const jack_options_t JackLoadOptions = ( jack_options_t.JackLoadInit | 
    jack_options_t.JackLoadName | jack_options_t.JackUseExactName );


enum jack_status_t {
    JackFailure = 0x01,
    JackInvalidOption = 0x02,
    JackNameNotUnique = 0x04,
    JackServerStarted = 0x08,
    JackServerFailed = 0x10,
    JackServerError = 0x20,
    JackNoSuchClient = 0x40,
    JackLoadFailure = 0x80,
    JackInitFailure = 0x100,
    JackShmFailure = 0x200,
    JackVersionError = 0x400,
    JackBackendError = 0x800,
    JackClientZombie = 0x1000
};

enum jack_latency_callback_mode_t {
    JackCaptureLatency,
    JackPlaybackLatency
};


struct jack_latency_range_t
{
    jack_nframes_t min;
    jack_nframes_t max;
};

alias extern(C) void function(jack_latency_callback_mode_t mode, void *arg) _JackLatencyCallback;
alias extern(C) int function(jack_nframes_t nframes, void *arg) _JackProcessCallback;
alias extern(C) void * function(void* arg) _JackThreadCallback;
alias extern(C) void function(void* arg) _JackThreadInitCallback;
alias extern(C) int function(void* arg) _JackGraphOrderCallback;
alias extern(C) int function(void* arg) _JackXRunCallback;
alias extern(C) int function(jack_nframes_t nframes, void *arg) _JackBufferSizeCallback;
alias extern(C) int function(jack_nframes_t nframes, void *arg) _JackSampleRateCallback;
alias extern(C) void function(jack_port_id_t port, int register, void *arg) _JackPortRegistrationCallback;
alias extern(C) void function(immutable(char)* name, int register, void *arg) _JackClientRegistrationCallback;
alias extern(C) void function(jack_port_id_t a, jack_port_id_t b, int connect, void* arg) _JackPortConnectCallback;
alias extern(C) int function(jack_port_id_t port, immutable(char)* old_name, immutable(char)* new_name, void *arg) _JackPortRenameCallback;
alias extern(C) void function(int starting, void *arg) _JackFreewheelCallback;
alias extern(C) void function(void *arg) _JackShutdownCallback;
alias extern(C) void function(jack_status_t code, immutable(char)* reason, void *arg) _JackInfoShutdownCallback;

enum string  JACK_DEFAULT_AUDIO_TYPE = "32 bit float mono audio";
enum string  JACK_DEFAULT_MIDI_TYPE = "8 bit raw midi";

alias float jack_default_audio_sample_t;


enum JackPortFlags {
    JackPortIsInput = 0x1,
    JackPortIsOutput = 0x2,
    JackPortIsPhysical = 0x4,
    JackPortCanMonitor = 0x8,
    JackPortIsTerminal = 0x10
};

enum jack_transport_state_t {
    JackTransportStopped = 0,
    JackTransportRolling = 1,
    JackTransportLooping = 2,
    JackTransportStarting = 3,
    JackTransportNetStarting = 4
};

alias uint64_t jack_unique_t;

enum jack_position_bits_t {
    JackPositionBBT = 0x10,
    JackPositionTimecode = 0x20,
    JackBBTFrameOffset = 0x40,
    JackAudioVideoRatio = 0x80,
    JackVideoFrameOffset = 0x100
};

const jack_position_bits_t JACK_POSITION_MASK = ( jack_position_bits_t.JackPositionBBT | 
    jack_position_bits_t.JackPositionTimecode);

struct jack_position_t {
    jack_unique_t       unique_1;       /**< unique ID */
    jack_time_t         usecs;          /**< monotonic, free-rolling */
    jack_nframes_t      frame_rate;     /**< current frame rate (per second) */
    jack_nframes_t      frame;     
    jack_position_bits_t valid;     
    int32_t             bar;            /**< current bar */
    int32_t             beat;           /**< current beat-within-bar */
    int32_t             tick;           /**< current tick-within-beat */
    double              bar_start_tick;
    float               beats_per_bar;  /**< time signature "numerator" */
    float               beat_type;      /**< time signature "denominator" */
    double              ticks_per_beat;
    double              beats_per_minute;
    double              frame_time;     /**< current time in seconds */
    double              next_time; 
    jack_nframes_t      bbt_offset;  
    float               audio_frames_per_video_frame; 
    jack_nframes_t      video_offset;
    int32_t             padding[7];
    jack_unique_t       unique_2;       /**< unique ID */

};

alias extern(C) int function(jack_transport_state_t state, jack_position_t *pos, void *arg) _JackSyncCallback;
alias extern(C) void function(jack_transport_state_t state, jack_nframes_t nframes, jack_position_t *pos, int new_pos, void *arg) _JackTimebaseCallback;



// jack/transport.h
extern(C)
{
    int  jack_release_timebase (jack_client_t *client);
    int  jack_set_sync_callback (jack_client_t *client, _JackSyncCallback sync_callback, void *arg);
    int  jack_set_sync_timeout (jack_client_t *client, jack_time_t timeout);
    int  jack_set_timebase_callback (jack_client_t *client, int conditional, _JackTimebaseCallback timebase_callback, void *arg);
    int  jack_transport_locate (jack_client_t *client, jack_nframes_t frame);
    jack_transport_state_t jack_transport_query ( jack_client_t *client, jack_position_t *pos);
    jack_nframes_t jack_get_current_transport_frame ( jack_client_t *client);
    int  jack_transport_reposition (jack_client_t *client, jack_position_t *pos);
    void jack_transport_start (jack_client_t *client);
    void jack_transport_stop (jack_client_t *client);
}




// jack/jack.h

alias extern(C) void function(immutable(char)*  msg) jack_error_callback;
alias extern(C) void function(immutable(char)*  msg) jack_info_callback;


extern(C)
{
    void jack_get_version( int *major_ptr, int *minor_ptr, int *micro_ptr, int *proto_ptr);
    immutable(char)*  jack_get_version_string ();
    jack_client_t * jack_client_open (immutable(char)*  client_name, jack_options_t options, jack_status_t *status, ...);
    int jack_client_close (jack_client_t *client);
    int jack_client_name_size();
    immutable(char)*  jack_get_client_name (jack_client_t *client);
    int jack_activate (jack_client_t *client);
    int jack_deactivate (jack_client_t *client);
    int jack_get_client_pid (immutable(char)*  name);
    jack_native_thread_t jack_client_thread_id (jack_client_t *);
    int jack_is_realtime (jack_client_t *client);
    jack_nframes_t jack_cycle_wait (jack_client_t* client);
    void jack_cycle_signal (jack_client_t* client, int status);
    int jack_set_process_thread(jack_client_t* client, _JackThreadCallback thread_callback, void *arg);
    int jack_set_thread_init_callback (jack_client_t *client, _JackThreadInitCallback thread_init_callback,  void *arg);
    void jack_on_shutdown (jack_client_t *client, _JackShutdownCallback shutdown_callback, void *arg);
    void jack_on_info_shutdown (jack_client_t *client, _JackInfoShutdownCallback shutdown_callback, void *arg);
    int jack_set_process_callback (jack_client_t *client, _JackProcessCallback process_callback, void *arg);
    int jack_set_freewheel_callback (jack_client_t *client, _JackFreewheelCallback freewheel_callback, void *arg);
    int jack_set_buffer_size_callback (jack_client_t *client, _JackBufferSizeCallback bufsize_callback, void *arg);
    int jack_set_sample_rate_callback (jack_client_t *client, _JackSampleRateCallback srate_callback,  void *arg);
    int jack_set_client_registration_callback (jack_client_t *, _JackClientRegistrationCallback registration_callback, void *arg);
    int jack_set_port_registration_callback (jack_client_t *, _JackPortRegistrationCallback registration_callback, void *arg);
    int jack_set_port_connect_callback (jack_client_t *, _JackPortConnectCallback connect_callback, void *arg);
    int jack_set_port_rename_callback (jack_client_t *, _JackPortRenameCallback rename_callback, void *arg);
    int jack_set_graph_order_callback (jack_client_t *, _JackGraphOrderCallback graph_callback, void *);
    int jack_set_xrun_callback (jack_client_t *, _JackXRunCallback xrun_callback, void *arg);
    int jack_set_latency_callback (jack_client_t *, _JackLatencyCallback latency_callback, void *);
    int jack_set_freewheel(jack_client_t* client, int onoff);
    int jack_set_buffer_size (jack_client_t *client, jack_nframes_t nframes);
    jack_nframes_t jack_get_sample_rate (jack_client_t *);
    jack_nframes_t jack_get_buffer_size (jack_client_t *);
    float jack_cpu_load (jack_client_t *client);

    jack_port_t * jack_port_register (jack_client_t *client, immutable(char)*  port_name, immutable(char)*  port_type, uint flags, uint buffer_size);
    int jack_port_unregister (jack_client_t *, jack_port_t *);
    void * jack_port_get_buffer (jack_port_t *, jack_nframes_t);
    immutable(char)*  jack_port_name (jack_port_t *port);
    immutable(char)*  jack_port_short_name (jack_port_t *port);
    JackPortFlags jack_port_flags (jack_port_t *port);
    immutable(char)*  jack_port_type (jack_port_t *port);
    jack_port_type_id_t jack_port_type_id (jack_port_t *port);
    int jack_port_is_mine (jack_client_t *, jack_port_t *port);
    int jack_port_connected (jack_port_t *port);
    int jack_port_connected_to (jack_port_t *port, immutable(char)*  port_name);
    immutable(char)* * jack_port_get_connections (jack_port_t *port);
    immutable(char)* * jack_port_get_all_connections (jack_client_t *client, jack_port_t *port);
    int jack_port_tie (jack_port_t *src, jack_port_t *dst);
    int jack_port_untie (jack_port_t *port);
    int jack_port_set_name (jack_port_t *port, immutable(char)*  port_name);
    int jack_port_set_alias (jack_port_t *port, immutable(char)*  _alias);
    int jack_port_unset_alias (jack_port_t *port, immutable(char)*  _alias);
    int jack_port_get_aliases (jack_port_t *port, immutable(char)** aliases);
    int jack_port_request_monitor (jack_port_t *port, int onoff);
    int jack_port_request_monitor_by_name (jack_client_t *client, immutable(char)*  port_name, int onoff);
    int jack_port_ensure_monitor (jack_port_t *port, int onoff);
    int jack_port_monitoring_input (jack_port_t *port);
    int jack_connect (jack_client_t *, immutable(char)*  source_port, immutable(char)*  destination_port);
    int jack_disconnect (jack_client_t *, immutable(char)*  source_port, immutable(char)*  destination_port);
    int jack_port_disconnect (jack_client_t *, jack_port_t *);
    int jack_port_name_size();
    int jack_port_type_size();
    size_t jack_port_type_get_buffer_size (jack_client_t *client, immutable(char)*  port_type);

    void jack_port_get_latency_range (jack_port_t *port, jack_latency_callback_mode_t mode, jack_latency_range_t *range);
    void jack_port_set_latency_range (jack_port_t *port, jack_latency_callback_mode_t mode, jack_latency_range_t *range);
    int jack_recompute_total_latencies (jack_client_t*);

    immutable(char)* * jack_get_ports (jack_client_t *, immutable(char)*  port_name_pattern, immutable(char)*  type_name_pattern, uint flags);
    jack_port_t * jack_port_by_name (jack_client_t *, immutable(char)*  port_name);
    jack_port_t * jack_port_by_id (jack_client_t *client, jack_port_id_t port_id);

    jack_nframes_t jack_frames_since_cycle_start (jack_client_t *);
    jack_nframes_t jack_frame_time ( jack_client_t *);
    jack_nframes_t jack_last_frame_time ( jack_client_t *client);
    jack_time_t jack_frames_to_time( jack_client_t *client, jack_nframes_t);
    jack_nframes_t jack_time_to_frames( jack_client_t *client, jack_time_t);
    jack_time_t jack_get_time();

    void jack_set_error_function (jack_error_callback);
    void jack_set_info_function(jack_info_callback);

    void jack_free(void* ptr);
}


// jack/midiport.h
alias ubyte jack_midi_data_t;

struct jack_midi_event_t
{
    jack_nframes_t    time;   /**< Sample index at which event is valid */
    size_t            size;   /**< Number of bytes of data in \a buffer */
    jack_midi_data_t *buffer; /**< Raw MIDI data */
};

extern(C)
{
    jack_nframes_t jack_midi_get_event_count(void* port_buffer);
    int jack_midi_event_get(jack_midi_event_t *event,  void *port_buffer, jack_nframes_t event_index);
    void jack_midi_clear_buffer(void *port_buffer);
    size_t jack_midi_max_event_size(void* port_buffer);
    jack_midi_data_t* jack_midi_event_reserve(void *port_buffer, jack_nframes_t  time, size_t data_size);
    int jack_midi_event_write(void *port_buffer, jack_nframes_t time, const jack_midi_data_t *data, size_t data_size);
    jack_nframes_t jack_midi_get_lost_event_count(void *port_buffer);
}


// jack/ringbuffer.h
struct jack_ringbuffer_data_t {
    char *buf;
    size_t len;
};

struct jack_ringbuffer_t {
    char	*buf;
    size_t write_ptr;
    size_t read_ptr;
    size_t	size;
    size_t	size_mask;
    int	mlocked;
}

extern(C)
{
    jack_ringbuffer_t *jack_ringbuffer_create(size_t sz);
    void jack_ringbuffer_free(jack_ringbuffer_t *rb);
    void jack_ringbuffer_get_read_vector(const jack_ringbuffer_t *rb, jack_ringbuffer_data_t *vec);
    void jack_ringbuffer_get_write_vector(const jack_ringbuffer_t *rb, jack_ringbuffer_data_t *vec);
    size_t jack_ringbuffer_read(jack_ringbuffer_t *rb, char *dest, size_t cnt);
    size_t jack_ringbuffer_peek(jack_ringbuffer_t *rb, char *dest, size_t cnt);
    void jack_ringbuffer_read_advance(jack_ringbuffer_t *rb, size_t cnt);
    size_t jack_ringbuffer_read_space(const jack_ringbuffer_t *rb);
    int jack_ringbuffer_mlock(jack_ringbuffer_t *rb);
    void jack_ringbuffer_reset(jack_ringbuffer_t *rb);
    void jack_ringbuffer_reset_size (jack_ringbuffer_t * rb, size_t sz);
    size_t jack_ringbuffer_write(jack_ringbuffer_t *rb, immutable(char)*  src, size_t cnt);
    void jack_ringbuffer_write_advance(jack_ringbuffer_t *rb, size_t cnt);
    size_t jack_ringbuffer_write_space(const jack_ringbuffer_t *rb);
}
