This project implements a 32-bit IEEE-754 single-precision Floating Point Adder in Verilog using a 4-stage pipelined architecture. The design is verified using a Python-based testing environment that generates random floating-point test cases, runs RTL simulation, and compares the hardware output against Python-computed reference results.

Repository Overview (Quick Links) : 

- [RTL](#pipeline-stages)
- [Waveform Verification](#waveform-verification)
- [Python-Based Testing Environment](#python-testing)
- [ASIC Flow](#asic-flow)
- [OpenLane Configuration](#openlane-configuration)
- [Synthesis](#synthesis)
- [Floorplanning](#floorplanning)
- [Placement](#placement)
- [Clock Tree Synthesis](#cts)
- [Routing](#routing)
- [Static Timing Analysis](#sta)
- [Power Analysis](#power-analysis)
- [Physical Verification and Signoff](#physical-verification)
- [Final GDSII Generation](#final-gds)
- [Final Results Summary](#final-results)

<a id="pipeline-stages"></a>
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

<a id="waveform-verification"></a>

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

<a id="python-testing"></a>
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

The script then reads all the original input vectors from stimulus.txt.

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

<a id="asic-flow"></a>
ASIC FLOW : 

The objective of this stage was to convert the synthesizable Verilog RTL of the 4-stage pipelined IEEE-754 single-precision floating-point adder into a physical ASIC layout. 

The RTL was taken through a complete RTL-to-GDSII flow using OpenLane. The flow starts from the synthesizable Verilog and performs synthesis, floorplanning, placement, clock tree synthesis, routing, static timing analysis, and physical verification. The final output of this process is a GDSII file, which represents the physical layout of the chip block and can be viewed using layout tools such as KLayout or Magic.

The ASIC implementation was performed using the SKY130 PDK and the `sky130_fd_sc_hd` high-density standard-cell library. The SKY130 PDK provides the technology-specific information required for physical implementation, including standard cells, timing models, metal layer definitions, design rules, antenna rules, and layout verification files. The `sky130_fd_sc_hd` library was used to map the RTL logic into real standard cells such as gates, multiplexers, buffers, and flip-flops.

The final goal of this stage was not only to generate a layout, but also to verify that the layout is physically and electrically clean. Therefore, the final OpenLane run was checked for timing closure, DRC correctness, LVS correctness, and antenna safety. A clean result means that the design meets the target clock constraint, follows the SKY130 manufacturing design rules, matches the intended gate-level netlist (LVS satisfied), and importantly does not contain antenna violations that could damage transistor gates during fabrication.

Overview : 

The ASIC flow followed in this project is shown below:

Synthesizable Verilog RTL
        ↓
OpenLane Configuration
        ↓
RTL Synthesis
        ↓
Floorplanning
        ↓
Placement
        ↓
Clock Tree Synthesis
        ↓
Routing
        ↓
Static Timing Analysis
        ↓
DRC / LVS / Antenna Signoff
        ↓
Final GDSII Layout

The RTL-to-GDSII implementation was carried out using OpenLane, which is an open-source automated ASIC design flow. OpenLane acts as the main flow controller and connects multiple EDA tools together to perform the complete ASIC backend flow.

The ASIC flow is not performed by a single tool. Each stage requires a different type of analysis or transformation. For example, synthesis converts RTL into gates, placement assigns physical locations to those gates, routing connects them using metal layers, and signoff checks verify that the final layout is correct and manufacturable.

In this project, OpenLane automated these stages using tools such as Yosys, ABC, OpenROAD, OpenSTA, Magic, Netgen, TritonRoute, and KLayout, along with technology files from the SKY130 PDK.

     Tool / Component	                                         Role in the ASIC Flow
     OpenLane	                        Controls the full RTL-to-GDSII flow and passes design data between tools
     Yosys	                                      Converts Verilog RTL into a gate-level netlist
     ABC	                                        Optimizes logic and maps it to SKY130 standard cells
     OpenROAD	                  Performs physical design stages such as floorplanning, placement, CTS, routing, and optimization
     OpenSTA	                                 Performs static timing analysis for setup and hold timing
     TritonRoute	                              Performs detailed routing using physical metal layers
     Magic	                             Performs DRC checks, layout extraction, and GDS-related verification
     Netgen	                        Performs LVS comparison between layout-extracted netlist and reference netlist
     KLayout	                                           Used to visually inspect the final GDSII layout
     SKY130 PDK	                Provides standard cells, timing models, layout rules, routing rules, DRC/LVS rules, and antenna rules

OpenLane

OpenLane is the main automation framework used in this project. It does not perform every ASIC task by itself. Instead, it coordinates several open-source EDA tools and runs them in the correct order.

OpenLane reads the design configuration file, RTL files, timing constraints, PDK information, and standard-cell library files. It then launches the required tools for synthesis, floorplanning, placement, clock tree synthesis, routing, timing analysis, and physical verification.

In this project, OpenLane was responsible for converting the floating-point adder from:

Synthesizable Verilog RTL

to:

Final GDSII layout

It also generated reports for timing, area, routing, DRC, LVS, antenna checks, and final design metrics.

Yosys

Yosys is the synthesis tool used by OpenLane.

The input to Yosys is the Verilog RTL. At this point, the design is written in a high-level hardware description. For example, the RTL may contain arithmetic operations, comparisons, multiplexers, registers, and conditional statements.

Yosys converts this RTL into a gate-level representation. This means that operations written in Verilog are transformed into logic structures made from gates, muxes, flip-flops, and other cells.

For example, a Verilog statement such as:

assign y = sel ? a : b;

can be synthesized into a multiplexer cell. Similarly, adders, shifters, comparators, and control logic in the floating-point adder are broken down into standard-cell logic.

In this project, Yosys synthesized the 4-stage pipelined floating-point adder and produced a gate-level netlist for the top module fp_adder_top.

ABC

ABC is used during synthesis for logic optimization and technology mapping.

After Yosys converts RTL into a logic network, ABC optimizes that logic. It tries to reduce unnecessary gates, improve timing, reduce area, and map the logic efficiently to the available cells in the standard-cell library.

Technology mapping is important because generic gates are not enough for ASIC implementation. The logic must be mapped to real cells available in the selected library. In this project, ABC helped map the design to the SKY130 sky130_fd_sc_hd standard-cell library.

So, ABC helps answer this question:

What combination of real SKY130 cells should be used to implement this RTL logic efficiently?
SKY130 PDK

The SKY130 PDK is the technology foundation of the entire ASIC flow.

PDK stands for Process Design Kit. It contains the process-specific information needed to manufacture and verify a chip in SkyWater’s 130 nm CMOS technology.

The PDK provides:

standard-cell libraries
timing models
power models
LEF physical abstracts
metal layer information
via rules
design rule checks
LVS rules
antenna rules
technology files

In this project, the standard-cell library used was:

sky130_fd_sc_hd

This is the SkyWater 130 nm foundry-provided high-density standard-cell library. It contains pre-designed cells such as inverters, NAND gates, NOR gates, muxes, buffers, flip-flops, and other logic cells.

Without the SKY130 PDK, OpenLane would not know the size of each cell, the delay of each cell, the power of each cell, the routing layers available, or the physical design rules that the final layout must obey.

OpenROAD

OpenROAD is the main physical design engine used inside OpenLane.

After synthesis, the design exists as a gate-level netlist. This netlist tells which cells are connected, but it does not yet say where the cells are placed on silicon or how they are physically connected.

OpenROAD performs many of the backend physical design steps, including:

floorplanning
power planning
placement
placement optimization
clock tree synthesis
routing support
timing-driven optimization
design repair

During floorplanning, OpenROAD defines the die area, core area, placement rows, and initial physical structure of the design.

During placement, OpenROAD assigns locations to the synthesized standard cells inside the core area.

During clock tree synthesis, OpenROAD inserts clock buffers and builds a clock distribution network so that the clock reaches all pipeline registers properly.

During optimization, OpenROAD may insert buffers, resize cells, or make changes to improve timing and routability.

In this project, OpenROAD handled the main transformation from a synthesized netlist into a physically placed and routed design.

OpenSTA

OpenSTA is the static timing analysis tool used in the flow.

Static Timing Analysis checks whether the design can run at the target clock frequency without requiring simulation vectors. It analyzes timing paths between registers, inputs, and outputs using cell delays, wire delays, clock delays, and timing constraints.

OpenSTA checks two major timing conditions:

setup timing
hold timing

Setup timing checks whether data reaches the destination flip-flop before the next active clock edge. Hold timing checks whether data remains stable long enough after the current clock edge.

In this project, OpenSTA was used to verify that the pipelined floating-point adder met the 20 ns clock period constraint. The final timing results showed positive setup and hold slack, meaning the design passed timing signoff.

TritonRoute

TritonRoute is the detailed routing tool used in the OpenLane/OpenROAD flow.

After placement and clock tree synthesis, the standard cells have fixed physical positions. However, their pins still need to be connected using actual metal wires. Routing creates these connections.

Routing usually happens in two stages:

global routing
detailed routing

Global routing decides the approximate path that each net should take. Detailed routing creates the exact metal shapes, vias, and layer transitions needed to connect the pins while following the design rules.

TritonRoute performs detailed routing. It uses the metal layers and via rules defined by the SKY130 PDK. It must make sure that wires do not short, do not violate spacing rules, and do not create illegal geometries.

Magic

Magic is used for physical verification and layout-related checks.

In the ASIC flow, a design can pass synthesis and timing but still fail manufacturing rules. Magic checks the actual physical layout against the design rules from the SKY130 PDK.

Magic is used for:

DRC checking
layout extraction
GDS-related checks
physical verification

DRC stands for Design Rule Check. It verifies that the layout follows the manufacturing rules of the process, such as minimum metal width, minimum spacing, via enclosure, and layer overlap rules.

In this project, Magic was used during signoff to check the final layout. The final DRC report showed zero violations, which means the layout satisfied the checked SKY130 design rules.

Netgen

Netgen is used for LVS verification.

LVS stands for Layout Versus Schematic. It checks whether the physical layout actually matches the intended circuit.

The layout is first extracted into a netlist. Then Netgen compares this layout-extracted netlist against the reference gate-level netlist generated from synthesis.

Netgen checks for issues such as:

missing connections
extra connections
wrong pins
shorted nets
open nets
device mismatches
property mismatches

In this project, Netgen reported zero LVS errors. This means the final physical layout electrically matched the intended floating-point adder netlist.

KLayout

KLayout was used to view and inspect the final GDSII file.

GDSII is the final layout file format used to represent the physical geometry of the chip. It contains the shapes for the different layers of the design, such as metal layers, vias, contacts, and cell layouts.

KLayout does not change the logic of the design in this project. It was used as a layout viewer to open the final fp_adder_top.gds file and visually confirm that the GDS layout was generated successfully.

The final GDS layout viewed in KLayout represents the completed physical implementation of the 4-stage pipelined floating-point adder.

<a id="openlane-configuration"></a>
OpenLane Configuration

After defining the toolchain, the next step was to set up the floating-point adder as an OpenLane-compatible design. OpenLane expects each design to be placed inside a dedicated design directory, containing the RTL source files and a configuration file that describes how the flow should be run.

In this project, the design was organized as:

     designs/
     └── fp_adder_pipelined/
         ├── config.tcl
         └── src/
             └── 4_Stage_Pipelined_FP_adder_SYNTHESIZABLE_RTL.v

The src/ directory contains the synthesizable Verilog RTL of the 4-stage pipelined IEEE-754 single-precision floating-point adder. The config.tcl file contains all design-specific settings required by OpenLane, such as the top module name, clock port, clock period, synthesis strategy, placement density, floorplanning utilization, and antenna diode insertion settings.

This setup is important because OpenLane is an automated flow. It needs clear information about the design before it can perform synthesis, floorplanning, placement, clock tree synthesis, routing, timing analysis, and physical verification.

Top-Level Module

The top-level module used for ASIC implementation was:

     fp_adder_top

This module acts as the main entry point of the design. OpenLane starts from this module and traces the complete design hierarchy below it. Since the floating-point adder contains multiple internal modules such as unpacking, exponent comparison, mantissa alignment, arithmetic, normalization, packing, and pipeline registers, specifying the correct top module is necessary for the flow to understand the complete design.

In the OpenLane configuration file, the top-level module was specified using:

     set ::env(DESIGN_NAME) fp_adder_top

This tells OpenLane that fp_adder_top is the root module of the design. If this name does not match the actual top module name in the Verilog RTL, OpenLane synthesis will fail because it will not be able to identify the main design hierarchy.

RTL Source File Inclusion

The synthesizable Verilog RTL was placed inside the src/ directory of the OpenLane design folder.

The RTL files were included using:

     set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

This command tells OpenLane to include all Verilog files present inside the src/ directory. The [glob ...] expression automatically collects all files ending with .v.

In this project, the RTL file used for ASIC implementation was:

4_Stage_Pipelined_FP_adder_SYNTHESIZABLE_RTL.v

This file contains the synthesizable version of the 4-stage pipelined floating-point adder. Only synthesizable Verilog should be placed in the OpenLane src/ folder. Testbenches, Python scripts, simulation-only code, $display statements, delays, and non-synthesizable constructs should not be included in the ASIC synthesis source files.

Clock Port and Clock Period

The pipelined floating-point adder uses a clock signal because pipeline registers are placed between different computation stages. These registers divide the floating-point addition operation into multiple stages and allow the design to operate synchronously.

The clock port was specified using:

     set ::env(CLOCK_PORT) clk

This tells OpenLane that the signal named clk is the main clock of the design.

The target clock period was specified using:
     
     set ::env(CLOCK_PERIOD) 20

The clock period is given in nanoseconds. A clock period of 20 ns corresponds to a target frequency of:

Frequency = 1 / Clock Period
Frequency = 1 / 20 ns
Frequency = 50 MHz

This timing constraint is used throughout the flow. During synthesis, the tool tries to build logic that can meet this clock period. During placement, CTS, routing, and timing analysis, the flow checks whether data can travel between registers within the given clock period.

For this project, a 20 ns clock period was selected as a safe baseline constraint for achieving clean timing closure in the SKY130 process.

Floorplanning Core Utilization

The floorplanning utilization was set using:
     
     set ::env(FP_CORE_UTIL) 35

FP_CORE_UTIL controls how much of the core area is initially targeted for standard-cell usage during floorplanning. A value of 35 means that the design is planned with approximately 35% core utilization.

This does not mean the entire chip is only 35% useful. Instead, it means the initial floorplan leaves enough whitespace for later physical design steps.

Whitespace is important because the design still needs space for:

routing wires
clock buffers
timing repair buffers
antenna diodes
decap cells
welltap cells
fill cells
power routing

If the utilization is too high, the design becomes tightly packed. This can cause routing congestion, timing issues, DRC violations, or antenna violations. A more relaxed utilization gives OpenLane more freedom during placement and routing.

For this project, 35% utilization was used to keep the layout easier to place and route cleanly.

Placement Density

The placement density was controlled using:
     
     set ::env(PL_TARGET_DENSITY) 0.45

PL_TARGET_DENSITY controls how densely the standard cells are placed during the placement stage. A value of 0.45 means that the placer targets approximately 45% density in the placement region.

This value was chosen to avoid overpacking the design. Since a floating-point adder contains a significant amount of datapath logic, including muxes, shifters, adders, comparison logic, and normalization logic, routing resources are important. If the cells are placed too close together, routing wires may not have enough space, which can lead to congestion and routing violations.

A placement density of 0.45 provides a balance between area and routability. It keeps the design compact enough while still leaving enough whitespace for routing and physical-only cell insertion.

Synthesis Strategy

The synthesis strategy was set using:

     set ::env(SYNTH_STRATEGY) "AREA 0"

This setting tells the synthesis stage to use an area-oriented optimization strategy.

During synthesis, the RTL is converted into a gate-level netlist using standard cells from the SKY130 library. The synthesis tool can optimize the design for different goals, such as area, timing, or power. In this project, the AREA 0 strategy was used because the selected clock period of 20 ns was relaxed enough for the design to meet timing while keeping the implementation reasonably compact.

This means the synthesis tool tries to reduce unnecessary logic and map the RTL into an efficient set of SKY130 standard cells.

Antenna Diode Insertion

Antenna diode insertion was configured using:

     set ::env(DIODE_INSERTION_STRATEGY) 3
     set ::env(RUN_HEURISTIC_DIODE_INSERTION) 1

Antenna violations can occur during chip fabrication when long metal wires collect charge and connect to sensitive MOS gate terminals. If this accumulated charge becomes too large, it can damage the thin gate oxide of transistors. This is called the antenna effect.

To prevent this, diode cells can be inserted into the design. These diodes provide a safe discharge path for the accumulated charge during fabrication.

In this project, an earlier OpenLane run showed antenna violations. To fix this, heuristic diode insertion was enabled using:

     set ::env(RUN_HEURISTIC_DIODE_INSERTION) 1

This allowed OpenLane to insert additional antenna protection diodes. After enabling this setting, the final design achieved clean antenna signoff with zero pin antenna violations and zero net antenna violations.

The diode insertion settings do not change the logical functionality of the floating-point adder. They are physical design fixes added to make the layout safe and manufacturable.

Final OpenLane Configuration

The final config.tcl used for the clean OpenLane run was:

     set ::env(DESIGN_NAME) fp_adder_top
     
     set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]
     
     set ::env(CLOCK_PORT) clk
     set ::env(CLOCK_PERIOD) 20
     
     set ::env(FP_CORE_UTIL) 35
     set ::env(PL_TARGET_DENSITY) 0.45
     
     set ::env(SYNTH_STRATEGY) "AREA 0"
     
     set ::env(DIODE_INSERTION_STRATEGY) 3
     set ::env(RUN_HEURISTIC_DIODE_INSERTION) 1

| Configuration Parameter | Value | Purpose |
|---|---|---|
| `DESIGN_NAME` | `fp_adder_top` | Specifies the top-level Verilog module |
| `VERILOG_FILES` | `src/*.v` | Includes all RTL source files |
| `CLOCK_PORT` | `clk` | Defines the main clock signal |
| `CLOCK_PERIOD` | `20 ns` | Sets the target timing constraint |
| `FP_CORE_UTIL` | `35` | Sets relaxed floorplan utilization |
| `PL_TARGET_DENSITY` | `0.45` | Controls placement density |
| `SYNTH_STRATEGY` | `AREA 0` | Uses area-oriented synthesis optimization |
| `DIODE_INSERTION_STRATEGY` | `3` | Enables antenna diode insertion strategy |
| `RUN_HEURISTIC_DIODE_INSERTION` | `1` | Adds extra diode insertion to fix antenna violations |

The 20 ns clock period gave the design a reasonable timing target. The 35% core utilization and 0.45 placement density gave the backend tools enough whitespace for routing and optimization. The area-oriented synthesis strategy helped keep the synthesized design compact. Finally, heuristic diode insertion was enabled to resolve antenna violations and achieve clean physical signoff.

Stages of the ASIC flow
<a id="synthesis"></a>
1. Synthesis : converts this high-level RTL into a gate level netlist made up of actual standard cells from the selected PDK such as:

          AND gates
          OR gates
          NAND gates
          NOR gates
          XOR gates
          XNOR gates
          MUXes
          buffers
          inverters
          flip-flops
          complex logic cells

For example, an RTL statement such as:
     
     assign y = sel ? a : b;

can be mapped to a multiplexer standard cell.

Tool Used: Yosys and ABC

Yosys reads the Verilog RTL, elaborates the design hierarchy, checks the modules, and converts the RTL into a generic logic representation. It then performs logic synthesis and prepares the design for mapping into a technology-specific cell library.

ABC is used after Yosys for logic optimization and technology mapping. It optimizes the logic network and maps it to actual cells available in the SKY130 sky130_fd_sc_hd standard-cell library.

So the synthesis flow is:

     Verilog RTL
        ↓
     Yosys elaboration and synthesis
        ↓
     Generic gate-level logic
        ↓
     ABC logic optimization
        ↓
     Mapping to SKY130 standard cells
        ↓
     Gate-level Verilog netlist

The final synthesized cell count was:
     
     Synthesized cell count = 1250

This means that the functional logic of the floating-point adder was implemented using 1250 synthesized standard cells before backend physical-only cells were inserted.

The main output of synthesis is the gate-level Verilog netlist.

For this project, the synthesis output was generated as:
     
     results/synthesis/fp_adder_top.v

This file represents the synthesized version of the RTL using SKY130 standard cells.

<img width="1052" height="436" alt="image" src="https://github.com/user-attachments/assets/971eb624-0329-4613-985c-691c89bd9fa7" />


<img width="701" height="82" alt="image" src="https://github.com/user-attachments/assets/d60c1a48-3076-49c7-8601-340cb190ad5a" />


Synthesis Summarized : 

| Category | Parameter | Count |
|---|---|---:|
| Routing & Wiring | Wires Count | `1,257` |
| Routing & Wiring | Wire Bits | `2,502` |
| Routing & Wiring | Public Wires Count | `116` |
| Routing & Wiring | Public Wire Bits | `1,361` |
| Routing & Wiring | Routed Wire Length | `45,024` |
| Routing & Wiring | Vias | `10,347` |
| Physical Cell Breakdown | Total Cells | `5,459` |
| Physical Cell Breakdown | Synthesized Logic Cells | `1,250` |
| Physical Cell Breakdown | Non-Physical Cells | `1,406` |
| Physical Cell Breakdown | Fill Cells | `1,089` |
| Physical Cell Breakdown | Decap Cells | `1,886` |
| Physical Cell Breakdown | Welltap Cells | `497` |
| Physical Cell Breakdown | Antenna Diode Cells | `581` |
| Logic Gate Distribution (Yosys/ABC) | XOR Gates | `129` |
| Logic Gate Distribution (Yosys/ABC) | OR Gates | `186` |
| Logic Gate Distribution (Yosys/ABC) | XNOR Gates | `6` |
| Logic Gate Distribution (Yosys/ABC) | AND Gates | `63` |
| Logic Gate Distribution (Yosys/ABC) | NOR Gates | `70` |
| Logic Gate Distribution (Yosys/ABC) | NAND Gates | `8` |
| Logic Gate Distribution (Yosys/ABC) | DFF / Pipeline Registers | `~166` |
| Logic Gate Distribution (Yosys/ABC) | MUX / Multiplexers | `318` |
<a id="floorplanning"></a>
2. Floor-Planning :

Floorplanning is the first major physical design step in the ASIC flow. After synthesis, the design exists as a gate-level netlist made up of SKY130 standard cells, but those cells do not yet have physical locations on silicon. Floorplanning creates the initial physical structure of the chip block so that placement, routing, clock tree synthesis, and signoff can be performed later.

The main purpose of floorplanning is to define:

     die area
     core area
     standard-cell rows
     input/output pin locations
     power and ground structure

The die is the complete physical boundary of the design. The core is the inner region where the standard cells are placed. The space between the core and die boundary is generally used for pin access, routing resources, and physical margins.

Floorplanning is mainly handled by:

OpenROAD

inside the OpenLane flow.

OpenROAD uses the gate-level netlist generated after synthesis along with the SKY130 technology files and standard-cell physical abstracts. These physical abstracts come from LEF files, which describe the height, width, pin locations, and routing blockages of each standard cell.

At this stage, OpenROAD does not yet route all signal wires. Instead, it prepares the physical canvas where cells and wires will later be placed.

During floorplanning, OpenLane/OpenROAD performs several important actions.

First, it determines the size of the die and core. The die defines the outer boundary of the design, while the core defines the region where the standard cells are placed. The size is influenced by the number of synthesized cells, target utilization, placement density, routing requirements, and physical-only cell requirements.

Next, standard-cell rows are created inside the core. These rows are important because standard cells are placed in aligned rows during placement. Standard cells from the sky130_fd_sc_hd library have a fixed cell height, so rows make it possible to place cells cleanly and connect their power rails properly.

Floorplanning also prepares power and ground distribution. All standard cells require VDD and GND connections. Therefore, the flow creates power rails and prepares the power delivery structure so that the placed cells can receive supply connections.

Input and output pins are also assigned positions around the design boundary. These pins are used to connect the block to the outside environment.

The floorplanning utilization was controlled using the following OpenLane setting:

set ::env(FP_CORE_UTIL) 35

FP_CORE_UTIL controls the approximate percentage of the core area that should be occupied by standard cells during the initial floorplan.

In this project, the value was set to:

35%

This means the design was not packed too tightly. A relaxed utilization was used intentionally to leave enough whitespace for later backend stages.

Whitespace is important because the design still needs room for:

     signal routing
     clock tree buffers
     timing repair buffers
     antenna diode cells
     decap cells (transistors switch so fast they need an instant flood of current. Since the main power supply is too far away to react in time, decap cells act as tiny, local energy reservoirs that dump their stored charge instantly to keep the voltage from dropping.)
     welltap cells (prevent Latch Up in CMOS)
     fill cells ()
     power routing

If the core utilization is too high, cells become packed very close together. This can cause routing congestion, timing issues, DRC violations, and difficulty inserting physical-only cells. If the utilization is too low, the design becomes larger than necessary. Therefore, floorplanning is a tradeoff between area and routability.

Floorplanning has a major effect on the rest of the ASIC flow. A good floorplan makes placement and routing easier, improves timing closure, and reduces the chance of DRC or routing violations.

If the floorplan is too small or too dense, the router may not have enough space to connect the cells. This can lead to routing failures or design rule violations. If the floorplan is too large, the design wastes area and may have longer wires, which can increase delay and power.

For this project, the floorplan settings provided enough whitespace for successful placement, routing, diode insertion, and final signoff. This helped the design pass routing, DRC, LVS, antenna, and timing checks in the final OpenLane run.

Floor-Planning Metrics

<img width="601" height="156" alt="image" src="https://github.com/user-attachments/assets/6f7061a0-f267-4531-b754-d8028ba8561a" />

<a id="placement"></a>
3. Placement :

Placement is the stage where the synthesized standard cells are assigned physical locations inside the core area created during floorplanning.

After synthesis, the design exists as a gate-level netlist. This netlist tells which standard cells are used and how they are connected, but it does not define where those cells should physically sit on the silicon layout. Floorplanning creates the die, core, rows, and power structure, but the cells are still not placed in their final positions.

Placement converts the synthesized netlist into a physical arrangement of cells inside the core.

In simple terms:

After synthesis:
The design knows what cells are needed.

After floorplanning:
The design knows the physical boundary and core area.

After placement:
The design knows where each standard cell is located.

During placement, the tool tries to arrange cells in a way that reduces wire length, avoids congestion, improves timing, and keeps the design legal with respect to the standard-cell rows.

Placement is mainly handled by: OpenROAD inside the OpenLane flow.

OpenROAD performs global placement, placement optimization, and detailed placement. OpenDP is used during detailed placement/legalization to ensure that cells are placed legally in standard-cell rows without overlap.

Placement is not just a single step where cells are randomly put inside the core. It is a multi-stage process where the tool gradually moves from an approximate placement to a final legal placement.

The main aim of placement is to arrange the synthesized standard cells in such a way that the design becomes easier to route, timing paths become shorter, and the final layout remains physically legal.

Placement is usually performed in three major sub-stages:

1. Global placement
2. Placement optimization
3. Detailed placement / legalization

Global placement is the first major placement step. At this stage, the tool assigns approximate locations to all the standard cells inside the core area.

The placement is not yet final or perfectly legal. The main goal is to get a good overall arrangement of the cells.

The tool tries to place cells based on their connectivity. Cells that communicate with each other frequently or are connected by the same nets are placed closer together. This helps reduce the total wire length needed later during routing.

For example, if the output of one logic gate drives another gate, placing those two cells close together reduces the length of the wire between them. Shorter wires generally help reduce:

     routing congestion
     wire delay
     switching power
     parasitic capacitance
     timing problems

2. Placement Optimization

After global placement, the tool analyzes the initial cell arrangement and improves it.

This stage is called placement optimization. The tool checks whether the current placement is good for timing, congestion, and routability. If needed, it modifies the placement or inserts additional cells to improve the design.

Placement optimization may involve:

     1. Moving Cells to Reduce Wire Length
     
     One of the main goals of placement optimization is to reduce the total wire length of the design.
     
     After synthesis, the netlist defines which cells are connected, but not where they are physically located. If two connected cells are placed far apart, the wire between them becomes long.
     
     Long wires can cause several problems:
     
     higher wire delay
     larger parasitic capacitance
     higher switching power
     more routing resource usage
     greater chance of congestion
     
     For example, if the output of one mux drives another logic block, placing those two cells far apart forces the router to create a long metal connection. This increases the delay of that signal and can make timing closure harder.
     
     To solve this, the placement optimizer moves connected cells closer together. By reducing the distance between connected cells, the tool reduces wire length, improves timing, lowers capacitance, and makes routing easier.
     
     In this floating-point adder, this is important because datapath blocks such as mantissa alignment, mantissa arithmetic, normalization, and packing are heavily connected. Keeping related cells close reduces unnecessary routing delay.
     
     2. Spreading Cells to Reduce Congestion
     
     Although placing connected cells close together is useful, placing too many cells in one small region can create congestion.
     
     Congestion happens when many wires need to pass through the same physical area. Even if the logic is correct, the router may struggle to connect all nets because there are limited routing tracks available in each metal layer.
     
     Congestion can cause problems such as:
     
     routing difficulty
     long routing detours
     higher wire delay
     DRC violations
     routing failure
     increased via usage
     
     For example, if too many muxes, adders, and shifter-related cells are placed very close together, many signals may need to enter and leave that small region. The router may then be forced to use longer detours or higher metal layers to complete the connections.
     
     To solve this, placement optimization spreads cells apart in congested regions. This creates more whitespace between cells and gives the router more space to pass wires through.
     
     This is why placement density matters. In this project, the placement density target was set to:
     
     set ::env(PL_TARGET_DENSITY) 0.45
     
     This helped avoid overpacking and made the design easier to route cleanly.
     
     3. Inserting Buffers on Long Nets
     
     A long net is a signal wire that travels a large distance across the chip. Long nets can become slow because the wire has resistance and capacitance. The driver cell at the start of the net must charge or discharge the entire wire capacitance.
     
     This can cause:
     
     large signal delay
     slow transition time
     timing violations
     high dynamic power
     poor signal integrity
     
     If a driver is too weak for a long wire, the signal transition becomes slow. Slow transitions can affect timing and may also increase short-circuit power in receiving gates.
     
     To solve this, the optimizer can insert buffers along long nets.
     
     Instead of one weak driver driving a long wire directly, the signal is split into shorter segments:
     
     Without buffer:
     Driver ───────────────────────────── Receiver
     
     With buffers:
     Driver ───── Buffer ───── Buffer ───── Receiver
     
     Each buffer regenerates the signal and drives the next shorter wire segment. This reduces transition time and improves timing.
     
     Buffer insertion is especially useful for signals that travel between different regions of the layout.
     
     4. Resizing Cells for Timing Improvement
     
     Standard-cell libraries usually contain multiple drive-strength versions of the same logic cell.
     
     For example, an inverter or buffer may exist in different strengths:
     
     small inverter
     medium inverter
     large inverter
     
     A small cell uses less area and power but drives signals more slowly. A larger cell uses more area and power but can drive larger loads faster.
     
     If a cell is on a slow timing path, the optimizer may replace it with a stronger version of the same cell. This is called cell resizing.
     
     The problem caused by weak cells is:
     
     larger gate delay
     slow output transition
     setup timing problems
     poor drive strength for large loads
     
     The solution is:
     
     replace weak cell with stronger drive-strength cell
     
     However, resizing has tradeoffs. Stronger cells improve delay but may increase:
     
     area
     power
     input capacitance
     local congestion
     
     So the optimizer does not simply make every cell large. It selectively resizes cells only where timing improvement is needed.
     
     In a floating-point adder, resizing may be useful on timing-sensitive datapath logic such as mantissa arithmetic, normalization, or exponent/mantissa selection paths.
     
     5. Improving Critical Timing Paths
     
     A critical path is one of the slowest timing paths in the design. It is the path that limits the maximum operating frequency of the circuit.
     
     In a pipelined design, timing paths usually exist between two sets of registers:
     
     launch register → combinational logic → capture register
     
     If the combinational logic and routing delay between two registers is too large, the data may not reach the capture register before the next clock edge. This causes a setup timing violation.
     
     Critical paths can be caused by:
     
     too much combinational logic between registers
     long wires
     weak drive cells
     high fanout nets
     poor placement
     large mux/shifter/arithmetic structures
     
     Placement optimization tries to improve these paths by physically moving cells closer together, resizing cells, inserting buffers, and reducing wire length.
     
     For this floating-point adder, possible timing-sensitive regions include:
     
     mantissa alignment path
     mantissa arithmetic path
     normalization path
     rounding/packing path
     mux-heavy exponent selection logic
     
     Because the design is pipelined, each stage has less combinational logic than a fully non-pipelined design. This helps timing closure. In the final run, the design achieved positive setup slack, showing that the timing paths met the 20 ns clock constraint.
     
     6. Reducing Excessive Fanout Problems
     
     Fanout refers to the number of loads driven by a signal.
     
     For example, if one signal drives 20 different cells, it has a fanout of 20.
     
     High fanout can cause problems because one driver has to charge the input capacitance of many receiving gates. This increases the load on the driver.
     
     High fanout can lead to:
     
     slow signal transition
     large delay
     setup timing problems
     increased power
     routing congestion
     poor signal quality
     
     Common high-fanout signals include:
     
     control signals
     enable signals
     select lines
     reset signals
     wide mux select signals
     clock-related control signals
     
     To solve high-fanout problems, the tool can insert buffers and create a small distribution tree.
     
     Instead of one cell driving many loads directly:
     
     One driver → many loads
     
     the tool creates buffered branches:
     
     Driver
       ├── Buffer → group of loads
       ├── Buffer → group of loads
       └── Buffer → group of loads
     
     This reduces the load seen by the original driver and improves transition time and delay.
     
3. Detailed Placement / Legalization

After global placement and optimization, the cells have reasonable approximate locations, but the placement may still not be physically legal.

Detailed placement, also called legalization, converts the approximate placement into a legal standard-cell placement.

Standard cells cannot be placed anywhere randomly. They must sit inside predefined standard-cell rows created during floorplanning. These rows are aligned so that the power rails of each cell connect properly to VDD and GND.

During detailed placement, the tool snaps cells into valid row locations and makes sure the final placement satisfies physical constraints.

This step ensures that:

cells do not overlap
cells are placed inside legal standard-cell rows
cells are aligned correctly
power rails line up properly
cell orientations are valid
placement sites are respected
the design is ready for CTS and routing

If two cells overlap after global placement, legalization separates them. If a cell is slightly off-row, detailed placement snaps it into the correct row. If cells are too close or not aligned properly, the tool adjusts their positions.

The placement density target was set using:

set ::env(PL_TARGET_DENSITY) 0.45

This means the placer was guided to avoid packing the cells too tightly. Since the floating-point adder contains datapath-heavy logic with many interconnections, a moderate placement density helped leave enough whitespace for routing, timing optimization, clock tree buffers, diode cells, decap cells, welltap cells, and filler cells.

The final OpenDP utilization reported by OpenLane was:

OpenDP Utilization = 36.28%

This indicates that after detailed placement, about 36.28% of the core placement area was occupied by cells. This value is close to the configured floorplan utilization target of 35%, showing that the design was placed in a relaxed and routable manner.

<a id="cts"></a>
4. Clock Tree Synthesis :

Clock Tree Synthesis, usually called CTS, is the stage where the clock network of the design is physically built.

Before CTS, the design has already gone through synthesis, floorplanning, and placement. At this point, the standard cells have been placed inside the core area, but the clock signal is still mostly treated as an ideal signal. In a real chip, the clock cannot reach every flip-flop instantly or automatically. It has to physically travel through metal wires and buffers.

Since this project implements a 4-stage pipelined IEEE-754 single-precision floating-point adder, the design contains pipeline registers between different computation stages. These registers are controlled by the clock signal. For the pipeline to work correctly, all registers must receive a clean and properly distributed clock.

The main purpose of CTS is to distribute the clock signal from the clock input port to all sequential elements in the design while controlling clock imperfections 

Clock Tree Synthesis is mainly handled by OpenROAD inside the OpenLane flow. OpenROAD uses clock tree synthesis algorithms and clock buffer cells from the sky130_fd_sc_hd standard-cell library to build the clock distribution network.

The CTS stage uses the placed design database, clock definition, clock period constraint, standard-cell timing models, and clock buffer cells from the SKY130 library.

In this project, the clock port was defined in config.tcl as:

     set ::env(CLOCK_PORT) clk

The target clock period was defined as:
     
     set ::env(CLOCK_PERIOD) 20

This means the design was implemented for a target clock period of 20 ns, which corresponds to a target frequency of 50 MHz

Significance of CTS : 

In a synchronous digital circuit, flip-flops capture data on active clock edges. A typical register-to-register timing path looks like this:

launch register → combinational logic → capture register

The launch register sends data on one clock edge, and the capture register captures that data on a later clock edge. For this to work correctly, the clock must reach both registers in a controlled and predictable way.

Before CTS, the clock is treated as an ideal signal during earlier stages. However, after physical implementation, the clock must travel through actual wires and buffers. These wires and buffers introduce delay. If the clock reaches different registers at different times, timing problems can occur.

The difference in clock arrival time between two sequential elements is called clock skew.

Clock skew can cause:

setup timing violations
hold timing violations
incorrect data capture
reduced timing margin
lower maximum operating frequency

Therefore, CTS is required to convert the ideal clock into a real physical clock network that can drive all sequential elements reliably.

During CTS, OpenROAD builds a tree-like clock distribution network from the clock input port to all flip-flops in the design.

A simplified clock tree looks like this:

     Clock input
         |
      Clock buffer
         |
      ---------------
      |             |
     Buffer       Buffer
      |             |
     FF group     FF group

Instead of one clock source directly driving every flip-flop, CTS divides the clock signal into multiple branches using clock buffers. This reduces the load on each buffer and helps control clock delay and skew.

CTS mainly tries to control the imperfections of a practical clock which can affect the proper functioning and performance of the circuit such as :

Clock Insertion Delay:

Clock insertion delay is the time taken by the clock signal to travel from the clock input port to a flip-flop.

The clock does not reach the registers instantly. It passes through metal wires and clock buffers, and each of these adds delay.

Insertion delay is not automatically bad. The important thing is that it must be controlled and properly accounted for during static timing analysis.

CTS builds the clock network so that insertion delay is predictable and balanced across the design.

Clock Transition Time:

Clock transition time refers to how fast the clock signal switches from low to high or high to low.

If the clock edge is too slow, flip-flops may not operate reliably. Slow clock transitions can also increase timing uncertainty and power consumption.

Clock buffers help strengthen the clock signal and maintain acceptable transition times across the design.

Clock Fanout:

Fanout refers to the number of loads driven by a signal.

The clock usually has very high fanout because it must drive all flip-flops in the design. If one clock source directly drives every register, the load becomes very large. This can make the clock signal slow and unreliable.

CTS solves this by creating a buffered clock tree.

Instead of:

     One clock source → all flip-flops

CTS creates:
     
     Clock source
         ├── Buffer → group of flip-flops
         ├── Buffer → group of flip-flops
         └── Buffer → group of flip-flops

This reduces the load on each clock driver and improves clock quality.

<img width="1217" height="302" alt="image" src="https://github.com/user-attachments/assets/063800d9-7998-417f-a6d6-8b87d40784af" />

<a id="routing"></a>
5. Routing

Routing is the stage where the physical electrical connections between all placed cells are created using metal wires and vias.

After synthesis, the design is converted into a gate-level netlist. After floorplanning and placement, the standard cells are assigned physical locations inside the core. After Clock Tree Synthesis, the clock network is also inserted. However, at this point, most of the signal connections still need to be physically implemented using actual metal layers.

Routing takes the placed design and connects all nets according to the synthesized netlist.

In simple terms:

After placement:
The cells know where they are located.

After CTS:
The clock tree has been inserted.

After routing:
The cells are physically connected using metal wires and vias.

outing in OpenLane is mainly performed using OpenROAD-based routing tools.

The routing stage is usually divided into two major parts:

1. Global Routing (OpenRoad)
2. Detailed Routing (TritonRoute)

The main tools involved are:

Global routing plans the approximate route of each net across the chip. Detailed routing then converts those approximate routes into real metal shapes and via connections that obey the SKY130 design rules.

Global Routing :

At this stage, the router does not yet draw the final exact metal wires. Instead, it divides the chip area into routing regions and estimates which regions each net should pass through.

Global routing tries to avoid congested areas and distribute wires across available routing resources. It also estimates wire length and routing demand.

For example, if a signal must connect a cell on the left side of the core to a cell on the right side, global routing decides the approximate path that signal should follow. It may choose a more direct route if space is available, or it may route around congested regions.

Global routing helps identify whether the placement is routable. If too many nets need to pass through the same region, congestion can occur. Congestion may later cause routing detours, timing problems, or routing violations.

Detailed Routing

This is the stage where the actual physical metal wires and vias are created.

After global routing decides approximate paths, detailed routing converts those paths into real layout geometry. It chooses exact routing tracks, metal layers, via locations, and wire shapes.

Detailed routing must obey all technology design rules from the SKY130 PDK, such as:

     minimum metal width
     minimum metal spacing
     via enclosure rules
     metal area rules
     routing track rules
     off-grid restrictions
     short-circuit prevention

This stage is handled by TritonRoute inside the OpenLane/OpenROAD flow.

TritonRoute creates the final legal routing for the design. It connects cell pins while avoiding shorts, spacing violations, and other physical design rule violations.

Metal Layers and Vias

In an ASIC, connections are not made using a single layer of wire. The design uses multiple metal layers stacked above the transistor and standard-cell layers.

A wire may start on one metal layer, move vertically through a via, continue on another metal layer, and then connect to a different cell.

A simplified example is:

     Metal 1 ───── Via ───── Metal 2 ───── Via ───── Metal 3

A via is a small vertical connection between two metal layers.

Metal layers are used because a complex design has many signals crossing each other. Multiple routing layers allow the router to connect many nets without creating shorts.

In this project, the routing report showed:

     Wire length = 45024
     Vias        = 10347

The wire length indicates the total routed interconnect length reported by the tool. The via count indicates how many layer-to-layer metal connections were used during routing.

Routing Violations

During routing, the tool must avoid physical violations. Some important routing violations are:

1. Short Violations

A short violation occurs when two nets that should be electrically separate accidentally touch each other.

This is a serious error because it changes the functionality of the circuit.

For example, if two unrelated signals are shorted, the chip may behave incorrectly or fail completely.

In this project:

     Short violations = 0

This means no unintended electrical shorts were reported.

Metal Spacing Violations

A metal spacing violation occurs when two metal wires are placed too close to each other.

Manufacturing rules require a minimum spacing between wires. If wires are too close, they may short during fabrication or suffer from reliability issues.

In this project:

     Metal spacing violations = 0

This means the routed wires satisfied the checked spacing rules.

Off-Grid Violations

Routing tracks are usually defined on a legal manufacturing grid. An off-grid violation occurs when a wire or via is placed outside the allowed routing grid.

This can make the layout difficult or invalid to manufacture.

In this project:

     Off-grid violations = 0

This means the routed shapes were aligned to valid routing locations.

TritonRoute Violations

TritonRoute violations refer to routing violations reported by the detailed router.

A clean TritonRoute result means the detailed router completed successfully without reported routing errors.

In this project:

     TritonRoute violations = 0

This indicates that detailed routing completed cleanly.

<img width="1482" height="102" alt="image" src="https://github.com/user-attachments/assets/f8f38a75-6c10-472a-948d-b0c86c0b7dd6" />


<img width="232" height="90" alt="image" src="https://github.com/user-attachments/assets/1df46c3b-3ae2-4c33-8038-c4ad9cf22b5b" />


Routing has a major impact on timing, power, area, and physical correctness.

Long wires increase parasitic resistance and capacitance. This can increase signal delay and switching power. Routing congestion can force signals to take detours, which can further increase wire length and delay.

Poor routing can cause:

     timing violations
     short circuits
     metal spacing violations
     antenna violations
     higher parasitic delay
     higher dynamic power

Final Routing Metrics : 

<img width="490" height="255" alt="image" src="https://github.com/user-attachments/assets/0187eac6-fe06-4c4d-a3ef-516b14645be2" />

<a id="sta"></a>
6.Static Timing Analysis

Static Timing Analysis, usually called STA, is the stage where the design is checked to confirm whether it can operate correctly at the target clock period.

After routing, the physical design contains actual standard-cell locations, routed wires, vias, and the inserted clock tree. At this point, the design is no longer just a logical netlist. It has physical interconnects, and those interconnects introduce real delay due to wire resistance and capacitance.

STA analyzes the timing of the routed design without applying simulation input vectors. Instead of running test cases, it mathematically checks timing paths across the circuit using the gate delays, wire delays, clock delays, and timing constraints.

The main goal of STA is to answer this question:

Can the design operate correctly at the target clock period?

For this project, the target clock period was:
     
     20 ns

This corresponds to a target frequency of:

     50 MHz

Tool Used inside OpenLane

Static Timing Analysis is mainly performed using:
     
     OpenSTA

inside the OpenLane flow.

OpenSTA analyzes the gate-level netlist along with timing models from the SKY130 standard-cell library. After routing, it also considers extracted parasitic information from the physical interconnects.

The STA stage uses:

     gate-level netlist
     clock constraints
     SKY130 Liberty timing files
     routed physical design
     extracted parasitics
     clock tree information

The Liberty files from the sky130_fd_sc_hd library contain timing information for every standard cell. This includes cell delay, setup time, hold time, transition behavior, and output load characteristics.

Significance of STA

Timing must be checked after routing because routing adds wire delay.

Before routing, timing estimates are less accurate because the exact metal wire lengths are not fully known. After routing, the tool knows the actual physical paths of the wires and the number of vias used. This allows more accurate timing analysis.

Routing can affect timing because:

longer wires increase delay
wires add parasitic resistance and capacitance
vias add extra resistance and delay
clock tree insertion changes clock arrival times
routing detours can increase path delay

Therefore, even if a design looks fine after synthesis or placement, it still needs post-routing STA to confirm that the final physical implementation meets timing.

In a synchronous pipelined design, most important timing paths are register-to-register paths.

A typical timing path looks like:

launch register → combinational logic → capture register

The launch register sends data on one clock edge. The data then passes through combinational logic and must reach the capture register before the next relevant clock edge.

For this floating-point adder, examples of register-to-register paths may exist between pipeline stages, such as:

Because the design is pipelined, the floating-point addition operation is divided across multiple clock cycles. This reduces the amount of combinational logic in each stage and helps the design meet timing.

Setup Timing

Setup timing checks whether data arrives at the capture register early enough before the next active clock edge.

A setup check asks:

Does the data reach the destination register before the next clock edge?

If the data arrives too late, the capture register may not capture the correct value. This is called a setup violation.

Setup timing depends on:

     clock period
     launch clock delay
     capture clock delay
     combinational logic delay
     wire delay
     setup time of the capture flip-flop
     clock uncertainty

A positive setup slack means the data arrives in time.

A negative setup slack means the design fails setup timing.

In this project, the worst setup slack was:

     Worst setup slack = 4.74 ns

This means that even on the worst setup path, the data arrived with 4.74 ns of margin before the required time. Therefore, the design passed setup timing at the 20 ns clock period.

Hold Timing

Hold timing checks whether data remains stable long enough after the active clock edge.

A hold check asks:

Does the data stay stable long enough after the clock edge?

If data changes too quickly after the clock edge, the capture register may accidentally capture the new value instead of the intended old value. This is called a hold violation.

Hold timing is different from setup timing because hold timing is not fixed by simply increasing the clock period. Hold violations usually need physical fixes such as delay insertion, buffer insertion, or clock/data path adjustment.

A positive hold slack means the data remains stable long enough.

A negative hold slack means the design fails hold timing.

In this project, the worst hold slack was:
     
     Worst hold slack = 0.14 ns

This means that the design had a small but positive hold margin, so there were no hold violations.

WNS and TNS

Two important STA metrics are WNS and TNS.

WNS: Worst Negative Slack

It reports the worst slack among all timing paths. If WNS is negative, at least one timing path has failed.

In this project:

     WNS = 0.00

This indicates that there were no negative-slack timing paths reported.

TNS: Total Negative Slack

TNS stands for Total Negative Slack.

It is the sum of all negative slack values across failing paths. If many paths are failing, TNS becomes more negative.

In this project:

     TNS = 0.00

This means that the design had no accumulated timing violations.

Together, WNS = 0.00 and TNS = 0.00 indicate clean timing signoff.

Critical Path

The critical path is the slowest timing path in the design. It limits the maximum clock frequency that the design can safely achieve.

In this project, the reported critical path was:

     Critical path = 5.47 ns

This means the longest data path delay reported in the design was around 5.47 ns.

Since the target clock period was 20 ns, the critical path was comfortably below the clock period. This helped the design achieve positive setup slack.

STA Metrics :

<img width="412" height="542" alt="image" src="https://github.com/user-attachments/assets/6df4a98d-165d-4f32-bf66-8e17f7f31096" />

Multiple STA summary reports were generated because OpenLane analyzes the routed design under different extracted RC conditions such as minimum, nominal, and maximum parasitic cases. These reports model how interconnect resistance and capacitance can affect timing after routing.

The maximum RC case is usually more critical for setup timing because larger parasitics increase data path delay. The minimum RC case is usually more critical for hold timing because smaller parasitics allow data to propagate faster.

Across all STA reports, `WNS = 0.00` and `TNS = 0.00`, indicating that there were no negative-slack timing paths. The smallest setup slack was `4.74 ns`, and the smallest hold slack was `0.14 ns`. Since both values are positive, the design passed timing at the target `20 ns` clock period.

WNS  = 0.00
TNS  = 0.00
Worst Setup Slack = 4.74 ns
Worst Hold Slack  = 0.14 ns

<a id="power-analysis"></a>
7. Power Analysis : 

Post-routing power analysis was performed as part of the OpenLane signoff flow. The report provides internal power, switching power, leakage power, and total power across multiple timing corners.

A timing corner represents a different operating condition used during ASIC signoff. These corners model how the chip may behave under different process, voltage, and temperature conditions.

In simple terms:

Fastest Corner  = transistors and interconnect behave faster than typical
Typical Corner  = normal expected operating condition
Slowest Corner  = transistors and interconnect behave slower than typical

Power changes across these corners because transistor speed, leakage, voltage assumptions, and switching behavior can vary depending on the operating condition. Therefore, checking power across multiple corners gives a more complete view of the design than using only one condition.

| Term | Meaning |
|---|---|
| Fastest Corner | Transistors and interconnect behave faster than typical |
| Typical Corner | Normal expected operating condition |
| Slowest Corner | Transistors and interconnect behave slower than typical |
| Internal Power | Power consumed inside standard cells during switching |
| Switching Power | Power consumed while charging and discharging nets/wires |
| Leakage Power | Power consumed even when transistors are not actively switching |
| Total Power | Internal power + switching power + leakage power |

| Power Corner | Internal Power | Switching Power | Leakage Power | Total Power |
|---|---:|---:|---:|---:|
| Fastest Corner | `1.06 mW` | `0.987 mW` | `0.0000144 mW` | `2.05 mW` |
| Slowest Corner | `0.760 mW` | `0.654 mW` | `0.00855 mW` | `1.42 mW` |
| Typical Corner | `0.947 mW` | `0.776 mW` | `0.00000959 mW` | `1.78 mW` |

<img width="912" height="892" alt="image" src="https://github.com/user-attachments/assets/d117f784-7283-44cb-b581-4ce6a984fa63" />

<a id="physical-verification"></a>
8. Physical Verification and Signoff:

After synthesis, floorplanning, placement, clock tree synthesis, routing, and timing analysis, the design must still be checked for physical correctness. A design can be logically correct and timing-clean, but it may still fail if the final layout violates manufacturing rules or does not electrically match the intended circuit.

Physical verification is the stage where the final routed layout is checked against the rules of the target fabrication process. Since this project uses the SKY130 PDK, the final layout must satisfy SKY130 design rules and signoff requirements.

The main physical verification checks performed in this project were:

1. DRC - Design Rule Check(Whether the layout follows SKY130 manufacturing rules)
2. LVS - Layout Versus Schematic(Whether the physical layout matches the intended netlist)
3. Antenna Check(Whether long metal wires can damage transistor gates during fabrication)

Design Rule Check

Design Rule Check, or DRC, verifies whether the final physical layout follows the manufacturing rules of the selected process technology.

Every semiconductor process has strict layout rules. These rules define how close metal wires can be, how wide wires must be, how vias should be placed, how much enclosure is required, and how different layers must interact.

For the SKY130 process, these rules are provided by the SKY130 PDK.

DRC checks rules such as:

     minimum metal width
     minimum metal spacing
     minimum via enclosure
     minimum area rules
     minimum hole rules
     off-grid geometry rules
     contact and via placement rules

These rules are important because the chip has to be manufacturable. If the layout violates design rules, the fabricated chip may have shorts, opens, reliability issues, or may fail during manufacturing.

In simple terms:

DRC checks whether the layout can be manufactured correctly.

In OpenLane, DRC is mainly performed using: Magic

Magic uses the SKY130 technology rule files to check the final layout. It analyzes the generated physical layout and reports any design rule violations.

The final DRC report showed:

     DRC COUNT: 0

This means that the final routed layout had zero reported DRC violations.

The result confirms that the generated layout satisfies the checked SKY130 physical design rules.

Layout Versus Schematic

Layout Versus Schematic, or LVS, checks whether the physical layout electrically matches the intended circuit.

After routing, the design exists as a physical layout containing standard cells, wires, vias, pins, and metal connections. However, it is possible for a layout to be physically clean but electrically incorrect. For example, a signal may be accidentally disconnected, two nets may be shorted, or a pin connection may not match the synthesized netlist.

LVS prevents this by comparing two versions of the design:

     1. The reference netlist generated from synthesis
     2. The netlist extracted from the final physical layout

If both netlists match, then the physical layout correctly represents the intended circuit.

LVS checks for mismatches such as:

     missing nets
     extra nets
     shorted nets
     open connections
     wrong pin connections
     device mismatches
     property mismatches
     incorrect cell connections

For a standard-cell digital design, LVS ensures that the final physical connections match the gate-level netlist produced after synthesis and implementation.

This is important because the final GDS should not just look correct. It must also behave like the original circuit.

In OpenLane, LVS is mainly performed using: Netgen

The final LVS report showed:
     
     Total errors = 0

The report also indicated that there were no net, device, pin, or property mismatches.

This means the physical layout matched the intended gate-level circuit.

Antenna Check:

Antenna checking verifies whether long metal wires connected to transistor gates can collect excessive charge during chip fabrication.

During fabrication, metal layers are formed step by step using plasma-based processes. Long metal wires can accumulate charge while they are being manufactured. If this charge is connected to a thin MOS gate oxide, it can damage the transistor gate.

This problem is called the antenna effect.

Antenna violations are not usually logical RTL problems. They are physical manufacturing problems that appear after placement and routing.

Antenna violations usually happen when a long metal wire is connected to a sensitive transistor gate before there is a safe discharge path.

The longer the metal wire connected to the gate, the more charge it can collect during fabrication.

This can cause:
     
     gate oxide damage
     transistor reliability issues
     manufacturing failure
     reduced chip yield

Therefore, antenna rules are checked after routing.

In the initial OpenLane run, the design did not pass antenna signoff. The antenna report showed violations after routing:

Pin antenna violations = 2
Net antenna violations = 2

This meant that some routed nets had antenna ratios exceeding the allowed SKY130 antenna rules. These were not RTL or functional simulation errors. The floating-point adder logic itself was still correct, but the physical layout needed additional protection against fabrication-related antenna effects.

To fix this, heuristic diode insertion was enabled in the OpenLane configuration:

set ::env(DIODE_INSERTION_STRATEGY) 3
set ::env(RUN_HEURISTIC_DIODE_INSERTION) 1

The important setting was:

set ::env(RUN_HEURISTIC_DIODE_INSERTION) 1

This allowed OpenLane to insert additional antenna protection diodes during the physical implementation flow. These diode cells provide safe discharge paths for charge that may accumulate on long metal wires during fabrication.

Before enabling heuristic diode insertion, only a small number of diode cells were inserted. After enabling it, the final design contained:

     Diode Cells = 581

The increase in diode cells was expected because OpenLane inserted additional physical protection cells to resolve the antenna violations. These diode cells do not change the logical functionality of the floating-point adder. They are physical-only protection cells added to make the layout safe for fabrication.

After enabling heuristic diode insertion and rerunning the flow, the final antenna results were:

     Pin antenna violations = 0
     Net antenna violations = 0

This means the final routed design passed antenna checks.

The antenna issue was therefore successfully resolved:

     Initial run  : 2 pin antenna violations, 2 net antenna violations
     Final run    : 0 pin antenna violations, 0 net antenna violations
     Fix applied  : Heuristic diode insertion enabled


<img width="457" height="277" alt="image" src="https://github.com/user-attachments/assets/dd328cc5-f751-48e9-a098-553802eb5836" />


Physical verification is one of the most important parts of the ASIC flow because it proves that the final layout is not only functionally and timing correct, but also physically valid.

A design is not considered complete only because GDS is generated. The GDS must also pass signoff checks.

For this project, the final OpenLane run passed:

     timing signoff
     DRC signoff
     LVS signoff
     antenna signoff

This means the 4-stage pipelined IEEE-754 floating-point adder was successfully converted from RTL into a physically verified ASIC layout.

Metrics Summarized  : 

| Metric | Value |
|---|---:|
| Target Clock Period | `20 ns` |
| Target Frequency | `50 MHz` |
| Critical Path Delay | `5.47 ns` |
| Estimated Maximum Frequency from Critical Path | `~182.8 MHz` |
| Worst Setup Slack | `4.74 ns` |
| Worst Hold Slack | `0.14 ns` |
| WNS | `0.00 ns` |
| TNS | `0.00 ns` |
| Die Area | `0.041732 mm²` |
| Core Area | `35223.7824 µm²` |
| Core Utilization Setting | `35%` |
| OpenDP Utilization | `36.28%` |
| Synthesized Logic Cells | `1,250` |
| Total Cells | `5,459` |
| Non-Physical Cells | `1,406` |
| Fill Cells | `1,089` |
| Decap Cells | `1,886` |
| Welltap Cells | `497` |
| Antenna Diode Cells | `581` |
| Routed Wire Length | `45,024` |
| Vias | `10,347` |
| DRC Violations | `0` |
| LVS Errors | `0` |
| Pin Antenna Violations | `0` |
| Net Antenna Violations | `0` |

<a id="final-gds"></a>
GDSII Generation and Output Files

After the design passed synthesis, floorplanning, placement, clock tree synthesis, routing, static timing analysis, DRC, LVS, and antenna checks, OpenLane generated the final ASIC implementation outputs.

The most important final output of the RTL-to-GDSII flow is the GDSII file.

GDSII is the standard file format used to represent the final physical layout of an ASIC. It contains the geometric shapes for the different layers of the chip, including standard cells, metal layers, vias, routing shapes, pins, and other physical layout structures.

In simple terms:

     RTL describes what the circuit should do.
     
     Gate-level netlist describes which standard cells are used.
     
     DEF describes where cells are placed and how routing is represented.
     
     GDSII describes the final physical layout that can be used for fabrication.

Therefore, GDSII generation is the final major output stage of the ASIC flow. It confirms that the design has been converted from a Verilog RTL description into a physical layout database.

Final output generation is handled by OpenLane using the physical design and verification tools inside the flow.

The main tools involved are:

     OpenROAD
     Magic
     KLayout

OpenROAD generates the placed and routed physical design database and DEF files. Magic and KLayout are used in the final layout generation, checking, and viewing stages. Magic is also used for layout-related signoff tasks such as DRC and extraction, while KLayout is useful for visually inspecting the final GDSII layout.

In this project, KLayout was used to open and view the generated fp_adder_top.gds file.

A GDSII file is the final layout file that represents the physical chip geometry.

It contains information about:

     standard-cell layouts
     metal routing layers
     vias between metal layers
     pin shapes
     cell placements
     routing geometry
     physical layer polygons

<img width="730" height="322" alt="image" src="https://github.com/user-attachments/assets/6e3ad953-ee4d-4e03-be1d-de23dc6bcb71" />

     Difference Between Final GDS, DEF, and Gate-Level Netlist
     
     The final output files represent the design in different forms.
     
     Gate-Level Netlist
     
     The gate-level netlist is a Verilog file that shows the design as a connection of standard cells.
     
     It answers:
     
     Which logic cells are used?
     How are the cells connected?
     
     This file is useful for logic-level verification and for understanding the mapped standard-cell implementation.
     
     DEF File
     
     The DEF file contains physical design information such as placement, routing, pins, and design dimensions.
     
     It answers:
     
     Where are the cells placed?
     Where are the pins located?
     How are the nets routed?
     
     DEF is useful for physical design tools and intermediate backend stages.
     
     GDSII File
     
     The GDSII file is the final layout database containing actual physical geometry.
     
     It answers:
     
     What does the final chip layout physically look like?
     What polygons exist on each manufacturing layer?
     
This is the final layout file viewed in KLayout.


<img width="1162" height="873" alt="Screenshot 2026-06-24 174857" src="https://github.com/user-attachments/assets/ccd9edf2-45da-48c4-8cf2-47423d6610f9" />

<a id="final-results"></a>
Output Summary

| Output / Check | Status |
|---|---|
| Final GDSII | Generated |
| Final DEF | Generated |
| Final Gate-Level Netlist | Generated |
| KLayout View | Verified |
| Timing Signoff | Passed |
| DRC Signoff | Passed |
| LVS Signoff | Passed |
| Antenna Signoff | Passed |


The successful generation of the final GDSII layout, along with clean timing, DRC, LVS, and antenna reports, confirms that the floating-point adder was successfully implemented as a physically verified ASIC layout using OpenLane and the SKY130 PDK.

Some Additional info : 

Overclocking Potential

The design was constrained and verified at a target clock period of 20 ns, corresponding to an operating frequency of 50 MHz. Static Timing Analysis reported positive setup and hold slack, meaning the design successfully met timing at the target frequency.

The worst setup slack was:
     
     Worst Setup Slack = 4.74 ns

This indicates that the design had additional setup timing margin at the 20 ns clock period. A conservative estimate of the next possible clock period can be calculated by subtracting the worst setup slack from the original clock period:

     Estimated tighter clock period = 20 ns - 4.74 ns = 15.26 ns

This corresponds to an estimated frequency of:

     Estimated frequency = 1 / 15.26 ns ≈ 65.5 MHz

Therefore, based on setup slack, the design shows potential frequency headroom beyond the verified 50 MHz target.

The timing report also showed a critical path delay of approximately 5.47 ns. Based only on this critical path delay, the theoretical maximum frequency would be:

     fmax = 1 / 5.47 ns ≈ 182.8 MHz

However, this should be treated only as a theoretical estimate. The design has been fully verified only at 50 MHz. To claim a higher operating frequency, the complete OpenLane flow should be rerun with a tighter clock constraint, followed by clean STA, DRC, LVS, and antenna signoff.

A technically safe conclusion is:
     
     Verified operating frequency: 50 MHz
     Conservative frequency estimate from setup slack: ~65.5 MHz
     Theoretical critical-path estimate: ~182.8 MHz

Higher-frequency operation is possible, but it must be validated through a new timing-driven implementation run.


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


*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~ PROJECT DONE UNDER THE ACM SMP UMBRELLA [DIGITAL-D2] *~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~

~veer
