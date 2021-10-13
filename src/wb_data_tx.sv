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
    output wire        o_busy, o_uart_tx;

    reg [W-1:0]        sreg;
    reg [7:0]          hex, tx_data;
    reg [3:0]          tx_index;
    reg [3:0]          state;
    wire               tx_busy;
    reg                tx_stb;

    initial tx_index = 0;
    initial state = 0;

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
                state  <= 1;
                tx_stb <= 0;
            end
        else if (trigger_condition)
            begin
                state  <= 1;
                tx_stb <= 1;
            end
        else if (tx_stb && !tx_busy) // increment state
            begin
                state     <= state + 1;
                if (state >= 4'hd)
                    begin
                        tx_stb <= 0;
                        state  <= 0;
                    end
            end

    // shift register logic
    initial sreg = 0;
    always @(posedge i_clk)
        if (trigger_condition)
            sreg <= i_data;
        else if (!tx_busy && state > 4'h1)
            sreg <= {sreg[27:0], 4'h0};

    // transform top 4 bits into proper character
    always @(posedge i_clk)
        case(sreg[31:28])
            4'h0: hex <= "0";
            4'h1: hex <= "1";
            4'h2: hex <= "2";
            4'h3: hex <= "3";
            4'h4: hex <= "4";
            4'h5: hex <= "5";
            4'h6: hex <= "6";
            4'h7: hex <= "7";
            4'h8: hex <= "8";
            4'h9: hex <= "9";
            4'hA: hex <= "a";
            4'hB: hex <= "b";
            4'hC: hex <= "c";
            4'hD: hex <= "d";
            4'hE: hex <= "e";
            4'hF: hex <= "f";
            default:begin end
        endcase // case (sreg[31:28])

    // LUT for the actual character to send (based on state)
    always @(posedge i_clk)
        if (!tx_busy)
            case(state)
                4'h1: tx_data    <= "0";
                4'h2: tx_data    <= "x";
                4'h3: tx_data    <= hex;
                4'h4: tx_data    <= hex;
                4'h5: tx_data    <= hex;
                4'h6: tx_data    <= hex;
                4'h7: tx_data    <= hex;
                4'h8: tx_data    <= hex;
                4'h9: tx_data    <= hex;
                4'hA: tx_data    <= hex;
                4'hB: tx_data    <= "\r";
                4'hC: tx_data    <= "\n";
                default: tx_data <= "Q";
            endcase // case (state)

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
    initial assume(i_reset);

    // past validation
    reg         f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid = 1'b1;

    reg [1:0]   f_minbusy;

    initial f_minbusy = 0;
    always @(posedge i_clk)
        if (trigger_condition)
            f_minbusy <= 2'b01;
        else if (f_minbusy !=  2'b00)
            f_minbusy <= f_minbusy + 1'b1;

    always @(*)
        if (f_minbusy != 0)
            assume(tx_busy);

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
        begin
            if (f_past_valid && $changed(tx_index))
                begin
                    assert($past(tx_stb) && !$past(tx_busy) && (tx_index == $past(tx_index)+1));
                end
            else if (f_past_valid)
                begin
                    assert($stable(tx_index) && (!$past(tx_stb) || $past(tx_busy)));
                end
        end
`endif
endmodule // wb_data_tx
