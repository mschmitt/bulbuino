// Bulbuino - Remote Controller for Bulb Exposure

// Possible exposure combinations (seconds):
// a = 60    (1m)
// b = 120   (2m)
// c = 240   (4m)
// d = 480   (8m)
// e = 900  (15m)
// f = 1800 (30m)
// g = 3600 (60m)
// h = 7200 (120m)
//
// Each single time, or any reasonable combination of 3 can be selected.
//
// Internally represented as:
// hgfedcba  DEC
// 00000000    0
// 00000001    1
// 00000010    2
// 00000100    4
// 00001000    8
// 00010000   16
// 00100000   32
// 01000000   64
// 10000000  128
// 00000111    7
// 00001110   14 
// 00011100   28
// 00111000   56
// 01110000  112
// 11100000  224


#define SELECT    2
#define START     3  
#define SHUTTER   4
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

int selected = 0;
int work_selected = 0;

int valid_times[] = {0,1,2,4,8,16,32,64,128,7,14,28,56,112,224};
int valid_index   = 14;

// runnable is set if exposure can be started
int runnable = 0;

// running is set while exposure is running
int running = 0;

void setup(){
  pinMode(SELECT,  INPUT);
  pinMode(START,   INPUT);
  pinMode(SHUTTER, OUTPUT);
  pinMode(LED0,    OUTPUT);
  pinMode(LED1,    OUTPUT);
  pinMode(LED2,    OUTPUT);
  pinMode(LED3,    OUTPUT);
  pinMode(LED4,    OUTPUT);
  pinMode(LED5,    OUTPUT);
  pinMode(LED6,    OUTPUT);
  pinMode(LED7,    OUTPUT);
  pinMode(13, OUTPUT); //////
  Serial.begin(9600);
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
    if (selected < valid_index){
      selected++;
    }else{
      selected = 0;
    }
    lock_select = 1;
    Serial.println(valid_times[selected], BIN);
  }
  if((0 == running) and (state_start == HIGH)){
    running = now;
    work_selected = selected;
  }
  if (running){
    while(0 != work_selected){
      if (work_selected & 1){
        Serial.println("Open shutter for 1m");
        work_selected = work_selected | 1;
      }
      
          
      running = 0;
    }
  }
}
