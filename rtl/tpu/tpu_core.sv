`resetall
`timescale 1ns/1ps
`default_nettype none

import tpu_pkg::*;

module tpu_core (
	// 50 MHz crystal clock
	input  wire        refclk_i          ,
	input  wire        rstn_i            , 

	// Status Out
	output wire [3:0]  design_instr_o    ,
	output wire        pll_lock_o		 ,

	// RGMII Pins
	output wire        ENET1_GTX_CLK     ,
	output wire        ENET1_TX_EN       ,
	output wire [ 3:0] ENET1_TX_DATA     ,
	input  wire        ENET1_RX_CLK      ,
	input  wire        ENET1_RX_DV       ,
	input  wire [ 3:0] ENET1_RX_DATA	 ,
	output wire        ENET1_RST_N
);


// AXI-S Interfaces
axis_if udp_rx_stream(.clk(compute_clk), .rstn(rstn_compute_clk));
axis_if udp_tx_stream(.clk(compute_clk), .rstn(rstn_compute_clk));

////////////// SIMPLE LOOPBACK FOR NOW ///////////////////
// Pass the data and control signals from RX to TX
assign udp_tx_stream.tdata  = udp_rx_stream.tdata;
assign udp_tx_stream.tvalid = udp_rx_stream.tvalid;
assign udp_tx_stream.tlast  = udp_rx_stream.tlast;
assign udp_tx_stream.tuser  = udp_rx_stream.tuser;
// Pass the backpressure (ready) from TX back to RX
assign udp_rx_stream.tready = udp_tx_stream.tready;
/////////////////////////////////////////////////////////

// Internal Clocks and Resets
wire comms_clk, comms_clk_90, compute_clk;
wire rstn_comms_clk, rstn_compute_clk;

//// CLOCK AND RESET GENERATION
tpu_clkgen I_tpu_clkgen (
	.refclk_i          (refclk_i),
	.rstn_i            (rstn_i),
	.pll_lock_o        (pll_lock_o),
	// Generated Clocks
	.comms_clk_o       (comms_clk),
	.comms_clk_90_o    (comms_clk_90),
	.compute_clk_o     (compute_clk),
	// Synchronoized Resets
	.rstn_comms_clk_o  (rstn_comms_clk),
	.rstn_compute_clk_o(rstn_compute_clk)
);

//// ETHERNET STACK
comms_core I_comms (
	.clk_125_i         (comms_clk            ),
	.clk_125_90_i      (comms_clk_90         ),
	.rstn_clk_125_i    (rstn_comms_clk       ),
	.compute_clk_i     (compute_clk          ),
	.rstn_compute_clk_i(rstn_compute_clk     ),
	.design_instr_o    (design_instr_o       ),
	.udp_rx_stream     (udp_rx_stream        ),
	.udp_tx_stream     (udp_tx_stream        ),
	.ENET1_GTX_CLK     (ENET1_GTX_CLK        ),
	.ENET1_TX_EN       (ENET1_TX_EN          ),
	.ENET1_TX_DATA     (ENET1_TX_DATA        ),
	.ENET1_RX_CLK      (ENET1_RX_CLK         ),
	.ENET1_RX_DV       (ENET1_RX_DV          ),
	.ENET1_RX_DATA     (ENET1_RX_DATA         )
);

//// Systolic Array
// TODO: Instantiate this thing


assign ENET1_RST_N = 1'b1;

endmodule : tpu_core

`default_nettype wire