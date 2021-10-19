
`default_nettype none

module data_debugger(i_clk, i_event,
`ifdef VERILATOR
                     o_setup,
`endif
                     o_uart_tx);

    parameter CLOCK_RATE_HZ = 25_000_000;
    parameter BAUD_RATE = 115_200;

    input wire i_clk, i_event;
    output wire o_uart_tx;

    parameter UART_SETUP = (CLOCK_RATE_HZ / BAUD_RATE);

`ifdef VERILATOR
    output wire [31:0] o_setup;
    assign o_setup = UART_SETUP;
`endif

    wire [31:0]        counterv, tx_data;
    wire               tx_busy, tx_stb;
    wire               btn_deb;
    wire               w_event;
    reg                last_btn;

    initial last_btn = 0;
    always @(posedge i_clk)
        last_btn   <= btn_deb;
    assign w_event  = btn_deb && !last_btn;

    debouncer event_deb(
                        .i_clk(i_clk),
                        .i_event(i_event),
                        .o_event(btn_deb));

    counter thecounter(
                       .i_clk(i_clk),
                       .i_event(w_event),
                       .i_reset(1'b0),
                       .o_counter(counterv));

    detect_change find_changes(
                               .i_clk(i_clk),
                               .i_data(counterv),
                               .i_busy(tx_busy),
                               .o_strobe(tx_stb),
                               .o_data(tx_data));

    wb_data_tx
        #(
          .UART_SETUP(UART_SETUP))
    debugger (
              .i_clk(i_clk),
              .i_reset(1'b0),
              .i_stb(tx_stb),
              .i_data(tx_data),
              .o_busy(tx_busy),
              .o_uart_tx(o_uart_tx));

endmodule // data_debugger
