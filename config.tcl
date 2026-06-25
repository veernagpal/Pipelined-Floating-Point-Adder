set ::env(DESIGN_NAME) fp_adder_top

set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

set ::env(CLOCK_PORT) clk
set ::env(CLOCK_PERIOD) 20

set ::env(FP_CORE_UTIL) 35
set ::env(PL_TARGET_DENSITY) 0.45

set ::env(SYNTH_STRATEGY) "AREA 0"

set ::env(DIODE_INSERTION_STRATEGY) 3
set ::env(RUN_HEURISTIC_DIODE_INSERTION) 1
