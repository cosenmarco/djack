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

import jack;
import deimos.sndfile;

import std.stdio;
import std.getopt;
import std.conv;
import std.string;
import core.thread;
import core.sync.condition;
import core.stdc.stdlib;
import core.stdc.signal;
import core.stdc.string;

enum int SIGHUP = 1;
enum int SIGQUIT = 3;

const size_t DEFAULT_RB_SIZE = 16384;
const size_t SAMPLE_SIZE = DefaultAudioSample.sizeof;
const size_t DISK_THREAD_BUFFER_IN_FRAMES = 256;

struct ThreadInfo {
    SNDFILE *sf;
    NFrames duration;
    NFrames rb_size = DEFAULT_RB_SIZE;
    int channels;
    int bitdepth = 16;
    string path;
    bool can_capture;
    bool can_process;
}

alias DefaultAudioSample* samplesPtr;

Client jackClient;
__gshared Port[] ports;
__gshared RingBuffer ringBuffer;
__gshared Condition dataAvailable;
__gshared ThreadInfo threadInfo;
__gshared samplesPtr portBuffers[];
__gshared int overruns = 0;


class DiskThread : Thread {

  this() {
    SF_INFO sf_info;
    int short_mask;

    sf_info.samplerate = jackClient.samplerate;
    sf_info.channels = threadInfo.channels;

    switch (threadInfo.bitdepth) {
      case 8: short_mask = SF_FORMAT_PCM_U8;
              break;
      case 16: short_mask = SF_FORMAT_PCM_16;
               break;
      case 24: short_mask = SF_FORMAT_PCM_24;
               break;
      case 32: short_mask = SF_FORMAT_PCM_32;
               break;
      default: short_mask = SF_FORMAT_PCM_16;
               break;
    }

    sf_info.format = SF_FORMAT_WAV | short_mask;
    threadInfo.sf = sf_open (toStringz(threadInfo.path), SFM_WRITE, &sf_info);

    if(threadInfo.sf == null) {
      const(char) *errstr = sf_strerror(null);
      stderr.writeln("Cannot open file ", threadInfo.path, " for output: ", to!string(errstr));
      jackClient.close();
      exit(1);
    }

    threadInfo.duration *= sf_info.samplerate;
    debug stdout.writeln("Duration in samples is ", threadInfo.duration);

    super(&run);
    start();
  }

  public void joinMe() {
    join(true);
    sf_close (threadInfo.sf);
  }

  // The disk thread itself
  private void run() {
    NFrames totalCaptured = 0;
    size_t bytes_per_frame = threadInfo.channels * SAMPLE_SIZE;
    size_t frameBufferSize = DISK_THREAD_BUFFER_IN_FRAMES * bytes_per_frame;
    void *frameBuffer;
    size_t bytesReaded, framesReaded;

    frameBuffer = malloc(frameBufferSize);
    scope(exit) free(frameBuffer);
    memset(frameBuffer, 0, frameBufferSize);

    debug stdout.writeln("FrameBuffer size is ", frameBufferSize, " (", bytes_per_frame, " bytes per frame)");

    synchronized(dataAvailable.mutex) {
      while(true) {

        /* Write the data one frame at a time.  This is
         * inefficient, but makes things simpler. */
        while(threadInfo.can_capture && ringBuffer.getReadSpace() >= bytes_per_frame) {

          bytesReaded = ringBuffer.peek(frameBuffer, frameBufferSize);
          framesReaded = bytesReaded / bytes_per_frame;
          ringBuffer.readAdvance(framesReaded * bytes_per_frame);

          if (sf_writef_float (threadInfo.sf, cast(float *) frameBuffer, framesReaded) != framesReaded) {
            printError();
            return;
          }

          totalCaptured += framesReaded;
          
          debug {
            if ((totalCaptured * bytes_per_frame) % 8192 == 0) {
              stdout.writeln("Captured:", totalCaptured, " Overruns:", overruns, " readSpace:", ringBuffer.getReadSpace());
            }
          }

          if(totalCaptured + overruns >= threadInfo.duration) {
            threadInfo.can_capture = false;
            stdout.writeln("disk thread finished");
            return;
          }

        }

        dataAvailable.wait();
      }
    }
  }

  void printError() {
    const(char) * errStrPtr = sf_strerror(threadInfo.sf);
    stderr.writeln("cannot write sndfile: ", to!string(errStrPtr));
  }
}

extern(C) int processCallback(NFrames nframes, void* data) {
  int chn;
  size_t sample;

  if(!threadInfo.can_process || !threadInfo.can_capture) {
    // Do nothing for this cycle
    return 0;
  }

  for (chn = 0; chn < threadInfo.channels; chn++) {
    portBuffers[chn] = cast(samplesPtr) ports[chn].getBuffer(nframes);
  }

  // debug stdout.writeln("writeSpace: ", ringBuffer.getWriteSpace(), " readSpace: ", ringBuffer.getReadSpace(), " gonnaWrite:", nframes * chn * SAMPLE_SIZE);

  /* Sndfile requires interleaved data.  It is simpler here to
   * just queue interleaved samples to a single ringbuffer. */
  for (sample = 0; sample < nframes; sample++) {
    for (chn = 0; chn < threadInfo.channels; chn++) {
      if(ringBuffer.write(portBuffers[chn] + sample, SAMPLE_SIZE) < SAMPLE_SIZE) {
        overruns++;
      }
    }
  }

  /* Tell the disk thread there is work to do.  If it is already
   * running, the lock will not be available.  We can't wait
   * here in the process() thread, but we don't need to signal
   * in that case, because the disk thread will read all the
   * data queued before waiting again. */
  if (dataAvailable.mutex.tryLock()) {
    dataAvailable.notify();
    dataAvailable.mutex.unlock();
  }

  return 0;
}

void setupPorts(string[] sources) {
  auto nports = threadInfo.channels;
  ports = new Port[nports];
  uint i;

  ringBuffer = createRingBuffer(nports * threadInfo.rb_size * SAMPLE_SIZE);
  memset(ringBuffer.buf, 0, ringBuffer.size);

  portBuffers = new samplesPtr[nports];

  for( i=0; i<nports; i++ ) {
    string portName = "input" ~ to!string(i);
    ports[i] = jackClient.portRegister(portName, JACK_DEFAULT_AUDIO_TYPE, PortFlags.IsInput, 0);
    debug stdout.writeln("Registered port ", ports[i].name);
  }

  for( i=0; i<nports; i++ ) {
    jackClient.connect(sources[i], ports[i].name);
    debug stdout.writeln("Connected port ", sources[i], " to port ", ports[i].name);
  }

  threadInfo.can_process = true;
}

extern(C) static void jackShutdown(void *data) {
  stderr.writeln("JACK shut down, exiting ...");
  exit(1);
}


extern(C) static void signal_handler(int sig) nothrow @system
{
  try {
    if (jackClient !is null) {
      jackClient.close();
    }
    stderr.writeln("signal received, exiting ...");
    exit(0);
  } catch {
    exit(1);
  }
}

void showHelp() {
    stderr.writeln("usage: capture_d_api -f filename [ -d second ] [ -b bitdepth ] [ -s bufsize ] [--] port1 [ port2 ... ]");
}

int main (string[] args)
{
  bool help = false;
  const string clientName = "capture_d_api";

  getopt(args,
      "help|h", &help,
      "duration|d", &threadInfo.duration,
      "file|f", &threadInfo.path,
      "bitdepth|b", &threadInfo.bitdepth,
      "bufsize|s", &threadInfo.rb_size);

  debug stdout.writeln("Params -- help:", help, " duration:", threadInfo.duration,
      " file:", threadInfo.path, " bitdepth:", threadInfo.bitdepth, " bufsize:", threadInfo.rb_size,
      " remaining args ", args);

  // Removing arg[0]
  args = args[1..$];

  if(help || threadInfo.path is null || threadInfo.path.length == 0 || args.length == 0) {
    showHelp();
    exit(1);
  }

  Status status;

  jackClient = clientOpen(clientName, Options.NullOption, status, "");
  threadInfo.channels = cast(int) args.length;

  dataAvailable = new Condition(new Mutex); 
  auto diskThread = new DiskThread();

  jackClient.setProcessCallback(&processCallback, null);
  jackClient.setShutdownCallback(&jackShutdown, null);

  jackClient.activate();

  /* Install signal handlers to properly quits jack client */
  signal(SIGQUIT, &signal_handler);
  signal(SIGTERM, &signal_handler);
  signal(SIGHUP, &signal_handler);
  signal(SIGINT, &signal_handler);

  // Start the process
  debug stdout.writeln("Starting capture");

  setupPorts(args);
  threadInfo.can_capture = true;

  diskThread.joinMe();

  if(overruns > 0) {
    stderr.writeln("Capture failed with ", overruns, " overruns. Try a bigger buffer than -B ", threadInfo.rb_size);
  }

  jackClient.close();
  ringBuffer.free();

  return 0;
}
