/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

`ifdef VERILATOR
module hellopsalm(i_clk, o_setup, o_uart_tx);
    input wire i_clk;
`else
module hellopsalm(clk_25mhz, o_uart_tx, o_led, wifi_gpio0);
    input wire clk_25mhz;
    output wire wifi_gpio0;
    output reg  o_led;
    wire       i_clk;
    assign i_clk = clk_25mhz;
    assign wifi_gpio0 = 1;
`endif
    output wire o_uart_tx;

`ifdef FORMAL
    parameter CLOCK_RATE_HZ = 15;
    parameter BAUD_RATE = 5;
`else
    parameter CLOCK_RATE_HZ = 25_000_000;
    parameter BAUD_RATE = 115_200;
`endif

    parameter INITIAL_UART_SETUP = (CLOCK_RATE_HZ/BAUD_RATE);
`ifdef VERILATOR
    output wire [31:0] o_setup;
    assign o_setup = INITIAL_UART_SETUP;
`endif

    // internal signals
    wire        tx_send_strobe;

    // tx process timer
    clock_div #(
                .CLOCK_RATE_HZ(CLOCK_RATE_HZ))
    tx_send_timer (
                   .i_clk(i_clk),
                   .enable(1'b1),
                   .strobe(tx_send_strobe));

    reg [10:0]   tx_index;
    wire [7:0]  tx_data;
    wire        tx_busy;
    reg         tx_stb;

    localparam DATA_LEN = 11'd1554;

    initial tx_index = 0;
    always @(posedge i_clk)
        if (tx_stb && !tx_busy)
            begin
                if (tx_index == DATA_LEN)
                    tx_index <= 0;
                else
                    tx_index <= tx_index + 1'b1;
            end


    hello_psalm_mem
        data0 (
               // Outputs
               .o_data                  (tx_data),
               // Inputs
               .i_clk                   (i_clk),
               .i_we                    (0),
               .i_addr                  (tx_index),
               .i_data                  (0));

    initial tx_stb = 1'b0;
    always @(posedge i_clk)
        if (tx_send_strobe)
            begin
                tx_stb <= 1'b1;
`ifndef VERILATOR
                o_led  <= !o_led;
`endif
            end
        else if (tx_stb && !tx_busy && tx_index == DATA_LEN)
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
endmodule // hellopsalm
