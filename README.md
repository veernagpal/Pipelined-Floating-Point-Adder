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

Modules to implement the Floating point addition algorithm : 

1. unpack

          The unpack module extracts the three IEEE-754 fields from each 32-bit input operand:
          
          Sign bit
          Exponent field
          Mantissa field
          
          For normalized numbers, the hidden leading 1 is restored to form the complete mantissa used during arithmetic.
          
          Inputs:
          Floating-point operands A and B
          
          Outputs:
          Sign, exponent, and mantissa components of each operand

2. exponent_compare

          Floating-point addition requires both operands to have the same exponent. This module compares the exponents of the two operands, determines which operand has the larger exponent, and computes the exponent difference.
          
          The exponent difference is later used to shift the mantissa of the smaller operand.

3. align_mantissa

          The mantissa corresponding to the smaller exponent is right-shifted by the exponent difference. After this step, both operands are aligned to the same exponent and are ready for mantissa arithmetic.

4. mantissa_arithmetic

          This module performs the actual arithmetic operation on the aligned mantissas.
          
          If both operands have the same sign, the mantissas are added.
          If the operands have different signs, subtraction is performed.
          
          The output of this stage is an intermediate mantissa result and a result sign.

5.normalize

          The result from the arithmetic stage may not be in normalized IEEE-754 format.
          
          IEEE-754 normalized form is:
          
          1.xxxxx × 2^n
          
          The normalize module shifts the mantissa and updates the exponent so that the result follows normalized floating-point representation.
          
          A leading-one detection style approach is used to determine the required shift amount.

6. pack
          
          After normalization, the final sign, exponent, and mantissa fields are combined to form a 32-bit IEEE-754 single-precision result.

The 3 pipeline registers store and pass the relevant signals from one stage to the next at every clock edge

Considering the following example to get an understanding of the Datapath

<img width="787" height="822" alt="Screenshot 2026-06-24 012302" src="https://github.com/user-attachments/assets/c7c1aee7-faaf-4163-a0aa-ba362ac352f7" />

<img width="771" height="787" alt="Screenshot 2026-06-24 012313" src="https://github.com/user-attachments/assets/4a9ffb06-820a-4a5c-bba5-0e7df9505a16" />

OUTPUT VERIFICATION VIA WAVEFORM ANALYSIS

