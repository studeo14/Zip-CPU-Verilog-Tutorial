/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

`ifdef VERILATOR
module hellopsalm(i_clk, i_reset, o_setup, o_uart_tx);
    input wire i_clk;
`else
module hellopsalm(clk_25mhz, i_reset, o_uart_tx, o_led, wifi_gpio0);
    input wire clk_25mhz;
    output wire wifi_gpio0;
    output reg  o_led;
    wire       i_clk;
    assign i_clk = clk_25mhz;
    assign wifi_gpio0 = 1;
`endif
    input wire i_reset;
    output wire o_uart_tx;
    localparam DATA_LEN = 11'd1554;

`ifdef FORMAL
    parameter CLOCK_RATE_HZ = DATA_LEN;
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

    initial tx_index = 0;
    always @(posedge i_clk)
        if (i_reset)
            tx_index <= 0;
        else
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
        if (i_reset)
            begin
                tx_stb <= 0;
`ifndef VERILATOR
                o_led  <= 0;
`endif
            end
        else
            begin
                if (tx_send_strobe)
                    begin
                        tx_stb <= 1'b1;
`ifndef VERILATOR
                        o_led  <= !o_led;
`endif
                    end
                else if (tx_stb && !tx_busy && tx_index >= (DATA_LEN - 1))
                    tx_stb <= 1'b0;
            end
`ifndef FORMAL
    wb_uart_tx #(
                 .CLOCKS_PER_BAUD(INITIAL_UART_SETUP[23:0]))
    uart0 (
           .i_clk(i_clk),
           .i_wr(tx_stb),
           .i_data(tx_data),
           .o_uart_tx(o_uart_tx),
           .o_busy(tx_busy));
`else
    (* anyseq *) wire f_ser_busy, f_ser_out;
    assign o_uart_tx = f_ser_out;
    assign tx_busy = f_ser_busy;
`endif

`ifdef FORMAL
    // past validation
    reg         f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid = 1'b1;

    always @(posedge i_clk)
        if (!f_past_valid || $past(i_reset))
            begin
                assert(tx_index == 0);
                assert(tx_stb == 0);
            end
        else if ($changed(tx_index))
            begin
                assert($past(tx_stb) && !$past(tx_busy));
                if (tx_index == 0)
                    assert($past(tx_index) == DATA_LEN);
                else
                    assert(tx_index == $past(tx_index) + 1);
            end
        else
            begin
                assert($stable(tx_index) && (!$past(tx_stb) || $past(tx_busy)));
            end

    always @(posedge i_clk)
        if (tx_index != 0)
            assert(tx_stb);

    always @(posedge i_clk)
        assert(tx_index < DATA_LEN);

    initial assume(!tx_busy);
    always @(posedge i_clk)
        if ($past(i_reset))
            assume(!tx_busy);
        else if ($past(tx_stb) && !$past(tx_busy))
            assume(tx_busy);
        else if (!$past(tx_busy))
            assume(tx_busy);

    reg [1:0] f_minbusy;
    initial f_minbusy = 0;
    always @(posedge i_clk)
        if (tx_stb && !tx_busy)
            f_minbusy <= 2'b01;
        else if (f_minbusy != 2'b00)
            f_minbusy <= f_minbusy + 1'b1;

    always @(*)
        if (f_minbusy != 0)
            assume(tx_busy);

    // assert initial values
    parameter W = 11;
    parameter DW = 8;
    parameter FILE_NAME = "../res/psalm.hex";
    reg [DW-1:0]        f_ram [0:(1<<W)-1];
    initial $readmemh(FILE_NAME, f_ram);

    (* anyconst *) reg [W-1:0] f_const_addr;
    reg [DW-1:0]        f_const_value;
    always @(posedge i_clk)
        if (!f_past_valid)
            f_const_value <= f_ram[f_const_addr];
        else
            assert(f_const_value == f_ram[f_const_addr]);

    always @(posedge i_clk)
        if (f_past_valid)
            if ($past(tx_stb) && $past(tx_busy) && ($past(tx_index) == f_const_addr))
                assert(tx_data == f_const_value);

    always @(*)
        if (!f_past_valid)
            assume(i_reset);

    always @(posedge i_clk)
        if ((!f_past_valid)||$past(i_reset))
            begin
                assert(tx_index == 0);
                assert(tx_stb == 0);
            end


`endif
endmodule // hellopsalm
