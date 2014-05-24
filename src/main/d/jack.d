module jack;

import jack_c;
import std.conv;
import std.string;

alias jack_c.JackOptions JackOptions;
alias jack_c.JackStatus JackStatus;
alias jack_c.JackPortFlags JackPortFlags;
alias jack_c.JackOpenOptions JackOpenOptions;
alias jack_c.JackLoadOptions JackLoadOptions;

alias jack_latency_range_t JackLatencyRange;
alias jack_port_type_id_t JackPortID;

alias jack_default_audio_sample_t DefaultAudioSample;

alias jack_c.JACK_DEFAULT_AUDIO_TYPE JACK_DEFAULT_AUDIO_TYPE;


interface JackNamesArray
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

interface JackPort
{
    void* getBuffer(JackNFrames nframes);
    bool isConnectedTo(string other_port_name);
    JackNamesArray getConnections();
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
        JackPortID typeID();
        bool connected();
        string[] aliases();
        bool isMonitoringInput();

        JackLatencyRange latencyRange();
        void latencyRange(JackLatencyRange lr);
    }
}

alias jack_nframes_t JackNFrames;
alias jack_time_t JackTime;

alias int function(JackNFrames nframes, void* data) JackProcessCallback;
alias ref Object function(Object data) JackThreadCallback;
alias void function(Object data) JackThreadInitCallback;
alias int function(Object data) JackGraphOrderCallback;
alias int function(Object data) JackXRunCallback;
alias int function(JackNFrames nframes, Object data) JackBufferSizeCallback;
alias int function(JackNFrames nframes, Object data) JackSampleRateCallback;
alias void function(jack_port_id_t port, int register, Object data) JackPortRegistrationCallback;
alias void function(string name, int register, Object data) JackClientRegistrationCallback;
alias void function(JackPort a, JackPort b, int connect, Object data) JackPortConnectCallback;
alias int function(JackPort port, string old_name, string new_name, Object data) JackPortRenameCallback;
alias void function(int starting, Object data) JackFreewheelCallback;
alias void function(void* data) JackShutdownCallback;
alias void function(JackStatus code, string reason, Object data) JackInfoShutdownCallback;
alias void function(JackLatencyCallbackMode mode, Object data) JackLatencyCallback;

interface JackClient
{
    void close();
    void activate();
    void deactivate();
    void engineTakeoverTimebase();

    JackPort portRegister(string port_name, string port_type, JackPortFlags flags, uint buffer_size);
    void portUnregister(JackPort port);
    bool portIsMine(JackPort port);
    JackNamesArray portGetAllConnections(JackPort port);
    void portRequestMonitorByName(string name, bool onoff);
    void portDisconnect(JackPort port);
    size_t portTypeGetBufferSize(string type);
    JackNamesArray getPorts(string pattern, string pattern_type, JackPortFlags flags);
    JackPort getByName(string port_name);
    JackPort getByID(JackPortID id);

    void connect(string source_port, string dest_port);
    void disconnect(string source_port, string dest_port);

    void recomputeTotalLatencies();
    
    // Callbacks
    void setProcessCallback(JackProcessCallback callback, void* data);
    void setShutdownCallback(JackShutdownCallback callback, void* data);
    void setFreewheelCallback(JackFreewheelCallback callback, Object data);
    void setBufferSizeCallback(JackBufferSizeCallback callback, Object data);
    void setSampleRateCallback(JackSampleRateCallback callback, Object data);
    void setClientRegistrationCallback(JackClientRegistrationCallback callback, Object data);
    void setPortRegistrationCallback(JackPortRegistrationCallback callback, Object data);
    void setPortConnectCallback(JackPortConnectCallback callback, Object data);
    void setPortRenameCallback(JackPortRenameCallback callback, Object data);
    void setGraphOrderCallback(JackGraphOrderCallback callback, Object data);
    void setXRunRenameCallback(JackXRunCallback callback, Object data);
    void setLatencyRenameCallback(JackLatencyCallback callback, Object data);

    JackTime framesToTime(JackNFrames frames);
    JackNFrames timeToFrames(JackTime time);

    @property
    {
        string name();
        int nameSize(); 
        int pid();
        JackThread thread();
        bool isRealtime();
        float cpuLoad();
        JackNFrames samplerate();
        JackNFrames buffersize();
        JackNFrames framesSinceCycleStart();
        JackNFrames frameTime();
        JackNFrames lastFrameTime();
    }
}

struct JackVersion
{
    int major;
    int minor;
    int micro;
    int proto;
}

interface JackThread {}


class JackException : Exception {
  JackStatus status = JackStatus.JackFailure;

  this(string message) {
    super(message);
  }

  this(string message, JackStatus status) {
    super(message);
    this.status = status;
  }
}

class JackNamesArrayImplementation : JackNamesArray {
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

class JackPortImplementation : JackPort {
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
  JackPortID typeID() { throw new Exception("Not yet implemented"); }
  bool connected() { throw new Exception("Not yet implemented"); }
  string[] aliases() { throw new Exception("Not yet implemented"); }
  bool isMonitoringInput() { throw new Exception("Not yet implemented"); }

  JackLatencyRange latencyRange() { throw new Exception("Not yet implemented"); }
  void latencyRange(JackLatencyRange lr) { throw new Exception("Not yet implemented"); }

  void* getBuffer(JackNFrames nframes) {
    return jack_port_get_buffer(port, nframes);
  }
  bool isConnectedTo(string other_port_name) { throw new Exception("Not yet implemented"); }
  JackNamesArray getConnections() { throw new Exception("Not yet implemented"); }
  void aliasSet(string al) { throw new Exception("Not yet implemented"); }
  void aliasUnset(string al) { throw new Exception("Not yet implemented"); }

  void request_monitor(bool onoff) { throw new Exception("Not yet implemented"); }
  void ensure_monitor(bool onoff) { throw new Exception("Not yet implemented"); }
}



class JackClientImplementation : JackClient {
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

  JackPort portRegister(string portName, string portType, JackPortFlags flags, uint bufferSize) {
    jack_port_t* port = jack_port_register (client, toStringz(portName), 
        toStringz(portType), flags, bufferSize);

    if( port == null ) {
      throw new JackException("Cannot register the port");
    }

    return new JackPortImplementation(port);
  }

  void portUnregister(JackPort port) { throw new Exception("Not yet implemented"); }
  bool portIsMine(JackPort port) { throw new Exception("Not yet implemented"); }
  JackNamesArray portGetAllConnections(JackPort port) { throw new Exception("Not yet implemented"); }
  void portRequestMonitorByName(string name, bool onoff) { throw new Exception("Not yet implemented"); }
  void portDisconnect(JackPort port) { throw new Exception("Not yet implemented"); }
  size_t portTypeGetBufferSize(string type) { throw new Exception("Not yet implemented"); }

  JackNamesArray getPorts(string pattern, string patternType, JackPortFlags flags) {
    immutable(char) ** rawPorts = jack_get_ports (client, toStringz(pattern), 
        toStringz(patternType), flags);
    if(rawPorts == null) {
      throw new JackException("Cannot get the ports");
    }
    return new JackNamesArrayImplementation(rawPorts);
  }

  JackPort getByName(string port_name) { throw new Exception("Not yet implemented"); }
  JackPort getByID(JackPortID id) { throw new Exception("Not yet implemented"); }


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

  void setProcessCallback(JackProcessCallback callback, void* data) {
    jack_set_process_callback (client, callback, data);
  }

  void setShutdownCallback(JackShutdownCallback callback, void* data) {
    jack_on_shutdown (client, callback, data);
  }

  void setFreewheelCallback(JackFreewheelCallback callback, Object data) { throw new Exception("Not yet implemented"); }
  void setBufferSizeCallback(JackBufferSizeCallback callback, Object data) { throw new Exception("Not yet implemented"); }
  void setSampleRateCallback(JackSampleRateCallback callback, Object data) { throw new Exception("Not yet implemented"); }
  void setClientRegistrationCallback(JackClientRegistrationCallback callback, Object data) { throw new Exception("Not yet implemented"); }
  void setPortRegistrationCallback(JackPortRegistrationCallback callback, Object data) { throw new Exception("Not yet implemented"); }
  void setPortConnectCallback(JackPortConnectCallback callback, Object data) { throw new Exception("Not yet implemented"); }
  void setPortRenameCallback(JackPortRenameCallback callback, Object data) { throw new Exception("Not yet implemented"); }
  void setGraphOrderCallback(JackGraphOrderCallback callback, Object data) { throw new Exception("Not yet implemented"); }
  void setXRunRenameCallback(JackXRunCallback callback, Object data) { throw new Exception("Not yet implemented"); }
  void setLatencyRenameCallback(JackLatencyCallback callback, Object data) { throw new Exception("Not yet implemented"); }

  JackTime framesToTime(JackNFrames frames) { throw new Exception("Not yet implemented"); }
  JackNFrames timeToFrames(JackTime time) { throw new Exception("Not yet implemented"); }


  string name() {
    return to!string( jack_get_client_name(client) );
  }

  int nameSize() { throw new Exception("Not yet implemented"); } 
  int pid() { throw new Exception("Not yet implemented"); }
  JackThread thread() { throw new Exception("Not yet implemented"); }
  bool isRealtime() { throw new Exception("Not yet implemented"); }
  float cpuLoad() { throw new Exception("Not yet implemented"); }
  JackNFrames samplerate() { throw new Exception("Not yet implemented"); }
  JackNFrames buffersize() { throw new Exception("Not yet implemented"); }
  JackNFrames framesSinceCycleStart() { throw new Exception("Not yet implemented"); }
  JackNFrames frameTime() { throw new Exception("Not yet implemented"); }
  JackNFrames lastFrameTime() { throw new Exception("Not yet implemented"); }
}


// ######### Global functions

static JackClient clientOpen(string clientName, JackOptions options, out JackStatus status, string serverName) {
  jack_client_t* client;

  if( status & JackOptions.JackServerName) {
    client = jack_client_open (toStringz(clientName), options, &status, toStringz(serverName));
  } else {
    client = jack_client_open (toStringz(clientName), options, &status);
  }

  if(client == null) {
    throw new JackException("Cannot open client", status);
  }

  return new JackClientImplementation(client);
}
static JackVersion getVersion() { throw new Exception("Not yet implemented"); }
static string getVersionString() { throw new Exception("Not yet implemented"); }
static int getClientPID(string name) { throw new Exception("Not yet implemented"); }
static int portNameSize() { throw new Exception("Not yet implemented"); }
static int portTypeSize() { throw new Exception("Not yet implemented"); }
static JackTime getTime() { throw new Exception("Not yet implemented"); }

