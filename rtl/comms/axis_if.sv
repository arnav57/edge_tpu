import tpu_pkg::*;

interface axis_if #(
    parameter DATA_WIDTH = tpu_pkg::ACTV_WIDTH
) (
    input  wire                     clk,
    input  wire                     rstn
);

    logic [DATA_WIDTH-1:0]  tdata;
    logic                   tvalid;
    logic                   tready;
    logic                   tlast;
    logic                   tuser;


    // mastter modport sends data
    modport master (
        output tdata, tvalid, tlast, tuser,
        input  tready
    );

    // slave modport receives data
    modport slave (
        input  tdata, tvalid, tlast, tuser,
        output tready
    );

endinterface : axis_if