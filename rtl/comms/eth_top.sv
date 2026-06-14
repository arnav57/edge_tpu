`resetall
`timescale 1ns/1ps
`default_nettype none

module eth_top (
	input  wire        clk_125_i         ,
	input  wire        clk_125_90_i      ,
	input  wire        rstn_clk_125_i    ,

	// Our Logic clock
	input  wire        compute_clk_i     ,
	input  wire        rstn_compute_clk_i,

	// Instruction Out
	output wire [3:0]  design_instr_o    ,

	// AXI-S interfaces to MAC
	axis_if.master     udp_rx_stream     , // Data from MAC to us
	axis_if.slave      udp_tx_stream     , // Data from us to MAC

	// RGMII Pins
	output wire        ENET1_GTX_CLK     ,
	output wire        ENET1_TX_EN       ,
	output wire [ 3:0] ENET1_TX_DATA     ,
	input  wire        ENET1_RX_CLK      ,
	input  wire        ENET1_RX_DV       ,
	input  wire [ 3:0] ENET1_RX_DATA
);

eth_core I_eth_core (
	.clk_125_i         (clk_125_i         ),
	.clk_125_90_i      (clk_125_90_i      ),
	.rstn_clk_125_i    (rstn_clk_125_i    ),
	.compute_clk_i     (compute_clk_i     ),
	.rstn_compute_clk_i(rstn_compute_clk_i),
	.design_instr_o    (design_instr_o    ),
	.udp_rx_stream     (udp_rx_stream     ),
	.udp_tx_stream     (udp_tx_stream     ),
	.enet1_gtx_clk     (ENET1_GTX_CLK     ),
	.enet1_tx_en       (ENET1_TX_EN       ),
	.enet1_tx_data     (ENET1_TX_DATA     ),
	.enet1_rx_clk      (ENET1_RX_CLK      ),
	.enet1_rx_dv       (ENET1_RX_DV       ),
	.enet1_rx_data     (ENET1_RX_DATA     )
);

endmodule : eth_top

`default_nettype wire

