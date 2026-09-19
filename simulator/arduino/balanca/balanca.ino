#define ENQ  0x05
#define ACK  0x06
#define NAK  0x25
#define STX  0x02
#define ETX  0x03
#define CR   0x0D

#define DELTA_T_SECONDS 60UL
#define BUTTON_DEBOUNCE_MS 40UL
#define LOOP_DELAY_MS 20UL

const uint8_t PIN_BUTTON_UP = 13;
const uint8_t PIN_BUTTON_DOWN = 7;
const uint8_t PIN_BUTTON_AUX = 8;

const float WEIGHT_STEP = 0.4f;

float peso = 0.0f;
float pesototal = 0.0f;
float tara = 0.0f;

unsigned long lastAutoChangeMs = 0;

bool flgContinuo = true;
bool flgMod = false;

bool lastButtonUpReading = HIGH;
bool stableButtonUpState = HIGH;
unsigned long lastButtonUpChangeMs = 0;

bool lastButtonDownReading = HIGH;
bool stableButtonDownState = HIGH;
unsigned long lastButtonDownChangeMs = 0;

void Welcome() {
  Serial.println("Emulador de protocolo");
  Serial.println("Emulador de Balanca Toledo!");
}

void StartButtons() {
  pinMode(PIN_BUTTON_UP, INPUT_PULLUP);
  pinMode(PIN_BUTTON_DOWN, INPUT_PULLUP);
  pinMode(PIN_BUTTON_AUX, OUTPUT);
}

void setup() {
  StartButtons();
  Serial.begin(2400);

  tara = 0.0f;
  pesototal = 0.0f;
  peso = 0.0f;

  flgContinuo = true;
  flgMod = false;

  lastAutoChangeMs = millis();
}

void SendWeight() {
  char weightText[16];
  char frame[20];
  float currentWeight = pesototal + peso - tara;

  // Mantem largura minima de 7 caracteres e 3 casas decimais.
  // O buffer possui folga suficiente para sinal, valor, ponto e terminador.
  dtostrf(currentWeight, 7, 3, weightText);

  for (uint8_t i = 0; weightText[i] != '\0'; i++) {
    if (weightText[i] == ' ') {
      weightText[i] = '0';
    }
  }

  size_t pos = 0;
  frame[pos++] = (char)STX;
  frame[pos++] = '+';

  for (uint8_t i = 0; weightText[i] != '\0' && pos < sizeof(frame) - 2; i++) {
    frame[pos++] = weightText[i];
  }

  frame[pos++] = (char)ETX;
  frame[pos] = '\0';

  // Nao usa println: o protocolo termina exatamente no ETX.
  Serial.write((const uint8_t *)frame, pos);
}

void HandleCommand(char c) {
  switch (c) {
    case ENQ:
      SendWeight();
      break;

    case 'T':
      tara = peso + pesototal;
      break;

    case 'P':
      pesototal = 0.0f;
      break;

    case 'Z':
      tara = 0.0f;
      break;

    case 'C':
      flgContinuo = !flgContinuo;
      break;

    case 'N':
      pesototal += peso;
      peso = random(1000) / 100.0f;
      break;

    case 'M':
      flgMod = !flgMod;
      break;
  }
}

void ProcessSerial() {
  while (Serial.available() > 0) {
    HandleCommand((char)Serial.read());
  }
}

bool DebouncedPressed(
  uint8_t pin,
  bool &lastReading,
  bool &stableState,
  unsigned long &lastChangeMs
) {
  bool reading = digitalRead(pin);

  if (reading != lastReading) {
    lastChangeMs = millis();
    lastReading = reading;
  }

  if ((millis() - lastChangeMs) >= BUTTON_DEBOUNCE_MS &&
      reading != stableState) {
    stableState = reading;

    // INPUT_PULLUP: pressionado = LOW.
    if (stableState == LOW) {
      return true;
    }
  }

  return false;
}

void ProcessButtons() {
  if (DebouncedPressed(
        PIN_BUTTON_UP,
        lastButtonUpReading,
        stableButtonUpState,
        lastButtonUpChangeMs)) {
    peso += WEIGHT_STEP;
  }

  if (DebouncedPressed(
        PIN_BUTTON_DOWN,
        lastButtonDownReading,
        stableButtonDownState,
        lastButtonDownChangeMs)) {
    peso -= WEIGHT_STEP;
    if (peso < 0.0f) {
      peso = 0.0f;
    }
  }
}

void ProcessAutoMode() {
  if (!flgMod) {
    return;
  }

  unsigned long now = millis();

  if ((now - lastAutoChangeMs) >= (DELTA_T_SECONDS * 1000UL)) {
    lastAutoChangeMs = now;
    pesototal += peso;
    peso = random(1000) / 100.0f;
  }
}

void loop() {
  ProcessSerial();
  ProcessButtons();
  ProcessAutoMode();

  if (flgContinuo) {
    SendWeight();
  }

  delay(LOOP_DELAY_MS);
}
