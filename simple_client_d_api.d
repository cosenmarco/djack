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


const int TABLE_SIZE = 200;
struct paTestData
{
    float sine[TABLE_SIZE];
    int left_phase;
    int right_phase;
string pippo="TEST";
};


int main (string[] args)
{
  string client_name;
  string server_name = "";

  __gshared paTestData data;

  if (args.length >= 2) {		
    // Client name specified
    client_name = args[1];
    if (args.length >= 3) {	
      // Server name specified
      server_name = args[2];
      options = JackOptions.JackNullOption | JackOptions.JackServerName;
    }
  } else {			
    // Use basename of argv[0]
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


}
