module apb_slave (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [7:0]  PADDR,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    output reg  [7:0]  tx_data,
    output reg         tx_start,
    output reg  [15:0] baud_div,
    output wire        uart_en,
    output wire        tx_en,
    output wire        rx_en,

    input  wire        tx_busy,
    input  wire        tx_done,
    input  wire [7:0]  rx_data,
    input  wire        rx_valid,
    input  wire        rx_busy,
    input  wire        frame_error
);

    localparam ADDR_TXDATA   = 8'h00;
    localparam ADDR_RXDATA   = 8'h04;
    localparam ADDR_STATUS   = 8'h08;
    localparam ADDR_CTRL     = 8'h0C;
    localparam ADDR_BAUD_DIV = 8'h10;

    reg [2:0]  ctrl_reg;
    reg        rx_valid_flag;
    reg [7:0]  rx_data_reg;
    reg        frame_err_flag;

    assign uart_en = ctrl_reg[0];
    assign tx_en   = ctrl_reg[1];
    assign rx_en   = ctrl_reg[2];

    assign PREADY = 1'b1;

    wire valid_addr = (PADDR == ADDR_TXDATA)   ||
                      (PADDR == ADDR_RXDATA)   ||
                      (PADDR == ADDR_STATUS)   ||
                      (PADDR == ADDR_CTRL)     ||
                      (PADDR == ADDR_BAUD_DIV);

    assign PSLVERR = PSEL & PENABLE & ~valid_addr;

    wire apb_write = PSEL & PENABLE & PWRITE  & PREADY;
    wire apb_read  = PSEL & PENABLE & ~PWRITE & PREADY;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_data        <= 8'd0;
            tx_start       <= 1'b0;
            baud_div       <= 16'd27;
            ctrl_reg       <= 3'b000;
            rx_valid_flag  <= 1'b0;
            rx_data_reg    <= 8'd0;
            frame_err_flag <= 1'b0;
        end else begin
            tx_start <= 1'b0;

            if (rx_valid) begin
                rx_valid_flag <= 1'b1;
                rx_data_reg   <= rx_data;
            end

            if (frame_error)
                frame_err_flag <= 1'b1;

            if (apb_write) begin
                case (PADDR)
                    ADDR_TXDATA: begin
                        tx_data  <= PWDATA[7:0];
                        tx_start <= 1'b1;
                    end
                    ADDR_CTRL:
                        ctrl_reg <= PWDATA[2:0];
                    ADDR_BAUD_DIV:
                        baud_div <= PWDATA[15:0];
                    default: ;
                endcase
            end

            if (apb_read && (PADDR == ADDR_RXDATA))
                rx_valid_flag <= 1'b0;

            if (apb_read && (PADDR == ADDR_STATUS))
                frame_err_flag <= 1'b0;
        end
    end

    always @(*) begin
        PRDATA = 32'd0;
        if (PSEL && !PWRITE) begin
            case (PADDR)
                ADDR_TXDATA:   PRDATA = {24'd0, tx_data};
                ADDR_RXDATA:   PRDATA = {24'd0, rx_data_reg};
                ADDR_STATUS:   PRDATA = {27'd0, frame_err_flag, rx_busy,
                                         rx_valid_flag, ~tx_busy, tx_busy};
                ADDR_CTRL:     PRDATA = {29'd0, ctrl_reg};
                ADDR_BAUD_DIV: PRDATA = {16'd0, baud_div};
                default:       PRDATA = 32'd0;
            endcase
        end
    end

endmodule
