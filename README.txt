Bulbuino++ - Serial photo and bulb exposure robot
-------------------------------------------------

Bulbuino++ operates in two modes.

Mode 1 - Serial photo robot
---------------------------

This mode is active after power-on. By pressing the SELECT button, the 
serial photo interval is selected. 

LED1 =    1s
LED2 =    2s
LED3 =    4s
LED4 =    8s
LED5 =   15s
LED6 =   30s
LED7 =   60s (1m)
LED8 =  120s (2m)

After pressing the START button, camera control starts and can only be 
aborted by powering off the device or by switching modes.

Switching Modes
---------------

Modes are switched by pressing SELECT and START at once. 

Mode 2 - Bulb exposure robot
----------------------------

In this mode (which was the original mode), Bulbuino++ takes automated bulb 
exposures. The LED display for program selection is reversed in this mode;
after pressing SELECT, the indicating LED "moves" in the other direction.

The available bulb exposure times are:

LED1 = 60    (1m)
LED2 = 120   (2m)
LED3 = 240   (4m)
LED4 = 480   (8m)
LED5 = 900  (15m)
LED6 = 1800 (30m)
LED7 = 3600 (60m)
LED8 = 7200 (120m)

Choose either time, or any 3-step combination, bracketed by one or two steps,
as you cycle through the available programs.

Power requirements
------------------

My own implementation of the device uses an Arduino Pro Mini 3.3V running 
at 8Mhz to minimize Power requirements.

Tests have shown that a Duracell 9V block will keep this unit powered for up 
to 48 hours.

If no exposure program is running (no faint LED blinking), the controller 
is sent to powerdown mode after 5 minutes. Beware that the power LED on the 
Arduino will still be draining the battery at a very slow rate. Power-cycle
to wake up. Or route your RESET button to the outside of the case.

With the 3.3V Arduino Pro Mini, power consumption is:

   Idle:                   5mA
   Program Selection:      15-35mA (depending on number of LEDs displayed)
   Program running:        (No reliable value, due to blinking LED)
   Shutter open:           40mA
   Powerdown mode:         400µA

History
-------

This started out as a test for user interaction, buttons, optocoupler and 
stuff. LED state/Program selection still is somewhat messy, but it works. :-)

Schematics
----------

Fritzing data is enclosed in the repository.

License and Disclaimer
----------------------

Copyright (c) 2010, Martin Schmitt <mas at scsy dot de>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
