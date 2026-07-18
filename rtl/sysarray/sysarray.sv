`resetall
`timescale 1ns/1ps
`default_nettype none

import tpu_pkg::*;

module sysarray #(
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
	input  wire                         Pv_i [NUM_COLS]  ,
	output wire                         Pv_o [NUM_COLS]
);

// Mesh dimensions are [ROWS+1][COLS+1] to account for boundaries
logic signed [DATA_WIDTH-1:0] a_mesh  [NUM_ROWS+1][NUM_COLS+1]; 
logic signed [ACCM_WIDTH-1:0] p_mesh  [NUM_ROWS+1][NUM_COLS+1]; 

logic                         av_mesh [NUM_ROWS+1][NUM_COLS+1]; 
logic                         pv_mesh [NUM_ROWS+1][NUM_COLS+1]; 

//////////////////// MESH/BOUNDARY ASSIGNMENTS
genvar r, c;
generate
	// Map left and right boundaries (Rows)
	for (r = 0; r < NUM_ROWS; r++) begin : gen_row_bounds
		// Inputs map to the 0th column of the mesh
		assign a_mesh[r][0]  = A_i[r];
		assign av_mesh[r][0] = Av_i[r];
		
		// Outputs map from the last column of the mesh
		assign A_o[r]  = a_mesh[r][NUM_COLS];
		assign Av_o[r] = av_mesh[r][NUM_COLS];
	end

	// Map top and bottom boundaries (Columns)
	for (c = 0; c < NUM_COLS; c++) begin : gen_col_bounds
		// Inputs map to the 0th row of the mesh
		assign p_mesh[0][c]  = P_i[c];
		assign pv_mesh[0][c] = Pv_i[c];
		
		// Outputs map from the last row of the mesh
		assign P_o[c]  = p_mesh[NUM_ROWS][c];
		assign Pv_o[c] = pv_mesh[NUM_ROWS][c];
	end
endgenerate


//////////////////// Per Column Latch Mesh (for weight loading)

logic latch_mesh [NUM_COLS];

genvar x;
generate
	for (x = 0; x < NUM_COLS; x++) begin : pe_latch_mesh
		if (x == 0) begin
			assign latch_mesh[x] = latch_i;
		end else begin
			logic [3:0] latch_delay;
			always_ff @(posedge clk_i or negedge rstn_i) begin
				if(~rstn_i) begin
					 latch_delay <= 4'd0;
				end else begin
					 latch_delay[0] <= latch_mesh[x - 1];
					 latch_delay[1] <= latch_delay[0];
					 latch_delay[2] <= latch_delay[1];
					 latch_delay[3] <= latch_delay[2];
				end
			end
			assign latch_mesh[x] = latch_delay[3];
		end
	end
endgenerate

//////////////////// PE GRID
genvar i, j;
generate 
	for (i = 0; i < NUM_ROWS; i++) begin : pe_row
		for (j = 0; j < NUM_COLS; j++) begin : pe_col

			ws_pe #(
				.DATA_WIDTH(DATA_WIDTH),
				.ACCM_WIDTH(ACCM_WIDTH)
			) I_ws_pe (
				.clk_i   (clk_i),
				.rstn_i  (rstn_i),
				.latch_i (latch_mesh[j]),
				.clear_i (clear_i),

				.Av_i    (av_mesh[i][j]),
				.Pv_i    (pv_mesh[i][j]),

				.Av_o    (av_mesh[i][j+1]),
				.Pv_o    (pv_mesh[i+1][j]),

				.A_i     (a_mesh[i][j]),
				.P_i     (p_mesh[i][j]),

				.A_o     (a_mesh[i][j+1]),
				.P_o     (p_mesh[i+1][j])
			);
		end
	end
endgenerate

endmodule : sysarray

`default_nettype wire