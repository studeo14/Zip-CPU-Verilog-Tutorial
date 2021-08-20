/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

`ifdef VERILATOR
module thruwire(i_clk, led);
    input wire i_clk;
`else
module thruwire(clk_25mhz, led);
    input wire clk_25mhz;
    wire       i_clk;
    assign i_clk = clk_25mhz;
`endif
    output wire [6:0] led;

    parameter WIDTH = 27;
    reg [WIDTH-1:0] counter;
    initial counter = 0;
    always @(posedge i_clk)
        begin
            counter <= counter + 1'b1;
        end

    assign led = counter[WIDTH-1:WIDTH-7];


`ifdef FORMAL
    always@(*)
        assert(WIDTH >= 7);
`endif

endmodule // thruwire
