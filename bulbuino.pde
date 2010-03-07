/* 

Bulbuino++ - Serial photo and bulb exposure robot

Mode 1: Serial photo robot

Possible intervals (seconds):

a =   1s
b =   2s
c =   4s
d =   8s
e =   15s
f =   30s
g =   60s (1m)
h =  120s (2m)

Mode 2: Classic bulbuino mode -- Bulb exposure robot

Possible exposure programs (seconds):
a = 60    (1m)
b = 120   (2m)
c = 240   (4m)
d = 480   (8m)
e = 900  (15m)
f = 1800 (30m)
g = 3600 (60m)
h = 7200 (120m)

Each single time, or any reasonable combination of 3 can be selected.

Hence, we have 19 programs including the "zero" program:

Program     hgfedcba
0           00000000
1           00000001
2           00000010
3           00000100
4           00001000
5           00010000
6           00100000
7           01000000
8           10000000
9           00000111
10          00001110
11          00011100
12          00111000
13          01110000
14          11100000
15          00010101
16          00101010
17          01010100
18          10101000

Fritzing data is enclosed in the repository.

*/

#include <avr/sleep.h>

#define BATTERY     0
#define SELECT     10
#define START      11  
#define SHUTTER    12
#define SHUTLED    13
#define DEBOUNCE   50
#define SHOTWAIT 2000
#define CAM_LAG   500

// Debug + development goodies:
//
// This is used to make time pass faster in testing. ;-)
long millis_in_a_second = 1000;
// Only print to serial if required.
int debug = 0;
// Enable or disable shutter LED on pin 13.
int debug_shutter = 0;

// Set VCC to voltage of the used arduino board.
float vcc = 3.3;

// Button states and debouncing
// Inverted input logic, so we can use internal pull-up
long last_statechange_select;
long last_statechange_start;
long last_statechange_battery;

int state_select = HIGH;
int state_start = HIGH;
int state_battery = 0;

int oldstate_select = HIGH;
int oldstate_start = HIGH;
int oldstate_battery = 0;

// Mode:
// 1) Serial photo robot
// 2) Bulb exposure robot
// 
// Switch mode by pressing SELECT+START simultaneously
int mode = 1;
// Timestamp when mode was switched
long mode_switched = 0;

// Block SELECT button when:
// 1) It is held depressed
// 2) Exposure is running
int lock_select = 0;

// Block BATTERY TEST button when it is held depressed
int lock_battery = 0;

// Time stamp for displaying battery status
// Initialized to zero so battery status is not displayed on startup
long batterydisplay_until = 0;

// State of battery display
// 0 Display not requested
// 1 Display has been started
// 2 Display has ended
int batterydisplay = 0;

// Stores battery voltage for battery test button action
float absvolt = 0;

// The SELECT button modifies only this value,
// which is then resolved to the actual exposure program by other means.
int program_selected = 0;

// Exposure programs for Mode 2, bulb exposure robot. Time in seconds.
int program[19][3]  = 
{
  {   0,    0,    0},
  {  60,    0,    0},
  { 120,    0,    0},
  { 240,    0,    0},
  { 480,    0,    0},
  { 900,    0,    0},
  {1800,    0,    0},
  {3600,    0,    0},
  {7200,    0,    0},
  {  60,  120,  240},
  { 120,  240,  480},
  { 240,  480,  900},
  { 480,  900, 1800},
  { 900, 1800, 3600},
  {1800, 3600, 7200},
  {  60,  240,  900},
  { 120,  480, 1800},
  { 240,  900, 3600},
  { 480, 1800, 7200}
};

// How to display selected program on LED row (Mode 2, bulb exposure robot):
int program_ledstate[19][8] =
{
  {0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 1},
  {0, 0, 0, 0, 0, 0, 1, 0},
  {0, 0, 0, 0, 0, 1, 0, 0},
  {0, 0, 0, 0, 1, 0, 0, 0},
  {0, 0, 0, 1, 0, 0, 0, 0},
  {0, 0, 1, 0, 0, 0, 0, 0},
  {0, 1, 0, 0, 0, 0, 0, 0},
  {1, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 1, 1, 1},
  {0, 0, 0, 0, 1, 1, 1, 0},
  {0, 0, 0, 1, 1, 1, 0, 0},
  {0, 0, 1, 1, 1, 0, 0, 0},
  {0, 1, 1, 1, 0, 0, 0, 0},
  {1, 1, 1, 0, 0, 0, 0, 0},
  {0, 0, 0, 1, 0, 1, 0, 1},
  {0, 0, 1, 0, 1, 0, 1, 0},
  {0, 1, 0, 1, 0, 1, 0, 0},
  {1, 0, 1, 0, 1, 0, 0, 0}
};

// The number of known programs in mode 2. Sorry, I know too little
// C to properly find the number of elements in the array. ;-)
int program_index   = 18;

// Pins to which the LEDs are connected:
int led[8] =  {2, 3, 4, 5, 6, 7, 8, 9};

// Holds current state per LED for display according to
// what is stored in program_selected. 
int ledstate[8];
// Store LEDstate here while battery display is in progress
int saved_ledstate[8];

// Timer interval for mode 1
long interval_selected = 0;
// Exposure timer for mode 1
long next_exposure_at;
// Track when to let go of the shutter again after pressing it
// Just to avoid delay() calls.
int shutter_is_down;
long shutter_release_at;
// Interval timings (in milliseconds)
int interval[9] = {0, 1000, 2000, 4000, 8000, 15000, 30000, 60000, 120000};

// running is set while exposure is running
long running = 0;

// Blink state foo (for during exposure)
long blink_interval_on = 5;
long blink_interval_off = 495;
long blink_timestamp;
int blinkstate = HIGH;

// Tracks whether shutter is closed or open
int shutter_open = 0;
// When the running exposure should end
long end_exposure;
// Which step of the program is currently running?
int program_step = 0;
// Used to keep the shutter closed for a while after each exposure.
long shutter_available_at = 0;

// Idle counter for powerdown
long idle_since = millis();
// Idle timeout: 5 minutes
long sleep_after = 300 * millis_in_a_second;

void setup(){
  // Activate inputs
  pinMode(SELECT,  INPUT);
  pinMode(START,   INPUT);
  // Activate internal pull-up for inputs
  digitalWrite(SELECT, HIGH);
  digitalWrite(START,  HIGH);
  // Output mode for shutter and on-board LED
  pinMode(SHUTTER, OUTPUT);
  pinMode(SHUTLED, OUTPUT);
  // Set Output mode for LEDs
  for (int thisled = 0; thisled <= 7; thisled++){
    pinMode(led[thisled], OUTPUT);
  }
  if (debug){
    Serial.begin(9600);
    Serial.print(millis());
    Serial.println(" Bulbuino is up.");
  }

}

void loop(){
  //
  // Loop entry phase.
  //
  // This is the phase when buttons are read and 
  // the program decides which mode it is in.

  // Stores millis per loop iteration
  long now = millis();
  
  // Temporary holding space for button readouts
  int reading;

  // Track state of SELECT button & debounce
  reading = digitalRead(SELECT);
  if(reading != oldstate_select){
    last_statechange_select = now;
  }
  if (now - last_statechange_select > DEBOUNCE){
      state_select = reading;
  }
  oldstate_select = reading;

  // Track state of START button & debounce
  reading = digitalRead(START);
  if(reading != oldstate_start){
    last_statechange_start = now;
  }
  if (now - last_statechange_start > DEBOUNCE){
      state_start = reading;
  }
  oldstate_start = reading;

  // Track state of BATTERY TEST button & debounce
  if (0 == analogRead(BATTERY)){
    reading = 0;
  }else{
    reading = 1;
  }
  if(reading != oldstate_battery){
    last_statechange_battery = now;
  }
  if (now - last_statechange_battery > DEBOUNCE){
      state_battery = reading;
  }
  oldstate_battery = reading;

  // Switch mode of operation if SELECT+START are pressed simultaneously
  if ((state_select == LOW) and (state_start == LOW) and (now - mode_switched > 1000)){
    // "Debounce" mode switching
    mode_switched = now;
    // Cancel all running operations and reset all variables
    if (debug){
      Serial.print(now);
      Serial.println(" Mode switch detected, canceling all operations.");
    }
    running = 0;
    idle_since = now;
    lock_select = 0;
    interval_selected = 0;
    program_step = 0;
    program_selected = 0;
    end_exposure = now;
    shutter_available_at = now;
    shutter_open = 0;
    shutter_is_down = 0;
    shutter_release_at = 0;
    if (debug){
      Serial.print(now);
    }
    digitalWrite(SHUTLED, LOW);
    digitalWrite(SHUTTER, LOW);
    if (1 == mode){
      mode = 2;
      if (debug){
	Serial.println(" Mode is now: 2 (bulb exposure robot)");
      }
    }else{
      mode = 1;
      if (debug){
	Serial.println(" Mode is now: 1 (serial photo robot)");
      }
    }
  }
  // Set "running" if start button was pressed and exposure is not already running
  // and we haven't just switched modes
  if((0 == running) and (state_start == LOW) and (now - mode_switched > 1000)){
    if (debug){
      Serial.print(now);
      Serial.println(" Running.");
    }
    running = now;
    lock_select = 1;
  }
  // 
  // End of loop entry phase.
  //

  // Go to deep sleep if the unit has been idle for too long.
  if ((0 == running) and (now - idle_since > sleep_after)){
    if (debug){
      Serial.print(now);
      Serial.println(" Idle timeout. Going to sleep now. Good night!");
    }
    // Turn off all LEDs
    for (int thisled = 0; thisled <= 7; thisled++){
      digitalWrite(led[thisled], LOW);
    }
    set_sleep_mode(SLEEP_MODE_PWR_DOWN);
    sleep_enable();
    sleep_mode();
    // Adios. Will need to rewrite this if I ever free up a pin for a 
    // wake-up interrupt.
  }

  // See if we are supposed to show the battery readout
  if (state_battery and (0 == lock_battery) and (0 == batterydisplay)){
    lock_battery = 1;
    float value = analogRead(BATTERY);
    // The voltage divider has split the voltage in thirds, to make
    // it palpaple for 3.3V arduino's analog pin.
    absvolt = (vcc / 1024.0) * value * 3.0;
    if (debug){
      Serial.print(now);
      Serial.print(" ");
      Serial.print(absvolt);
      Serial.println(" Volt");
      Serial.print(now);
      Serial.println(" Battery display state 0 => 1");
    }
    batterydisplay_until = now + 2000;
    batterydisplay = 1;
  }
  // Release lock_battery if the BATTERY TEST button has been released
  if(lock_battery and (0 == state_battery)){
    lock_battery = 0;
  }
  
  // Take care of the LEDs
  //
  // Is blinking requested (exposure running)
  // Then set blinkstate accordingly.
  // Otherwise, blinkstate is HIGH (LED is on)
  //
  if (running){
    if ((blinkstate == HIGH) and (now > blink_timestamp)){
      blinkstate = LOW;
      blink_timestamp = now + blink_interval_off;
    }else if (now > blink_timestamp){
      blinkstate = HIGH; 
      blink_timestamp = now + blink_interval_on;
    }
  }else{
    blinkstate = HIGH;
  }
  if (1 == batterydisplay){
    int batt_ledstate[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    // Set LED states according to voltage
    if (absvolt > 9.0){
      batt_ledstate[7] = 1;
    }
    if (absvolt > 8.8){
      batt_ledstate[6] = 1;
    }
    if (absvolt > 8.5){
      batt_ledstate[5] = 1;
    }
    if (absvolt > 8.2){
      batt_ledstate[4] = 1;
    }
    if (absvolt > 7.8){
      batt_ledstate[3] = 1;
    }
    if (absvolt > 7.5){
      batt_ledstate[2] = 1;
    }
    if (absvolt > 7.3){
      batt_ledstate[1] = 1;
    } 
    // Lowest LED always visible
    batt_ledstate[0] = 1;
    // Save ledstate for the time when battery display is over
    for (int thisled = 0; thisled <= 7; thisled++){    
      saved_ledstate[thisled] = ledstate[thisled];
      ledstate[thisled]       = batt_ledstate[thisled];
    }    
    batterydisplay = 2; // Now wait till end of display time
    if (debug){
      Serial.print(now);
      Serial.println(" Battery display state 1 => 2");
    }
  }
  // If battery display is requested, override blinking
  if (2 == batterydisplay){
    blinkstate = HIGH;
  }
  // Restore old LED state when blinking time is over
  if ((now > batterydisplay_until) and (2 == batterydisplay)){
    for (int thisled = 0; thisled <= 7; thisled++){    
      ledstate[thisled]       = saved_ledstate[thisled];
    }    
    if (debug){
      Serial.print(now);
      Serial.println(" Battery display state 2 => 0");
    }
    batterydisplay = 0;
  }
  // Set LEDs to requested state, salted with blinkstate.
  for (int thisled = 0; thisled <= 7; thisled++){
    if (ledstate[thisled]){
      digitalWrite(led[thisled], blinkstate);
    }else{
      digitalWrite(led[thisled], LOW);
    }
  }
  // LEDs should be fine now.
            
  if (1 == mode){  
    // serial photo robot
    // Select next interval only once, even if SELECT button is kept pressed.
    if (state_select == HIGH){
      lock_select = 0;
    } 
    if ((state_select == LOW) and (0 == lock_select) and (0 == running)){  
      // Pat idle timer
      idle_since = now;
      if (interval_selected < 8){
        interval_selected++;
      }else{
        interval_selected = 0;
      }
      lock_select = 1;
  
      if (debug){
        char program_summary[40];
        Serial.print(now);
        Serial.print(" Selected Interval: ");
        Serial.println(interval_selected);
      }
      // Turn on the respective LED for chosen interval
      for (int thisled = 0; thisled <= 7; thisled++){
        ledstate[thisled] = 0;
      }
      ledstate[interval_selected-1] = 1;
    }  
    // do nothing if interval is 0
    if (0 == interval_selected){
      running = 0;
      idle_since = now;
    }
    if (running){
      // Let go of the shutter if required.
      if (shutter_is_down and (now > shutter_release_at)){
        digitalWrite(SHUTTER, LOW);
        digitalWrite(SHUTLED, LOW);
        shutter_is_down = 0;
        if (debug){
          Serial.print(now);
          Serial.println(" Shutter released.");
        }
      }
      // Shoot.
      if (now > next_exposure_at){
        next_exposure_at   = now + interval[interval_selected];
        shutter_is_down    = now;
        shutter_release_at = now + CAM_LAG;
        digitalWrite(SHUTTER, HIGH);
        if (debug_shutter){
           digitalWrite(SHUTLED, HIGH);
        }
        if (debug){
          Serial.print(now);
          Serial.print(" Shutter pressed. Next shot at: ");
          Serial.println(next_exposure_at);
        }
      }
    }  
  }else if (2 == mode){
    // bulb exposure robot
    // Select next program only once, even if SELECT button is kept pressed.
    if (state_select == HIGH){
      lock_select = 0;
    } 
    if ((state_select == LOW) and (0 == lock_select) and (0 == running)){  
      // Pat idle timer
      idle_since = now;
      if (program_selected < program_index){
        program_selected++;
      }else{
        program_selected = 0;
      }
      lock_select = 1;
  
      if (debug){
        char program_summary[40];
        sprintf(program_summary, "%i -> %i %i %i", 
          program_selected, 
          program[program_selected][0],
          program[program_selected][1],
          program[program_selected][2]
        );
        Serial.print(now);
        Serial.print(" Selected Program: ");
        Serial.println(program_summary);
      }
      // Prepare LED states according to selected program
      ledstate[0] = program_ledstate[program_selected][0];
      ledstate[1] = program_ledstate[program_selected][1];
      ledstate[2] = program_ledstate[program_selected][2];
      ledstate[3] = program_ledstate[program_selected][3];
      ledstate[4] = program_ledstate[program_selected][4];
      ledstate[5] = program_ledstate[program_selected][5];
      ledstate[6] = program_ledstate[program_selected][6];
      ledstate[7] = program_ledstate[program_selected][7];
    }
 
    // We will take three exposures
    // 1) program[program_selected][0]
    // 2) program[program_selected][1]
    // 3) program[program_selected][2]
    //
    // program_step holds 0, 1, 2 - The step that we are currently working on.
    // 
    // Unset the running flag if program step has gone over 2 after last shutter close
    if (running){
      if ((0 == shutter_open) and (now > shutter_available_at)){
        if (program[program_selected][program_step] > 0){
          if (debug_shutter){
            digitalWrite(SHUTLED, HIGH);
          }
          digitalWrite(SHUTTER, HIGH);
          // Calculate when the shutter shall close again
          long duration = program[program_selected][program_step] * millis_in_a_second;
          // CAMLAG is a rough (but sufficient) estimate for shutter lag.
          // (This does nothing for exposure, but gives nice round EXIF data.)
          end_exposure = now + duration + CAM_LAG;
          if (debug){
            Serial.print(now);
            Serial.print(" Start Exposure for milliseconds: ");
            Serial.println(duration);
          }
          shutter_open = 1;
        }else{
          program_step++;
          if (debug){
            Serial.print(now);
            Serial.println(" Skipping zero Exposure, not actually opening shutter.");
            Serial.print(now);
            Serial.print(" Program Step++ (Skipping) -> ");
            Serial.println(program_step);
          }
        }
      }
    }
    if (1 == shutter_open){
      // See whether we are ready to close the shutter again
      if (program[program_selected][program_step] > 0){
        if (now > end_exposure){
          digitalWrite(SHUTLED, LOW);
          digitalWrite(SHUTTER, LOW);
          shutter_available_at = now + SHOTWAIT;
          shutter_open = 0;
          program_step++;
          if (debug){
            Serial.print(now);
            Serial.println(" End Exposure.");
            Serial.print(now);
            Serial.print(" Shutter will be available again at: ");
            Serial.println(shutter_available_at);
            Serial.print(now);
            Serial.print(" Program Step++ -> ");
            Serial.println(program_step);
          }
        }
      }
    }
    // See whether end of program was reached and go back to selection phase.
    if (program_step > 2){
      if (debug){
        Serial.print(now);
        Serial.println(" Done! (Program Step > 2) -> Reset Program Step to 0.");
      }
      running = 0;
      idle_since = 0;
      lock_select = 0;
      program_step = 0;
    }
  }
}
