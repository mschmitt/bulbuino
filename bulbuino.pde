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
long now;

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
  if (0 != selectbutton_pressed_at){
    if (now - selectbutton_pressed_at > DEBOUNCE){
      selectbutton_is_pressed = 1;
    }
  }
  if (selectbutton_is_pressed){  
    selectbutton_is_pressed = 0;
    selectbutton_pressed_at = 0;
    if (255 == selected){
      selected = 0;
    }else{
      selected++;
    }
    Serial.println(selected);
  }
}
