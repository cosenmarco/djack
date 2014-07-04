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

import std.conv;
import std.stdio;
import std.string;
import core.stdc.signal;
import core.stdc.stdlib;

enum int SIGHUP = 1;
enum int SIGQUIT = 3;

Client client;

/* Time and tempo variables.  These are global to the entire,
 * transport timeline.  There is no attempt to keep a true tempo map.
 * The default time signature is: "march time", 4/4, 120bpm
 */
immutable float time_beats_per_bar = 4.0;
immutable float time_beat_type = 4.0;
immutable double time_ticks_per_beat = 1920.0;
__gshared double time_beats_per_minute = 120.0;
__gshared int time_reset = 1;		/* true when time values change */

/* JACK timebase callback.
 *
 * Runs in the process thread.  Realtime, must not wait.
 */
extern(C) static void timebase(TransportState state, NFrames nframes, Position *pos, int new_pos, void *arg)
{
  double min;			/* minutes since frame 0 */
  long abs_tick;			/* ticks since frame 0 */
  long abs_beat;			/* beats since frame 0 */

  if (new_pos || time_reset) {

    pos.valid = PositionBits.PositionBBT;
    pos.beats_per_bar = time_beats_per_bar;
    pos.beat_type = time_beat_type;
    pos.ticks_per_beat = time_ticks_per_beat;
    pos.beats_per_minute = time_beats_per_minute;

    time_reset = 0;		/* time change complete */

    /* Compute BBT info from frame number.  This is relatively
     * simple here, but would become complex if we supported tempo
     * or time signature changes at specific locations in the
     * transport timeline. */

    min = pos.frame / (cast(double) pos.frame_rate * 60.0);
    abs_tick = to!long (min * pos.beats_per_minute * pos.ticks_per_beat);
    abs_beat = to!long (abs_tick / pos.ticks_per_beat);

    pos.bar = to!int (abs_beat / pos.beats_per_bar);
    pos.beat = to!int(abs_beat) - to!int (pos.bar * pos.beats_per_bar) + 1;
    pos.tick = to!int(abs_tick) - to!int (abs_beat * pos.ticks_per_beat);
    pos.bar_start_tick = pos.bar * pos.beats_per_bar * pos.ticks_per_beat;
    pos.bar++;		/* adjust start to bar 1 */

    /* some debug code... */

    stderr.writeln("\nnew position: ", pos.frame, "\tBBT: ", pos.bar,
        "|", pos.beat, "|", pos.tick);


  } else {

    /* Compute BBT info based on previous period. */
    pos.tick += nframes * pos.ticks_per_beat * pos.beats_per_minute / (pos.frame_rate * 60);

    while (pos.tick >= pos.ticks_per_beat) {
      pos.tick -= pos.ticks_per_beat;
      if (++pos.beat > pos.beats_per_bar) {
        pos.beat = 1;
        ++pos.bar;
        pos.bar_start_tick +=	pos.beats_per_bar * pos.ticks_per_beat;
      }
    }
  }
}

extern(C) static void jack_shutdown(void *arg)
{
  stderr.writeln("JACK shut down, exiting ...");
  exit(1);
}

extern(C) static void signal_handler(int sig) nothrow @system
{
  try {
    if(client !is null)
      client.close();
    stderr.writeln("signal received, exiting ...");
    exit(0);
  } catch {
    exit(1);
  }
}

/* Command functions: see commands[] table following. */

static void com_activate()
{
  client.activate();
}

static void com_deactivate()
{
  client.deactivate();
}

static void com_locate(int frame)
{
  client.transportLocate(frame);
}

static void com_master(int cond)
{
  client.setTimebaseCallback(cond, &timebase, null);
}

static void com_play()
{
  client.transportStart();
}

static void com_release()
{
  client.releaseTimebase();
}

static void com_stop()
{
  client.transportStop();
}

/* Change the tempo for the entire timeline, not just from the current
 * location. */
static void com_tempo(float tempo)
{
  time_beats_per_minute = tempo;
  time_reset = 1;
}

/* Set sync timeout in seconds. */
static void com_timeout(float timeout)
{
  client.setSyncTimeout(cast(Time) (timeout*1000000));
}

/* command table must be in alphabetical order */
immutable string helpContents = 
"activate\t\tCall jack_activate()\n"~
"exit\t\tExit transport program\n" ~
"deactivate\t\tCall jack_deactivate()\n" ~
"help\t\tDisplay help text [<command>]\n" ~
"locate\t\tLocate to frame <position>" ~
"master\t\tBecome timebase master [<conditionally>]\n" ~
"play\t\tStart transport rolling\n" ~
"quit\t\tSynonym for `exit'\n" ~
"release\t\tRelease timebase\n" ~
"stop\t\tStop transport\n" ~
"tempo\t\tSet beat tempo <beats_per_min>\n" ~
"timeout\t\tSet sync timeout in <seconds>\n" ~
"?\t\tPrints this help\n";
     
static void com_help()
{
  stdout.writeln(helpContents);
}

static void command_loop()
{
  bool done = false;
  string command;

  /* Read and execute commands until the user quits. */
  while (!done) {
    stdout.writeln("COMMANDS 1:activate  2:deactivate  3:locate  4:master  5:release  6:tempo  7:timeout  p:play  s:stop  q:quit  x:exit  ?:help");
    command = readln().chomp();

    stdout.writeln("Command was ", command);

    switch(to!string(command)) {
      case "?":
        com_help();
        break;
      case "1":
        com_activate();
        break;
      case "2":
        com_deactivate();
        break;
      case "3":
        stdout.write("locate: ");
        com_locate( to!int (readln().chomp()) );
        break;
      case "4":
        stdout.write("conditional: ");
        com_master( to!int (readln().chomp()) );
        break;
      case "5":
        com_release();
        break;
      case "6":
        stdout.write("tempo: ");
        com_tempo( to!float (readln().chomp()) );
        break;
      case "7":
        stdout.write("timeout: ");
        com_timeout( to!float (readln().chomp()) );
        break;
      case "p":
        com_play();
        break;
      case "s":
        com_stop();
        break;
      case "q":
      case "x":
        done = true;
        break;
      default:
    }
  }
}

int 
main(string[] argv)
{
  Status status;

  /* basename $0 */
  string clientName = "trasnport_c_api.d";
  
  /* open a connection to the JACK server */
  client = clientOpen(clientName, Options.NullOption, status, "");

  signal(SIGQUIT, &signal_handler);
  signal(SIGTERM, &signal_handler);
  signal(SIGHUP, &signal_handler);
  signal(SIGINT, &signal_handler);

  client.setShutdownCallback(&jack_shutdown, null);

  client.activate();

  /* execute commands until done */
  command_loop();

  client.close();
  return 0;
}
