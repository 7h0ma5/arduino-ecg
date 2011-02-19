#include <MI0283QT2.h>
#include <ADS7846.h>

#define BUFFER       25

#define LIMIT_LOW    60
#define LIMIT_HIGH   180
#define INPUT_LOW    150
#define INPUT_HIGH   600

#define HISTORY_SIZE 20

#define HEART_RATE_LIMIT_LOW  30
#define HEART_RATE_LIMIT_HIGH 200

#define COLOR_BACKGROUND COLOR_BLACK
#define COLOR_ECGLINE    COLOR_GREEN
#define COLOR_HEART_RATE COLOR_RED

#define TONE_FREQUENCY 700

MI0283QT2 lcd;
ADS7846 touch;

word x;  // x-axis counter
byte bc; // buffer counter

// for heart rate detection
byte history[HISTORY_SIZE];
byte hc; // history counter
byte avg;
boolean overPeak;
unsigned long lastTimeOverPeak;
byte lastHeartRate;

// to draw lines between the points
word lastX;
word lastY;

void setup() {
  lcd.init(2);
  lcd.clear(COLOR_BACKGROUND);

  lcd.drawText(0, 225, "       kardiotechnik.fh-aachen.de", 1, RGB(100, 100, 100), COLOR_BACKGROUND);

  lcd.led(100);

  x = 0;
  bc = 0;
  hc = 0;

  lastX = 0;
  lastY = 0;

  pinMode(2, OUTPUT);
  digitalWrite(2, HIGH);
}

void loop() {
  int value = map(analogRead(A0), INPUT_LOW, INPUT_HIGH, LIMIT_HIGH, LIMIT_LOW);

  if (value > LIMIT_LOW && value < LIMIT_HIGH) {
    if (lastX) lcd.drawLine(lastX, lastY, x, value, COLOR_ECGLINE);
    else lcd.drawPixel(x, value, COLOR_ECGLINE);
  }

  lastX = x;
  lastY = value;

  if (bc < BUFFER) {
    bc++;
  }
  else {
    bc = 0;

    if (x == 319) {
      x = 0;
      lastX = 0;
    }
    else x++;

    // calculate average
    if (hc < HISTORY_SIZE) hc++;
    else hc = 0;

    history[hc] = value;

    byte sum;
    for (int i = 0; i < HISTORY_SIZE; i++) {
      sum += history[i];
    }
    avg = sum/HISTORY_SIZE;

    if (value > (avg + 100)) {
      if (!overPeak) {
        int difference = millis() - lastTimeOverPeak;
        int heartRate = 60/(difference/1000.0);
	if (heartRate > HEART_RATE_LIMIT_LOW && heartRate < HEART_RATE_LIMIT_HIGH && heartRate != lastHeartRate) {
          lcd.fillRect(0, 0, 80, 30, COLOR_BACKGROUND);
          lcd.drawText(0, 0, heartRate, 3, COLOR_HEART_RATE, COLOR_BACKGROUND);
          lastHeartRate = heartRate;
        }
	lastTimeOverPeak = millis();
      }

      digitalWrite(2, LOW);
      noTone(3);
      overPeak = true;
    }
    else {
      overPeak = false;
      tone(3, TONE_FREQUENCY, 100);
      digitalWrite(2, HIGH);
    }

    // clear the next line
    lcd.drawLine(x, 60, x, 180, COLOR_BACKGROUND);
  }
}
