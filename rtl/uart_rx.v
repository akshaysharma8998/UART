module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick,
    input  wire       rx_enable,
    input  wire       uart_rxd,
    output reg  [7:0] rx_data,
    output reg        rx_valid,
    output reg        rx_busy,
    output reg        frame_error
);

    localparam [1:0] RX_IDLE  = 2'd0,
                     RX_START = 2'd1,
                     RX_DATA  = 2'd2,
                     RX_STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;

    reg rxd_sync1, rxd_sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rxd_sync1 <= 1'b1;
            rxd_sync2 <= 1'b1;
        end else begin
            rxd_sync1 <= uart_rxd;
            rxd_sync2 <= rxd_sync1;
        end
    end

    wire rxd_s = rxd_sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= RX_IDLE;
            rx_data     <= 8'd0;
            rx_valid    <= 1'b0;
            rx_busy     <= 1'b0;
            frame_error <= 1'b0;
            tick_cnt    <= 4'd0;
            bit_cnt     <= 3'd0;
            shift_reg   <= 8'd0;
        end else begin
            rx_valid <= 1'b0;

            case (state)
                RX_IDLE: begin
                    rx_busy     <= 1'b0;
                    frame_error <= 1'b0;
                    tick_cnt    <= 4'd0;
                    if (rx_enable && ~rxd_s) begin
                        state   <= RX_START;
                        rx_busy <= 1'b1;
                    end
                end

                RX_START: begin
                    if (tick) begin
                        if (tick_cnt == 4'd7) begin
                            if (~rxd_s) begin
                                state    <= RX_DATA;
                                tick_cnt <= 4'd0;
                                bit_cnt  <= 3'd0;
                            end else begin
                                state   <= RX_IDLE;
                                rx_busy <= 1'b0;
                            end
                        end else begin
                            tick_cnt <= tick_cnt + 4'd1;
                        end
                    end
                end

                RX_DATA: begin
                    if (tick) begin
                        if (tick_cnt == 4'd15) begin
                            tick_cnt  <= 4'd0;
                            shift_reg <= {rxd_s, shift_reg[7:1]};
                            if (bit_cnt == 3'd7) begin
                                state <= RX_STOP;
                            end else begin
                                bit_cnt <= bit_cnt + 3'd1;
                            end
                        end else begin
                            tick_cnt <= tick_cnt + 4'd1;
                        end
                    end
                end

                RX_STOP: begin
                    if (tick) begin
                        if (tick_cnt == 4'd15) begin
                            state   <= RX_IDLE;
                            rx_busy <= 1'b0;
                            if (rxd_s) begin
                                rx_data  <= shift_reg;
                                rx_valid <= 1'b1;
                            end else begin
                                frame_error <= 1'b1;
                            end
                        end else begin
                            tick_cnt <= tick_cnt + 4'd1;
                        end
                    end
                end

                default: state <= RX_IDLE;
            endcase
        end
    end

endmodule
