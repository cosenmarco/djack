/*
   Copyright (c) 2014 Marco Cosentino

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import jack.core;

import std.stdio;
import std.math;
import std.string;
import std.conv;
import core.stdc.signal;
import core.stdc.stdlib;
import core.thread;

enum int SIGHUP = 1;
enum int SIGQUIT = 3;


const int TABLE_SIZE = 200;
struct paTestData
{
  Port outputPort1, outputPort2;
  float sine[TABLE_SIZE];
  int left_phase;
  int right_phase;
};

  
Client client;
__gshared paTestData data;

/**
* The process callback for this JACK application is called in a
* special realtime thread once for each audio cycle.
*/

extern(C) int jProcess (NFrames nframes, void* arg)
{
  Port outputPort1 = data.outputPort1;
  Port outputPort2 = data.outputPort2;

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
extern(C) void jShutdown (void * data)
{
    exit (1);
}

int main (string[] args)
{

  Port outputPort1, outputPort2;
  Options options;
  Status status;

  string clientName = "test";
  string serverName = "";


  if (args.length >= 2) {		
    // Client name specified
    clientName = args[1];
    if (args.length >= 3) { /* server name specified? */
      serverName = args[2];
      options = Options.NullOption | Options.ServerName;
    }
  }

  for( int i=0; i<TABLE_SIZE; i++ ) {
    data.sine[i] = 0.2 * cast(float) sin( (cast(double)i/cast(double)TABLE_SIZE) * PI * 2.0 );
  }
  data.left_phase = data.right_phase = 0;

  client = clientOpen(clientName, options, status, serverName);

  if (status & Status.ServerStarted) {
    stderr.writeln("JACK server started");
  }

  if (status & Status.NameNotUnique) {
    clientName = client.name();
    stderr.writeln ("unique name `", clientName, "' assigned");
  }


  client.setProcessCallback(&jProcess, null);
  client.setShutdownCallback(&jShutdown, null);


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

  NamesArray ports = client.getPorts(null, null, PortFlags.IsPhysical | PortFlags.IsInput);

  client.connect(outputPort1.name(), ports.stringAt(0));
  client.connect(outputPort1.name(), ports.stringAt(1));

  /* Install signal handlers to properly quits jack client */
  signal(SIGQUIT, &signal_handler);
  signal(SIGTERM, &signal_handler);
  signal(SIGHUP, &signal_handler);
  signal(SIGINT, &signal_handler);

  /* keep running until the Ctrl+C */
  while (1) {
    Thread.sleep (seconds(10));
  }
  return 0;
}

extern(C) static void signal_handler(int sig) nothrow @system
{
  try {
    if (client !is null) {
      client.close();
    }
    stderr.writeln("signal received, exiting ...");
    exit(0);
  } catch {
    exit(1);
  }
}
