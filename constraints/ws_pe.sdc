# bully quartus by making it try to close timing at >150MHz
create_clock -name clk_i -period 6.75 [get_ports clk_i]

derive_clock_uncertainty