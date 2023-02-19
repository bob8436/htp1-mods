Welcome to the community-produced firmware for the Monoprice HTP-1!
https://www.avsforum.com/threads/the-official-monoprice-monolith-htp-1-owners-thread.3112176

*** IMPORTANT ***
Use a high performance "A1" "U3" SD-card with this firmware

Do not use this firmware unless your HTP-1 has been upgraded
to version 1.9.1 at some point.
*** IMPORTANT ***

Running this firmware requires a high-performance SD-card. A slow
SD-card could result in a slow system that unexpectedly reboots
because it thinks it has hung. Please only use with an SD-card rated
as "A1" and "U3". Here is a fine SD-card:
https://www.amazon.com/SanDisk-Extreme-microSDHC-Memory-Adapter/dp/B06XYHN68L

This distribution will not self-updgrade in any way - including
updating the firmware for internal components. To ensure things work,
you must have upgraded your HTP-1 to v1.9.1 at some point in the past.
This will ensure internal components have the appropriate verison.
You don't need to be on v1.9.1 right now as long as you have used
it on your HTP-1 at some point.


JSoosiah's lovely UI is available at http://your-htp1-ip-address/custom


If you put a config.json file that you've exported from the HTP-1's
settings page in the root of this drive, it will automatically be
imported on the first start.

*** EXPERTS ONLY ***
If you put an authorized_keys file in the root of this drive, you
will be able to SSH into your HTP-1 as root using your private key.
WARNING: Through SSH you could modify things outside of the SD-card
and potentially cause damage to your HTP-1.
*** EXPERTS ONLY ***
