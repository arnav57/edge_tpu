`resetall
`timescale 1ns/1ps
`default_nettype none


import tpu_pkg::*;


module sysarray_serial_buf #(
	// Inherit PE Config
	parameter int DATA_WIDTH = tpu_pkg::PSUM_WIDTH,

	// Inherit Systolic Array Config
	parameter int DIM_SIZE   = tpu_pkg::ARRAY_NUM_COLS * tpu_pkg::ARRAY_NUM_ROWS
) (
	
	input wire 						clk_i,
	input wire 					 	rstn_i,

	// Read control to Parallel Buffers
	input  wire [DATA_WIDTH-1:0] 	parallel_rd_data_i [tpu_pkg::ARRAY_NUM_COLS],
	output wire 			 	 	parallel_rd_en_o   [tpu_pkg::ARRAY_NUM_COLS],

	// Read control to downstream Serial Consumer of this module's FIFO
	input  wire						serial_rd_en_i,
	output wire [DATA_WIDTH-1:0]    serial_rd_data_o,

	// Status Flags
	input  wire							parallel_full_i, // From parallel buffer
	output wire 						serial_full_o    // To consumers of this serial buffer
);

////////////////////// FSM to Control reading from the parallel buffer

logic [$clog2(tpu_pkg::ARRAY_NUM_COLS)-1:0] parallel_rd_idx;
logic                                       serial_wr_en;

sysarray_serial_buf_ctrl 
I_systolic_serial_buf_ctrl (
	.clk_i            ( clk_i              ),
	.rstn_i           ( rstn_i 		       ),
	.parallel_full_i  ( parallel_full_i    ),
	.parallel_rd_en_o ( parallel_rd_en_o   ),
	.parallel_rd_idx_o( parallel_rd_idx    ),
	.serial_wr_en_o   ( serial_wr_en       ),
	.serial_rd_done_o ( serial_full_o      )
);

////////////////////// Muxing logic for parallel to serial
// This will infer a (horrid) NUM_COLS -> 1 INT24 mux by default

logic signed [DATA_WIDTH-1:0] serial_data_to_write;

always_comb begin
	serial_data_to_write = parallel_rd_data_i[parallel_rd_idx];
end

////////////////////// Actual Serial Buffer (SURPRISE!!! its another FIFO)

std_sync_fifo #(
	.FIFO_DEPTH (  DIM_SIZE    ),
	.FIFO_WIDTH (  DATA_WIDTH  )
) I_serial_fifo (
	.fifo_clk_i  (clk_i),
	.fifo_rstn_i (rstn_i),

	.wr_en_i     (serial_wr_en),
	.rd_en_i     ( 1'd0 ),

	.wr_data_i   (serial_data_to_write),
	.rd_data_o   ( /* FLOATING */ ),

	.rd_ptr_o     ( /* FLOATING */ ),
	.wr_ptr_o     ( /* FLOATING */ ),
	.fifo_sz_o    ( /* FLOATING */ ),
	.fifo_full_o  ( /* FLOATING */ ),
	.fifo_empty_o ( /* FLOATING */ )
);



endmodule : sysarray_serial_buf

`default_nettype wire

