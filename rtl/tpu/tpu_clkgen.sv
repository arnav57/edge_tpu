`resetall
`timescale 1ns/1ps
`default_nettype none

module tpu_clkgen (

	// Refclk and Async Reset
	input wire refclk_i,
	input wire rstn_i,

	// PLL Status
	output wire pll_lock_o,

	// Generated clocks from PLL
	output wire comms_clk_o,
	output wire comms_clk_90_o,
	output wire compute_clk_o,

	// Synchronized Resets
	output wire rstn_comms_clk_o,
	output wire rstn_compute_clk_o
);

/////////// PLL INSTANTIATION
tpu_pll	tpu_pll_inst (
	.areset  ( ~rstn_i        ),
	.inclk0  ( refclk_i       ),
	.c0      ( comms_clk_o    ), // 125 M
	.c1      ( comms_clk_90_o ), // 125 M (90 deg)
	.c2      ( compute_clk_o  ), // 150 M
	.locked  ( pll_lock_o     )
);

wire rstn_int;
assign rstn_int = rstn_i & pll_lock_o;

///////// RESET SYNCHRONIZERS
std_rstn_sync I_rstn_sync_compute_clk (
	.clk(compute_clk_o), 
	.arstn(rstn_int),
	.orstn(rstn_compute_clk_o)
);

std_rstn_sync I_rstn_sync_comms_clk (
	.clk(comms_clk_o), 
	.arstn(rstn_int),
	.orstn(rstn_comms_clk_o)
);


endmodule : tpu_clkgen

`default_nettype wire