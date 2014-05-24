/*
   Copyright (c) 2014 Marco Cosentino
   Licence GPLv3
*/

import std.conv;
import std.stdio;
import std.math;
import std.string;
import core.stdc.signal;
import core.stdc.stdlib;
import core.thread;
import core.memory;

enum int SIGHUP = 1;
enum int SIGQUIT = 3;


const int TABLE_SIZE = 200;
struct paTestData
{
  JackPort outputPort1, outputPort2;
  float sine[TABLE_SIZE];
  int left_phase;
  int right_phase;
};

  
JackClient client;

/**
* The process callback for this JACK application is called in a
* special realtime thread once for each audio cycle.
*/

extern(C) int
process (JackNFrames nframes, void* arg)
{
  paTestData* data = cast(paTestData *) arg;

  JackPort outputPort1 = data.outputPort1;
  JackPort outputPort2 = data.outputPort2;

  DefaultAudioSample* out1, out2;
  int i;

  out1 = cast(DefaultAudioSample *) outputPort1.getBuffer(nframes);
  out2 = cast(DefaultAudioSample *) outputPort2.getBuffer(nframes);


  for( i = 0; i < nframes; i++ ) {
    out1[i] = data.sine[data.left_phase];  // left 
    out2[i] = data.sine[data.right_phase];  // right 
    data.left_phase += 1;
    if( data.left_phase >= TABLE_SIZE ) data.left_phase -= TABLE_SIZE;
    data.right_phase += 3; // higher pitch so we can distinguish left and right.
    if( data.right_phase >= TABLE_SIZE ) data.right_phase -= TABLE_SIZE;
  }

  return 0;      
}

/**
* JACK calls this shutdown_callback if the server ever shuts down or
* decides to disconnect the client.
*/
void shutdown (void * data)
{
    exit (1);
}

int main (string[] args)
{
  __gshared paTestData data;

  JackPort outputPort1, outputPort2;
  Options options;
  Status status;

  string clientName;
  string serverName = "";


  if (args.length >= 2) {		
    // Client name specified
    clientName = args[1];
    if (args.length >= 3) { /* server name specified? */
      serverName = args[2];
      options = Options.NullOption | Options.ServerName;
    }
  } else {			
    // Use basename of argv[0]
    clientName= args[0];
    auto pos = lastIndexOf(clientName,"/");
    if(pos >= 0) 
      clientName = clientName[(pos+1)..$];
  }

  for( int i=0; i<TABLE_SIZE; i++ ) {
    data.sine[i] = 0.2 * cast(float) sin( (cast(double)i/cast(double)TABLE_SIZE) * PI * 2.0 );
  }
  data.left_phase = data.right_phase = 0;


  client = clientOpen(clientName, options, status, serverName);

  if (status & Status.ServerStarted) {
    stderr.write("JACK server started\n");
  }

  if (status & Status.NameNotUnique) {
    clientName = client.name();
    stderr.write("unique name `%s' assigned\n", clientName);
  }


  client.setProcessCallback(&process, &data);
  client.setShutdownCallback(&shutdown, &data);


  outputPort1 = client.portRegister("output1", JACK_DEFAULT_AUDIO_TYPE, PortFlags.IsOutput, 0);
  outputPort2 = client.portRegister("output2", JACK_DEFAULT_AUDIO_TYPE, PortFlags.IsOutput, 0);

  data.outputPort1 = outputPort1;
  data.outputPort2 = outputPort2;
  
  client.activate();


  /* 
   * Connect the ports.  You can't do this before the client is
   * activated, because we can't make connections to clients
   * that aren't running.  Note the confusing (but necessary)
   * orientation of the driver backend ports: playback ports are
   * "input" to the backend, and capture ports are "output" from
   * it.
   */

  JackNamesArray ports = client.getPorts(null, null, PortFlags.IsPhysical | PortFlags.IsInput);

  client.connect(outputPort1.name(), ports.stringAt(0));
  client.connect(outputPort1.name(), ports.stringAt(1));

  /* Install signal handlers to properly quits jack client */
  signal(SIGQUIT, &signal_handler);
  signal(SIGTERM, &signal_handler);
  signal(SIGHUP, &signal_handler);
  signal(SIGINT, &signal_handler);

  /* keep running until the Ctrl+C */
  while (1) {
    Thread.sleep (1);
  }

  client.close();

  return 0;
}

static void signal_handler(int sig)
{
  if (client !is null) {
    client.close();
  }
  stderr.write("signal received, exiting ...\n");
  exit(0);
}
