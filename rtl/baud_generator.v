module baud_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [15:0] divisor,
    output reg         tick
);

    reg [15:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            tick    <= 1'b0;
        end else if (enable) begin
            if (counter >= divisor) begin
                counter <= 16'd0;
                tick    <= 1'b1;
            end else begin
                counter <= counter + 16'd1;
                tick    <= 1'b0;
            end
        end else begin
            counter <= 16'd0;
            tick    <= 1'b0;
        end
    end

endmodule
