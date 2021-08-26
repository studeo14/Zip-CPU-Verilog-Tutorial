/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

`ifdef VERILATOR
module walker(i_clk, led);
    input wire i_clk;
`else
module walker(clk_25mhz, led);
    input wire clk_25mhz;
    wire       i_clk;
    assign i_clk = clk_25mhz;
`endif
    output reg [6:0] led;

    reg [3:0]         state, next_state;
    reg [6:0]         next_led;
    initial state = 0;
    initial led = 0;
    always @(posedge i_clk)
        begin
            state <= next_state;
            led   <= next_led;
        end

    always @(*)
        begin
            if (state >= 4'hB)
                next_state = 0;
            else
                next_state = state + 4'd1;
            case(state)
                4'h0: next_led    = 7'b000_0001;
                4'h1: next_led    = 7'b000_0010;
                4'h2: next_led    = 7'b000_0100;
                4'h3: next_led    = 7'b000_1000;
                4'h4: next_led    = 7'b001_0000;
                4'h5: next_led    = 7'b100_0000;
                4'h6: next_led    = 7'b010_0000;
                4'h7: next_led    = 7'b001_0000;
                4'h8: next_led    = 7'b000_1000;
                4'h9: next_led    = 7'b000_0100;
                4'hA: next_led    = 7'b000_0010;
                4'hB: next_led    = 7'b000_0001;
                default: next_led = 0;
            endcase // case (state)
        end

`ifdef FORMAL
`endif

endmodule // walker
