/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

module detect_change(i_clk, i_data, i_busy, o_strobe, o_data);
    parameter W = 32;
    input wire          i_clk, i_busy;
    input wire [W-1:0]  i_data;
    output reg          o_strobe;
    output reg [W-1:0]  o_data;

    initial o_strobe = 0;
    initial o_data = 0;

    always @(posedge i_clk)
        if (!i_busy)
            begin
                o_strobe   <= 0;
                if (o_data != i_data)
                    begin
                        o_strobe <= 1'b1;
                        o_data   <= i_data;
                    end
            end

`ifdef FORMAL
  // past validation
  reg               f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid = 1'b1;

    // initial conditions
    initial
        begin
            assert(i_data == 0);
            assert(i_busy == 0);
            assert(o_strobe == 0);
            assert(o_data == 0);
        end

    // contract
    always @(posedge i_clk)
        if (f_past_valid)
            begin
                if ($past(i_busy))
                    begin
                        assert($stable(o_strobe));
                        assert($stable(o_data));
                    end
                else
                    begin
                        if ($past(i_data) != i_data)
                            begin
                                assert($next(o_strobe));
                                assert($next(o_data) == i_data);
                            end
                        else // if equal
                            begin
                                assert(!$next(o_strobe));
                                assert($next(o_data) == o_data); // $stable in the future?
                            end
                    end
            end

    always @(posedge i_clk)
        if (f_past_valid)
            begin
                if ($rose(o_strobe))
                    begin
                        assert(o_data == $past(i_data));
                        assert($past(o_data) != $past(i_data));
                    end
                if ($past(o_strobe) && $stable(i_busy))
                    begin
                        assert(o_strobe);
                        assert($stable(o_data));
                    end

            end

`endif

endmodule // detect_change
