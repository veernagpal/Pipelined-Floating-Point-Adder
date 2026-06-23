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

7. Pipeline Registers

        The 3 pipeline registers store and pass the relevant signals from one stage to the next at every clock edge

Considering the following example to get an understanding of the Datapath

<img width="787" height="822" alt="Screenshot 2026-06-24 012302" src="https://github.com/user-attachments/assets/c7c1aee7-faaf-4163-a0aa-ba362ac352f7" />

<img width="771" height="787" alt="Screenshot 2026-06-24 012313" src="https://github.com/user-attachments/assets/4a9ffb06-820a-4a5c-bba5-0e7df9505a16" />


OUTPUT VERIFICATION VIA WAVEFORM ANALYSIS

<img width="1810" height="277" alt="image" src="https://github.com/user-attachments/assets/1f69756e-b2e8-4c28-b09c-ac7db711f656" />

The following test cases were applied in the waveform testbench to check the basic operation of the pipelined floating-point adder:

     - Test Case 1: 
       - Input A: `32'h3F800000` = `1.0`
       - Input B: `32'h40000000` = `2.0`
       - Expected Result: `3.0`
       - Expected Hex: `32'h40400000`
     
     - Test Case 2: 
       - Input A: `32'h40400000` = `3.0`
       - Input B: `32'h40800000` = `4.0`
       - Expected Result: `7.0`
       - Expected Hex: `32'h40E00000`
     
     - Test Case 3:
       - Input A: `32'h3F000000` = `0.5`
       - Input B: `32'h3F800000` = `1.0`
       - Expected Result: `1.5`
       - Expected Hex: `32'h3FC00000`
     
     - Test Case 4:
       - Input A: `32'hBF800000` = `-1.0`
       - Input B: `32'h3F800000` = `1.0`
       - Expected Result: `0.0`
       - Expected Hex: `32'h00000000`
     
     - Test Case 5:
       - Input A: `32'h41200000` = `10.0`
       - Input B: `32'hC0500000` = `-3.25`
       - Expected Result: `6.75`
       - Expected Hex: `32'h40D80000`

These inputs were given one after another on consecutive positive clock edges. The output for each input pair appears only after the pipeline latency (3 clock cycles).

PYTHON BASED TESTING ENVIRONMENT 

A Python-based verification framework was developed to automate the testing of the pipelined floating-point adder.

The verification flow is:

<img width="390" height="620" alt="image" src="https://github.com/user-attachments/assets/b3a6ff49-a34a-459e-8b2a-553d20c428ba" />


The Python environment performs three main tasks:

     1.Generates random IEEE-754 floating-point test vectors
     2.Runs the Verilog testbench using those input vectors
     3.Compares RTL-generated outputs with Python reference results

to run the python testing framework : 

1: Generate Test Vectors

     python generate_stimulus.py

This creates:

     stimulus.txt

2: Compile the RTL and Testbench

     iverilog -o fp_pipelined_test.out FP_Adder_Pipelined.v tb_FP_Adder_Pipelined.v

3: Run the RTL Simulation

     vvp fp_pipelined_test.out

This creates:

     rtl_results_pipelined.txt
     
4: Run the Python Tester

     python test_pipelined.py

More About the Testing Framework : 

Stimulus Generation :

The script generate_stimulus.py is used to create the input vectors for the RTL simulation. Its main purpose is to generate floating-point operands in Python, convert them into exact 32-bit IEEE-754 hexadecimal form, and write them into stimulus.txt so that the Verilog testbench can read them (feed generated FP numbers to the RTL FP adder).

The script uses Python’s random module to generate a wide range of input values and the struct module to handle IEEE-754 conversion. The helper function float_to_hex() takes a Python floating-point value, packs it into single-precision format using "struct.pack('!f', f)" , and then unpacks the same 4 bytes as a 32-bit integer using "struct.unpack('!I', , ,)". This integer is finally converted into an 8-character hexadecimal string using "hex(__)[2:].zfill(8)".

def float_to_hex(f):
              
     "return hex(struct.unpack('!I', struct.pack('!f', f))[0])[2:].zfill(8)"

Each line generated which contains two 32-bit hexadecimal operands is written to stimulus.txt:

     A_HEX B_HEX

Testbench and Stimuli Application : 

The Verilog testbench's "tb_FP_Adder_Pipelined.v" job is to read the hexadecimal operands from stimulus.txt, apply them to the floating-point adder on the active clock edges, handle the pipeline latency by waiting 3 clock cycles for the correct output and then writing the output values into "rtl_results_pipelined.txt."

The testbench then opens the input and output files using $fopen.

     infile  = $fopen("stimulus.txt", "r");
     outfile = $fopen("rtl_results_pipelined.txt", "w");

The file "stimulus.txt" is opened in read mode because it already contains the operands generated by Python. The file "rtl_results_pipelined.txt" is opened in write mode because the testbench will store the RTL output results there.

Error checks are included to make sure both files open correctly.

     if (infile == 0) begin
         $display("ERROR: Could not open stimulus.txt");
         $finish;
     end
     
     if (outfile == 0) begin
         $display("ERROR: Could not open rtl_results_pipelined.txt");
         $finish;
     end
A loop reads input operands from stimulus.txt using $fscanf and are applied before the active edge of the clock.

     scan_status = $fscanf(infile, "%h %h\n", a, b);

The format specifier %h tells Verilog to read hexadecimal values. Since each line of stimulus.txt contains two hex operands, the testbench reads them directly into a and b.

The testbench uses a pipeline latency parameter to handle the pipeline latency

     parameter PIPELINE_LATENCY = 3;

Thus The result is observed on the 4th clock cycle relative to when the input was applied.

The output capture condition is implemented as:

     if ((cycle_count >= PIPELINE_LATENCY) && (output_count < input_count)) begin
         $fwrite(outfile, "%08h\n", result);
         output_count = output_count + 1;
     end
This condition ensures that the testbench does not write the initial invalid pipeline outputs and also that it does not write more output lines than the number of valid inputs applied.

The result is written using $fwrite.

     $fwrite(outfile, "%08h\n", result);
     The %08h format writes the result as an 8-character hexadecimal value.

An important aspect to take into account is that even after all inputs are read, the testbench still needs to flush the remaining pipeline outputs. This is because the last few inputs are still moving through the pipeline even after the input file has ended.

     while (output_count < input_count) begin
         @(posedge clk);
         #1;
     
         cycle_count = cycle_count + 1;
     
         $fwrite(outfile, "%08h\n", result);
         output_count = output_count + 1;
     end

This loop keeps the clock running until every input has a corresponding output written to rtl_results_pipelined.txt.

Output Verifier : 

test_pipelined.py is used to compare the RTL-generated outputs with reference results computed in Python. After the Verilog simulation finishes, this script reads both the original input vectors from "stimulus.txt" and the RTL outputs from "rtl_results_pipelined.txt", then checks whether each pipelined output matches the expected floating-point addition result within a chosen tolerance.

The script first imports Python’s struct module, which is used for converting between IEEE-754 hexadecimal bit patterns and floating-point values.

     import struct

hex_to_float(), converts an 8-character hexadecimal string into a Python floating-point value.

     def hex_to_float(hex_str):
         integer = int(hex_str, 16)
         return struct.unpack('!f', integer.to_bytes(4, byteorder='big'))[0]

The line int(hex_str, 16) converts the hexadecimal string into an integer. Then integer.to_bytes(4, byteorder='big') converts that integer into 4 bytes. Finally, struct.unpack('!f', ...) interprets those 4 bytes as a single-precision floating-point number.

to_float32(), forces Python’s computed result into single-precision format.

     def to_float32(value):
         return struct.unpack('!f', struct.pack('!f', value))[0]

This step is needed because Python normally uses double-precision floating-point internally. Since the RTL design works with 32-bit single-precision values, the expected result must also be rounded into FP32 format before comparison.

he script then reads all the original input vectors from stimulus.txt.

     stimulus = []
     
     with open("stimulus.txt", "r", encoding="utf-8", errors="ignore") as f:
         for line in f:
             parts = line.strip().split()
     
             if len(parts) == 2:
                 a_hex, b_hex = parts
                 stimulus.append((a_hex, b_hex))

Each line of stimulus.txt contains two hexadecimal operands. The script splits each line, checks that exactly two values are present, and stores them as a pair inside the stimulus list. Each entry in this list corresponds to one input test case.

Next, the RTL output values are read from rtl_results_pipelined.txt.

     rtl_results = []
     
     with open("rtl_results_pipelined.txt", "r", encoding="utf-8", errors="ignore") as f:
         for line in f:
             line = line.strip()
     
             if line:
                 rtl_results.append(line)
                 
Each line in rtl_results_pipelined.txt contains one 32-bit hexadecimal result produced by the Verilog simulation. The testbench has already handled the pipeline latency, so output 'i' convienently corresponds to input pair 'i'

Computing the Test Statistics : 

Error is Computed for each test as : 

     error = abs(expected - r)
     
The pass/fail decision is made using a tolerance value.
     
     if error < 1e-4:
         print("Status      = PASS")
         pass_count += 1
     else:
         print("Status      = FAIL")
         fail_count += 1

Error Statistics : 

     total_error += error if error > max_error: max_error = error avg_error = total_error / total_count

A tolerance is used because the RTL implementation does not fully implement all IEEE-754 rounding behavior such as guard, round, and sticky bits. Small numerical differences can occur due to truncation, rounding, and finite-precision representation. The tolerance allows the checker to focus on practical numerical correctness rather than exact bit-level equality for every case. As we make the tolerance lesser and lesser the number of failed tests increases due to accuracy limitation.

VERIFICATION OUTPUTS:

<img width="1506" height="55" alt="image" src="https://github.com/user-attachments/assets/adc5a46f-23d2-4e17-b62f-e5b5cc3f446d" />


<img width="1917" height="152" alt="image" src="https://github.com/user-attachments/assets/c4c33a07-d8c1-42c2-a4ae-a7d6fdba20a1" />


<img width="1486" height="37" alt="image" src="https://github.com/user-attachments/assets/c352fc6b-b977-40cb-8cd9-a31d1a647fe4" />


Examples of PASS CASES (Tolerance = 1e-4)

<img width="540" height="750" alt="image" src="https://github.com/user-attachments/assets/f70ebaff-11e2-4bff-8220-c915fd6b2a7a" />


<img width="512" height="761" alt="image" src="https://github.com/user-attachments/assets/983de4e6-dcff-4cf1-af88-29e0ee95bb2b" />


Examples of FAIL CASES (Tolerance = 1e-4)

<img width="452" height="241" alt="image" src="https://github.com/user-attachments/assets/b1644f45-e18e-4400-a4c6-5e3c8870612c" />


<img width="442" height="242" alt="image" src="https://github.com/user-attachments/assets/fda7afe5-ddcc-426e-88a5-23c9036039a9" />


Summaries Obtained for Different Tolerances : 

1e-4 :

<img width="407" height="202" alt="image" src="https://github.com/user-attachments/assets/5f28e532-eee2-4044-833b-0f3a62a25282" />


<img width="387" height="201" alt="image" src="https://github.com/user-attachments/assets/60a33704-e10b-4c0d-bdf3-2f979749f0af" />


<img width="382" height="192" alt="image" src="https://github.com/user-attachments/assets/00dc6573-ee43-4f9b-b857-a51b95ada345" />


<img width="376" height="202" alt="image" src="https://github.com/user-attachments/assets/6bfa3369-820c-4077-9010-53a4db037ff7" />


1e-5 :

<img width="372" height="191" alt="image" src="https://github.com/user-attachments/assets/a761d5b4-127a-4ed3-901c-a0c7da5c74cc" />


<img width="372" height="210" alt="image" src="https://github.com/user-attachments/assets/14f30306-d9b3-4657-9d3a-32719cddc076" />


<img width="377" height="192" alt="image" src="https://github.com/user-attachments/assets/16912051-d2fa-4d9a-abed-a2ddf3637b4d" />


<img width="390" height="195" alt="image" src="https://github.com/user-attachments/assets/c1d8c80c-0a6a-4244-b641-b21eae2e35a5" />


1e-6 : 

<img width="391" height="206" alt="image" src="https://github.com/user-attachments/assets/c671c8af-584b-45ec-8381-64e6df75e48c" />


<img width="412" height="216" alt="image" src="https://github.com/user-attachments/assets/54d82bca-889a-49da-bf4d-243d9b2d4ff8" />


<img width="420" height="192" alt="image" src="https://github.com/user-attachments/assets/0455cea1-1b59-4876-a008-aa4399a2a7c3" />


<img width="407" height="207" alt="image" src="https://github.com/user-attachments/assets/4e7ec17c-6566-4564-8d38-8b3141785242" />


As the tolerance is reduced, fewer test cases pass because the comparison becomes stricter. The main accuracy loss happens during mantissa alignment, where the mantissa of the smaller-exponent operand is right-shifted. In the current RTL, the bits shifted out are discarded, so some precision gets lost before arithmetic even happens. Since guard, round, and sticky bits are not implemented, these truncation errors show up as small differences from Python’s highly accurate reference result.

CURRENT LIMITATIONS :

The following has not been taken care of in the current implementation : 

     -NaN handling
     -Infinity handling
     -Subnormal number handling
     -Guard, round, and sticky-bit based rounding
     -Multiple IEEE-754 rounding modes
     -Exception flags
     -Overflow and underflow flag handling


FUTURE IMPROVEMENTS AND WORK :

     -Add full IEEE-754 special-case handling
     -Implement guard, round, and sticky bits
     -Add configurable rounding modes
     -Add overflow, underflow, invalid, and inexact flags
     -Extend the project into synthesis and ASIC flow 


~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~ PROJECT DONE UNDER THE ACM SMP UMBRELLA [DIGITAL-D2] *~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~

~veer
