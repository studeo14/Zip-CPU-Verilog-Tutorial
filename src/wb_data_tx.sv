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


    always @(posedge i_clk)
        if (tx_stb && !tx_busy)
            tx_index <= tx_index + 1'b1;

    initial tx_stb = 1'b0;
    always @(posedge i_clk)
        if (tx_send_strobe)
            begin
                tx_stb <= 1'b1;
            end
        else if (tx_stb && !tx_busy && tx_index == 4'hF)
            tx_stb <= 1'b0;

    wb_uart_tx #(
                 .CLOCKS_PER_BAUD(INITIAL_UART_SETUP[23:0]))
    uart0 (
           .i_clk(i_clk),
           .i_wr(tx_stb),
           .i_data(tx_data),
           .o_uart_tx(o_uart_tx),
           .o_busy(tx_busy));

`ifdef FORMAL
    // past validation
    reg         f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid = 1'b1;

    always @(*)
        if (tx_index != 4'h0)
            assert(tx_stb);
    always @(*)
        if (tx_stb && !tx_busy)
            case(tx_index)
                4'h0: assert(tx_data == "H");
                4'h1: assert(tx_data == "e");
                4'h2: assert(tx_data == "l");
                4'h3: assert(tx_data == "l");
                //
                4'h4: assert(tx_data == "o");
                4'h5: assert(tx_data == ",");
                4'h6: assert(tx_data == " ");
                4'h7: assert(tx_data == "W");
                //
                4'h8: assert(tx_data == "o");
                4'h9: assert(tx_data == "r");
                4'hA: assert(tx_data == "l");
                4'hB: assert(tx_data == "d");
                //
                4'hC: assert(tx_data == "!");
                4'hD: assert(tx_data == " ");
                4'hE: assert(tx_data == "\n");
                4'hF: assert(tx_data == "\r");
                //
            endcase // case (i_index)

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
