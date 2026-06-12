`resetall
`timescale 1ns/1ps
`default_nettype none


import tpu_pkg::*;


module sysarray_core #(
	// Inherit PE Config
	parameter int DATA_WIDTH = tpu_pkg::ACTV_WIDTH,
	parameter int ACCM_WIDTH = tpu_pkg::PSUM_WIDTH,

	// Inherit Systolic Array Config
	parameter int NUM_ROWS   = tpu_pkg::ARRAY_NUM_ROWS,
	parameter int NUM_COLS   = tpu_pkg::ARRAY_NUM_COLS
) (

	// Clock/Rstn
	input  wire                         clk_i  ,
	input  wire                         rstn_i ,

	// Latch/Clear Weight
	input  wire                         latch_i,
	input  wire                         clear_i,

	// Activation IO
	input  wire signed [DATA_WIDTH-1:0] A_i  [NUM_ROWS]  ,
	output wire signed [DATA_WIDTH-1:0] A_o  [NUM_ROWS]  ,

	// Partial Sum IO
	input  wire signed [ACCM_WIDTH-1:0] P_i  [NUM_COLS]  ,
	output wire signed [ACCM_WIDTH-1:0] P_o  [NUM_COLS]  ,

	// Validity Flags
	input  wire                         Av_i [NUM_ROWS]  ,
	output wire                         Av_o [NUM_ROWS]  ,
	output wire                         Pv_o [NUM_COLS]

);

/// Here we connect and create the skewed datapath for activations. This ensures we feed the array at the proper timings
/// Also lets us simplify the memory-fetch logic upstream that drives this entire thing :P

logic signed [DATA_WIDTH-1:0] A_skewed_int  [NUM_ROWS];
logic 						  Av_skewed_int [NUM_ROWS];

genvar i;
generate
	for (i = 0; i < NUM_ROWS; i++) begin
		sys_skew #(
			.DATA_WIDTH( DATA_WIDTH ),
			.DEPTH     ( i          )
		) I_systolic_A_skew (
			.clk_i                  ( clk_i            ),
			.rstn_i                 ( rstn_i           ),
			.bypass_i               ( latch_i          ),
			.signal_i               ( A_i[i]           ),
			.signal_valid_i         ( Av_i[i]          ),
			.signal_skewed_o        ( A_skewed_int[i]  ),
			.signal_valid_skewed_o  ( Av_skewed_int[i] )
		);
	end
endgenerate


sysarray #(
	.DATA_WIDTH  ( DATA_WIDTH ),
	.ACCM_WIDTH  ( ACCM_WIDTH ),
	.NUM_ROWS    ( NUM_ROWS   ),
	.NUM_COLS    ( NUM_COLS   )
) I_systolic (
	.clk_i    ( clk_i               ),
	.rstn_i   ( rstn_i              ),
	.latch_i  ( latch_i             ),
	.clear_i  ( clear_i             ),
	.A_i      ( A_skewed_int        ),
	.A_o      ( A_o                 ),
	.P_i      ( P_i                 ),
	.P_o      ( P_o                 ),
	.Av_i     ( Av_skewed_int       ),
	.Av_o     ( Av_o                ),
	.Pv_i     ( {NUM_COLS{1'b1}}    ),
	.Pv_o     ( Pv_o                )
);



endmodule : sysarray_core

`default_nettype wire