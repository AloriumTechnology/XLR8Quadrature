/*--------------------------------------------------------------------
 Copyright (c) 2017 Alorim Technology.  All right reserved.
 This file is part of the Alorium Technology XLR8 Quadrature library.
 Written by Bryan Craker (bryancraker.com) of
   Alorium Technology (info@aloriumtech.com).
   The XLR8 Quadrature library is built to take advantage of the FPGA 
   hardware acceleration available on the XLR8 board.

 This library gives access to a quadrature quadrature on the FPGA 
 fabric of an XLR8 board.

 Functions:
  XLR8Quadrature()
    The class constructor, instantiates a quadrature.
  disable()
    Turns off the instance of quadrature until it is re-enabled. The 
    quadrature will not increment count or rate while disabled. Does 
    not return anything.
  enable()
    Turns on the instance of quadrature. Does not return anything.
  reset()
    Sets count and rate values for the quadrature back to zero. Does 
    not return anything.
  sample20ms()
    Sets the quadrature to update every 20 milliseconds, so the "rate" 
    value will correspond to number of pulses per 20 milliseconds. 
    Does not return anything.
  sample200ms()
    Sets the quadrature to update every 200 milliseconds, so the 
    "rate" value will correspond to number of pulses per 200 
    milliseconds. This is the default sample speed. Does not return 
    anything.
  readCount()
    Gets the current value of "count" from the quadrature, the number 
    of pulses seen so far. Returns a signed 32 bit integer, with a 
    positive number corresponding to forward motion and a negative 
    number corresponding to reverse motion.
  readRate()
    Gets the current value of "rate" from the quadrature, the number 
    of pulses seen during the defined sample period, either 20ms or 
    200ms. Returns a signed 32 bit integer, with a positive number 
    corresponding to forward motion and a negative number 
    corresponding to reverse motion.
  enabled()
    Returns a value of true or false indicating whether the 
    quadrature is currently enabled.

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
    int32_t readCount();
    int32_t readRate();
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
