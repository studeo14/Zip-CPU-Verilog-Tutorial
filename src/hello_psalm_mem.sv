/*
 * PSALM BRAM
 */

module hello_psalm_mem(i_clk, i_addr, i_data, i_we, o_data);
    parameter W = 8;
    parameter DW = 8;
    parameter FILE_NAME = "psalm_mem.hex";

    // interface
    input i_clk, i_we;
    input [W-1:0] i_addr;
    input [DW-1:0] i_data;

    output reg [DW-1:0] o_data;

    reg [DW-1:0]        ram [0:(1<<W)-1];

    initial $readmemh(FILE_NAME, ram);

    always @(posedge i_clk)
        if (i_we)
            ram[i_addr] <= i_data;

    always @(posedge i_clk)
        o_data <= ram[i_addr];

endmodule // hello_psalm_mem
