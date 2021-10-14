/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

module wb_data_tx(i_clk, i_reset, i_stb, i_data, o_busy, o_uart_tx);
    parameter W = 32;
    parameter UART_SETUP = 858;

    // interface
    input wire         i_clk, i_stb, i_reset;
    input wire [W-1:0] i_data;
    output wire        o_uart_tx;
    output reg         o_busy;

    reg [W-1:0]        sreg, next_sreg;
    reg [7:0]          hex, next_hex, tx_data, next_tx_data;
    reg [3:0]          state, next_state;
    wire               tx_busy;
    reg                tx_stb;

    initial state = 0;
    initial o_busy = 0;
    initial sreg = 0;
    initial hex = 0;
    initial tx_data = 0;

    // trigger condition
    reg                trigger_condition;
    initial trigger_condition = 1'b0;
    always @(*)
        trigger_condition = i_stb && !o_busy;

    // basic state machine for trigger condition, trigger single char tx, character counter
    initial tx_stb = 1'b0;
    always @(posedge i_clk)
        if (i_reset)
            begin
                state   <= 0;
                sreg    <= 0;
                tx_data <= 0;
                hex     <= 0;
            end
        else
            begin
                state   <= next_state;
                sreg    <= next_sreg;
                tx_data <= next_tx_data;
                hex     <= next_hex;
            end

    // state, o_busy, tx_stb
    always @(*)
        begin
            next_state  = state;
            if (trigger_condition)
                begin
                    next_state  = 1;
                end
            else if (tx_stb && !tx_busy) // increment state
                begin
                    next_state = state + 1;
                    if (state >= 4'hd)
                        begin
                            next_state  = 0;
                        end
                end
        end

    always @(*)
        o_busy = (state > 0) || tx_busy;

    // tx_stb
    always @(*)
        tx_stb = state > 0;


    // sreg
    always @(*)
        begin
            next_sreg = sreg;
            if (!o_busy) // && i_stb
                next_sreg = i_data;
            else if (!tx_busy && state > 4'h2)
                next_sreg = {sreg[27:0], 4'h0};
        end


    // transform top 4 bits into proper character
    // - hex
    always @(*)
        begin
            next_hex = hex;
            case(sreg[31:28])
                4'h0: next_hex = "0";
                4'h1: next_hex = "1";
                4'h2: next_hex = "2";
                4'h3: next_hex = "3";
                4'h4: next_hex = "4";
                4'h5: next_hex = "5";
                4'h6: next_hex = "6";
                4'h7: next_hex = "7";
                4'h8: next_hex = "8";
                4'h9: next_hex = "9";
                4'hA: next_hex = "a";
                4'hB: next_hex = "b";
                4'hC: next_hex = "c";
                4'hD: next_hex = "d";
                4'hE: next_hex = "e";
                4'hF: next_hex = "f";
                default:begin end
            endcase // case (sreg[31:28])
        end

    // LUT for the actual character to send (based on state)
    // - tx_data
    always @(*)
        begin
            next_tx_data = tx_data;
            if (!tx_busy)
                case(state)
                    4'h1: next_tx_data    = "0";
                    4'h2: next_tx_data    = "x";
                    4'h3: next_tx_data    = hex;
                    4'h4: next_tx_data    = hex;
                    4'h5: next_tx_data    = hex;
                    4'h6: next_tx_data    = hex;
                    4'h7: next_tx_data    = hex;
                    4'h8: next_tx_data    = hex;
                    4'h9: next_tx_data    = hex;
                    4'hA: next_tx_data    = hex;
                    4'hB: next_tx_data    = "\r";
                    4'hC: next_tx_data    = "\n";
                    default: next_tx_data = "Q";
                endcase // case (state)
        end

`ifdef FORMAL
    (* anyseq *) wire serial_busy, serial_out;
    assign o_uart_tx = serial_out;
    assign tx_busy = serial_busy;
`else
    wb_uart_tx #(
                 .CLOCKS_PER_BAUD(UART_SETUP[23:0]))
    uart0 (
           .i_clk(i_clk),
           .i_wr(tx_stb),
           .i_data(tx_data),
           .o_uart_tx(o_uart_tx),
           .o_busy(tx_busy));
`endif


`ifdef FORMAL
    initial
        begin
            assume(i_reset);
            assume(tx_busy == 0);
            assume(o_busy == 0);
            assume(state == 0);
            assume(sreg == 0);
            assume(hex == 0);
            assume(tx_data == 0);
        end

    // past validation
    reg         f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid = 1'b1;

    reg [1:0]   f_minbusy;

    initial f_minbusy = 0;
    always @(posedge i_clk)
        if (tx_stb && !tx_busy)
            f_minbusy <= 2'b01;
        else if (f_minbusy !=  2'b00)
            f_minbusy <= f_minbusy + 1'b1;

    always @(*)
        if (f_minbusy != 0)
            assume(tx_busy);

    always @(*)
        assert(trigger_condition == (i_stb && !o_busy));

    // assumptions about tx_busy
    initial assume(!tx_busy);
    always @(posedge i_clk)
        if($past(i_reset))
            assume(!tx_busy);
        else if ($past(tx_stb) && !$past(tx_busy))
            assume(tx_busy);
        else if (!$past(tx_busy))
            assume(!tx_busy);

    always @(posedge i_clk)
        if (f_past_valid)
            cover($fell(o_busy));

    always @(posedge i_clk)
        if (f_past_valid && !$past(i_reset))
            cover($fell(o_busy));

    // seen data
    reg         f_seen_data;
    initial f_seen_data = 0;
    always @(posedge i_clk)
        if (i_reset)
            f_seen_data <= 0;
        else if (trigger_condition && i_data == 32'h12345678)
            f_seen_data <= 1;

    always @(posedge i_clk)
        if (f_past_valid && !$past(i_reset) && f_seen_data)
            cover($fell(o_busy));

    reg [13:0]  f_p1reg;
    initial f_p1reg = 0;
    initial assume(f_p1reg == 0);
    always @(posedge i_clk)
        if (i_reset)
            f_p1reg <= 0;
        else if (trigger_condition)
            begin
                f_p1reg        <= 1;
                assert(f_p1reg == 0 || f_p1reg == 15'h2000);
            end
        else if (!tx_busy)
            f_p1reg <= {f_p1reg[12:0], 1'b0};

    reg [31:0] fv_data;
    initial fv_data = 0;
    initial assume(fv_data == 0);
    always @(posedge i_clk)
        if (i_reset)
            fv_data <= 0;
        else if (trigger_condition)
            fv_data <= i_data;

    always @(posedge i_clk)
        if (!tx_busy || (f_minbusy == 0))
            begin
                if (f_p1reg[0])
                    begin
                        assert(tx_data == "Q");
                        assert(state == 1);
                        assert(sreg == fv_data);
                    end
                if (f_p1reg[1])
                    begin
                        assert(tx_data == "0");
                        assert(state == 2);
                    end
                if (f_p1reg[2])
                    begin
                        assert(tx_data == "x");
                        assert(state == 4'h3);
                    end
                if (f_p1reg[3])
                    begin
                        assert(state == 4'h4);
                    end
                if (f_p1reg[4])
                    begin
                        assert(state == 4'h5);
                    end
                if (f_p1reg[5])
                    begin
                        assert(state == 4'h6);
                    end
                if (f_p1reg[6])
                    begin
                        assert(state == 4'h7);
                    end
                if (f_p1reg[7])
                    begin
                        assert(state == 4'h8);
                    end
                if (f_p1reg[8])
                    begin
                        assert(state == 4'h9);
                    end
                if (f_p1reg[9])
                    begin
                        assert(state == 4'hA);
                    end
                if (f_p1reg[10])
                    begin
                        assert(state == 4'hB);
                    end
                if (f_p1reg[11])
                    begin
                        assert(tx_data == "\r");
                        assert(state == 4'hC);
                    end
                if (f_p1reg[12])
                    begin
                        assert(tx_data == "\n");
                        assert(state == 4'hD);
                    end
                if (f_p1reg[13])
                    begin
                        assert(tx_data == "Q");
                        assert(state == 4'h0);
                    end

            end

    always @(*)
        begin
            assert(tx_stb != (state == 0));
            assert(state <= 4'hD);
        end

    always @(posedge i_clk)
        if (f_past_valid)
            if (!$past(i_reset) && $past(o_busy) && $past(tx_busy))
                assert($stable(sreg));

`endif
endmodule // wb_data_tx
