# Timing constraints for Xilinx Artix-7 (xc7a35t or xc7a100t)
# Target: 100 MHz (10 ns period)
# Adjust PACKAGE_PIN if targeting a specific board (e.g. Basys3, Nexys A7)

# Primary clock constraint — this is what drives Fmax reporting
create_clock -period 15.000 -name clk -waveform {0.000 7.500} [get_ports clk]

# Input delay constraints (assume inputs arrive 2ns after clock edge)
set_input_delay -clock clk 2.0 [get_ports rst]

# Output delay constraints (outputs must be stable 2ns before next edge)
set_output_delay -clock clk 2.0 [get_ports pc_out]
set_output_delay -clock clk 2.0 [get_ports instr_count_out]
set_output_delay -clock clk 2.0 [get_ports stall_count_out]
set_output_delay -clock clk 2.0 [get_ports flush_count_out]

# False path on reset (async reset doesn't need timing analysis)
set_false_path -from [get_ports rst]
