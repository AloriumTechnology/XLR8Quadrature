/*--------------------------------------------------------------------
 Copyright (c) 2017 Alorim Technology.  All right reserved.
 This file is part of the Alorium Technology XLR8 Quadrature library.
 Written by Bryan Craker (bryancraker.com) of
   Alorium Technology (info@aloriumtech.com).
   The XLR8 Quadrature library is built to take advantage of the FPGA 
   hardware acceleration available on the XLR8 board.

 This library gives access to a quadrature quadrature on the FPGA 
 fabric of an XLR8 board.

 Usage
 The XLR8Quadrature library is included with the line
   #include <XLR8Quadrature.h>
 It provides access to six quadratures in the FPGA fabric. As 
 quadrature objects are instatiated, they are created sequentially. 
 I.e., the first quadrature object will control quadrature 0 in the 
 fabric, the second will control quadrature 1, etc., through 
 quadrature 5. The quadratures are connected to the physical pins 
 starting with digital pin 2, going through 13, with each quadrature 
 connected to the two sequential pins in order. So, quadrature 0 is 
 tied to pins 2 & 3, quadrature 1 is tied to pins 4 & 5, etc. The 
 simplest way to manage multiple quadratures in an application is to 
 create an array of quadrature objects. So if you instantiate an 
 array like this:
   Quadrature quadratures[6];
 You will have an array able to access all 6 quadratures in the FPGA. 
 In this example, you can think of the entire layout like this:

   Quadrature Object     FPGA Quadrature     XLR8 Board Pins
   ---------------------------------------------------
    quadratures[0]    |     0          |      2 &  3
    quadratures[1]    |     1          |      4 &  5
    quadratures[2]    |     2          |      6 &  5
    quadratures[3]    |     3          |      8 &  5
    quadratures[4]    |     4          |     10 & 11
    quadratures[5]    |     5          |     12 & 13

 Once you instantiate an quadrature object, the quadrature is enabled 
 by default. The software library then allows you to disable & 
 re-enable the quadratures, and read the count and rate values of the 
 quadrature. By default, the quadrature samples every 200ms to get the 
 rate, but can be set to sample every 20ms instead.

 This library is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as
 published by the Free Software Foundation, either version 3 of
 the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library.  If not, see
 <http://www.gnu.org/licenses/>.
 --------------------------------------------------------------------*/

#ifndef XLR8QUADRATURE_H
#define XLR8QUADRATURE_H

#ifdef ARDUINO_XLR8

#define MAX_QUADRATURES 6

#define INVALID_QUADRATURE 255

#define RATE_200MS 0
#define RATE_20MS  1

typedef struct {
  uint8_t sample_rate;
  bool    enable;
} QuadratureSettings_t;

typedef struct {
  QuadratureSettings_t settings;
} quadrature_t;

class XLR8Quadrature {
  public:
    XLR8Quadrature();
    void disable();
    void enable();
    void reset();
    void sample20ms();
    void sample200ms();
    int32_t read_count();
    int32_t read_rate();
    bool enabled();
  private:
    uint8_t quadratureIndex;
    void init();
    void update();
};

#else
#error "XLR8Quadrature library requires Tools->Board->XLR8xxx selection. Install boards from https://github.com/AloriumTechnology/Arduino_Boards"
#endif

#endif
