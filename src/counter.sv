/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

module counter(i_clk, i_event, i_reset, o_counter);
    parameter W = 32;
    input wire i_clk, i_event, i_reset;
    output reg [W-1:0] o_counter;

    initial o_counter = 0;
    always @(posedge i_clk)
        if (i_reset)
            o_counter <= 0;
        else if (i_event)
            o_counter <= o_counter + 1'b1;

`ifdef FORMAL
    // past validation
    reg               f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid = 1'b1;

    // assert initial conditions
    initial
        begin
            assert(i_event == 0);
            assert(i_reset == 0);
            assert(o_counter == 0);
        end

    always @(posedge i_clk)
        if (f_past_valid)
            if ($past(i_reset))
                begin
                    assert(o_counter == 0);
                end
            else if ($past(i_event))
                begin
                    assert(o_counter == $past(o_counter) + 1'b1);
                end
            else
                begin
                    assert($stable(o_counter));
                end
`endif

endmodule // counter
