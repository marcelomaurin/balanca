#define ENQ  0x05
#define ACK  0x06
#define NAK  0x25
#define STX  0x02
#define ETX  0x03
#define CR   0x0D

#define DELTA_T_SECONDS 60UL
#define BUTTON_DEBOUNCE_MS 40UL
#define LOOP_DELAY_MS 20UL
#define FAILURE_DELAY_MS 1500UL

const uint8_t PIN_BUTTON_UP = 13;
const uint8_t PIN_BUTTON_DOWN = 7;
const uint8_t PIN_BUTTON_AUX = 8;

const float WEIGHT_STEP = 0.4f;
const float UNSTABLE_RANGE = 0.050f;

enum FailureMode {
  FM_NORMAL = 0,
  FM_MISSING_ETX = 1,
  FM_NOISE = 2,
  FM_TRUNCATED = 3,
  FM_DELAYED = 4,
  FM_UNSTABLE = 5,
  FM_SILENT = 6
};

float peso = 0.0f;
float pesototal = 0.0f;
float tara = 0.0f;

unsigned long lastAutoChangeMs = 0;

bool flgContinuo = true;
bool flgMod = false;

bool waitingFailureMode = false;
FailureMode failureMode = FM_NORMAL;

bool delayedResponsePending = false;
unsigned long delayedResponseAtMs = 0;

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
  failureMode = FM_NORMAL;
  waitingFailureMode = false;
  delayedResponsePending = false;

  randomSeed(analogRead(A0));
  lastAutoChangeMs = millis();
}

float CurrentWeight() {
  float currentWeight = pesototal + peso - tara;

  if (failureMode == FM_UNSTABLE) {
    long jitter = random(-50, 51);
    currentWeight += ((float)jitter / 1000.0f);
  }

  return currentWeight;
}

size_t BuildWeightFrame(char *frame, size_t frameSize, bool includeEtx) {
  char weightText[16];
  float currentWeight = CurrentWeight();

  dtostrf(currentWeight, 7, 3, weightText);

  for (uint8_t i = 0; weightText[i] != '\0'; i++) {
    if (weightText[i] == ' ') {
      weightText[i] = '0';
    }
  }

  size_t pos = 0;

  if (frameSize < 4) {
    return 0;
  }

  frame[pos++] = (char)STX;
  frame[pos++] = '+';

  for (uint8_t i = 0; weightText[i] != '\0' && pos < frameSize - 2; i++) {
    frame[pos++] = weightText[i];
  }

  if (includeEtx && pos < frameSize - 1) {
    frame[pos++] = (char)ETX;
  }

  frame[pos] = '\0';
  return pos;
}

void SendNoise() {
  const uint8_t noise[] = {0x55, 0x7F, 0x00, 0x31, 0x0D, 0x0A};
  Serial.write(noise, sizeof(noise));
}

void SendWeightNow() {
  char frame[20];
  size_t frameLength;

  switch (failureMode) {
    case FM_SILENT:
      return;

    case FM_MISSING_ETX:
      frameLength = BuildWeightFrame(frame, sizeof(frame), false);
      Serial.write((const uint8_t *)frame, frameLength);
      return;

    case FM_NOISE:
      SendNoise();
      frameLength = BuildWeightFrame(frame, sizeof(frame), true);
      Serial.write((const uint8_t *)frame, frameLength);
      SendNoise();
      return;

    case FM_TRUNCATED:
      frameLength = BuildWeightFrame(frame, sizeof(frame), true);
      if (frameLength > 3) {
        Serial.write((const uint8_t *)frame, frameLength / 2);
      }
      return;

    case FM_UNSTABLE:
    case FM_NORMAL:
    default:
      frameLength = BuildWeightFrame(frame, sizeof(frame), true);
      Serial.write((const uint8_t *)frame, frameLength);
      return;
  }
}

void RequestWeightResponse() {
  if (failureMode == FM_DELAYED) {
    if (!delayedResponsePending) {
      delayedResponsePending = true;
      delayedResponseAtMs = millis() + FAILURE_DELAY_MS;
    }
    return;
  }

  SendWeightNow();
}

void ProcessDelayedResponse() {
  if (!delayedResponsePending) {
    return;
  }

  if ((long)(millis() - delayedResponseAtMs) >= 0) {
    delayedResponsePending = false;

    // Envia uma resposta normal depois do atraso, sem reagendar.
    FailureMode previousMode = failureMode;
    failureMode = FM_NORMAL;
    SendWeightNow();
    failureMode = previousMode;
  }
}

bool TrySetFailureMode(char modeCode) {
  if (modeCode < '0' || modeCode > '6') {
    return false;
  }

  failureMode = (FailureMode)(modeCode - '0');
  delayedResponsePending = false;
  return true;
}

void HandleCommand(char c) {
  if (waitingFailureMode) {
    TrySetFailureMode(c);
    waitingFailureMode = false;
    return;
  }

  switch (c) {
    case ENQ:
      RequestWeightResponse();
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

    case 'F':
      // O proximo byte seleciona o modo de falha: F0..F6.
      waitingFailureMode = true;
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
  ProcessDelayedResponse();

  if (flgContinuo && !delayedResponsePending) {
    RequestWeightResponse();
  }

  delay(LOOP_DELAY_MS);
}
