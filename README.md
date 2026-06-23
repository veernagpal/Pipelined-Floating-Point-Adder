This project implements a 32-bit IEEE-754 single-precision Floating Point Adder in Verilog using a 4-stage pipelined architecture. The design is verified using a Python-based testing environment that generates random floating-point test cases, runs RTL simulation, and compares the hardware output against Python-computed reference results.

A 32-bit IEEE-754 single-precision floating-point number is represented as:

     Sign : 1 bit
     Exponent	: 8 bits
     Mantissa : 23 bits
 
Before two Floating point numbers can be added, their exponents must be compared, their mantissas must be aligned, arithmetic must be performed based on their signs, and the result must be normalized and packed back into IEEE-754 format, thus the floating-point addition operation is divided into multiple stages and implemented as a pipelined datapath.

The Steps involved are :

     1.Unpacking the operands
     2.Comparing the exponents
     3.Aligning the mantissas
     4.Performing mantissa arithmetic
     5.Normalizing the intermediate result
     6.Packing the final result
Pipeline registers are inserted between major stages. This allows the datapath to be split across multiple clock cycles.

The Top level data path is organised as : 


     <img width="332" height="530" alt="image" src="https://github.com/user-attachments/assets/dc047ac1-7e42-4b63-a66b-b889a0a9f0c9" />

PIPELINE STAGES:

Stage 1: Unpack and Exponent Comparison

    The input operands are separated into sign, exponent, and mantissa fields. The hidden leading 1 is restored for normalized floating-point numbers. The exponents are then compared to identify the larger operand and calculate the exponent difference.

Stage 2: Mantissa Alignment

    The mantissa of the operand with the smaller exponent is right-shifted by the exponent difference. This ensures that both mantissas correspond to the same exponent before arithmetic is performed.

Stage 3: Mantissa Arithmetic

    The aligned mantissas are either added or subtracted depending on the signs of the input operands.
    
    If both operands have the same sign, the mantissas are added.
    If the operands have different signs, the smaller mantissa is subtracted from the larger mantissa.
Stage 4: Normalization and Packing

    The arithmetic result may not be in normalized IEEE-754 form. The normalize block shifts the mantissa and adjusts the exponent accordingly. Finally, the pack block combines the sign, exponent, and mantissa into a 32-bit floating-point result.
