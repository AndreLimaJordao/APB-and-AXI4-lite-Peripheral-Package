module receiver #(
    parameter   DBIT    =   8,
    parameter   SB_TICK =   16
)(
    input   logic           clk,
    input   logic           rst_n,
    input   logic           rx,
    input   logic           s_tick,
    output  logic           rx_done_tick,
    output  logic   [DBIT-1:0]   dout
);

    typedef enum {idle, start, data, stop} state_type;

    state_type                      state_reg, state_next;
    logic   [$clog2(SB_TICK)-1:0]   s_reg,  s_next;
    logic   [$clog2(DBIT)-1:0]      n_reg,  n_next;
    logic   [DBIT-1:0]              d_reg,  d_next;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            state_reg   <=  idle;
            s_reg       <=  '0;
            n_reg       <=  '0;
            d_reg       <=  '0;
        end else begin
            state_reg   <=  state_next;
            s_reg       <=  s_next;
            n_reg       <=  n_next;
            d_reg       <=  d_next;
        end
    end

    always_comb begin
        state_next      =   state_reg;
        rx_done_tick    =   1'b0;
        s_next          =   s_reg;
        n_next          =   n_reg;
        d_next          =   d_reg;
        case (state_reg)
            idle:
                if(!rx) begin
                    state_next  =   start;
                    s_next      =   '0;
                end
            start:
                if(s_tick) begin
                    if(s_reg == ((SB_TICK/2) - 1)) begin
                        state_next  =   data;
                        s_next      =   '0;
                        n_next      =   '0;
                    end else
                        s_next      =   s_reg + 1;
                end
            data:
                if(s_tick) begin
                    if(s_reg == (SB_TICK - 1)) begin
                        s_next          =   '0;
                        d_next          =   {rx, d_reg[DBIT-1:1]};
                        if(n_reg == (DBIT - 1)) begin
                            state_next  =   stop;
                        end else 
                            n_next      =   n_reg + 1;
                    end else
                        s_next  =   s_reg + 1;
                end
            stop:
                if(s_tick) begin
                    if(s_reg == (SB_TICK - 1)) begin
                        state_next      =   idle;
                        rx_done_tick    =   1'b1;
                    end else
                        s_next          =   s_reg + 1;
                end
            default: 
                state_next  =   idle;
        endcase
    end

    assign dout =   d_reg;

endmodule