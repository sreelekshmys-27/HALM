# ============================================================
# constraints.sdc
# Timing constraints for streamlined_halm_multiplier

# ============================================================

set CLK_PERIOD_NS 1.667

create_clock -name clk -period $CLK_PERIOD_NS [get_ports clk]

# Reasonable defaults -- tune to your actual board/interface assumptions
set_input_delay  -clock clk [expr $CLK_PERIOD_NS * 0.2] [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk [expr $CLK_PERIOD_NS * 0.2] [all_outputs]

set_clock_uncertainty 0.05 [get_clocks clk]
set_clock_transition   0.03 [get_clocks clk]

# Reset is asynchronous
set_false_path -from [get_ports reset]
