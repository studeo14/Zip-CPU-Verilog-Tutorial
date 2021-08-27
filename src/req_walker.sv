/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

`ifdef VERILATOR
module req_walker(i_clk, i_req, o_busy, led);
    input wire i_clk;
`else
module req_walker(clk_25mhz, i_req, o_busy, led);
    input wire clk_25mhz;
    wire       i_clk;
    assign i_clk = clk_25mhz;
`endif
    // custom signals
    input wire i_req;
    output wire o_busy;
    output reg [6:0] led;

    reg [3:0]         state, next_state;
    reg [6:0]         next_led;

    // submodules
    //wire              strobe;
    //clock_div
    //   clk_div_A (.i_clk(i_clk), .enable(1'b1), .strobe(strobe));

    // custom logic
    initial state = 0;
    initial led = 1;
    always @(posedge i_clk)
        begin
            state <= next_state;
            led   <= next_led;
        end

    always @(*)
        begin
            next_state = 4'h0;
            if (i_req && !o_busy)
                next_state = 4'h1;
            else if (state >= 4'hB)
                next_state = 0;
            else if (state != 0)
                next_state = state + 4'd1;
            case(state)
                4'h0: next_led    = 7'b000_0001;
                4'h1: next_led    = 7'b000_0010;
                4'h2: next_led    = 7'b000_0100;
                4'h3: next_led    = 7'b000_1000;
                4'h4: next_led    = 7'b001_0000;
                4'h5: next_led    = 7'b010_0000;
                4'h6: next_led    = 7'b100_0000;
                4'h7: next_led    = 7'b010_0000;
                4'h8: next_led    = 7'b001_0000;
                4'h9: next_led    = 7'b000_1000;
                4'hA: next_led    = 7'b000_0100;
                4'hB: next_led    = 7'b000_0010;
                default: next_led = 0;
            endcase // case (state)
        end

    assign o_busy = (state != 0);

`ifdef FORMAL
    always @(*)
        begin
            assert(state <= 4'hB);
            assert(led > 0);
            assert(led < 7'b100_0001);
            cover((led == 4'h2) && (state == 0));
            assert (o_busy == (state != 0));
        end
`endif

endmodule // req_walker
