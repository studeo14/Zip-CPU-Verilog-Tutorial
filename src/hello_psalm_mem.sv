/*
 * PSALM BRAM
 */

module hello_psalm_mem(i_clk, i_addr, i_data, i_we, o_data);
    parameter W = 11;
    parameter DW = 8;
    parameter FILE_NAME = "../res/psalm.hex";

    // interface
    input i_clk, i_we;
    input [W-1:0] i_addr;
    input [DW-1:0] i_data;

    output reg [DW-1:0] o_data;

    reg [DW-1:0]        ram [0:(1<<W)-1];

    initial $readmemh(FILE_NAME, ram);

    always @(posedge i_clk)
        begin
            if (i_we)
                ram[i_addr] <= i_data;
        end
    always @(posedge i_clk)
        begin
            o_data <= ram[i_addr];
        end

`ifdef FORMAL
    reg         f_past_valid;
    initial f_past_valid = 0;
    always @(posedge i_clk)
        f_past_valid = 1'b1;

    always @(posedge i_clk)
        if (!f_past_valid)
            assert(o_data == 0);

    (* anyconst *) reg [W-1:0] f_const_addr;
    reg [DW-1:0]        f_const_value;
    always @(posedge i_clk)
        if (!f_past_valid)
            f_const_value <= ram[f_const_addr];
        else
            assert(f_const_value == ram[f_const_addr]);

`endif

endmodule // hello_psalm_mem
