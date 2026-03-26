module UART #(
    parameter   DBIT    =   8,
    parameter   SB_TICK =   16,
    parameter   FIFO_W  =   2
)(
    input   logic               clk,
    input   logic               rst_n,
    input   logic               rd_uart,
    input   logic               wr_uart,
    input   logic               rx,
    input   logic   [DBIT-1:0]  w_data,
    input   logic   [10:0]      dvsr,
    output  logic               tx_full,
    output  logic               rx_empty,
    output  logic               tx,
    output  logic   [DBIT-1:0]  r_data
);

    logic               tick, rx_done_tick, tx_done_tick;
    logic               tx_empty, tx_fifo_not_empty;
    logic   [DBIT-1:0]  tx_fifo_out, rx_data_out;

    baud_gen baud_gen_unit (.*);

    receiver #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_rx_unit (.*, .s_tick(tick), .dout(rx_data_out));

    transmitter #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_tx_unit (.*, .s_tick(tick), .tx_start(tx_fifo_not_empty), .d_in(tx_fifo_out));

    FIFO #(.DATA_WIDTH(DBIT), .ADDR_WIDTH(FIFO_W)) fifo_rx_unit (.*, .rd(rd_uart), .wr(rx_done_tick), .w_data(rx_data_out), .empty(rx_empty), .full(), .r_data(r_data));

    FIFO #(.DATA_WIDTH(DBIT), .ADDR_WIDTH(FIFO_W)) fifo_tx_unit (.*, .rd(tx_done_tick), .wr(wr_uart), .w_data(w_data), .empty(tx_empty), .full(tx_full), .r_data(tx_fifo_out));

    assign  tx_fifo_not_empty = !tx_empty;
endmodule