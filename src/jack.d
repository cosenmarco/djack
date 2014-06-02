/*
   Copyright (c) 2014 Marco Cosentino
   Licence GPLv3
*/

module jack;

import jack_c;
import std.conv;
import std.string;

alias jack_c.jack_native_thread_t ThreadId;
alias jack_c.JACK_POSITION_MASK JACK_POSITION_MASK;

alias jack_c.JackOpenOptions OpenOptions;
alias jack_c.JackLoadOptions LoadOptions;

alias jack_latency_range_t LatencyRange;
alias jack_port_id_t PortID;
alias jack_port_type_id_t PortTypeID;

alias jack_default_audio_sample_t DefaultAudioSample;
alias jack_c.JACK_DEFAULT_AUDIO_TYPE JACK_DEFAULT_AUDIO_TYPE;

alias jack_c.jack_unique_t Unique;
alias jack_c.jack_shmsize_t Shmsize;
alias jack_nframes_t NFrames;
alias jack_time_t Time;

alias jack_c.JACK_MAX_FRAMES MAX_FRAMES;
alias jack_c.JACK_LOAD_INIT_LIMIT LOAD_INIT_LIMIT;

enum Options : jack_options_t {
  NullOption =    jack_options_t.JackNullOption,
  NoStartServer = jack_options_t.JackNoStartServer,
  UseExactName =  jack_options_t.JackUseExactName,
  ServerName =    jack_options_t.JackServerName,
  LoadName =      jack_options_t.JackLoadName,
  LoadInit =      jack_options_t.JackLoadInit,
  SessionID =     jack_options_t.JackSessionID
};

enum Status : jack_status_t {
  Failure =       jack_status_t.JackFailure,
  InvalidOption = jack_status_t.JackInvalidOption,
  NameNotUnique = jack_status_t.JackNameNotUnique,
  ServerStarted = jack_status_t.JackServerStarted,
  ServerFailed =  jack_status_t.JackServerFailed,
  ServerError =   jack_status_t.JackServerError,
  NoSuchClient =  jack_status_t.JackNoSuchClient,
  LoadFailure =   jack_status_t.JackLoadFailure,
  InitFailure =   jack_status_t.JackInitFailure,
  ShmFailure =    jack_status_t.JackShmFailure,
  VersionError =  jack_status_t.JackVersionError,
  BackendError =  jack_status_t.JackBackendError,
  ClientZombie =  jack_status_t.JackClientZombie
};

enum LatencyCallbackMode : jack_latency_callback_mode_t {
  CaptureLatency =  jack_latency_callback_mode_t.JackCaptureLatency,
  PlaybackLatency = jack_latency_callback_mode_t.JackPlaybackLatency
}

enum PortFlags : JackPortFlags {
  IsInput =     JackPortFlags.JackPortIsInput,
  IsOutput =    JackPortFlags.JackPortIsOutput,
  IsPhysical =  JackPortFlags.JackPortIsPhysical,
  CanMonitor =  JackPortFlags.JackPortCanMonitor,
  IsTerminal =  JackPortFlags.JackPortIsTerminal
};

enum TransportState : jack_transport_state_t {
  Stopped = jack_transport_state_t.JackTransportStopped,
  Rolling = jack_transport_state_t.JackTransportRolling,
  Looping = jack_transport_state_t.JackTransportLooping,
  Starting = jack_transport_state_t.JackTransportStarting,
  NetStarting = jack_transport_state_t.JackTransportNetStarting,
};

enum PositionBits : jack_position_bits_t {
  PositionBBT =       jack_position_bits_t.JackPositionBBT,
  PositionTimecode =  jack_position_bits_t.JackPositionTimecode,
  BBTFrameOffset =    jack_position_bits_t.JackBBTFrameOffset,
  AudioVideoRatio =   jack_position_bits_t.JackAudioVideoRatio,
  VideoFrameOffset =  jack_position_bits_t.JackVideoFrameOffset
};


struct Position {
  Unique unique_1;
  Time usecs;
  NFrames frame_rate;
  NFrames frame;
  PositionBits valid;
  int bar;
  int beat;
  int tick;
  double bar_start_tick;
  float beats_per_bar;
  float beat_type;
  double ticks_per_beat;
  double beats_per_minute;
  double frame_time;
  double next_time; 
  NFrames bbt_offset;  
  float audio_frames_per_video_frame; 
  NFrames video_offset;
  int padding[7];
  Unique unique_2;
}

interface NamesArray
{
    string stringAt(size_t index);
    void dispose();
    string opIndex(size_t index);

    @property
    {
        int length();
        bool isDisposed();
    }
}

interface Port
{
    void* getBuffer(NFrames nframes);
    bool isConnectedTo(string otherPortName);
    NamesArray getConnections();
    void aliasSet(string al);
    void aliasUnset(string al);
    
    void requestMonitor(bool onoff);
    void ensureMonitor(bool onoff);

    LatencyRange getLatencyRange(LatencyCallbackMode callbackMode);
    void setLatencyRange(LatencyCallbackMode callbackMode, LatencyRange lr);

    @property
    {
        string name();
        void name(string newname);

        string shortname();
        PortFlags flags();
        string type();
        PortTypeID typeID();
        bool connected();
        // TODO: It's not clear how can I interface to get the aliases
        //string[] aliases();
        bool isMonitoringInput();
    }
}


alias extern(C) void function(LatencyCallbackMode mode, void* data) LatencyCallback;
alias extern(C) int function(NFrames nframes, void* data) ProcessCallback;
alias _JackThreadCallback ThreadCallback;
alias _JackThreadInitCallback ThreadInitCallback;
alias _JackGraphOrderCallback GraphOrderCallback;
alias _JackXRunCallback XRunCallback;
alias extern(C) int function(NFrames nframes, void* data) BufferSizeCallback;
alias extern(C) int function(NFrames nframes, void* data) SampleRateCallback;
alias extern(C) void function(PortID port, int register, void* data) PortRegistrationCallback;
alias _JackClientRegistrationCallback ClientRegistrationCallback;
alias extern(C) void function(PortID a, PortID b, int connect, void* data) PortConnectCallback;
alias extern(C) int function(PortID port, immutable(char)* old_name, immutable(char)* new_name, void* data) PortRenameCallback;
alias _JackFreewheelCallback FreewheelCallback;
alias _JackShutdownCallback ShutdownCallback;
alias extern(C) void function(Status code, immutable(char)* reason, void* data) InfoShutdownCallback;
alias extern(C) int function(TransportState state, Position *pos, void *arg) SyncCallback;
alias extern(C) void function(TransportState state, NFrames nframes, Position *pos, int new_pos, void *arg) TimebaseCallback;

alias jack_error_callback ErrorCallback;
alias jack_info_callback InfoCallback;

interface Client
{
    void close();
    void activate();
    void deactivate();

    // Port management
    Port portRegister(string port_name, string port_type, PortFlags flags, uint buffer_size);
    void portUnregister(Port port);
    bool portIsMine(Port port);
    NamesArray portGetAllConnections(Port port);
    void portRequestMonitorByName(string name, bool onoff);
    void portDisconnect(Port port);
    size_t portTypeGetBufferSize(string type);
    NamesArray getPorts(string pattern, string pattern_type, PortFlags flags);
    Port getByName(string port_name);
    Port getByID(PortID id);
    void connect(string source_port, string dest_port);
    void disconnect(string source_port, string dest_port);
    void recomputeTotalLatencies();


    // Transport
    void releaseTimebase();
    void transportStart();
    void transportStop();
    void setSyncTimeout(Time timeout);
    void transportLocate(NFrames frame);
    TransportState transportQuery(Position *pos);
    NFrames getCurrentTransportFrame();
    void trasnportReposition(Position *pos);


    
    // Callbacks
    void setProcessCallback(ProcessCallback callback, void* data);
    void setShutdownCallback(ShutdownCallback callback, void* data);
    void setFreewheelCallback(FreewheelCallback callback, void* data);
    void setBufferSizeCallback(BufferSizeCallback callback, void* data);
    void setSampleRateCallback(SampleRateCallback callback, void* data);
    void setClientRegistrationCallback(ClientRegistrationCallback callback, void* data);
    void setPortRegistrationCallback(PortRegistrationCallback callback, void* data);
    void setPortConnectCallback(PortConnectCallback callback, void* data);
    void setPortRenameCallback(PortRenameCallback callback, void* data);
    void setGraphOrderCallback(GraphOrderCallback callback, void* data);
    void setXRunCallback(XRunCallback callback, void* data);
    void setLatencyCallback(LatencyCallback callback, void* data);
    void setSyncCallback(SyncCallback callback, void* data);
    void setTimebaseCallback(int conditional, TimebaseCallback callback, void* data);

    Time framesToTime(NFrames frames);
    NFrames timeToFrames(Time time);

    @property
    {
        string name();
        ThreadId threadId();
        bool isRealtime();
        float cpuLoad();
        NFrames samplerate();
        NFrames buffersize();
        NFrames framesSinceCycleStart();
        NFrames frameTime();
        NFrames lastFrameTime();
    }
}

struct Version
{
    int major;
    int minor;
    int micro;
    int proto;
}


// ######### Implementation ###########

class JackException : Exception {
  Status status = Status.Failure;

  this(string message) {
    super(message);
  }

  this(string message, Status status) {
    super(message);
    this.status = status;
  }
}

class NamesArrayImplementation : NamesArray {
  immutable(char) ** rawPorts;
  bool disposed;
  int count;

  this(immutable(char) ** rawPorts) {
    this.rawPorts = rawPorts;
    disposed = false;
    count = 0;
    while( rawPorts[count] != null ) count ++;
  }

  ~this() {
    dispose();
  }

  void dispose() {
    jack_free(rawPorts);
    disposed = true;
  }

  bool isDisposed() {
    return disposed;
  }

  string stringAt(size_t index) {
    if(index >= count) {
      throw new JackException("Requested index out of bound");
    }
    return to!string( rawPorts[index] );
  }

  int length() {
    return count;
  }

  string opIndex(size_t index) {
    return stringAt(index);
  }
}

class PortImplementation : Port {
  jack_port_t* port;

  this(jack_port_t* port) {
    this.port = port;
  }

  string name() {
    return to!string( jack_port_name(port) );
  }

  void name(string newName) {
    if( jack_port_set_name(port, toStringz(newName)) ) {
      throw new JackException("Cannot set port name to " ~ newName);
    }
  }

  string shortname() {
    return to!string( jack_port_short_name(port) );
  }

  PortFlags flags() {
    return cast(PortFlags) jack_port_flags(port);
  }

  string type() {
    return to!string (jack_port_type(port));
  }

  PortTypeID typeID() {
    return jack_port_type_id(port);
  }

  bool connected() {
    return (jack_port_connected(port) != 0);
  }

  bool isMonitoringInput() {
    return (jack_port_monitoring_input(port) != 0);
  }


  LatencyRange getLatencyRange(LatencyCallbackMode callbackMode) {
    LatencyRange result;
    jack_port_get_latency_range(port, callbackMode, &result);
    return result;
  }

  void setLatencyRange(LatencyCallbackMode callbackMode, LatencyRange lr) {
    jack_port_set_latency_range(port, callbackMode, &lr);
  }

  void* getBuffer(NFrames nframes) {
    return jack_port_get_buffer(port, nframes);
  }

  bool isConnectedTo(string otherPortName) { 
    return (jack_port_connected_to(port, toStringz(otherPortName)) != 0);
  }

  NamesArray getConnections() {
    immutable(char)** rawConnections = jack_port_get_connections(port);
    if(rawConnections == null) {
      throw new JackException("Cannot get port connections");
    }
    return new NamesArrayImplementation(rawConnections);
  }
 
  void aliasSet(string al) {
    if( jack_port_set_alias(port, toStringz(al)) ) {
      throw new JackException("Cannot set port alias " ~ al);
    }
  }

  void aliasUnset(string al) {
    if( jack_port_unset_alias(port, toStringz(al)) ) {
      throw new JackException("Cannot unset port alias " ~ al);
    }
  }

  void requestMonitor(bool onoff) {
    if( jack_port_request_monitor(port, to!int (onoff)) ){
      throw new JackException("Cannot request port monitor for port " ~ this.name);
    }
  }

  void ensureMonitor(bool onoff) {
    if( jack_port_ensure_monitor(port, to!int (onoff)) ){
      throw new JackException("Cannot ensure port monitor for port " ~ this.name);
    }
  }

  @property jack_port_t* rawPointer() {
    return port;
  }
}



class ClientImplementation : Client {
  jack_client_t* client;

  this(jack_client_t* client) {
    this.client = client;
  }

  void close() {
    if( jack_client_close(client) ) {
      throw new JackException("Cannot close client");
    }
  }

  void activate() {
    if(jack_activate(client)) {
      throw new JackException("Cannot activate client");
    }
  }

  void deactivate() {
    if(jack_deactivate(client)) {
      throw new JackException("Cannot deactivate client");
    }
  }

  Port portRegister(string portName, string portType, PortFlags flags, uint bufferSize) {
    jack_port_t* port = jack_port_register (client, toStringz(portName), 
        toStringz(portType), flags, bufferSize);

    if( port == null ) {
      throw new JackException("Cannot register the port");
    }

    return new PortImplementation(port);
  }

  void portUnregister(Port port) {
    if( jack_port_unregister(client, (cast(PortImplementation) port).rawPointer) ) {
      throw new JackException("Cannot unregister port " ~ port.name);
    }
  }

  bool portIsMine(Port port) {
    return (jack_port_is_mine(client, (cast(PortImplementation) port).rawPointer) != 0);
  }

  NamesArray portGetAllConnections(Port port) {
    immutable(char) ** rawPorts = jack_port_get_all_connections(client, 
        (cast(PortImplementation) port).rawPointer);

    if(rawPorts == null) {
      throw new JackException("Cannot get all ports connection");
    }
    return new NamesArrayImplementation(rawPorts);
  }

  void portRequestMonitorByName(string name, bool onoff) {
    if( jack_port_request_monitor_by_name(client, toStringz(name), to!int(onoff)) ) {
      throw new JackException("Cannot request monitor by nme for " ~ name);
    }
  }

  void portDisconnect(Port port) {
    if( jack_port_disconnect(client, (cast(PortImplementation) port).rawPointer) ){
      throw new JackException("Cannot disconnect port " ~ port.name);
    }
  }

  size_t portTypeGetBufferSize(string type) {
    return jack_port_type_get_buffer_size(client, toStringz(type));
  }

  NamesArray getPorts(string pattern, string patternType, PortFlags flags) {
    immutable(char) ** rawPorts = jack_get_ports (client, toStringz(pattern), 
        toStringz(patternType), flags);
    if(rawPorts == null) {
      throw new JackException("Cannot get the ports");
    }
    return new NamesArrayImplementation(rawPorts);
  }

  Port getByName(string portName) {
    jack_port_t * portPtr = jack_port_by_name(client, toStringz(portName));
    if(portPtr == null) {
      throw new JackException("Cannot get port " ~ portName ~ " by name");
    }
    return new PortImplementation(portPtr);
  }

  Port getByID(PortID id) {
    jack_port_t * portPtr = jack_port_by_id(client, id);
    if(portPtr == null) {
      throw new JackException("Cannot get port " ~ to!string(id) ~ " by ID");
    }
    return new PortImplementation(portPtr);
  }

  void connect(string sourcePort, string destPort) {
    if( jack_connect (client, toStringz(sourcePort), toStringz(destPort)) ) {
      throw new JackException("Cannot connect the ports <" ~ sourcePort ~ "," ~ destPort ~ ">");
    }
  }

  void disconnect(string sourcePort, string destPort) {
    if( jack_disconnect (client, toStringz(sourcePort), toStringz(destPort)) ) {
      throw new JackException("Cannot disconnect the ports <" ~ sourcePort ~ "," ~ destPort ~ ">");
    }
  }

  void recomputeTotalLatencies() {
    if( jack_recompute_total_latencies(client) ) {
      throw new JackException("Cannot recompute total latencies");
    }
  }

  void releaseTimebase() {
    if( jack_release_timebase(client) ) {
      throw new JackException("Cannot release timebase");
    }
  }

  void transportStart() {
    jack_transport_start(client);
  }

  void transportStop() {
    jack_transport_stop(client);
  }

  void setSyncTimeout(Time timeout) { 
    if( jack_set_sync_timeout(client, timeout) ) {
      throw new JackException("Cannot set sync timeout");
    }
  }

  void transportLocate(NFrames frame){ 
    if(jack_transport_locate(client, frame)) {
      throw new JackException("Cannot locate frame " ~ to!string (frame));
    }
  }

  TransportState transportQuery(Position *pos) { 
    return cast(TransportState) jack_transport_query(client, cast(jack_position_t *) pos);
  }

  NFrames getCurrentTransportFrame() { 
    return jack_get_current_transport_frame(client);
  }

  void trasnportReposition(Position *pos) {
    if(jack_transport_reposition(client, cast(jack_position_t *) pos)) {
      throw new JackException("Cannot reposition");
    }
  }

  void setProcessCallback(ProcessCallback callback, void* data) {
    if(jack_set_process_callback (client, callback, data)) {
      throw new JackException("Cannot set process callback");
    }
  }

  void setShutdownCallback(ShutdownCallback callback, void* data) {
    jack_on_shutdown (client, callback, data);
  }

  void setFreewheelCallback(FreewheelCallback callback, void* data) { 
    if(jack_set_freewheel_callback (client, callback, data)) {
      throw new JackException("Cannot set freewheel callback");
    }
  }

  void setBufferSizeCallback(BufferSizeCallback callback, void* data) { 
    if(jack_set_buffer_size_callback (client, callback, data)) {
      throw new JackException("Cannot set buffer size callback");
    }
  }

  void setSampleRateCallback(SampleRateCallback callback, void* data) { 
    if(jack_set_sample_rate_callback (client, callback, data)) {
      throw new JackException("Cannot set sample rate callback");
    }
  }

  void setClientRegistrationCallback(ClientRegistrationCallback callback, void* data) { 
    if(jack_set_client_registration_callback (client, cast(_JackClientRegistrationCallback ) callback, data)) {
      throw new JackException("Cannot set client registration callback");
    }
  }

  void setPortRegistrationCallback(PortRegistrationCallback callback, void* data) { 
    if(jack_set_port_registration_callback (client, callback, data)) {
      throw new JackException("Cannot set port registration callback");
    }
  }

  void setPortConnectCallback(PortConnectCallback callback, void* data) { 
    if(jack_set_port_connect_callback (client, cast(_JackPortConnectCallback) callback, data)) {
      throw new JackException("Cannot set port connect callback");
    }
  }

  void setPortRenameCallback(PortRenameCallback callback, void* data) { 
    if(jack_set_port_rename_callback (client, cast(_JackPortRenameCallback) callback, data)) {
      throw new JackException("Cannot set port rename callback");
    }
  }

  void setGraphOrderCallback(GraphOrderCallback callback, void* data) { 
    if(jack_set_graph_order_callback (client, callback, data)) {
      throw new JackException("Cannot set graph order callback");
    }
  }

  void setXRunCallback(XRunCallback callback, void* data) { 
    if(jack_set_xrun_callback (client, callback, data)) {
      throw new JackException("Cannot set xrun callback");
    }
  }

  void setLatencyCallback(LatencyCallback callback, void* data) { 
    if(jack_set_latency_callback (client, cast(_JackLatencyCallback) callback, data)) {
      throw new JackException("Cannot set latency callback");
    }
  }

  void setSyncCallback(SyncCallback callback, void* data) {
    if(jack_set_sync_callback(client, cast(_JackSyncCallback) callback, data)) {
      throw new JackException("Cannot set sync callback");
    }
  }

  void setTimebaseCallback(int conditional, TimebaseCallback callback, void* data) {
    if (jack_set_timebase_callback(client, conditional, cast(_JackTimebaseCallback) callback, data)) {
      throw new JackException("Cannot set timebase callback");
    }
  }

  Time framesToTime(NFrames frames) {
    return jack_frames_to_time(client, frames);
  }

  NFrames timeToFrames(Time time) {
    return jack_time_to_frames(client, time);
  }


  string name() {
    return to!string( jack_get_client_name(client) );
  }

  ThreadId threadId() {
    return jack_client_thread_id(client);
  }

  bool isRealtime() {
    return (jack_is_realtime(client) != 0);
  }

  float cpuLoad() {
    return jack_cpu_load(client);
  }

  NFrames samplerate() {
    return jack_get_sample_rate(client);
  }

  NFrames buffersize() {
    return jack_get_buffer_size(client);
  }

  NFrames framesSinceCycleStart() {
    return jack_frames_since_cycle_start(client);
  }

  NFrames frameTime() {
    return jack_frame_time(client);
  }

  NFrames lastFrameTime() {
    return jack_last_frame_time(client);
  }
}


// ######### Global functions

static Client clientOpen(string clientName, Options options, out Status status, string serverName) {
  jack_client_t* client;

  if( status & Options.ServerName) {
    client = jack_client_open (toStringz(clientName), options, cast(jack_status_t *) &status, toStringz(serverName));
  } else {
    client = jack_client_open (toStringz(clientName), options, cast(jack_status_t *) &status);
  }

  if(client == null) {
    throw new JackException("Cannot open client", status);
  }

  return new ClientImplementation(client);
}

static Version getVersion() {
  Version result;
  jack_get_version(&result.major, &result.minor, &result.micro, &result.proto);
  return result;
}

static string getVersionString() {
  return to!string (jack_get_version_string());
}

static int getClientPID(string name) {
  return jack_get_client_pid(toStringz(name));
}

static int portNameSize() {
  return jack_port_name_size();
}

static int portTypeSize() {
  return jack_port_type_size();
}

static Time getTime() {
  return jack_get_time();
}

static setErrorCallback(ErrorCallback callback) {
  jack_set_error_function(callback);
}

static setInfoCallback(InfoCallback callback) {
  jack_set_info_function(callback);
}
