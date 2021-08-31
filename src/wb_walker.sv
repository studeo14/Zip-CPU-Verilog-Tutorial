/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`ifdef VERILATOR
module wb_walker(i_clk,
                 i_cyc, i_stb, i_we, i_addr, i_data,
                 o_stall, o_ack, o_data,
                 o_led);
    input wire i_clk;
`else
module wb_walker(clk_25mhz,
                 i_cyc, i_stb, i_we, i_addr, i_data,
                 o_stall, o_ack, o_data,
                 o_led);
    input wire clk_25mhz;
    wire       i_clk;
    assign i_clk = clk_25mhz;
`endif

    // INTERFACES
    // - WB
    input wire i_cyc, i_stb, i_we, i_addr;
    input wire [31:0] i_data;
    //
    output wire       o_stall;
    output reg        o_ack;
    output wire [31:0] o_data;

    // - led
    output reg [6:0]   o_led;

    // INTERNAL signals
    localparam IDLE = 0, COUNT = 1;
    reg                state, next_state;
    reg [3:0]          led_addr, next_led_addr;
    wire               strobe;

    // submodules
    clock_div
        #(
          .CLOCK_RATE_HZ(10))
    div0(
         .i_clk(i_clk),
         .enable(state),
         .strobe(strobe)
         );

    initial state = IDLE;
    initial led_addr = 0;
    // state transition
    always @(posedge i_clk)
        begin
            // state vars
            state    <= next_state;
            led_addr <= next_led_addr;
        end

    // calc next state
    always @(*)
        begin
            next_state = state;
            case (state)
                IDLE:
                    begin
                        // if new req, write, and not busy
                        if ((i_stb) && (i_we) && (!o_stall))
                            next_state = COUNT;
                    end
                COUNT:
                    begin
                        if (led_addr >= 4'hC && strobe)
                            next_state = IDLE;
                    end
                default: next_state = IDLE;
            endcase // case (state)
        end

    // calc next led address
    always @(*)
        begin
            next_led_addr = 0;
            if (state == COUNT)
                if (strobe || led_addr == 4'b0)
                    next_led_addr = led_addr + 1;
                else
                    next_led_addr = led_addr;
        end

    // calc next led output value
    always @(*)
        begin
            o_led = 0;
            if (state == COUNT)
                case(led_addr)
                    4'h0: o_led    = 7'b000_0001;
                    4'h1: o_led    = 7'b000_0010;
                    4'h2: o_led    = 7'b000_0100;
                    4'h3: o_led    = 7'b000_1000;
                    4'h4: o_led    = 7'b001_0000;
                    4'h5: o_led    = 7'b010_0000;
                    4'h6: o_led    = 7'b100_0000;
                    4'h7: o_led    = 7'b010_0000;
                    4'h8: o_led    = 7'b001_0000;
                    4'h9: o_led    = 7'b000_1000;
                    4'hA: o_led    = 7'b000_0100;
                    4'hB: o_led    = 7'b000_0010;
                    4'hC: o_led    = 7'b000_0001;
                    default: o_led = 0;
                endcase // case (led_addr)
        end

    // wishbone output calculations
    wire busy;
    assign busy = state != IDLE;

    // immediately return ack for any req
    initial o_ack = 0;
    always @(posedge i_clk)
        o_ack      <= (i_stb) && (!o_stall);
    // stall if busy and another request is given (write)
    assign o_stall  = (busy) && (i_we);
    // always give data for ready request
    assign o_data = {28'h0, led_addr};
    // Verilator lint_off UNUSED
    wire [33:0] unused;
    assign unused = {i_cyc, i_addr, i_data};
    // Verilator lint_on UNUSED

    /* FORMAL VERIFCATION */
`ifdef FORMAL
    // past validation
    reg         f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid = 1'b1;

    // assert o_led
    always @(*)
        if(state)
            begin
                assert(o_led != 7'b0);
                case(led_addr)
                    4'h0: assert(o_led == 7'b000_0001);
                    4'h1: assert(o_led == 7'b000_0010);
                    4'h2: assert(o_led == 7'b000_0100);
                    4'h3: assert(o_led == 7'b000_1000);
                    4'h4: assert(o_led == 7'b001_0000);
                    4'h5: assert(o_led == 7'b010_0000);
                    4'h6: assert(o_led == 7'b100_0000);
                    4'h7: assert(o_led == 7'b010_0000);
                    4'h8: assert(o_led == 7'b001_0000);
                    4'h9: assert(o_led == 7'b000_1000);
                    4'hA: assert(o_led == 7'b000_0100);
                    4'hB: assert(o_led == 7'b000_0010);
                    4'hC: assert(o_led == 7'b000_0001);
                endcase // case (led_addr)
            end
        else
            begin
                assert(o_led == 7'b0);
            end

    always @(*)
        assert(busy != (state == IDLE));

    always @(*)
        assert(led_addr <= 4'hC + 4'h1);

    // after a request and not stalled, start processing request
    always @(posedge i_clk)
        begin
            if ((f_past_valid) && ($past(i_stb)) && ($past(i_we)) && (!$past(o_stall)))
                begin
                    assert(state == COUNT);
                    assert(busy);
                end
        end

    // during the cycle the address should increment
    always @(posedge i_clk)
        begin
            if ((f_past_valid) && ($past(busy)) && ($past(strobe) || $past(led_addr) == 4'h0) && ($past(state < 4'hC + 4'h1)))
                begin
                    assert(led_addr == $past(led_addr) + 1);
                end
        end

    initial assume(!i_cyc);

    // i_stb is only allowed if i_cyc
    always @(*)
        if (!i_cyc)
            assume(!i_stb);

    // when i_cyc goes high so too does i_stb
    always @(posedge i_clk)
        begin
            if ((!$past(i_cyc)) && (i_cyc))
                assume(i_stb);
        end

    always @(posedge i_clk)
        begin
            if ((f_past_valid) && ($past(i_stb)) && ($past(o_stall)))
                begin
                    // request is stalled
                    // should not change
                    assume(i_stb);
                    assume(i_we == $past(i_we));
                    assume(i_addr == $past(i_addr));
                    if (i_we)
                        assume(i_data == $past(i_data));
                end
        end

    always @(posedge i_clk)
        begin
            if ((f_past_valid) && ($past(i_stb)) && (!$past(o_stall)))
                assert(o_ack);
        end

    always @(posedge i_clk)
        if (f_past_valid)
            cover((!busy) && ($past(busy)));
`endif

endmodule // wb_walker
