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
#define DEBOUNCE 20
#define REPEAT   500

int selected = 0;
long selectbutton_pressed_at;
int selectbutton_is_pressed = 0;
int run = 0;
long now;
int valid_times[] = {0,1,2,4,8,16,32,64,128,7,14,28,56,112,224};
int valid_index   = 14;

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
  Serial.begin(9600);
}

void loop(){
  now = millis();
  if(digitalRead(SELECT) == HIGH){
    selectbutton_pressed_at = now;
  }
  if (digitalRead(START) == HIGH){
    run = 1;
  }
  if (0 != selectbutton_pressed_at){
    if (now - selectbutton_pressed_at > DEBOUNCE){
      selectbutton_is_pressed = 1;
    }
  }
  if (selectbutton_is_pressed){  
    selectbutton_is_pressed = 0;
    selectbutton_pressed_at = 0;
    if (selected < valid_index){
      selected++;
    }else{
      selected = 0;
    }
    Serial.println(valid_times[selected], BIN);
  }
  if(1 == run){
    run = 0;
    Serial.println("Program start");
  }
}
