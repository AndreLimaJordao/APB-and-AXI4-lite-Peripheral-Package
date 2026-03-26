`timescale 1ns/1ps

module tb_UART;

    localparam int DBIT    = 8;
    localparam int SB_TICK = 16;
    localparam int FIFO_W  = 2;

    logic               clk;
    logic               rst_n;
    logic               rd_uart;
    logic               wr_uart;
    logic               rx;
    logic [DBIT-1:0]    w_data;
    logic [10:0]        dvsr;
    logic               tx_full;
    logic               rx_empty;
    logic               tx;
    logic [DBIT-1:0]    r_data;

    localparam int NUM_TEST_BYTES = 4;
    logic [DBIT-1:0] test_vec [0:NUM_TEST_BYTES-1];
    logic [DBIT-1:0] recv_byte;

    int tx_idx;
    int timeout_cnt;

    UART #(
        .DBIT(DBIT),
        .SB_TICK(SB_TICK),
        .FIFO_W(FIFO_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rd_uart(rd_uart),
        .wr_uart(wr_uart),
        .rx(rx),
        .w_data(w_data),
        .dvsr(dvsr),
        .tx_full(tx_full),
        .rx_empty(rx_empty),
        .tx(tx),
        .r_data(r_data)
    );

    // Loopback local: o TX do DUT alimenta o RX do proprio DUT.
    assign rx = tx;

    always #5 clk = ~clk;

    task automatic uart_write_byte(input logic [DBIT-1:0] data);
        begin
            while (tx_full) @(posedge clk);
            w_data   <= data;
            wr_uart  <= 1'b1;
            @(posedge clk);
            wr_uart  <= 1'b0;
        end
    endtask

    task automatic uart_read_byte(output logic [DBIT-1:0] data);
        begin
            while (rx_empty) @(posedge clk);
            data    = r_data;
            rd_uart <= 1'b1;
            @(posedge clk);
            rd_uart <= 1'b0;
        end
    endtask

    initial begin
        clk     = 1'b0;
        rst_n   = 1'b0;
        rd_uart = 1'b0;
        wr_uart = 1'b0;
        w_data  = '0;

        // Valor pequeno para simular mais rapido.
        dvsr    = 11'd3;

        test_vec[0] = 8'h55;
        test_vec[1] = 8'hA3;
        test_vec[2] = 8'h00;
        test_vec[3] = 8'hFF;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        for (tx_idx = 0; tx_idx < NUM_TEST_BYTES; tx_idx++) begin
            uart_write_byte(test_vec[tx_idx]);

            timeout_cnt = 0;
            while (rx_empty) begin
                @(posedge clk);
                timeout_cnt++;
                if (timeout_cnt > 20000) begin
                    $error("Timeout aguardando byte idx=%0d", tx_idx);
                    $fatal(1);
                end
            end

            uart_read_byte(recv_byte);
            if (recv_byte !== test_vec[tx_idx]) begin
                $error("Mismatch em idx=%0d: esperado=0x%0h recebido=0x%0h", tx_idx, test_vec[tx_idx], recv_byte);
                $fatal(1);
            end
        end

        $display("TESTE PASSOU: %0d bytes enviados e recebidos com sucesso.", NUM_TEST_BYTES);
        $finish;
    end

endmodule
