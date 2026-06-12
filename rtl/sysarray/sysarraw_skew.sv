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

    generate if (DEPTH == 0) begin : skew_path

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
                S_sr  <= '{default: 1'b0}; // auto-sizing unpacked array assignment (nice good feature, NOT confusing!!)
                Sv_sr <= '{default: 1'b0}; // auto-sizing unpacked array assignment (nice good feature, NOT confusing!!)
            end else begin
                S_sr [0] <= signal_i;
                Sv_sr[0] <= signal_valid_i;
                for (int s = 1; s < DEPTH; s++) begin
                    S_sr [s] <= S_sr [s-1];
                    Sv_sr[s] <= Sv_sr[s-1];
                end
            end
        end

        // Mux between skewed and direct path
        assign signal_skewed_o       = bypass_i ? signal_i       : S_sr [DEPTH-1];
        assign signal_valid_skewed_o = bypass_i ? signal_valid_i : Sv_sr[DEPTH-1];
    end
    endgenerate

endmodule : sys_skew

`default_nettype wire