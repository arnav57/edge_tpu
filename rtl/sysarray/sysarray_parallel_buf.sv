`resetall
`timescale 1ns/1ps
`default_nettype none


import tpu_pkg::*;

module sysarray_parallel_buf #(
	// Inherit PE Config
	parameter int DATA_WIDTH = tpu_pkg::PSUM_WIDTH,

	// Inherit Systolic Array Config
	parameter int DIM_SIZE   = tpu_pkg::ARRAY_NUM_COLS
) (
	input wire clk_i,
	input wire rstn_i,

	input wire wr_en_i [DIM_SIZE],
	input wire rd_en_i [DIM_SIZE],

	input wire [DATA_WIDTH-1:0] wr_data_i [DIM_SIZE],
	output wire [DATA_WIDTH-1:0] rd_data_o [DIM_SIZE],

	output wire buf_full_o
);

// net to know when all FIFOs are full
wire [$clog2(DIM_SIZE):0] fifo_size [DIM_SIZE];
// logic 					  fifo_full [DIM_SIZE];
logic [DIM_SIZE-1:0]	  fifo_full_packed;

// generate N=DIM_SIZE FIFOs
genvar i;
generate for (i = 0; i < DIM_SIZE; i++) begin : gen_buf_fifo
	
	std_sync_fifo #(
		.FIFO_DEPTH (  DIM_SIZE    ),
		.FIFO_WIDTH (  DATA_WIDTH  )
	) I_skew_fifo (
		.fifo_clk_i  (clk_i),
		.fifo_rstn_i (rstn_i),

		.wr_en_i     (wr_en_i[i]),
		.rd_en_i     (rd_en_i[i]),

		.wr_data_i   (wr_data_i[i]),
		.rd_data_o   (rd_data_o[i]),

		.rd_ptr_o     ( /* FLOATING */ ),
		.wr_ptr_o     ( /* FLOATING */ ),
		.fifo_sz_o    ( fifo_size[i]   ),
		.fifo_full_o  ( /* FLOATING */ ),
		.fifo_empty_o ( /* FLOATING */ )
	);

	assign fifo_full_packed[i] = (fifo_size[i] == 'd20);

end	
endgenerate



assign buf_full_o = &fifo_full_packed; // "every FIFO is full (with 20 things)" flag lmao


endmodule : sysarray_parallel_buf

`default_nettype wire