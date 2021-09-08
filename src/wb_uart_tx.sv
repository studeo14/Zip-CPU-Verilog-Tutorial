/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

module wb_uart_tx(i_clk, i_wr, i_data, o_uart_tx, o_busy);
    // interface
    input wire       i_clk;
    input wire       i_wr;
    input wire [7:0] i_data;
    output wire      o_uart_tx;
    output reg       o_busy;

    localparam [3:0]
        IDLE  = 4'h0,
        START = 4'h1,
        B0    = 4'h2,
        B1    = 4'h3,
        B2    = 4'h4,
        B3    = 4'h5,
        B4    = 4'h6,
        B5    = 4'h7,
        B6    = 4'h8,
        B7    = 4'h9,
        LAST  = 4'hA;

    // internal signals
    reg [3:0]        state, next_state;
    reg [8:0]        local_data, next_local_data;
    reg	             trigger;
    // - baud
    reg [23:0]       counter, next_counter;
    reg              baud_strobe;

    initial state = IDLE;
    initial local_data = {9{1'b1}};
    initial o_busy = 0;
    initial counter = 0;

    // state transitions
    always @(posedge i_clk)
        begin
            state      <= next_state;
            local_data <= next_local_data;
            counter    <= next_counter;
        end

    // trigger condition
    always @(*)
        trigger = (i_wr && !o_busy);

    // determine next state
    always @(*)
        begin
            next_state = state;
            // simple state machine
            // start on trigger then iterate through states
            // could be done with a counter but this method is (v.) explicit
            if (trigger)
                next_state = START;
            else if (baud_strobe)
                begin
                    case (state)
                        // stay in idle
                        IDLE: next_state  = IDLE;
                        // increment
                        START: next_state   = B0;
                        B0: next_state      = B1;
                        B1: next_state      = B2;
                        B2: next_state      = B3;
                        B3: next_state      = B4;
                        B4: next_state      = B5;
                        B5: next_state      = B6;
                        B6: next_state      = B7;
                        B7: next_state      = LAST;
                        // end bit
                        LAST: next_state    = IDLE;
                        default: next_state = IDLE;
                    endcase // case (state)
                end
        end

    // determine o_busy
    always @(*)
        o_busy = (state != IDLE);

    // determine local_data
    always @(*)
        begin
            next_local_data = local_data;
            if (trigger)
                // load on trigger
                next_local_data = {i_data, 1'b0};
            else if (baud_strobe)
                // shift out
                next_local_data = {1'b1, local_data[8:1]};
        end

    // determine actual output
    assign o_uart_tx = local_data[0];

    // baud
    parameter [23:0] CLOCKS_PER_BAUD = 24'd868;
    always @(*)
        begin
            next_counter = counter;
            if (trigger)
                begin
                    next_counter = CLOCKS_PER_BAUD - 1;
                end
            else if (counter > 0)
                begin
                    next_counter = counter - 1;
                end
            else if (state != IDLE)
                begin
                    next_counter = CLOCKS_PER_BAUD - 1;
                end
        end

    always @(*)
        baud_strobe = (counter == 0);

`ifdef FORMAL

`ifdef TXUART
`define AS assume
`else
`define AS assert
`endif
    // past validation
    reg         f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid = 1'b1;

    // contract
    reg [7:0] fv_data;
    always @(posedge i_clk)
        if (trigger)
            fv_data <= i_data;

    always @(posedge i_clk)
        case (state)
            IDLE: 	assert(o_uart_tx == 1'b1);
            START: 	assert(o_uart_tx == 1'b0);
            B0:			assert(o_uart_tx == fv_data[0]);
            B1:			assert(o_uart_tx == fv_data[1]);
            B2:			assert(o_uart_tx == fv_data[2]);
            B3:			assert(o_uart_tx == fv_data[3]);
            B4:			assert(o_uart_tx == fv_data[4]);
            B5:			assert(o_uart_tx == fv_data[5]);
            B6:			assert(o_uart_tx == fv_data[6]);
            B7:			assert(o_uart_tx == fv_data[7]);
            default:assert(0);
        endcase // case (state)

    // internal checks
    always @(posedge i_clk)
        assert(baud_strobe == (counter == 0));

    always @(posedge i_clk)
        if (f_past_valid && ($past(counter) != 0))
            assert(counter == $past(counter - 1'b1));

    // input requests should remain constant until they are serviced
    always @(posedge i_clk)
        if (f_past_valid && $past(i_wr) && $past(o_busy))
            begin
                `AS(i_wr == $past(i_wr));
                `AS(i_data == $past(i_data));
            end

    // baud
    always @(*)
        assert(counter < CLOCKS_PER_BAUD);

    always @(*)
        if (counter > 0)
            assert(o_busy);

    always @(*)
        assert(trigger == (i_wr && !o_busy));

    always @(posedge i_clk)
        if (!baud_strobe)
            assert(o_busy);
`endif

endmodule // wb_uart_tx
