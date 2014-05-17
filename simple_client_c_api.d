import jack;
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

__gshared jack_port_t* output_port1, output_port2;
__gshared jack_client_t* client;


const int TABLE_SIZE = 200;
struct paTestData
{
    float sine[TABLE_SIZE];
    int left_phase;
    int right_phase;
string pippo="TEST";
};

static void signal_handler(int sig)
{
        if (client != null)
        jack_client_close(client);
        stderr.write("signal received, exiting ...\n");
        exit(0);
}

/**
* The process callback for this JACK application is called in a
* special realtime thread once for each audio cycle.
*
* This client follows a simple rule: when the JACK transport is
* running, copy the input port to the output.  When it stops, exit.
*/

extern(C) int
process (jack_nframes_t nframes, void *arg)
{
    jack_default_audio_sample_t* out1, out2;
    paTestData* data = cast(paTestData*) arg;
    int i;

    out1 = cast(jack_default_audio_sample_t*) jack_port_get_buffer (output_port1, nframes);
    out2 = cast(jack_default_audio_sample_t*) jack_port_get_buffer (output_port2, nframes);

    for( i=0; i<nframes; i++ )
    {
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
void jack_shutdown (void *arg)
{
    exit (1);
}

int
main (string[] args)
{
    immutable(char)** ports;
    string client_name;
    string server_name = "";
    jack_options_t options = jack_options_t.JackNullOption;
    jack_status_t status;
    __gshared paTestData data;
    int i;

    if (args.length >= 2) {		/* client name specified? */
        client_name = args[1];
        if (args.length >= 3) {	/* server name specified? */
            server_name = args[2];
            options = jack_options_t.JackNullOption | jack_options_t.JackServerName;
        }
    } else {			/* use basename of argv[0] */
        client_name= args[0];
        auto pos = lastIndexOf(client_name,"/");
        if(pos >= 0) 
            client_name = client_name[(pos+1)..$];
    }

    for( i=0; i<TABLE_SIZE; i++ )
    {
        data.sine[i] = 0.2 * cast(float) sin( (cast(double)i/cast(double)TABLE_SIZE) * PI * 2.0 );
    }
    data.left_phase = data.right_phase = 0;


    /* open a client connection to the JACK server */

    client = jack_client_open (std.string.toStringz(client_name), options, &status, std.string.toStringz(server_name));
    if (client == null) {
        stderr.write("jack_client_open() failed, status = 0x%2.0x\n", status);
        if (status & JackStatus.JackServerFailed) {
            stderr.write("Unable to connect to JACK server\n");
        }
        exit (1);
    }
    if (status & JackStatus.JackServerStarted) {
        stderr.write("JACK server started\n");
    }
    if (status & JackStatus.JackNameNotUnique) {
            client_name = std.conv.to!string( jack_get_client_name(client) );
            stderr.write("unique name `%s' assigned\n", client_name);
    }

    /* tell the JACK server to call `process()' whenever
        there is work to be done.
    */
    
    paTestData * data_ptr = &data;
    jack_set_process_callback (client, &process, data_ptr);

    /* tell the JACK server to call `jack_shutdown()' if
        it ever shuts down, either entirely, or if it
        just decides to stop calling us.
    */

    jack_on_shutdown (client, &jack_shutdown, null);

    /* create two ports */

    output_port1 = jack_port_register (client, "output1",
                                        std.string.toStringz(JACK_DEFAULT_AUDIO_TYPE),
                                        JackPortFlags.JackPortIsOutput, 0);

    output_port2 = jack_port_register (client, "output2",
                                        std.string.toStringz(JACK_DEFAULT_AUDIO_TYPE),
                                        JackPortFlags.JackPortIsOutput, 0);

    if ((output_port1 == null) || (output_port2 == null)) {
            stderr.write("no more JACK ports available\n");
            exit (1);
    }

    /* Tell the JACK server that we are ready to roll.  Our
        * process() callback will start running now. */

    if (jack_activate (client)) {
            stderr.write("cannot activate client");
            exit (1);
    }

    /* Connect the ports.  You can't do this before the client is
        * activated, because we can't make connections to clients
        * that aren't running.  Note the confusing (but necessary)
        * orientation of the driver backend ports: playback ports are
        * "input" to the backend, and capture ports are "output" from
        * it.
        */
    
    ports =  jack_get_ports (client, null, null,
                            JackPortFlags.JackPortIsPhysical|JackPortFlags.JackPortIsInput);
    if (ports == null) {
            stderr.write("no physical playback ports\n");
            exit (1);
    }

    //stderr.write(std.conv.to!string(ports[0]));

    if (jack_connect (client, jack_port_name (output_port1), ports[0] )) {
            stderr.write("cannot connect output ports\n");
    }

    if (jack_connect (client, jack_port_name (output_port2), ports[1] )) {
            stderr.write("cannot connect output ports\n");
    }

    jack_free (ports);

/* install a signal handler to properly quits jack client */
    signal(SIGQUIT, &signal_handler);
    signal(SIGTERM, &signal_handler);
    signal(SIGHUP, &signal_handler);
    signal(SIGINT, &signal_handler);

    /* keep running until the Ctrl+C */

    while (1) {
        Thread.sleep (1);
    }

    jack_client_close (client);

    return 0;
}
