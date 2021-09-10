/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

module data_mem(i_clk,
                i_cyc, i_stb, i_we, i_addr, i_data,
                o_stall, o_ack, o_data);
    // interface
    parameter L = 8; // 1 word
    parameter W = 8; // 1 character
    localparam total_size = L*W;
    input wire         i_clk;
    input wire 				 i_cyc, i_stb, i_we;
    input wire [4:0] 	 i_addr;
    input wire [total_size-1:0] i_data;
    output wire        o_stall;
    output reg         o_ack;
    output reg [W-1:0] o_data;

    // internal logic
    // - request condition
    reg                request_condition;
    always @(*)
        // assumes that i_cyc goes high with i_stb
        request_condition = (i_stb && !o_stall);

    // - state
    reg                next_ack;
    // we never stall
    assign o_stall = 1'b0;

    // - local data
    reg [W-1:0]        local_data[L-1:0], next_local_data[L-1:0];
    integer            i;

    // - addr
    reg [4:0]          local_addr, next_local_addr;

    initial o_data = 0;
    initial o_ack = 0;
    initial local_addr = 0;
    initial
        for (i = 0; i < L; i++)
            local_data[i] = 0;

    // state
    always @(posedge i_clk)
        begin
            for (i = 0; i < L; i++)
                local_data[i] <= next_local_data[i];
            o_ack             <= next_ack;
            local_addr        <= next_local_addr;
        end

    always @(*)
        begin
            next_local_addr = local_addr;
            if (request_condition)
                next_local_addr = i_addr;
        end

    // next local data
    always @(*)
        begin
            for (i = 0; i < L; i++)
                next_local_data[i] = local_data[i];
            if (request_condition && i_we)
                for (i = 0; i < L; i++)
                    next_local_data[i] = i_data[W*(i+1)-1:W*i];
        end

    // next ack
    always @(*)
        // ack immediatly since everything takes one cycle
        next_ack = request_condition;

    // internal mem
    always @(*)
        case (local_addr)
            4'h0: 	o_data = "0";
            4'h1: 	o_data = "x";
            //
            4'h2, 4'h3, 4'h4,
                4'h5, 4'h6, 4'h7,
                4'h8, 4'h9:
                    o_data = local_data[local_addr-2];
            //
            4'hA: 	o_data = "\n";
            4'hB: 	o_data = "\r";
            default:o_data = W'b0;
        endcase // case (i_addr)


`ifdef FORMAL

`ifdef DM
`define AS assume
`else
`define AS assert
`endif
    // past validation
    reg              f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid <= 1'b1;

    // initial conditions
    initial
        begin
            `AS(i_cyc == 0);
            `AS(i_stb == 0);
            `AS(i_we == 0);
            `AS(i_addr == 0);
            `AS(o_stall == 0);
            `AS(o_ack == 0);
            `AS(local_addr == 0);
            for (i = 0; i < L; i++)
                `AS(local_data[i] == W'b0);
        end

    // i_stb is only allowed if i_cyc
    always @(*)
        if (!i_cyc)
            `AS(!i_stb);

    // request condition
    always @(*)
        assert(request_condition == (i_stb && !o_stall));

    // i_cyc must stay high until ack (and during) then will go low on the next clock
    // a request must always be serviced (eventually)
    reg during;
    initial during = 0;
    always @(posedge i_clk)
        if (f_past_valid)
            begin
                // take advantage of knowing our timing
                if ($rose(o_ack))
                    begin
                        `AS($stable(i_cyc) && i_cyc);
                        `AS($past(request_condition));
                    end
                if ($fell(o_ack))
                    begin
                        `AS($fell(i_cyc));
                        `AS($past(request_condition, 2));
                    end
            end

    /* Things I want to work...
    cyc_high: assert property (@posedge (i_clk) disable iff (!f_past_valid)
        $rose(request_condition) |-> i_cyc until_with o_ack ##1 !i_cyc);

    req_srv: assert property (@posedge (i_clk) disable iff (!f_past_valid)
        // !o_ack -> !$rose(request_condition)
        $rose(request_condition) |-> ##[1:$] o_ack);
     */

    // if local addr changed then there was a request condition also o_data changed
    // plus the inverse
    always @(posedge i_clk)
        if (f_past_valid)
            if ($changed(local_addr))
                begin
                    assert($past(request_condition));
                    assert($changed(o_data));
                end
            else // if $stable(local_addr)
                begin
                    assert(!$past(request_condition));
                    assert($stable(o_data));
                end

    // covers
    always @(*)
        begin
            // a request is serviced
            cover(request_condition);
            cover(o_ack);
        end

    // contract
    always @(*)
        case (local_addr)
            4'h0: 	assert(o_data == "0");
            4'h1: 	assert(o_data == "x");
            //
            4'h2, 4'h3, 4'h4,
                4'h5, 4'h6, 4'h7,
                4'h8, 4'h9:
                    assert(o_data == local_data[local_addr - 2]);
            //
            4'hA: 	assert(o_data == "\n");
            4'hB: 	assert(o_data == "\r");
            default:assert(o_data == W'b0);
        endcase // case (i_addr)

    // if no request condition then the output should not change
    always @(posedge i_clk)
        if (f_past_valid)
            begin
                if(!$past(request_condition))
                    begin
                        assert($stable(o_data));
                        assert($stable(local_addr));
                    end
            end
`endif

endmodule // data_mem
