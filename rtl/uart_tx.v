module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        uart_txd,
    output reg        tx_busy,
    output reg        tx_done
);

    localparam [1:0] TX_IDLE  = 2'd0,
                     TX_START = 2'd1,
                     TX_DATA  = 2'd2,
                     TX_STOP  = 2'd3;

    reg [1:0] state, next_state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= TX_IDLE;
            uart_txd  <= 1'b1;
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;
            tick_cnt  <= 4'd0;
            bit_cnt   <= 3'd0;
            shift_reg <= 8'd0;
        end else begin
            tx_done <= 1'b0;

            case (state)
                TX_IDLE: begin
                    uart_txd <= 1'b1;
                    tx_busy  <= 1'b0;
                    if (tx_start) begin
                        state     <= TX_START;
                        shift_reg <= tx_data;
                        tx_busy   <= 1'b1;
                        tick_cnt  <= 4'd0;
                    end
                end

                TX_START: begin
                    uart_txd <= 1'b0;
                    if (tick) begin
                        if (tick_cnt == 4'd15) begin
                            state    <= TX_DATA;
                            tick_cnt <= 4'd0;
                            bit_cnt  <= 3'd0;
                        end else begin
                            tick_cnt <= tick_cnt + 4'd1;
                        end
                    end
                end

                TX_DATA: begin
                    uart_txd <= shift_reg[0];
                    if (tick) begin
                        if (tick_cnt == 4'd15) begin
                            tick_cnt  <= 4'd0;
                            shift_reg <= {1'b0, shift_reg[7:1]};
                            if (bit_cnt == 3'd7) begin
                                state <= TX_STOP;
                            end else begin
                                bit_cnt <= bit_cnt + 3'd1;
                            end
                        end else begin
                            tick_cnt <= tick_cnt + 4'd1;
                        end
                    end
                end

                TX_STOP: begin
                    uart_txd <= 1'b1;
                    if (tick) begin
                        if (tick_cnt == 4'd15) begin
                            state   <= TX_IDLE;
                            tx_done <= 1'b1;
                        end else begin
                            tick_cnt <= tick_cnt + 4'd1;
                        end
                    end
                end

                default: state <= TX_IDLE;
            endcase
        end
    end

endmodule
