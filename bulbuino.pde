/* 

Bulbuino - Camera Remote Controller for Bulb Exposure

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

*/


#define SELECT    2
#define START     3  
#define SHUTTER   4
#define SHUTLED  13
#define LED0      5
#define LED1      6
#define LED2      7
#define LED3      8
#define LED4      9
#define LED5     10
#define LED6     11
#define LED7     12
#define DEBOUNCE 50
#define REPEAT   500
#define CAM_LAG  200

long now;

// Button states and debouncing
long last_statechange_select;
long last_statechange_start;

int state_select = LOW;
int state_start = LOW;

int oldstate_select = LOW;
int oldstate_start = LOW;

int lock_select = 0;

int reading;

int program_selected = 0;

// Preset programs. Time in seconds.
int program[14][3]  = 
{
  {   0,    0,    0},
  {  60,    0,    0},
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

int program_index   = 13;

// running is set while exposure is running
long running = 0;

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
// Used to make time pass faster. ;-)
long millis_in_a_second = 100;

void setup(){
  pinMode(SELECT,  INPUT);
  pinMode(START,   INPUT);
  pinMode(SHUTTER, OUTPUT);
  pinMode(SHUTLED, OUTPUT);
  pinMode(LED0,    OUTPUT);
  pinMode(LED1,    OUTPUT);
  pinMode(LED2,    OUTPUT);
  pinMode(LED3,    OUTPUT);
  pinMode(LED4,    OUTPUT);
  pinMode(LED5,    OUTPUT);
  pinMode(LED6,    OUTPUT);
  pinMode(LED7,    OUTPUT);
  Serial.begin(9600);
  Serial.print(millis());
  Serial.println(" Bulbuino is up.");
}

void loop(){
  now = millis();
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
