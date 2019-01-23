# XLR8 Quadrature Encoder Library
Quadrature Encoder control for use with the Quadrature Xcelerator Block on an XLR8 or Sno board.

**Features:**

- Interface with a quadrature via FPGA leaving the AVR processor free for other work.

**More Information:**

- For use with an [XLR8 Board](https://www.aloriumtech.com/products/) with a quadrature XB loaded on it.
- In the Arduino IDE, burn a bootloader image that includes the quadrature XB. Check out our [Quickstart Guide](https://http://www.aloriumtech.com/xlr8-quickstart/).

**Usage:**

The XLR8Quadrature library is included with the line

  #include <XLR8Quadrature.h>

It provides access for up to six quadratures in the FPGA fabric.

As quadrature objects are instantiated, they are created sequentially. I.e., the first quadrature object will control quadrature 0 in the fabric, the second will control quadrature 1, etc., through quadrature 5.

The quadratures are connected to the physical pins starting with digital pin 2, going through 13, with each quadrature connected to the two sequential pins in order. So, quadrature 0 is tied to pins 2 & 3, quadrature 1 is tied to pins 4 & 5, etc. The simplest way to manage multiple quadratures in an application is to create an array of quadrature objects. So if you instantiate an array like this:

  Quadrature quadratures[6];

You will have an array able to access the instantiated quadratures in the FPGA. In this example, you can think of the entire layout like this:

   Quadrature Object     FPGA Quadrature     XLR8 Board Pins
   ---------------------------------------------------
    quadratures[0]    |     0          |      2 &  3
    quadratures[1]    |     1          |      4 &  5
    quadratures[2]    |     2          |      6 &  5
    quadratures[3]    |     3          |      8 &  5
    quadratures[4]    |     4          |     10 & 11
    quadratures[5]    |     5          |     12 & 13

Once you instantiate an quadrature object, the quadrature is enabled by default. The software library then allows you to disable & re-enable the quadratures, and read the count and rate values of the quadrature. By default, the quadrature samples every 200ms to get the rate, but can be set to sample every 20ms instead.

