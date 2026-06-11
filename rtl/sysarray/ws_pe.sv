`resetall
`timescale 1ns/1ps
`default_nettype none


import tpu_pkg::*;

module ws_pe #(
	parameter int DATA_WIDTH = tpu_pkg::ACTV_WIDTH,
	parameter int ACCM_WIDTH = tpu_pkg::PSUM_WIDTH
) (
	// Clock/Rstn
	input  wire                         clk_i  ,
	input  wire                         rstn_i ,

	// Latch/Clear Weight
	input  wire                         latch_i,
	input  wire                         clear_i,

	// Activation IO
	input  wire signed [DATA_WIDTH-1:0] A_i    ,
	output wire signed [DATA_WIDTH-1:0] A_o    ,

	// Partial Sum IO
	input  wire signed [ACCM_WIDTH-1:0] P_i    ,
	output wire signed [ACCM_WIDTH-1:0] P_o    ,

	// Validity Flags
	input  wire                         Av_i   ,
	output wire                         Av_o   ,
	input  wire                         Pv_i   ,
	output wire                         Pv_o
);


//////////// Latching and Clearing the Weight Values

logic signed [DATA_WIDTH-1:0] B_r;

always_ff @(posedge clk_i) begin
	if (~rstn_i) begin
		B_r <= {DATA_WIDTH{1'b0}};
	end else begin
		if (clear_i) begin
			B_r <= {DATA_WIDTH{1'b0}};
		end else if (latch_i) begin
			B_r <= A_i;
		end
	end
end

//////////// Main Delay Stages

logic signed [DATA_WIDTH-1:0] A_d1r;
logic signed [DATA_WIDTH-1:0] A_d2r;
logic signed [DATA_WIDTH-1:0] A_d3r;

logic 						  Av_d1r;
logic 						  Av_d2r;
logic 						  Av_d3r;

logic signed [ACCM_WIDTH-1:0] P_d1r;
logic signed [ACCM_WIDTH-1:0] P_d2r;

logic 						  Pv_d1r;
logic 						  Pv_d2r;
logic 						  Pv_d3r;

always_ff @(posedge clk_i) begin
	if(~rstn_i) begin
		A_d1r  <= {DATA_WIDTH{1'b0}};
		A_d2r  <= {DATA_WIDTH{1'b0}};
		A_d3r  <= {DATA_WIDTH{1'b0}};

		Av_d1r <= 1'b0;
		Av_d2r <= 1'b0;
		Av_d3r <= 1'b0;

		P_d1r  <= {ACCM_WIDTH{1'b0}};
		P_d2r  <= {ACCM_WIDTH{1'b0}};

		Pv_d1r <= 1'b0;
		Pv_d2r <= 1'b0;
		Pv_d3r <= 1'b0;
	end else begin
		 A_d1r  <= A_i;
		 A_d2r  <= A_d1r;
		 A_d3r  <= A_d2r;

 		 Av_d1r <= Av_i;
		 Av_d2r <= Av_d1r;
		 Av_d3r <= Av_d2r;

		 P_d1r  <= P_i;
		 P_d2r  <= P_d1r;

  		 Pv_d1r <= Pv_i & Av_i;
		 Pv_d2r <= Pv_d1r;
		 Pv_d3r <= Pv_d2r;
	end
end

//////////// Computation Path
//
// A_i trace:
// 	cc 1: A_i   -> A_d1r 
// 	cc 2: A_d1r -> mul_r
// 	cc 3: mul_r -> add_r
//
// P_i trace:
//	cc 1: P_i 	 -> P_d1r
// 	cc 2: P_d1r -> P_d2r
// 	cc 3: P_d2r -> P_d3r
//
// We can see here, we need P value ready when mul_r is ready, this at the second cc. Thus we use P_d2r in the compuation for add_r

logic signed [2*DATA_WIDTH-1:0] mul_r;
logic signed [ACCM_WIDTH-1:0]   add_r;

always_ff @(posedge clk_i) begin
	if(~rstn_i) begin
		mul_r <= {2*DATA_WIDTH{1'b0}};
		add_r <= {ACCM_WIDTH{1'b0}};
	end else begin
		mul_r <= $signed(A_d1r * B_r);
		add_r <= $signed(mul_r + P_d2r);
	end
end


//////////// Port Connections

// datapath takes 3 cc's
assign A_o  = A_d3r;
assign P_o  = add_r;

// validity path is delayed by 3 cc's to match datapath
assign Av_o = Av_d3r;
assign Pv_o = Pv_d3r;

endmodule : ws_pe

`default_nettype wire