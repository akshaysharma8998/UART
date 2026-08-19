`timescale 1ns / 1ps

module apb_uart_tb;

    parameter CLK_PERIOD = 20;
    parameter BAUD_DIV   = 3;
    parameter BIT_PERIOD = 16 * (BAUD_DIV + 1) * CLK_PERIOD;
    parameter FRAME_PERIOD = 10 * BIT_PERIOD;

    localparam ADDR_TXDATA   = 8'h00;
    localparam ADDR_RXDATA   = 8'h04;
    localparam ADDR_STATUS   = 8'h08;
    localparam ADDR_CTRL     = 8'h0C;
    localparam ADDR_BAUD_DIV = 8'h10;

    reg         PCLK;
    reg         PRESETn;
    reg         PSEL;
    reg         PENABLE;
    reg         PWRITE;
    reg  [7:0]  PADDR;
    reg  [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;
    wire        uart_txd;

    reg         uart_rxd_tb;
    reg         loopback_en;
    wire        uart_rxd = loopback_en ? uart_txd : uart_rxd_tb;

    integer pass_count;
    integer fail_count;
    integer test_num;

    reg [31:0] read_data;

    initial PCLK = 0;
    always #(CLK_PERIOD/2) PCLK = ~PCLK;

    apb_uart_controller dut (
        .PCLK     (PCLK),
        .PRESETn  (PRESETn),
        .PSEL     (PSEL),
        .PENABLE  (PENABLE),
        .PWRITE   (PWRITE),
        .PADDR    (PADDR),
        .PWDATA   (PWDATA),
        .PRDATA   (PRDATA),
        .PREADY   (PREADY),
        .PSLVERR  (PSLVERR),
        .uart_txd (uart_txd),
        .uart_rxd (uart_rxd)
    );

    task apb_write;
        input [7:0]  addr;
        input [31:0] data;
        begin
            @(posedge PCLK);
            PSEL    = 1'b1;
            PENABLE = 1'b0;
            PWRITE  = 1'b1;
            PADDR   = addr;
            PWDATA  = data;
            @(posedge PCLK);
            PENABLE = 1'b1;
            @(posedge PCLK);
            PSEL    = 1'b0;
            PENABLE = 1'b0;
            PWRITE  = 1'b0;
        end
    endtask

    task apb_read;
        input  [7:0]  addr;
        output [31:0] data;
        begin
            @(posedge PCLK);
            PSEL    = 1'b1;
            PENABLE = 1'b0;
            PWRITE  = 1'b0;
            PADDR   = addr;
            @(posedge PCLK);
            PENABLE = 1'b1;
            @(posedge PCLK);
            data    = PRDATA;
            PSEL    = 1'b0;
            PENABLE = 1'b0;
        end
    endtask

    task uart_send_byte;
        input [7:0] data;
        integer i;
        begin
            uart_rxd_tb = 1'b0;
            #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rxd_tb = data[i];
                #(BIT_PERIOD);
            end
            uart_rxd_tb = 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    task check;
        input [31:0] expected;
        input [31:0] actual;
        input [8*64-1:0] test_name;
        begin
            test_num = test_num + 1;
            if (actual === expected) begin
                $display("[PASS] Test %0d: %0s (expected=0x%08h, got=0x%08h)",
                         test_num, test_name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %0s (expected=0x%08h, got=0x%08h)",
                         test_num, test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_bit;
        input         expected;
        input         actual;
        input [8*64-1:0] test_name;
        begin
            test_num = test_num + 1;
            if (actual === expected) begin
                $display("[PASS] Test %0d: %0s (expected=%0b, got=%0b)",
                         test_num, test_name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %0s (expected=%0b, got=%0b)",
                         test_num, test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task loopback_test;
        input [7:0] tx_byte;
        input [8*32-1:0] label;
        reg [31:0] status;
        reg [31:0] rx_result;
        begin
            $display("\n--- Loopback Test: %0s (0x%02h) ---", label, tx_byte);

            apb_write(ADDR_TXDATA, {24'd0, tx_byte});

            apb_read(ADDR_STATUS, status);
            check_bit(1'b1, status[0], "TX busy after write");

            #(FRAME_PERIOD + BIT_PERIOD * 3);

            apb_read(ADDR_STATUS, status);
            check_bit(1'b0, status[0], "TX not busy after frame");
            check_bit(1'b1, status[2], "RX valid flag set");

            apb_read(ADDR_RXDATA, rx_result);
            check({24'd0, tx_byte}, rx_result, "Loopback data match");

            apb_read(ADDR_STATUS, status);
            check_bit(1'b0, status[2], "RX valid cleared after read");
        end
    endtask

    initial begin
        pass_count  = 0;
        fail_count  = 0;
        test_num    = 0;
        PCLK        = 0;
        PRESETn     = 1;
        PSEL        = 0;
        PENABLE     = 0;
        PWRITE      = 0;
        PADDR       = 8'd0;
        PWDATA      = 32'd0;
        uart_rxd_tb = 1'b1;
        loopback_en = 1'b0;

        $display("============================================================");
        $display("       APB UART Controller - Self-Checking Testbench        ");
        $display("============================================================");
        $display("Clock Period: %0d ns  |  Baud Divisor: %0d", CLK_PERIOD, BAUD_DIV);
        $display("Bit Period:   %0d ns  |  Frame Period: %0d ns", BIT_PERIOD, FRAME_PERIOD);
        $display("============================================================\n");

        // TEST GROUP 1: Reset Behavior
        $display("=== TEST GROUP 1: Reset Behavior ===");

        PRESETn = 1'b0;
        repeat(5) @(posedge PCLK);

        check_bit(1'b1, uart_txd, "TX line HIGH during reset");

        PRESETn = 1'b1;
        repeat(3) @(posedge PCLK);

        apb_read(ADDR_STATUS, read_data);
        check(32'h0000_0002, read_data, "STATUS after reset");

        apb_read(ADDR_CTRL, read_data);
        check(32'h0000_0000, read_data, "CTRL after reset");

        apb_read(ADDR_BAUD_DIV, read_data);
        check(32'h0000_001B, read_data, "BAUD_DIV default (27)");

        // TEST GROUP 2: APB Register Write/Read
        $display("\n=== TEST GROUP 2: APB Register Write/Read ===");

        apb_write(ADDR_BAUD_DIV, {16'd0, 16'd3});
        apb_read(ADDR_BAUD_DIV, read_data);
        check(32'h0000_0003, read_data, "BAUD_DIV write/read");

        apb_write(ADDR_CTRL, 32'h0000_0007);
        apb_read(ADDR_CTRL, read_data);
        check(32'h0000_0007, read_data, "CTRL write/read");

        apb_write(ADDR_CTRL, 32'h0000_0005);
        apb_read(ADDR_CTRL, read_data);
        check(32'h0000_0005, read_data, "CTRL update verify");

        apb_write(ADDR_CTRL, 32'h0000_0007);

        // TEST GROUP 3: PSLVERR on Invalid Address
        $display("\n=== TEST GROUP 3: APB Error Response ===");

        @(posedge PCLK);
        PSEL = 1; PENABLE = 0; PWRITE = 0; PADDR = 8'hFF;
        @(posedge PCLK);
        PENABLE = 1;
        @(posedge PCLK);
        check_bit(1'b1, PSLVERR, "PSLVERR on invalid addr 0xFF");
        PSEL = 0; PENABLE = 0;
        @(posedge PCLK);

        // TEST GROUP 4: UART Loopback Tests (TX -> RX)
        $display("\n=== TEST GROUP 4: UART Loopback Tests ===");

        loopback_en = 1'b1;

        loopback_test(8'h55, "Pattern 0x55");
        loopback_test(8'hAA, "Pattern 0xAA");
        loopback_test(8'hFF, "All ones 0xFF");
        loopback_test(8'h00, "All zeros 0x00");
        loopback_test(8'hA5, "Pattern 0xA5");
        loopback_test(8'h41, "ASCII 'A' 0x41");
        loopback_test(8'h5A, "Pattern 0x5A");
        loopback_test(8'hC3, "Pattern 0xC3");

        // TEST GROUP 5: Independent RX Test (TB bit-bang -> DUT)
        $display("\n=== TEST GROUP 5: Independent RX Test ===");

        loopback_en = 1'b0;
        uart_rxd_tb = 1'b1;

        #(BIT_PERIOD * 2);

        $display("\n--- Sending 0x37 via TB bit-bang ---");
        uart_send_byte(8'h37);

        #(BIT_PERIOD * 3);

        apb_read(ADDR_STATUS, read_data);
        check_bit(1'b1, read_data[2], "RX valid after TB send");

        apb_read(ADDR_RXDATA, read_data);
        check(32'h0000_0037, read_data, "RX data = 0x37 from TB");

        $display("\n--- Sending 0x4D via TB bit-bang ---");
        #(BIT_PERIOD);
        uart_send_byte(8'h4D);
        #(BIT_PERIOD * 3);

        apb_read(ADDR_STATUS, read_data);
        check_bit(1'b1, read_data[2], "RX valid after 0x4D");

        apb_read(ADDR_RXDATA, read_data);
        check(32'h0000_004D, read_data, "RX data = 0x4D from TB");

        // TEST GROUP 6: TX Waveform Verification
        $display("\n=== TEST GROUP 6: TX Waveform Verification ===");
        loopback_en = 1'b0;
        uart_rxd_tb = 1'b1;

        check_bit(1'b1, uart_txd, "TX idle HIGH before transmit");

        $display("\n--- Monitoring TX waveform for 0xA5 ---");
        apb_write(ADDR_TXDATA, 32'h0000_00A5);

        @(negedge uart_txd);
        check_bit(1'b0, uart_txd, "TX start bit detected (LOW)");

        #(BIT_PERIOD);
        begin : tx_wave_check
            reg [7:0] expected_bits;
            integer bi;
            expected_bits = 8'hA5;
            for (bi = 0; bi < 8; bi = bi + 1) begin
                #(BIT_PERIOD / 2);
                check_bit(expected_bits[bi], uart_txd, "TX data bit");
                #(BIT_PERIOD / 2);
            end
        end

        #(BIT_PERIOD / 2);
        check_bit(1'b1, uart_txd, "TX stop bit (HIGH)");
        #(BIT_PERIOD);

        // TEST GROUP 7: Back-to-Back TX Test
        $display("\n=== TEST GROUP 7: Back-to-Back TX ===");

        loopback_en = 1'b1;

        apb_write(ADDR_TXDATA, 32'h0000_00DE);
        #(FRAME_PERIOD + BIT_PERIOD * 3);

        apb_read(ADDR_RXDATA, read_data);
        check(32'h0000_00DE, read_data, "Back-to-back byte 1 (0xDE)");

        apb_write(ADDR_TXDATA, 32'h0000_00AD);
        #(FRAME_PERIOD + BIT_PERIOD * 3);

        apb_read(ADDR_RXDATA, read_data);
        check(32'h0000_00AD, read_data, "Back-to-back byte 2 (0xAD)");

        // TEST GROUP 8: Baud Divisor Reconfiguration
        $display("\n=== TEST GROUP 8: Baud Divisor Change ===");

        apb_write(ADDR_BAUD_DIV, 32'h0000_0005);
        apb_read(ADDR_BAUD_DIV, read_data);
        check(32'h0000_0005, read_data, "New BAUD_DIV = 5");

        apb_write(ADDR_TXDATA, 32'h0000_0072);
        #(16 * 6 * CLK_PERIOD * 10 + BIT_PERIOD * 3);

        apb_read(ADDR_STATUS, read_data);
        check_bit(1'b1, read_data[2], "RX valid with new baud");

        apb_read(ADDR_RXDATA, read_data);
        check(32'h0000_0072, read_data, "Data correct new baud 0x72");

        apb_write(ADDR_BAUD_DIV, {16'd0, 16'd3});

        // TEST GROUP 9: TX Busy Behavior
        $display("\n=== TEST GROUP 9: TX Busy Check ===");

        apb_write(ADDR_TXDATA, 32'h0000_00BB);

        apb_read(ADDR_STATUS, read_data);
        check_bit(1'b1, read_data[0], "TX busy = 1 during TX");
        check_bit(1'b0, read_data[1], "TX ready = 0 during TX");

        #(FRAME_PERIOD + BIT_PERIOD * 3);

        apb_read(ADDR_STATUS, read_data);
        check_bit(1'b0, read_data[0], "TX busy = 0 after TX done");
        check_bit(1'b1, read_data[1], "TX ready = 1 after TX done");

        apb_read(ADDR_RXDATA, read_data);

        // TEST GROUP 10: UART Enable/Disable
        $display("\n=== TEST GROUP 10: Enable/Disable ===");

        apb_write(ADDR_CTRL, 32'h0000_0005);

        apb_write(ADDR_TXDATA, 32'h0000_00EE);
        repeat(5) @(posedge PCLK);
        apb_read(ADDR_STATUS, read_data);
        check_bit(1'b0, read_data[0], "TX busy=0 when tx_en=0");

        apb_write(ADDR_CTRL, 32'h0000_0007);

        // FINAL SUMMARY
        #(CLK_PERIOD * 20);
        $display("\n============================================================");
        $display("                    TEST SUMMARY                            ");
        $display("============================================================");
        $display("  Total Tests : %0d", pass_count + fail_count);
        $display("  PASSED      : %0d", pass_count);
        $display("  FAILED      : %0d", fail_count);
        $display("============================================================");
        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** SOME TESTS FAILED - REVIEW ABOVE ***");
        $display("============================================================\n");
        $finish;
    end

    initial begin
        $dumpfile("apb_uart_tb.vcd");
        $dumpvars(0, apb_uart_tb);
    end

    initial begin
        #(FRAME_PERIOD * 50);
        $display("\n[ERROR] Simulation timeout! Possible hang detected.");
        $display("============================================================");
        $display("  Total Tests : %0d", pass_count + fail_count);
        $display("  PASSED      : %0d", pass_count);
        $display("  FAILED      : %0d", fail_count);
        $display("============================================================");
        $finish;
    end

endmodule
