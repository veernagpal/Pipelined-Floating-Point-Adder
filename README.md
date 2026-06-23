This project implements a 32-bit IEEE-754 single-precision Floating Point Adder in Verilog using a 4-stage pipelined architecture. The design is verified using a Python-based testing environment that generates random floating-point test cases, runs RTL simulation, and compares the hardware output against Python-computed reference results.

A 32-bit IEEE-754 single-precision floating-point number is represented as:
 Sign	  Exponent	  Mantissa
1 bit	   8 bits	     23 bits
                
