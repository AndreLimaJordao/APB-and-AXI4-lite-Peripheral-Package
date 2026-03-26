module FIFO #(
    parameter   DATA_WIDTH  =   8,
    parameter   ADDR_WIDTH  =   4
)(
    input   logic                       clk,
    input   logic                       rst_n,
    input   logic                       wr,
    input   logic                       rd,
    input   logic   [DATA_WIDTH-1:0]    w_data,
    output  logic   [DATA_WIDTH-1:0]    r_data,
    output  logic                       full,
    output  logic                       empty
);

    logic  [ADDR_WIDTH-1:0]     w_addr, r_addr;
    logic                       wr_en, full_tmp;

    assign  wr_en = wr & !full_tmp;
    assign  full = full_tmp;

    FIFO_control #(.ADDR_WIDTH(ADDR_WIDTH)) ctl_unit (.*, .full(full_tmp));

    reg_file #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) fifo_unit (.*);
endmodule