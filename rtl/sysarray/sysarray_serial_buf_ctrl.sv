`resetall
`timescale 1ns/1ps
`default_nettype none


import tpu_pkg::*;


module sysarray_serial_buf_ctrl (
	
	input wire 											clk_i,
	input wire 					 						rstn_i,

	// Is the parallel buffer full?
	input wire 											parallel_full_i,

	// This block controls reading out the values from the Parallel buffer, and writing them into the serial buffer
	output  wire 										parallel_rd_en_o [tpu_pkg::ARRAY_NUM_COLS],
	output  wire [$clog2(tpu_pkg::ARRAY_NUM_COLS)-1:0]	parallel_rd_idx_o,
	output  wire										serial_wr_en_o,

	// Status flags for downstram consumer
	output  wire 										serial_rd_done_o

);

/// Description:
/*

This block basically handles reading from the Parallel FIFO, and writing to the Serial FIFO.
The proper read sequence is

Col 0 -> Col 1 -> Col 2 -> ... -> Col (tpu_pkg::ARRAY_NUM_COLS)
Repeating the above (tpu_pkg::ARRAY_NUM_ROWS) times.

In terms of implementation this is quite simple (really!)
We just need a row counter, and a col "counter" thats one hot encoded (i guess its more of a shift register lmao)

The row counter should start on the posedge of the Parallel buffer filling up.

*/


localparam NUM_ROWS   = tpu_pkg::ARRAY_NUM_ROWS;
localparam NUM_COLS   = tpu_pkg::ARRAY_NUM_COLS;
localparam ROW_CNT_SZ = $clog2(tpu_pkg::ARRAY_NUM_ROWS);
localparam COL_CNT_SZ = $clog2(tpu_pkg::ARRAY_NUM_COLS);

///////////////////// Check a posedge on parallel_full_i
logic parallel_full_d1r;
wire  parallel_full_rising;

always_ff @(posedge clk_i) begin
	if (~rstn_i) begin
		parallel_full_d1r <= 1'd0;
	end else begin
		parallel_full_d1r <= parallel_full_i;
	end
end
assign parallel_full_rising = parallel_full_i & ~parallel_full_d1r;

///////////////////// The Row Counter

typedef enum logic [1:0] {
	IDLE,		// 2'd0
	COL_START,	// 2'd1
	COL_WAIT,	// 2'd2
	DONE   		// 2'd3
} e_row_counter_st;
e_row_counter_st row_cnt_st_r;

logic [ROW_CNT_SZ-1:0] row_cnt_r;
logic				   row_cnt_done_r;

logic 				   col_cnt_begin_r;
logic 				   col_cnt_done_r;

always_ff @(posedge clk_i) begin
	if(~rstn_i) begin
		row_cnt_st_r 	<= IDLE;
		row_cnt_r 	 	<= {ROW_CNT_SZ{1'd0}};	// Current row count
		row_cnt_done_r 	<= 1'd0;
		col_cnt_begin_r <= 1'd0;
	end else begin
		unique case (row_cnt_st_r)
			
			IDLE: begin
				// if we see a posedge on the parallel_full signal, start the count sequence
				row_cnt_done_r <= 1'b0;

				if (parallel_full_rising) begin
					row_cnt_st_r <= COL_START;
					row_cnt_r    <= {ROW_CNT_SZ{1'd0}};
				end
			end

			COL_START: begin
				// start the sequence reading out a full column's worth of data if we are still within the range [0, NUM_COLS]
				// Note: row_cnt_r is incremented here, so it represents how many times we've read the columns out (which is the same as reading a row)
				row_cnt_r       <= row_cnt_r + { {ROW_CNT_SZ-1{1'b0}} , 1'b1 }; // increment row_cnt_r 
				col_cnt_begin_r <= 1'd1;
				row_cnt_st_r    <= COL_WAIT;
			end

			COL_WAIT: begin
				// Here we set the col_cnt_begin_r low (its a pulsed enable), and wait for the count to finish
				col_cnt_begin_r <= 1'd0;

				if (col_cnt_done_r) begin
					// check if we need more iterations or not
					row_cnt_st_r <= (row_cnt_r < NUM_ROWS) ? (COL_START) : (DONE);
				end
			end

			DONE: begin
				// asert the done flag and transition to back IDLE
				row_cnt_done_r <= 1'b1;
				row_cnt_st_r   <= IDLE;
			end
			
		endcase
	end
end

///////////////////// The Col "Counter"

logic [$clog2(NUM_COLS)-1:0] col_idx_r;
logic [NUM_COLS-1:0] col_cnt_r;		// This is the read-en going to the Parallel FIFO
logic [NUM_COLS-1:0] col_cnt_d1r;   // This is the write-en  going to the Serial FIFO

always_ff @(posedge clk_i or negedge rstn_i) begin : proc_
	if(~rstn_i) begin
		col_cnt_r 	   <= {NUM_COLS{1'b0}};
		col_cnt_d1r    <= {NUM_COLS{1'b0}};
		col_cnt_done_r <= 1'd0;
		col_idx_r      <= 'd0;
	end else begin
		col_cnt_r[0] 	<= col_cnt_begin_r;
		col_cnt_done_r 	<= col_cnt_d1r[NUM_COLS-1];
		col_idx_r       <= (|col_cnt_d1r) ? (
										    (col_idx_r < NUM_ROWS-1) ? (col_idx_r + 'd1) : ('d0) // handle max value condition
											)  
										   : col_idx_r; // handle enable condition
		col_cnt_d1r 	<= col_cnt_r;
		// one hot encoded shift register
		for (int i = 1; i < NUM_COLS; i++) begin
			col_cnt_r[i] <= col_cnt_r[i-1];
		end
	end
end



///////////////////// TLIO Assignments

assign serial_wr_en_o    = |col_cnt_d1r;
assign serial_rd_done_o  = row_cnt_done_r;
assign parallel_rd_idx_o = col_idx_r;

///// Here col_cnt_r is packed, need to make it unpacked
logic col_cnt_unpacked [NUM_COLS];
genvar x;

generate for (x = 0; x < NUM_COLS; x++) begin : col_cnt_convert
	assign col_cnt_unpacked[x] = col_cnt_r[x];
end
endgenerate

assign parallel_rd_en_o = col_cnt_unpacked;

endmodule : sysarray_serial_buf_ctrl

`default_nettype wire