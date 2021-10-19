

module debouncer(i_clk, i_event, o_event);
    parameter TIME_PERIOD = 25_000;
    input i_clk, i_event;
    output reg   o_event;

    // time domain crossing sync
    reg [1:0]    sync;
    initial sync = 0;
    always @(posedge i_clk)
        sync <= {sync[0], i_event};
    // actual timer
    reg [31:0]   timed;
    initial timed = 0;
    always @(posedge i_clk)
        if (timed != 0)
            timed <= timed - 1;
        else if(sync[1])
            timed <= TIME_PERIOD - 1;

    initial o_event = 0;
    always @(posedge i_clk)
        if (0 == timed)
            o_event <= sync[1];

endmodule // debouncer
