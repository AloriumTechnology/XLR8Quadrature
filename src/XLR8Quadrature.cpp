/*--------------------------------------------------------------------
 Copyright (c) 2017 Alorim Technology.  All right reserved.
 This file is part of the Alorium Technology XLR8 Quadrature library.
 Written by Bryan Craker (bryancraker.com) of
   Alorium Technology (info@aloriumtech.com).
   The XLR8 Quadrature library is built to take advantage of the FPGA 
   hardware acceleration available on the XLR8 board.
 
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

#include <Arduino.h>

#include "XLR8Quadrature.h"

#define QECR_ADDR   _SFR_MEM8(0xe0) // The quadrature control register
#define QECNT0_ADDR _SFR_MEM8(0xe2) // LSBs of the quadrature count register
#define QECNT1_ADDR _SFR_MEM8(0xe3) // Upper LSBs of the quadrature count register
#define QECNT2_ADDR _SFR_MEM8(0xe4) // Lower MSBs of the quadrature count register
#define QERAT0_ADDR _SFR_MEM8(0xe6) // LSBs of the quadrature rate register
#define QERAT1_ADDR _SFR_MEM8(0xe7) // Upper LSBs of the quadrature rate register

#define QEEN  7 // Enable bit of the control register
#define QEDIS 6 // Disable bit of the control register
#define QEUP 5 // Count reset bit of the control register
#define QERS 4 // Sample rate select bit of the control register

static quadrature_t quadratures[MAX_QUADRATURES]; // static array of quadrature structures

uint8_t QuadratureCount = 0;                // the total number of quadratures

XLR8Quadrature::XLR8Quadrature() {
  if (QuadratureCount < MAX_QUADRATURES) {
    this->quadratureIndex = QuadratureCount++;                            // assign a servo index to this instance and increment the count
    quadratures[this->quadratureIndex].settings.sample_rate = RATE_200MS; // default to 200ms sample rate
    quadratures[this->quadratureIndex].settings.enable = 1;               // enable the quadrature by default
    this->init();
    this->update();
  }
  else {
    this->quadratureIndex = INVALID_QUADRATURE; // too many quadratures
  }
}

// Disable the quadrature
void XLR8Quadrature::disable() {
  quadratures[this->quadratureIndex].settings.enable = 0;
  this->update();
}

// Enable the quadrature
void XLR8Quadrature::enable() {
  quadratures[this->quadratureIndex].settings.enable = 1;
  this->update();
}

// Reset the count and register to zero
void XLR8Quadrature::reset() {
  QECR_ADDR = (quadratures[this->quadratureIndex].settings.enable << QEEN) | (!quadratures[this->quadratureIndex].settings.enable << QEDIS)
    | (1 << QEUP) | (quadratures[this->quadratureIndex].settings.sample_rate << QERS) | (0x0F & this->quadratureIndex);
}

// Set the quadrature sample rate to every 20ms
void XLR8Quadrature::sample20ms() {
  quadratures[this->quadratureIndex].settings.sample_rate = RATE_20MS;
  this->update();
}

// Set the quadrature sample rate to every 200ms
void XLR8Quadrature::sample200ms() {
  quadratures[this->quadratureIndex].settings.sample_rate = RATE_200MS;
  this->update();
}

// Read the count registers and return as a 32 bit integer, extended from 24 bits of data
int32_t XLR8Quadrature::readCount() {
  QECR_ADDR = 0x0F & this->quadratureIndex;
  if ((QECNT2_ADDR >> 7) == 1) {
    return (((uint32_t)(B11111111) << 24) | ((uint32_t)(QECNT2_ADDR) << 16) | ((uint32_t)(QECNT1_ADDR) << 8) | (uint32_t)(QECNT0_ADDR));
  } else {
    return (((uint32_t)(B00000000) << 24) | ((uint32_t)(QECNT2_ADDR) << 16) | ((uint32_t)(QECNT1_ADDR) << 8) | (uint32_t)(QECNT0_ADDR));
  }
}

// Read the rate registers and return as a 16 bit integer
int16_t XLR8Quadrature::readRate() {
  QECR_ADDR = 0x0F & this->quadratureIndex;
  return (((uint32_t)(QERAT1_ADDR) << 8) | (uint32_t)(QERAT0_ADDR));
}

// Report whether the quadrature is enabled
bool XLR8Quadrature::enabled() {
  return quadratures[this->quadratureIndex].settings.enable;
}

// Set up the pins for this channel, channels use pins in sequential pairs starting from digital pin 2 ending at pin 13.
// Though it may seem counterintuitive, we set the pin to be an OUTPUT and set it to LOW. This puts the pin in a state 
//   that opens the path straight to the FPGA.
void XLR8Quadrature::init() {
  pinMode((this->quadratureIndex+1)*2, INPUT);
  pinMode(((this->quadratureIndex+1)*2)+1, INPUT);
}

// Update the control register based on current settings
void XLR8Quadrature::update() {
  QECR_ADDR = (quadratures[this->quadratureIndex].settings.enable << QEEN) | (!quadratures[this->quadratureIndex].settings.enable << QEDIS)
    | (0 << QEUP) | (quadratures[this->quadratureIndex].settings.sample_rate << QERS) | (0x0F & this->quadratureIndex);
}

