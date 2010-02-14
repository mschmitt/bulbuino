/* 

Bulbuino - Bulb Exposure Bracketer

Possible exposure combinations (seconds):
a = 60    (1m)
b = 120   (2m)
c = 240   (4m)
d = 480   (8m)
e = 900  (15m)
f = 1800 (30m)
g = 3600 (60m)
h = 7200 (120m)

Each single time, or any reasonable combination of 3 can be selected.

Hence, we have 15 programs including the "zero" program:

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

For schematics, see Fritzing data enclosed in the repository.

*/

#define SHUTTER   2
#define SELECT    3
#define START     4  
#define SHUTLED  13
#define DEBOUNCE 50
#define REPEAT   500
#define CAM_LAG  200

// This is used to make time pass faster in testing. ;-)
long millis_in_a_second = 1000;

// Stores millis per loop iteration
long now;

// Button states and debouncing
long last_statechange_select;
long last_statechange_start;

int state_select = LOW;
int state_start = LOW;

int oldstate_select = LOW;
int oldstate_start = LOW;

// Block SELECT button when:
// 1) It is held depressed
// 2) Exposure is running
int lock_select = 0;

// The SELECT button modifies only this value,
// which is then resolved to the actual exposure program by other means.
int program_selected = 0;

// Exposure programs. Time in seconds.
int program[15][3]  = 
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
  {1800, 3600, 7200}
};

// How to display selected program on LED row:
int program_ledstate[15][8] =
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
  {1, 1, 1, 0, 0, 0, 0, 0}
};

// The number of known programs. Sorry, I know too little
// C to properly find the number of elements in the array. ;-)
int program_index   = 14;

// Pins to which the LEDs are connected:
int led[8] =  {5, 6, 7, 8, 9, 10, 11, 12};

// Holds current state per LED for display according to
// what is stored in program_selected. 
int ledstate[8];

// running is set while exposure is running
long running = 0;

// Blink state foo (for during exposure)
long blink_interval = 200;
long blink_timestamp;
int blinkstate = HIGH;

// Tracks whether shutter is closed or open
int shutter_open = 0;
// Stores calculated duration
long duration;
// When the running exposure should end
long end_exposure;
// Which step of the program is currently running?
int program_step = 0;
// Program_summary - For serial debug output during program selection
char program_summary[40];
// Used to keep the shutter closed for a while after each exposure.
long shutter_available_at = 0;

void setup(){
  Serial.begin(9600);
  Serial.print(millis());
  Serial.println(" Bulbuino is up.");
  pinMode(SELECT,  INPUT);
  pinMode(START,   INPUT);
  pinMode(SHUTTER, OUTPUT);
  pinMode(SHUTLED, OUTPUT);
  // Set Output mode for LEDs
  Serial.print(millis());
  Serial.println(" Now setting LED modes.");
  for (int thisled = 0; thisled <= 7; thisled++){
    Serial.print(millis());
    Serial.print(" LED set to OUTPUT: ");
    Serial.println(thisled);
    pinMode(led[thisled], OUTPUT);
  }
}

void loop(){
  now = millis();
  
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

  // Select next mode only once, even if SELECT button is kept pressed.
  if (state_select == LOW){
    lock_select = 0;
  } 
  if ((state_select == HIGH) and (0 == lock_select) and (0 == running)){  
    if (program_selected < program_index){
      program_selected++;
    }else{
      program_selected = 0;
    }
    lock_select = 1;
    sprintf(program_summary, "%i -> %i %i %i", 
      program_selected, 
      program[program_selected][0],
      program[program_selected][1],
      program[program_selected][2]
      );
    Serial.print(now);
    Serial.print(" Selected Program: ");
    Serial.println(program_summary);
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
  
  // Is blinking requested (exposure running)
  // Then set blinkstate accordingly.
  // Otherwise, blinkstate is HIGH (LED is on)
  if (running){
    if ((blinkstate == HIGH) and (now > blink_timestamp)){
      blinkstate = LOW;
      blink_timestamp = now + blink_interval;
    }else if (now > blink_timestamp){
      blinkstate = HIGH; 
      blink_timestamp = now + blink_interval;
    }
  }else{
    blinkstate = HIGH;
  }
 
  // Set LEDs to requested state.
  for (int thisled = 0; thisled <= 7; thisled++){
    if (ledstate[thisled]){
      digitalWrite(led[thisled], blinkstate);
    }else{
      digitalWrite(led[thisled], LOW);
    }
  }
            
  // Set "running" if start button was pressed and exposure is not already running.
  if((0 == running) and (state_start == HIGH)){
    Serial.print(now);
    Serial.println(" Running.");
    running = now;
    lock_select = 1;
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
        digitalWrite(SHUTLED, HIGH);
        digitalWrite(SHUTTER, HIGH);
        // Calculate when the shutter shall close again
        duration = program[program_selected][program_step] * millis_in_a_second;
        // CAMLAG is a rough (but sufficient) estimate for shutter lag.
        // (This does nothing for exposure, but gives nice round EXIF data.)
        end_exposure = now + duration + CAM_LAG;
        Serial.print(now);
        Serial.print(" Start Exposure for milliseconds: ");
        Serial.println(duration);
        shutter_open = 1;
      }else{
        Serial.print(now);
        Serial.println(" Skipping zero Exposure, not actually opening shutter.");
        program_step++;
        Serial.print(now);
        Serial.print(" Program Step++ (Skipping) -> ");
        Serial.println(program_step);
      }
    }
  }
  if (1 == shutter_open){
    // See whether we are ready to close the shutter again
    if (program[program_selected][program_step] > 0){
      if (now > end_exposure){
        digitalWrite(SHUTLED, LOW);
        digitalWrite(SHUTTER, LOW);
        Serial.print(now);
        Serial.println(" End Exposure.");
        shutter_available_at = now + 2000;
        Serial.print(now);
        Serial.print(" Shutter will be available again at: ");
        Serial.println(shutter_available_at);
        shutter_open = 0;
        program_step++;
        Serial.print(now);
        Serial.print(" Program Step++ -> ");
        Serial.println(program_step);
      }
    }
  }
  // See whether end of program was reached and go back to selection phase.
  if (program_step > 2){
    Serial.print(now);
    Serial.println(" Done! (Program Step > 2) -> Reset Program Step to 0.");
    running = 0;
    lock_select = 0;
    program_step = 0;
  }
}
