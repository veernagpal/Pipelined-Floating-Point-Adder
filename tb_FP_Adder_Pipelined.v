`timescale 1ns/1ps

module tb_FP_Adder_Pipelined;

reg clk;
reg reset;

reg [31:0] a, b;
wire [31:0] result;

integer infile;
integer outfile;
integer scan_status;

integer input_count;
integer output_count;
integer cycle_count;

parameter PIPELINE_LATENCY = 3;

fp_adder_top dut (
    .clk(clk),
    .reset(reset),
    .a(a),
    .b(b),
    .result(result)
);

// Clock generation: 10 ns clock period
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    infile  = $fopen("stimulus.txt", "r");
    outfile = $fopen("rtl_results_pipelined.txt", "w");

    if (infile == 0) begin
        $display("ERROR: Could not open stimulus.txt");
        $finish;
    end

    if (outfile == 0) begin
        $display("ERROR: Could not open rtl_results_pipelined.txt");
        $finish;
    end

    a = 32'b0;
    b = 32'b0;

    input_count = 0;
    output_count = 0;
    cycle_count = 0;

    reset = 1;
    repeat (3) @(posedge clk);
    reset = 0;

    scan_status = 2;

    while (scan_status == 2) begin

        // Apply next input before the active clock edge
        @(negedge clk);

        scan_status = $fscanf(infile, "%h %h\n", a, b);

        if (scan_status == 2) begin
            input_count = input_count + 1;
        end

        // DUT captures input at posedge
        @(posedge clk);

        // Wait small time so result settles after clock edge
        #1;

        cycle_count = cycle_count + 1;

        // Ignore first 3 cycles, then capture real outputs
        if ((cycle_count >= PIPELINE_LATENCY) && (output_count < input_count)) begin
            $fwrite(outfile, "%08h\n", result);
            output_count = output_count + 1;
        end
    end

    // Stop giving meaningful inputs
    @(negedge clk);
    a = 32'b0;
    b = 32'b0;

    // Flush remaining pipeline outputs
    while (output_count < input_count) begin
        @(posedge clk);
        #1;

        cycle_count = cycle_count + 1;

        $fwrite(outfile, "%08h\n", result);
        output_count = output_count + 1;
    end

    $display("Inputs given     : %0d", input_count);
    $display("Outputs captured : %0d", output_count);
    $display("Results written to rtl_results_pipelined.txt");

    $fclose(infile);
    $fclose(outfile);

    $finish;
end

endmodule