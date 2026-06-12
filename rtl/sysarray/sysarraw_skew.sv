`resetall
`timescale 1ns/1ps
`default_nettype none


import tpu_pkg::*;

module sys_skew #(
    parameter int unsigned DATA_WIDTH = tpu_pkg::ACTV_WIDTH,
    parameter int unsigned DEPTH      = 0
) (
/* verilator lint_off UNUSEDSIGNAL */
    // these signals are not used when DEPTH=0 as syn infers a wire
    // For other rows (DEPTH != 0) these are used
    // Removing these verilator guards shows these 3 signals are unused for DEPTH=0
    // This bejaviour is intended
    input  wire                         clk_i  ,
    input  wire                         rstn_i ,
    input  wire                         bypass_i ,  // 1 = bypass skew, provides a direct path
/* verilator lint_on UNUSEDSIGNAL */

    input  wire signed [DATA_WIDTH-1:0] signal_i    ,
    input  wire                         signal_valid_i   ,

    output wire signed [DATA_WIDTH-1:0] signal_skewed_o    ,
    output wire                         signal_valid_skewed_o
);

    if (DEPTH == 0) begin

        // Row 0 always direct regardless of hold_i
        // This infers a wire
        assign signal_skewed_o  	 = signal_i;
        assign signal_valid_skewed_o = signal_valid_i;

    end else begin

    	// Otherwise we generate a shift-register chain
    	// And MUX the endpoint with the direct connection
        logic signed [DATA_WIDTH-1:0] S_sr  [DEPTH-1:0];
        logic                         Sv_sr [DEPTH-1:0];

        always_ff @(posedge clk_i) begin
            if (~rstn_i) begin
                S_sr  <= {DEPTH{DATA_WIDTH{1'b0}}};
                Sv_sr <= {DEPTH{1'b0}};
            end else begin
                S_sr [0] <= S_i;
                Sv_sr[0] <= Sv_i;
                for (int s = 1; s < DEPTH; s++) begin
                    S_sr [s] <= S_sr [s-1];
                    Sv_sr[s] <= Sv_sr[s-1];
                end
            end
        end

        // Mux between skewed and direct path
        assign S_o  = bypass_i ? S_i             : S_sr [DEPTH-1];
        assign Sv_o = bypass_i ? Sv_i            : Sv_sr[DEPTH-1];

    end

endmodule : sys_skew
