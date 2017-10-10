/* 

  SimpleQuadrature.ino

  Copyright (c) 2015-2017 Alorium Technology.  All rights reserved.
  For support, contact support@aloriumtech.com

  Description: 
  This is a simple example sketch for using the XLR8 Quadrature XB.
 
  Requirements: 
  This sketch requires that the XLR8 board has been updated with the 
  robotics image or the user has created a custom image via OpenXLR8
  that includes the Quadrature XB.

  Usage: 
  The Robotics Image contains five (5) quadrature interfaces
  connected via adjacent pin pairs on XLR8. As quadrature objects are
  instantiated, they are created sequentially. The first quadrature 
  object will control quadrature 0 in the fabric on pins 2 & 3, the
  second will control quadrature 1 on 4 & 5, etc.
  
  Quadrature     Pins
  ======================= 
       0     |   2 & 3
       1     |   4 & 5
       2     |   6 & 7
       3     |   8 & 9
       4     |  10 & 11

  No additional pin definitions or specific assignments are required.

*/

#include <XLR8Quadrature.h>

XLR8Quadrature quad0;  // quadrature 0 - wired to pins 2 & 3
 
int16_t rate,  rate_prev;
int32_t count, count_prev;

long int now;
long int then = 0;

void setup() {
  
  Serial.begin(115200);

  Serial.println("===========================");
  Serial.println("= SimpleQuadrature Sketch");
  Serial.println("===========================");
  
  quad0.sample200ms();   // Set sample time for 200ms

  rate_prev  = 0;
  count_prev = 0;

}

void loop() {
  
  now = millis();

  if ((now - then) >= 500) {  //  Check values every 500 ms
    
    then = now;

    // Read rate/count
    rate  = quad0.readRate();
    count = quad0.readCount();

    // If rate or count has changed, print out the values
    if ( (rate != rate_prev) || (count != count_prev) ) {

      // Print rate and count values
      Serial.print("count: ");
      Serial.print(count);
      
      Serial.print(" ");    
      
      Serial.print("rate:  ");
      Serial.println(rate);

    }

    // Update previous values
    rate_prev  = rate;
    count_prev = count;

  }
}
