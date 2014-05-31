/*
Copyright (c) 2014 Marco Cosentino
Licence GPLv3
*/

import jack;

import std.stdio;
import std.conv;
import core.stdc.signal;
import core.stdc.stdlib;
import core.thread;

enum int SIGHUP = 1;
enum int SIGQUIT = 3;

Client client;

extern(C) static nothrow @system void signal_handler(int sig)
{
  try {
    if (client !is null) {
      client.close();  
    }
    stderr.writeln ("signal received, exiting ...");
    exit(0);
  } catch {
    exit(1);
  }
}

extern(C) static void
port_callback (PortID port, int yn, void* arg)
{
  stdout.writeln ("Port ", port, (yn ? " registered" : " unregistered"));
}

extern(C) static void
connect_callback (PortID a, PortID b, int yn, void* arg)
{
  stdout.writeln ("Ports ", a, " and ", b, (yn ? " connected" : " disconnected"));
}

extern(C) static void
client_callback (immutable(char)* client, int yn, void* arg)
{
  stdout.writeln ("Client ", to!string(client), (yn ? " registered" : " unregistered"));
}

extern(C) static int
graph_callback (void* arg)
{
  stdout.writeln ("Graph reordered");
  return 0;
}

int
main (string[] args)
{
  Options options = Options.NullOption;
  Status status;

  client = clientOpen ("event-monitor", options, status, "");

  client.setPortRegistrationCallback(&port_callback, null);
  client.setPortConnectCallback(&connect_callback, null);
  client.setClientRegistrationCallback(&client_callback, null);
  client.setGraphOrderCallback(&graph_callback, null);

  client.activate();

  signal(SIGQUIT, &signal_handler);
  signal(SIGTERM, &signal_handler);
  signal(SIGHUP, &signal_handler);
  signal(SIGINT, &signal_handler);

  while (1) {
    Thread.sleep (seconds(1));
  }
  return 0;
}

