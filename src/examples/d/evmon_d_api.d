/*
Copyright (c) 2014 Marco Cosentino
Licence GPLv3
*/

import jack;

import std.stdio;
import core.stdc.signal;
import core.stdc.stdlib;
import core.thread;

enum int SIGHUP = 1;
enum int SIGQUIT = 3;

JackClient client;

static void signal_handler(int sig)
{
  if (client !is null) {
    client.close();  
  }
  stderr.writeln ("signal received, exiting ...");
  exit(0);
}

extern(C) static void
port_callback (JackPortID port, int yn, void* arg)
{
  stdout.writeln ("Port ", port, (yn ? " registered" : " unregistered"));
}

extern(C) static void
connect_callback (JackPortID a, JackPortID b, int yn, void* arg)
{
  stdout.writeln ("Ports ", a, " and ", b, (yn ? " connected" : " disconnected"));
}

extern(C) static void
client_callback (const char* client, int yn, void* arg)
{
  stdout.writeln ("Client ", client, (yn ? " registered" : " unregistered"));
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
    Thread.sleep (1);
  }

  return (0);
}

