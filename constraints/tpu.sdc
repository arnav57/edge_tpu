#################### CLOCKS ####################
## define clocks
create_clock -name REFCLK_CLK   -period 20.00 [get_ports {refclk_i}]
create_clock -name RGMII_RX_CLK -period 8.000 [get_ports {ENET1_RX_CLK}]

## derive the generated clocks (like compute clk)
derive_pll_clocks
derive_clock_uncertainty