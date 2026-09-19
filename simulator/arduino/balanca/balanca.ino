#define ENQ  0x05
#define ACK  0x06
#define NAK  0x25
#define STX  0x02
#define ETX  0x03
#define CR  0x0D
#define SWA  "A"
#define SWB  "B"
#define SWC  "C"
#define NNN  "+"
#define DeltaT 60 /*Tempo de mudança de valor da balanca*/

float peso;
float pulo = 0.4; //400 gramas
float pesototal;
float tara;
unsigned long meutempo;
unsigned long diferencadetempo;
String buffer;
char strPeso[6];
char strTara[6];

int pushButtonA = 13;
int pushButtonB = 7;
int pushButtonC = 8;

int flgContinuo;
int flgMod;
void Wellcome(){
  Serial.println('Emulador de protocolo');
  Serial.println('Emulador de Balança Toledo!');

}

void Start_Button(){
  pinMode(pushButtonA, INPUT);
  pinMode(pushButtonB, INPUT);
  pinMode(pushButtonC, OUTPUT);
}

void setup() {
  Start_Button();
  // initialize serial:
  Serial.begin(2400);
  //Wellcome();
  tara = 0;
  pesototal = 0;
  //peso = random(1000)/100;
  peso = 0;
  flgContinuo = 1;
  flgMod = 0;
  //Mudou de nivel:
  meutempo = millis();

}

char Checksum(String info){
  char dado;
  int a;
  dado = info[0]; 
  for (a=1;a < info.length();a++){
    dado = dado ^ info[a];
  }
  return dado;
}

void EnviaPeso(){     
    dtostrf((pesototal+peso-tara),7,3,strPeso);
    //scanf(strPeso,"%6d",(pesototal+peso-tara));
    scanf(strTara,"%6d",tara);
    buffer = String(char(STX)) + String(NNN) + String(strPeso) + String(char(ETX));
    //buffer = buffer + Checksum(buffer);
    buffer.replace(" ","0");
    Serial.println(buffer);
}

void LeBotaoB(){
   int buttonStateB = digitalRead(pushButtonB);
   if (buttonStateB == HIGH){     
     peso =peso - pulo;
     if (peso <0){
      peso = 0;
     }
   }
}

void LeBotaoA(){
   int buttonStateA = digitalRead(pushButtonA);
   if (buttonStateA == HIGH){
     peso = peso + pulo;
   } 
}

void loop() {
  while (Serial.available() > 0) {
    char c = Serial.read();
    if (c==ENQ){
      EnviaPeso();  
    }
    if (c=='T'){
      tara = peso+pesototal;  
    }
    if (c=='P'){
      pesototal = 0;  
    }    
    if (c=='Z'){
      tara = 0;  
    }
    if (c=='C'){
      flgContinuo = ~flgContinuo;  
      if (flgContinuo!=0){
      }
    }
    if (c=='N'){
       pesototal = pesototal + peso;
       peso = random(1000)/100;
    }    
    if (c=='M'){
       flgMod = ~flgMod;  
    }
  }

  if (flgContinuo!=0) {
    EnviaPeso();
  }

  if (flgMod!=0) {
    diferencadetempo = (millis() - meutempo)/1000;
    if (diferencadetempo > DeltaT) {
        meutempo = millis();
        pesototal = pesototal + peso;
        peso = random(1000)/100;        
    }
  }  
  LeBotaoA();
  LeBotaoB();
  delay(1000);
}
