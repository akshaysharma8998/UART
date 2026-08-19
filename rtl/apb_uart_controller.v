module apb_uart_controller (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [7:0]  PADDR,
    input  wire [31:0] PWDATA,
    output wire [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    output wire        uart_txd,
    input  wire        uart_rxd
);

    wire [7:0]  tx_data;
    wire        tx_start_raw;
    wire [15:0] baud_div;
    wire        uart_en;
    wire        tx_en;
    wire        rx_en;

    wire        tx_busy;
    wire        tx_done;
    wire [7:0]  rx_data;
    wire        rx_valid;
    wire        rx_busy;
    wire        frame_error;

    wire        baud_tick;

    wire tx_start_gated = tx_start_raw & uart_en & tx_en;
    wire rx_enable_gated = uart_en & rx_en;

    apb_slave u_apb_slave (
        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .PSEL        (PSEL),
        .PENABLE     (PENABLE),
        .PWRITE      (PWRITE),
        .PADDR       (PADDR),
        .PWDATA      (PWDATA),
        .PRDATA      (PRDATA),
        .PREADY      (PREADY),
        .PSLVERR     (PSLVERR),
        .tx_data     (tx_data),
        .tx_start    (tx_start_raw),
        .baud_div    (baud_div),
        .uart_en     (uart_en),
        .tx_en       (tx_en),
        .rx_en       (rx_en),
        .tx_busy     (tx_busy),
        .tx_done     (tx_done),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid),
        .rx_busy     (rx_busy),
        .frame_error (frame_error)
    );

    baud_generator u_baud_gen (
        .clk     (PCLK),
        .rst_n   (PRESETn),
        .enable  (uart_en),
        .divisor (baud_div),
        .tick    (baud_tick)
    );

    uart_tx u_uart_tx (
        .clk      (PCLK),
        .rst_n    (PRESETn),
        .tick     (baud_tick),
        .tx_start (tx_start_gated),
        .tx_data  (tx_data),
        .uart_txd (uart_txd),
        .tx_busy  (tx_busy),
        .tx_done  (tx_done)
    );

    uart_rx u_uart_rx (
        .clk        (PCLK),
        .rst_n      (PRESETn),
        .tick       (baud_tick),
        .rx_enable  (rx_enable_gated),
        .uart_rxd   (uart_rxd),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid),
        .rx_busy    (rx_busy),
        .frame_error(frame_error)
    );

endmodule
