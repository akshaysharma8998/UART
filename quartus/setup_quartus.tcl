# =============================================================================
# Quartus Prime TCL Setup Script for APB UART Controller
# Usage: In Quartus TCL Console (Tools > Tcl Scripts), run:
#        source setup_quartus.tcl
# Or from command line:
#        quartus_sh -t setup_quartus.tcl
# =============================================================================

# Project settings
set PROJECT_NAME "apb_uart_controller"
set TOP_ENTITY   "apb_uart_controller"

# NOTE: Change the FPGA device below to match your target board.
# Examples:
#   Cyclone IV E: EP4CE115F29C7  (DE2-115 board)
#   Cyclone V:    5CSEMA5F31C6   (DE1-SoC board)
#   MAX 10:       10M50DAF484C7G (DE10-Lite board)
set DEVICE_PART  "5CGXFC7C6F23C6"
set DEVICE_FAMILY "Cyclone V"
# Create project
project_new -revision uart_rev $PROJECT_NAME -overwrite
# Set device
set_global_assignment -name FAMILY "$DEVICE_FAMILY"
set_global_assignment -name DEVICE $DEVICE_PART
set_global_assignment -name TOP_LEVEL_ENTITY $TOP_ENTITY

# Add RTL source files
set_global_assignment -name VERILOG_FILE ../rtl/baud_generator.v
set_global_assignment -name VERILOG_FILE ../rtl/uart_tx.v
set_global_assignment -name VERILOG_FILE ../rtl/uart_rx.v
set_global_assignment -name VERILOG_FILE ../rtl/apb_slave.v
set_global_assignment -name VERILOG_FILE ../rtl/apb_uart_controller.v

# Compilation settings
set_global_assignment -name RESERVE_ALL_UNUSED_PINS_WEAK_PULLUP "AS INPUT TRI-STATED"
set_global_assignment -name OPTIMIZATION_MODE "HIGH PERFORMANCE EFFORT"
set_global_assignment -name TIMING_ANALYZER_MULTICORNER_ANALYSIS ON
set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL

# Close project setup
project_close

puts "=============================================="
puts " Quartus project '$PROJECT_NAME' created."
puts " Device: $DEVICE_PART ($DEVICE_FAMILY)"
puts " Top entity: $TOP_ENTITY"
puts "=============================================="
puts " Next steps:"
puts "   1. Open the project in Quartus Prime"
puts "   2. Processing > Start Compilation"
puts "   3. View RTL Viewer, Technology Map, etc."
puts "=============================================="
