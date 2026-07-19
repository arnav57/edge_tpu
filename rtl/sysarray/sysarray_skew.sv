`resetall
`timescale 1ns/1ps
`default_nettype none

import tpu_pkg::*;

module sysarray_skew #(
	parameter int DIM_SIZE   = tpu_pkg::ARRAY_NUM_ROWS,
	parameter int DATA_WIDTH = tpu_pkg::ACTV_WIDTH
) (
	input wire clk_i,
	input wire rstn_i,

	input wire loading_i,

	input  wire signed [DATA_WIDTH-1:0] data_i  [DIM_SIZE]  ,
	output wire signed [DATA_WIDTH-1:0] data_o  [DIM_SIZE]  ,

	output wire signed 					data_valid_o [DIM_SIZE],

	input wire rd_en_i,
	input wire wr_en_i
);

// Local Signals
wire         [DIM_SIZE-1:0]  rd_en_mesh;
wire signed [DATA_WIDTH-1:0] fifo_data  [DIM_SIZE];

// generate one FIFO per row
genvar row;
generate for (row = 0; row < DIM_SIZE; row++) begin : gen_skew_fifo
	
	std_sync_fifo #(
		.FIFO_DEPTH (  2*DIM_SIZE  ),
		.FIFO_WIDTH (  DATA_WIDTH  )
	) I_skew_fifo (
		.fifo_clk_i  (clk_i),
		.fifo_rstn_i (rstn_i),

		.wr_en_i     (wr_en_i),
		.rd_en_i     (rd_en_mesh[row]),

		.wr_data_i   (data_i[row]),
		.rd_data_o   (fifo_data[row]),

		.rd_ptr_o     ( /* FLOATING */ ),
		.wr_ptr_o     ( /* FLOATING */ ),
		.fifo_sz_o    ( /* FLOATING */ ),
		.fifo_full_o  ( /* FLOATING */ ),
		.fifo_empty_o ( /* FLOATING */ )
	);

	// Bypass the FIFOs entirely when loading weights
	assign data_o[row] = (loading_i) ? data_i[row] : fifo_data[row];

end	
endgenerate

// generate the flops connecting the read_en and latch delays
genvar i;
generate for (i = 0; i < DIM_SIZE; i++) begin : gen_meshes
	if (i == 0) begin
		assign rd_en_mesh[i] = rd_en_i;
		logic valid_delay;
		always_ff @(posedge clk_i) begin
			if(~rstn_i) begin
				valid_delay <= 1'b0;
			end else begin
				valid_delay <= rd_en_i;
			end
		end
		assign data_valid_o[i] = valid_delay;
	end else begin

		logic [2:0] rd_en_delay;
		logic       valid_delay;
		always_ff @(posedge clk_i) begin
			if (~rstn_i) begin
				rd_en_delay <= 3'b0;
				valid_delay <= 1'b0;
			end else begin
				rd_en_delay[0] <= rd_en_mesh[i - 1];
				rd_en_delay[1] <= rd_en_delay[0];
				rd_en_delay[2] <= rd_en_delay[1]; 
				valid_delay    <= rd_en_mesh[i];
			end
		end

		assign rd_en_mesh[i]   = rd_en_delay[2]; 
		assign data_valid_o[i] = valid_delay;
	end
end
endgenerate



endmodule : sysarray_skew

`default_nettype wire