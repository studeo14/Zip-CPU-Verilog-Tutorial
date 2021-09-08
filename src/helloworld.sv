/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

`ifdef VERILATOR
module helloworld(i_clk, o_setup, o_uart_tx);
    input wire i_clk;
`else
module helloworld(clk_25mhz, o_uart_tx, o_led, wifi_gpio0);
    input wire clk_25mhz;
    output wire wifi_gpio0;
    output reg  o_led;
    wire       i_clk;
    assign i_clk = clk_25mhz;
    assign wifi_gpio0 = 1;
`endif
    output wire o_uart_tx;

    parameter CLOCK_RATE_HZ = 25_000_000;
    parameter BAUD_RATE = 115_200;

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

    reg [3:0]   tx_index;
    wire [7:0]  tx_data;
    wire        tx_busy;
    reg         tx_stb;

    initial tx_index = 0;
    always @(posedge i_clk)
        if (tx_stb && !tx_busy)
            tx_index <= tx_index + 1'b1;

    hello_world_mem
        data0 (
               .i_clk(i_clk),
               .i_index(tx_index),
               .o_char(tx_data));

    initial tx_stb = 1'b0;
    always @(posedge i_clk)
        if (tx_send_strobe)
            begin
                tx_stb <= 1'b1;
`ifndef VERILATOR
                o_led  <= !o_led;
`endif
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
endmodule // helloworld

