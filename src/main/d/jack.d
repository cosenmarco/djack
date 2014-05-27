/*
   Copyright (c) 2014 Marco Cosentino
   Licence GPLv3
*/

module jack;

import jack_c;
import std.conv;
import std.string;

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
    string stringAt(int index);
    //const char* ptrAt(); ?? useful?
    void dispose();

    @property
    {
        int length();
        bool isDisposed();
    }
}

interface Port
{
    void* getBuffer(NFrames nframes);
    bool isConnectedTo(string other_port_name);
    NamesArray getConnections();
    void aliasSet(string al);
    void aliasUnset(string al);
    
    void request_monitor(bool onoff);
    void ensure_monitor(bool onoff);
    
    @property
    {
        string name();
        void name(string newname);

        string shortname();
        uint flags();
        string type();
        PortID typeID();
        bool connected();
        string[] aliases();
        bool isMonitoringInput();

        LatencyRange latencyRange();
        void latencyRange(LatencyRange lr);
    }
}


alias int function(NFrames nframes, void* data) ProcessCallback;
alias void* function(void* data) ThreadCallback;
alias void function(void* data) ThreadInitCallback;
alias int function(void* data) GraphOrderCallback;
alias int function(void* data) XRunCallback;
alias int function(NFrames nframes, void* data) BufferSizeCallback;
alias int function(NFrames nframes, void* data) SampleRateCallback;
alias void function(PortID port, int register, void* data) PortRegistrationCallback;
alias void function(string name, int register, void* data) ClientRegistrationCallback;
alias void function(Port a, Port b, int connect, void* data) PortConnectCallback;
alias int function(Port port, string old_name, string new_name, void* data) PortRenameCallback;
alias void function(int starting, void* data) FreewheelCallback;
alias void function(void* data) ShutdownCallback;
alias void function(Status code, string reason, void* data) InfoShutdownCallback;
alias void function(LatencyCallbackMode mode, void* data) LatencyCallback;
alias int function(TransportState state, Position *pos, void *arg) SyncCallback;
alias void function(TransportState state, NFrames nframes, Position *pos, int new_pos, void *arg) TimebaseCallback;

interface Client
{
    void close();
    void activate();
    void deactivate();
    void engineTakeoverTimebase();

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
        int nameSize(); 
        int pid();
        JackThread thread();
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

interface JackThread {}


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

  void dispose() {
    jack_free(rawPorts);
    disposed = true;
  }

  bool isDisposed() {
    return disposed;
  }

  string stringAt(int index) {
    if(index >= count) {
      throw new JackException("Requested index out of bound");
    }
    return to!string( rawPorts[index] );
  }

  int length() {
    return count;
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

  void name(string newName) { throw new Exception("Not yet implemented"); }
  string shortname() { throw new Exception("Not yet implemented"); }
  uint flags() { throw new Exception("Not yet implemented"); }
  string type() { throw new Exception("Not yet implemented"); }
  PortID typeID() { throw new Exception("Not yet implemented"); }
  bool connected() { throw new Exception("Not yet implemented"); }
  string[] aliases() { throw new Exception("Not yet implemented"); }
  bool isMonitoringInput() { throw new Exception("Not yet implemented"); }

  LatencyRange latencyRange() { throw new Exception("Not yet implemented"); }
  void latencyRange(LatencyRange lr) { throw new Exception("Not yet implemented"); }

  void* getBuffer(NFrames nframes) {
    return jack_port_get_buffer(port, nframes);
  }
  bool isConnectedTo(string other_port_name) { throw new Exception("Not yet implemented"); }
  NamesArray getConnections() { throw new Exception("Not yet implemented"); }
  void aliasSet(string al) { throw new Exception("Not yet implemented"); }
  void aliasUnset(string al) { throw new Exception("Not yet implemented"); }

  void request_monitor(bool onoff) { throw new Exception("Not yet implemented"); }
  void ensure_monitor(bool onoff) { throw new Exception("Not yet implemented"); }
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

  void engineTakeoverTimebase()  { throw new Exception("Not yet implemented"); }

  Port portRegister(string portName, string portType, PortFlags flags, uint bufferSize) {
    jack_port_t* port = jack_port_register (client, toStringz(portName), 
        toStringz(portType), flags, bufferSize);

    if( port == null ) {
      throw new JackException("Cannot register the port");
    }

    return new PortImplementation(port);
  }

  void portUnregister(Port port) { throw new Exception("Not yet implemented"); }
  bool portIsMine(Port port) { throw new Exception("Not yet implemented"); }
  NamesArray portGetAllConnections(Port port) { throw new Exception("Not yet implemented"); }
  void portRequestMonitorByName(string name, bool onoff) { throw new Exception("Not yet implemented"); }
  void portDisconnect(Port port) { throw new Exception("Not yet implemented"); }
  size_t portTypeGetBufferSize(string type) { throw new Exception("Not yet implemented"); }

  NamesArray getPorts(string pattern, string patternType, PortFlags flags) {
    immutable(char) ** rawPorts = jack_get_ports (client, toStringz(pattern), 
        toStringz(patternType), flags);
    if(rawPorts == null) {
      throw new JackException("Cannot get the ports");
    }
    return new NamesArrayImplementation(rawPorts);
  }

  Port getByName(string port_name) { throw new Exception("Not yet implemented"); }
  Port getByID(PortID id) { throw new Exception("Not yet implemented"); }


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

  void recomputeTotalLatencies() { throw new Exception("Not yet implemented"); }

  void releaseTimebase() {
    jack_release_timebase(client);
  }

  void transportStart() {
    jack_transport_start(client);
  }

  void transportStop() {
    jack_transport_stop(client);
  }

  void setSyncTimeout(Time timeout) { 
    jack_set_sync_timeout(client, timeout);
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
    if(jack_set_client_registration_callback (client, callback, data)) {
      throw new JackException("Cannot set client registration callback");
    }
  }
  void setPortRegistrationCallback(PortRegistrationCallback callback, void* data) { 
    if(jack_set_port_registration_callback (client, callback, data)) {
      throw new JackException("Cannot set port registration callback");
    }
  }
  void setPortConnectCallback(PortConnectCallback callback, void* data) { 
    if(jack_set_port_connect_callback (client, callback, data)) {
      throw new JackException("Cannot set port connect callback");
    }
  }
  void setPortRenameCallback(PortRenameCallback callback, void* data) { 
    if(jack_set_port_rename_callback (client, callback, data)) {
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
    if(jack_set_latency_callback (client, callback, data)) {
      throw new JackException("Cannot set latency callback");
    }
  }
  void setSyncCallback(SyncCallback callback, void* data){
  }
  void setTimebaseCallback(int conditional, TimebaseCallback callback, void* data) {
    if (jack_set_timebase_callback(client, conditional, callback, data)) {
      throw new JackException("Cannot set timebase callback");
    }
  }

  Time framesToTime(NFrames frames) { throw new Exception("Not yet implemented"); }
  NFrames timeToFrames(Time time) { throw new Exception("Not yet implemented"); }


  string name() {
    return to!string( jack_get_client_name(client) );
  }

  int nameSize() { throw new Exception("Not yet implemented"); } 
  int pid() { throw new Exception("Not yet implemented"); }
  JackThread thread() { throw new Exception("Not yet implemented"); }
  bool isRealtime() { throw new Exception("Not yet implemented"); }
  float cpuLoad() { throw new Exception("Not yet implemented"); }
  NFrames samplerate() { throw new Exception("Not yet implemented"); }
  NFrames buffersize() { throw new Exception("Not yet implemented"); }
  NFrames framesSinceCycleStart() { throw new Exception("Not yet implemented"); }
  NFrames frameTime() { throw new Exception("Not yet implemented"); }
  NFrames lastFrameTime() { throw new Exception("Not yet implemented"); }
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
static Version getVersion() { throw new Exception("Not yet implemented"); }
static string getVersionString() { throw new Exception("Not yet implemented"); }
static int getClientPID(string name) { throw new Exception("Not yet implemented"); }
static int portNameSize() { throw new Exception("Not yet implemented"); }
static int portTypeSize() { throw new Exception("Not yet implemented"); }
static Time getTime() { throw new Exception("Not yet implemented"); }

