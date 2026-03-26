module transmitter #(
    parameter   DBIT    =   8,
    parameter   SB_TICK =   16
)(
    input   logic           clk,
    input   logic           rst_n,
    input   logic           tx_start,
    input   logic           s_tick,
    input   logic   [DBIT-1:0]   d_in,
    output  logic           tx_done_tick,
    output  logic           tx    
);

    typedef enum {idle, start, data, stop} state_type;

    state_type                      state_reg, state_next;
    logic   [$clog2(SB_TICK)-1:0]   s_reg, s_next;
    logic   [$clog2(DBIT)-1:0]      n_reg, n_next;
    logic   [DBIT-1:0]              d_reg, d_next;
    logic                           tx_reg, tx_next;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            state_reg   <=  idle;
            s_reg       <=  '0;
            n_reg       <=  '0;
            d_reg       <=  '0;
            tx_reg      <=  1'b1;
        end else begin
            state_reg   <=  state_next;
            s_reg       <=  s_next;
            n_reg       <=  n_next;
            d_reg       <=  d_next;
            tx_reg      <=  tx_next;
        end
    end 

    always_comb begin
        state_next      =   state_reg;
        tx_done_tick    =   1'b0;
        s_next          =   s_reg;
        n_next          =   n_reg;
        d_next          =   d_reg;
        tx_next         =   tx_reg;
        case(state_reg)
            idle: begin
                tx_next     =   1'b1;
                if(tx_start) begin
                    state_next      =   start;
                    s_next          =   '0;
                    d_next          =   d_in;
                end
            end
            start: begin
                tx_next     =   1'b0;
                if(s_tick) begin
                    if(s_reg == (SB_TICK-1)) begin
                        state_next  =   data;
                        s_next      =   '0;
                        n_next      =   '0;
                    end else begin
                        s_next      =   s_reg + 1;
                    end
                end 
            end
            data: begin
                tx_next                 =   d_reg[0];
                if(s_tick) begin
                    if(s_reg == (SB_TICK-1)) begin
                        s_next          =   '0;
                        d_next          =   d_reg >> 1;
                        if(n_reg == (DBIT-1)) begin
                            state_next  =   stop;
                        end else begin
                            n_next      =   n_reg + 1;
                        end 
                    end else begin
                        s_next          =   s_reg + 1;
                    end
                end
            end
            stop: begin
                tx_next                 =   1'b1;
                if(s_tick) begin
                    if(s_reg == (SB_TICK-1)) begin
                        state_next      =   idle;
                        tx_done_tick    = 1'b1;
                    end else begin
                        s_next          = s_reg + 1;
                    end
                end
            end
            default: 
                state_next  =   idle;
        endcase           
    end

    assign tx = tx_reg;

endmodule