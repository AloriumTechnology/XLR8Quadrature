#include <XLR8Quadrature.h>

#define NUM_QUADS 6
#define LOWEST_PIN 2
#define HIGHEST_PIN (NUM_QUADS * 2) + LOWEST_PIN
#define NUM_TOGGLES 0xffff

long fast_rates[NUM_QUADS];
long slow_rates[NUM_QUADS];

XLR8Quadrature quadratures[NUM_QUADS];

void setup() {

  Serial.begin(115200);

  Serial.println("Testing Started, Enabling Quadratures");
  Serial.println();

  // Enable all quads at slow sample speed and set one quad pin continually high
  for (int idx = 0; idx < NUM_QUADS; idx++) {
    quadratures[idx].enable();
    digitalWrite((((idx + 1) * 2) + 1), HIGH);
  }

  // Stimulate all quads and store the observed rate
  for (long idx = 0; idx < NUM_QUADS; idx++) {
    for (long jdx = 0; jdx < NUM_TOGGLES + idx; jdx++) {
      digitalWrite(((idx + 1) * 2), LOW);
      digitalWrite(((idx + 1) * 2), HIGH);
    }
    slow_rates[idx] = quadratures[idx].read_rate();
  }

  // Disable all quads
  for (int idx = 0; idx < NUM_QUADS; idx++) {
    quadratures[idx].disable();
  }

  // Re-enable all quads at fast sample speed
  for (int idx = 0; idx < NUM_QUADS; idx++) {
    quadratures[idx].enable();
    quadratures[idx].sample20ms();
  }

  // Stimulate all quads and store the observed rate
  for (long idx = 0; idx < NUM_QUADS; idx++) {
    for (long jdx = 0; jdx < NUM_TOGGLES + idx; jdx++) {
      digitalWrite(((idx + 1) * 2), LOW);
      digitalWrite(((idx + 1) * 2), HIGH);
    }
    fast_rates[idx] = quadratures[idx].read_rate();
  }

  for (long idx = 0; idx < NUM_QUADS; idx++) {
    Serial.print("Testing Quadrature ");
    Serial.print(idx);
    Serial.println(":");
    Serial.print("Sampled Slow Rate: ");
    Serial.print(slow_rates[idx]);
    Serial.println();
    Serial.print("Sampled Fast Rate: ");
    Serial.println(fast_rates[idx]);
    Serial.print("Quadrature ");
    Serial.print(idx);
    Serial.print(" toggled ");
    Serial.print(quadratures[idx].read_count());
    Serial.print(" times, ");
    if (quadratures[idx].read_count() == NUM_TOGGLES + idx) {
      Serial.println(" PASSED");
    }
    else {
      Serial.println(" FAILED");
    }
    Serial.println();
  }
}

void loop() {

}
