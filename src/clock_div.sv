/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

module clock_div(i_clk, enable, strobe);

    input wire i_clk;
    input wire enable;
    output reg strobe;

    parameter CLOCK_RATE_HZ = 100_000_000;
    parameter STROBE_RATE = 1;
    localparam LIMIT = CLOCK_RATE_HZ >> (STROBE_RATE - 1);

    reg [31:0]  counter, next_counter;

    initial counter = 0;
    always @(posedge i_clk)
        begin
            if (enable)
                begin
                    counter <= next_counter;
                end
        end

    always @(*)
        begin
            strobe = 0;
            if (counter == 0)
                begin
                    next_counter = LIMIT - 1;
                    strobe       = 1;
                end
            else
                next_counter = counter - 1'b1;
        end

`ifdef FORMAL
    always @(*)
        assert(strobe == (counter == 0));
    always @(posedge i_clk)
        begin
            assert((LIMIT - 1) >= counter);
        end
`endif


endmodule // clock_div
