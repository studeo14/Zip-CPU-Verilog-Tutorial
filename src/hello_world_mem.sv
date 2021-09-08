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
    always @(posedge i_clk)
        case(i_index)
            4'h0: o_char <= "H";
            4'h1: o_char <= "e";
            4'h2: o_char <= "l";
            4'h3: o_char <= "l";
            //
            4'h4: o_char <= "o";
            4'h5: o_char <= ",";
            4'h6: o_char <= " ";
            4'h7: o_char <= "W";
            //
            4'h8: o_char <= "o";
            4'h9: o_char <= "r";
            4'hA: o_char <= "l";
            4'hB: o_char <= "d";
            //
            4'hC: o_char <= "!";
            4'hD: o_char <= " ";
            4'hE: o_char <= "\n";
            4'hF: o_char <= "\r";
            //
        endcase // case (i_index)

endmodule // hello_world_rom
