# JACK.D
This is an attempt to develop a D API to the low latency JACK Audio toolkit.

# Examples
In order to compile the examples I do the following (on my Debian unstable):

dmd src/examples/d/transport_c_api.d src/main/d/jack_c.di -L-ljack
dmd src/examples/d/transport_d_api.d src/main/d/jack.d src/main/d/jack_c.di -L-ljack

This implies that you have correctly setup the dmd compiler and installed libjack-dev

# Licence
This repository is released under the terms of GPLv3 license.
