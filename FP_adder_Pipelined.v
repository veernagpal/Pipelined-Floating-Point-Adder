// fp_adder_top.v
// ├── unpack.v
// ├── exponent_compare.v
// ├── align_mantissa.v
// ├── mantissa_arithmetic.v
// ├── normalize.v
// └── pack.v

module fp_adder_top(clk, reset, a, b, result);
input clk, reset;
input [31:0] a, b;
output [31:0] result;

// stage 1: unpack + exponent_compare
wire sign_in_a;
wire [7:0] exponent_in_a;
wire [23:0] mantissa_in_a;
unpack unpack_muu_A(.fp_in(a), .sign_in(sign_in_a), .mantissa_in(mantissa_in_a), .exponent_in(exponent_in_a));

wire sign_in_b;
wire [7:0] exponent_in_b;
wire [23:0] mantissa_in_b;
unpack unpack_muu_B(.fp_in(b), .sign_in(sign_in_b), .mantissa_in(mantissa_in_b), .exponent_in(exponent_in_b));

wire sign_larger,sign_smaller;
wire [23:0] mant_larger,mant_smaller;
wire [7:0] exp_larger,exp_smaller,exp_diff;
exponent_compare exponent_compare_muu(.exp_a(exponent_in_a),.exp_b(exponent_in_b),.mant_a(mantissa_in_a),
                                      .mant_b(mantissa_in_b),.sign_a(sign_in_a),.sign_b(sign_in_b),
                                      .exp_larger(exp_larger),.exp_smaller(exp_smaller),.mant_larger(mant_larger),
                                      .mant_smaller(mant_smaller),.sign_larger(sign_larger),.sign_smaller(sign_smaller),.exp_diff(exp_diff));

// pipeline register 1
wire [7:0] exp_larger_1, exp_smaller_1, exp_diff_1;
wire [23:0] mant_larger_1, mant_smaller_1;
wire sign_larger_1, sign_smaller_1;
pipeline_register1 preg1(.clk(clk), .reset(reset),
    .exp_larger_1_in(exp_larger), .exp_smaller_1_in(exp_smaller),
    .mant_larger_1_in(mant_larger), .mant_smaller_1_in(mant_smaller),
    .sign_larger_1_in(sign_larger), .sign_smaller_1_in(sign_smaller),
    .exp_diff_1_in(exp_diff), .exp_larger_1_out(exp_larger_1), .exp_smaller_1_out(exp_smaller_1),
    .mant_larger_1_out(mant_larger_1), .mant_smaller_1_out(mant_smaller_1),
    .sign_larger_1_out(sign_larger_1), .sign_smaller_1_out(sign_smaller_1),
    .exp_diff_1_out(exp_diff_1));

// stage 2: align_mantissa
wire [23:0] mant_larger_out, mant_smaller_aligned;
align_mantissa align_mantissa_muu(.mant_larger(mant_larger_1),.mant_smaller(mant_smaller_1),.exp_diff(exp_diff_1),.mant_larger_out(mant_larger_out),.mant_smaller_aligned(mant_smaller_aligned));

// pipeline register 2
wire [23:0] mant_larger_out_2, mant_smaller_aligned_2;
wire sign_larger_2, sign_smaller_2;
wire [7:0] exp_larger_2;
pipeline_register2 preg2(.clk(clk), .reset(reset),
    .mant_larger_out_in_2(mant_larger_out), .mant_smaller_aligned_in_2(mant_smaller_aligned),
    .sign_larger_in_2(sign_larger_1), .sign_smaller_in_2(sign_smaller_1), .exp_larger_in_2(exp_larger_1),
    .mant_larger_out_out_2(mant_larger_out_2), .mant_smaller_aligned_out_2(mant_smaller_aligned_2),
    .sign_larger_out_2(sign_larger_2), .sign_smaller_out_2(sign_smaller_2), .exp_larger_out_2(exp_larger_2));

// stage 3: mantissa_arithmetic
wire [24:0] mant_result; 
wire sign_result;
wire [7:0] exp_result;
mantissa_arithmetic mantissa_arithmetic_muu(.mant_a(mant_larger_out_2),.mant_b(mant_smaller_aligned_2),.sign_a(sign_larger_2),.sign_b(sign_smaller_2),.exp_larger(exp_larger_2),.mant_result(mant_result),.sign_result(sign_result),.exp_result(exp_result));

// pipeline register 3
wire [24:0] mant_result_3;
wire sign_result_3;
wire [7:0] exp_result_3;
pipeline_register3 preg3(.clk(clk), .reset(reset),
    .mant_result_in_3(mant_result), .sign_result_in_3(sign_result), .exp_result_in_3(exp_result),
    .mant_result_out_3(mant_result_3), .sign_result_out_3(sign_result_3), .exp_result_out_3(exp_result_3));

// stage 4: normalize + pack
wire [22:0] mant_out;
wire [7:0] exp_out;
wire sign_out;
normalize normalize_muu(.mant_in(mant_result_3),.exp_in(exp_result_3),.sign_in(sign_result_3),.mant_out(mant_out),.exp_out(exp_out),.sign_out(sign_out));

pack pack_muu(.sign_out(sign_out),.mantissa_out(mant_out),.exponent_out(exp_out),.fp_out(result));

endmodule


module unpack(fp_in, sign_in, mantissa_in, exponent_in);
input [31:0] fp_in;
output sign_in;
output [7:0] exponent_in;
output [23:0] mantissa_in;

assign sign_in = fp_in[31];  
assign exponent_in = fp_in[30:23];
assign mantissa_in = (fp_in[30:23] == 8'd0) ? {1'b0, fp_in[22:0]} : {1'b1, fp_in[22:0]};

endmodule

module exponent_compare(exp_a,exp_b,mant_a,mant_b,sign_a,sign_b,exp_larger,exp_smaller,mant_larger,mant_smaller,sign_larger,sign_smaller,exp_diff);
input sign_a,sign_b;
output reg sign_smaller,sign_larger;
input [23:0] mant_a,mant_b;
output reg [23:0] mant_smaller,mant_larger;
input [7:0] exp_a,exp_b;
output reg [7:0] exp_smaller,exp_larger;
output reg [7:0] exp_diff;

always @ (*) begin
    if(exp_a >= exp_b) begin
        sign_larger = sign_a;
        sign_smaller = sign_b;
        exp_larger = exp_a;
        exp_smaller = exp_b;
        mant_larger = mant_a;
        mant_smaller = mant_b;
        exp_diff = exp_a - exp_b;
    end

    else begin
        sign_larger = sign_b;
        sign_smaller = sign_a;
        exp_larger = exp_b;
        exp_smaller = exp_a;
        mant_larger = mant_b;
        mant_smaller = mant_a;
        exp_diff = exp_b - exp_a;
    end
end
endmodule

module pipeline_register1(input clk,input reset,input [7:0] exp_larger_1_in,input [7:0] exp_smaller_1_in,input [23:0] mant_larger_1_in,
                          input [23:0] mant_smaller_1_in,input sign_larger_1_in,input sign_smaller_1_in,input [7:0] exp_diff_1_in,
                          output reg [7:0] exp_larger_1_out,output reg [7:0] exp_smaller_1_out,output reg [23:0] mant_larger_1_out,
                          output reg [23:0] mant_smaller_1_out,output reg sign_larger_1_out,output reg sign_smaller_1_out,
                          output reg [7:0] exp_diff_1_out);

always @ (posedge clk) begin
    if(reset) begin
        exp_larger_1_out <= 0;
        exp_smaller_1_out <= 0;
        mant_larger_1_out <= 0;
        mant_smaller_1_out <= 0;
        sign_larger_1_out <= 0;
        sign_smaller_1_out <= 0;
        exp_diff_1_out <= 0;
    end

    else begin
        exp_larger_1_out <= exp_larger_1_in;
        exp_smaller_1_out <= exp_smaller_1_in;
        mant_larger_1_out <= mant_larger_1_in;
        mant_smaller_1_out <= mant_smaller_1_in;
        sign_larger_1_out <= sign_larger_1_in;
        sign_smaller_1_out <= sign_smaller_1_in;
        exp_diff_1_out <= exp_diff_1_in;
    end
end
endmodule

module align_mantissa(mant_larger,mant_smaller,exp_diff,mant_larger_out,mant_smaller_aligned);
input [23:0] mant_larger, mant_smaller;
input [7:0] exp_diff;
output [23:0] mant_larger_out, mant_smaller_aligned;

assign mant_larger_out = mant_larger;
assign mant_smaller_aligned = mant_smaller >> exp_diff;

endmodule

module pipeline_register2(input clk,input reset,input [23:0] mant_larger_out_in_2,input [23:0] mant_smaller_aligned_in_2, input sign_larger_in_2, input sign_smaller_in_2, input [7:0] exp_larger_in_2,
                          output reg [23:0] mant_larger_out_out_2, output reg [23:0] mant_smaller_aligned_out_2, output reg sign_larger_out_2, output reg sign_smaller_out_2, output reg [7:0] exp_larger_out_2);

always @ (posedge clk) begin
    if(reset) begin
        mant_larger_out_out_2 <= 0;
        mant_smaller_aligned_out_2 <= 0; 
        sign_larger_out_2 <= 0;
        sign_smaller_out_2 <= 0;
        exp_larger_out_2 <= 0;

    end
    else begin
        mant_larger_out_out_2 <= mant_larger_out_in_2 ;
        mant_smaller_aligned_out_2 <= mant_smaller_aligned_in_2;
        sign_larger_out_2 <= sign_larger_in_2;
        sign_smaller_out_2 <= sign_smaller_in_2;
        exp_larger_out_2 <= exp_larger_in_2;
    end
end
endmodule

module mantissa_arithmetic(mant_a,mant_b,sign_a,sign_b,exp_larger,mant_result,sign_result,exp_result);
input [23:0] mant_a,mant_b;
input sign_a,sign_b;
input [7:0] exp_larger;

output reg [24:0] mant_result; //to accomodate for carry if occurs when performing the mantissa arithmetic
output reg sign_result;
output [7:0] exp_result;

assign exp_result = exp_larger;

always @ (*) begin
    if(sign_a == sign_b) begin
        mant_result = mant_a + mant_b;
        sign_result = sign_a;
    end

    else if(mant_a >= mant_b) begin
        mant_result = mant_a - mant_b;
        sign_result = sign_a;
    end

    else begin
        mant_result = mant_b - mant_a;
        sign_result = sign_b;
    end
end

endmodule

module pipeline_register3(input clk, input reset, input [24:0] mant_result_in_3, input sign_result_in_3, input [7:0] exp_result_in_3,
                          output reg [24:0] mant_result_out_3, output reg sign_result_out_3, output reg [7:0] exp_result_out_3);
always @ (posedge clk) begin
    if(reset) begin
        mant_result_out_3 <= 0;
        sign_result_out_3 <= 0;
        exp_result_out_3 <= 0;
    end
    else begin
        mant_result_out_3 <= mant_result_in_3;
        sign_result_out_3 <= sign_result_in_3;
        exp_result_out_3  <= exp_result_in_3;
    end
end
endmodule

module normalize(mant_in,exp_in,sign_in,mant_out,exp_out,sign_out);

input[24:0] mant_in;
input [7:0] exp_in;
input sign_in;

output reg [22:0] mant_out;
output reg [7:0] exp_out;
output reg sign_out;

reg [24:0] mant;
reg [4:0] shift;
integer i;

always @ (*) begin
    mant = mant_in;
    exp_out = exp_in;
    sign_out = sign_in;
    shift = 0;

    if (mant == 0) begin
        mant_out = 0;
        exp_out  = 0;
        sign_out = 0;
    end

    else begin
        if (mant[24] == 1'b1) begin
            mant = mant >> 1;
            exp_out = exp_out + 1;
        end
        else begin
        //counting the number of leading zeros in the mantissa - this determines the shift amount
        for(i=0 ; i<24 ; i=i+1) begin
            if(mant[i] == 1'b1) 
                shift = 23 - i;
        end

        mant = mant << shift;
        if (exp_out > shift)
            exp_out = exp_out - shift;

        else
            exp_out = 0;
        end
        mant_out = mant[22:0]; //removing the hidden implicit 1 bit
    end
end
endmodule

module pack(sign_out,mantissa_out,exponent_out,fp_out);
input sign_out;
input [7:0] exponent_out;
input [22:0] mantissa_out;
output [31:0] fp_out;
assign fp_out = {sign_out,exponent_out,mantissa_out};

endmodule

// COMMANDS TO RUN THE PYTHON TESTING ENVIRONMENT : 
// cd C:\Users\veern\Desktop\Veer\NITK_ECE_BTech\Projects_ExtraCourses\Floating_Point_Adder_RTL2ASIC
// python stimuli_generation.py
// iverilog -o fp_pipelined_test.out .\FP_Adder_Pipelined.v .\tb_FP_Adder_Pipelined.v
// vvp fp_pipelined_test.out
// python test_pipelined.py




//BRUTE FORCE TESTBENCH
// `timescale 1ns/1ps

// module tb;

// reg clk;
// reg reset;

// reg [31:0] a,b;
// wire [31:0] result;

// fp_adder_top dut (
//     .clk(clk),
//     .reset(reset),
//     .a(a),
//     .b(b),
//     .result(result)
// );

// initial begin
//     clk = 0;
//     forever #5 clk = ~clk;
// end

// initial begin

//     $dumpfile("wave.vcd");
//     $dumpvars(0,tb);

//     reset = 1;
//     a = 0;
//     b = 0;

//     #25;
//     reset = 0;

//     @(posedge clk);
//     a <= 32'h3F800000;  // 1.0
//     b <= 32'h40000000;  // 2.0
//                         // Expected = 3.0 (0x40400000)

//     @(posedge clk);
//     a <= 32'h40400000;  // 3.0
//     b <= 32'h40800000;  // 4.0
//                         // Expected = 7.0 (0x40E00000)

//     @(posedge clk);
//     a <= 32'h3F000000;  // 0.5
//     b <= 32'h3F800000;  // 1.0
//                         // Expected = 1.5 (0x3FC00000)

//     @(posedge clk);
//     a <= 32'hBF800000;  // -1.0
//     b <= 32'h3F800000;  // +1.0
//                         // Expected = 0.0 (0x00000000)

//     @(posedge clk);
//     a <= 32'h41200000;  // 10.0
//     b <= 32'hC0500000;  // -3.25
//                         // Expected = 6.75 (0x40D80000)

//     @(posedge clk);
//     a <= 0;
//     b <= 0;

//     #100;
//     $finish;

// end

// endmodule