/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

`default_nettype none

module thruwire(btn, led);

    input wire  [6:0] btn;
    output wire [6:0] led;

    wire [6:0]        w_internal;

    assign w_internal = 7'h7A;
    assign led = btn ^ w_internal;

endmodule // thruwire
