/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

module hello_world_mem(i_clk, i_index, o_char);
    // interface
    input wire 			 i_clk;
    input wire [3:0] i_index;
    output reg [7:0] o_char;

    // internal logic
    initial o_char = "H";
    always @(*)
        case(i_index)
            4'h0: o_char = "H";
            4'h1: o_char = "e";
            4'h2: o_char = "l";
            4'h3: o_char = "l";
            //
            4'h4: o_char = "o";
            4'h5: o_char = ",";
            4'h6: o_char = " ";
            4'h7: o_char = "W";
            //
            4'h8: o_char = "o";
            4'h9: o_char = "r";
            4'hA: o_char = "l";
            4'hB: o_char = "d";
            //
            4'hC: o_char = "!";
            4'hD: o_char = " ";
            4'hE: o_char = "\n";
            4'hF: o_char = "\r";
            //
        endcase // case (i_index)

`ifdef FORMAL
    // past validation
    reg              f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid = 1'b1;

    always @(*)
        case(i_index)
            4'h0: assert(o_char == "H");
            4'h1: assert(o_char == "e");
            4'h2: assert(o_char == "l");
            4'h3: assert(o_char == "l");
            //
            4'h4: assert(o_char == "o");
            4'h5: assert(o_char == ",");
            4'h6: assert(o_char == " ");
            4'h7: assert(o_char == "W");
            //
            4'h8: assert(o_char == "o");
            4'h9: assert(o_char == "r");
            4'hA: assert(o_char == "l");
            4'hB: assert(o_char == "d");
            //
            4'hC: assert(o_char == "!");
            4'hD: assert(o_char == " ");
            4'hE: assert(o_char == "\n");
            4'hF: assert(o_char == "\r");
            //
        endcase // case (i_index)

    always @(*)
        begin
            cover(o_char == "H");
            cover(o_char == "e");
            cover(o_char == "l");
            cover(o_char == "l");
            //
            cover(o_char == "o");
            cover(o_char == ",");
            cover(o_char == " ");
            cover(o_char == "W");
            //
            cover(o_char == "o");
            cover(o_char == "r");
            cover(o_char == "l");
            cover(o_char == "d");
            //
            cover(o_char == "!");
            cover(o_char == " ");
            cover(o_char == "\n");
            cover(o_char == "\r");
        end

`endif

endmodule // hello_world_rom
