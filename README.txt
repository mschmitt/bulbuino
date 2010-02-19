Bulbuino++ - Serial photo and bulb exposure robot
-------------------------------------------------

Bulbuino++ operates in two modes.

Mode 1 - Serial photo robot
---------------------------

This mode is active after power-on. By pressing the SELECT button, the 
serial photo interval is selected. 

LED1 =  7.5s
LED2 =   15s
LED3 =   30s
LED4 =   60s (1m)
LED5 =  120s (2m)
LED6 =  240s (4m)
LED7 =  480s (8m)
LED8 =  900s (15m)

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

Camera control ends after the last exposure, after which the controller is 
sent to deep sleep mode. (FIXME: Actually implement deep sleep.)

History
-------

This started out as a test for user interaction, buttons, optocoupler and 
stuff. LED state/Program selection still is a mess, but it works. :-)

Schematics
----------

The Fritzing data enclosed in the repository used to be accurate
on the Arduino prototype board.

The pinout used now matches my Arduino Pro Mini integration, with nicer
pin routing on the circuit board.

An update with different cabling may follow at a later date.

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
