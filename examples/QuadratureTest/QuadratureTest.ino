#include <XLR8Quadrature.h>

/* QuadratureExample
 Copyright (c) 2015-2017 Alorium Technology.  All rights reserved.
 by Bryan R. Craker (support@aloriumtech.com) of
 Alorium Technology (info@aloriumtech.com)
 Exercises the XLR8Quadrature Library
 No external hardware is required, this example is an internal 
   board exercise.
 Set serial monitor to 115200 baud
*/

#define NUM_QUADS 5
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
    pinMode(((idx + 1) * 2), OUTPUT);
    pinMode((((idx + 1) * 2) + 1), OUTPUT);
    digitalWrite((((idx + 1) * 2) + 1), HIGH);
  }

  // Stimulate all quads and store the observed rate
  for (long idx = 0; idx < NUM_QUADS; idx++) {
    for (long jdx = 0; jdx < NUM_TOGGLES + idx; jdx++) {
      digitalWrite(((idx + 1) * 2), LOW);
      digitalWrite(((idx + 1) * 2), HIGH);
    }
    slow_rates[idx] = quadratures[idx].readRate();
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
    fast_rates[idx] = quadratures[idx].readRate();
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
    Serial.print(quadratures[idx].readCount());
    Serial.print(" times, ");
    if (quadratures[idx].readCount() == (NUM_TOGGLES + idx) * 2) {
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
