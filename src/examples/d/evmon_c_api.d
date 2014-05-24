/*
   Copyright (c) 2014 Marco Cosentino
   Licence GPLv3
*/


import jack_c;

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

jack_client_t *client;

static void signal_handler(int sig)
{
    if (client != null)
        jack_client_close(client);
	stderr.writeln ("signal received, exiting ...");
	exit(0);
}

extern(C) static void
port_callback (jack_port_id_t port, int yn, void* arg)
{
	stdout.writeln ("Port ", port, (yn ? " registered" : " unregistered"));
}

extern(C) static void
connect_callback (jack_port_id_t a, jack_port_id_t b, int yn, void* arg)
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
	jack_options_t options = jack_options_t.JackNullOption;
	jack_status_t status;

	client = jack_client_open ("event-monitor", options, &status);
	if (client == null) {
		stderr.writeln ("jack_client_open() failed, status = ", status);
		if (status & jack_status_t.JackServerFailed) {
			stderr.writeln ("Unable to connect to JACK server");
		}
		return 1;
	}
	
	if (jack_set_port_registration_callback (client, &port_callback, null)) {
		stderr.writeln ("cannot set port registration callback");
		return 1;
	}
	if (jack_set_port_connect_callback (client, &connect_callback, null)) {
		stderr.writeln ("cannot set port connect callback");
		return 1;
	}
	if (jack_set_client_registration_callback (client, &client_callback, null)) {
		stderr.writeln ("cannot set client registration callback");
		return 1;
	}
	if (jack_set_graph_order_callback (client, &graph_callback, null)) {
		stderr.writeln ("cannot set graph order registration callback");
		return 1;
	}
	if (jack_activate (client)) {
		stderr.writeln ("cannot activate client");
		return 1;
	}
    
    signal(SIGQUIT, &signal_handler);
    signal(SIGTERM, &signal_handler);
    signal(SIGHUP, &signal_handler);
    signal(SIGINT, &signal_handler);

    while (1) {
        Thread.sleep (1);
    }

	exit (0);
}

