# =============================================================================
# ModelSim Simulation Script for APB UART Controller
# Usage: In ModelSim, navigate to the sim/ directory and run:
#        do run_sim.do
# =============================================================================

# Quit any existing simulation
quit -sim

# Create work library
vlib work
vmap work work

# Compile RTL sources (order: leaf modules first, top-level last)
vlog -work work ../rtl/baud_generator.v
vlog -work work ../rtl/uart_tx.v
vlog -work work ../rtl/uart_rx.v
vlog -work work ../rtl/apb_slave.v
vlog -work work ../rtl/apb_uart_controller.v

# Compile testbench
vlog -work work ../tb/apb_uart_tb.v

# Load simulation
vsim -t 1ps -novopt work.apb_uart_tb

# ---- Add Waveform Signals ----

# Top-level APB signals
add wave -divider "APB Interface"
add wave -radix hex /apb_uart_tb/PCLK
add wave -radix hex /apb_uart_tb/PRESETn
add wave -radix hex /apb_uart_tb/PSEL
add wave -radix hex /apb_uart_tb/PENABLE
add wave -radix hex /apb_uart_tb/PWRITE
add wave -radix hex /apb_uart_tb/PADDR
add wave -radix hex /apb_uart_tb/PWDATA
add wave -radix hex /apb_uart_tb/PRDATA
add wave -radix hex /apb_uart_tb/PREADY
add wave -radix hex /apb_uart_tb/PSLVERR

# UART serial lines
add wave -divider "UART Serial"
add wave /apb_uart_tb/uart_txd
add wave /apb_uart_tb/uart_rxd
add wave /apb_uart_tb/loopback_en

# APB Slave / Registers
add wave -divider "APB Slave Internals"
add wave -radix hex /apb_uart_tb/dut/u_apb_slave/tx_data
add wave /apb_uart_tb/dut/u_apb_slave/tx_start
add wave -radix hex /apb_uart_tb/dut/u_apb_slave/ctrl_reg
add wave -radix hex /apb_uart_tb/dut/u_apb_slave/baud_div
add wave /apb_uart_tb/dut/u_apb_slave/rx_valid_flag
add wave -radix hex /apb_uart_tb/dut/u_apb_slave/rx_data_reg
add wave /apb_uart_tb/dut/u_apb_slave/frame_err_flag

# Baud Generator
add wave -divider "Baud Generator"
add wave /apb_uart_tb/dut/u_baud_gen/enable
add wave -radix unsigned /apb_uart_tb/dut/u_baud_gen/counter
add wave -radix unsigned /apb_uart_tb/dut/u_baud_gen/divisor
add wave /apb_uart_tb/dut/u_baud_gen/tick

# TX FSM
add wave -divider "UART TX"
add wave -radix unsigned /apb_uart_tb/dut/u_uart_tx/state
add wave -radix unsigned /apb_uart_tb/dut/u_uart_tx/tick_cnt
add wave -radix unsigned /apb_uart_tb/dut/u_uart_tx/bit_cnt
add wave -radix hex /apb_uart_tb/dut/u_uart_tx/shift_reg
add wave /apb_uart_tb/dut/u_uart_tx/uart_txd
add wave /apb_uart_tb/dut/u_uart_tx/tx_busy
add wave /apb_uart_tb/dut/u_uart_tx/tx_done
add wave /apb_uart_tb/dut/u_uart_tx/tx_start

# RX FSM
add wave -divider "UART RX"
add wave -radix unsigned /apb_uart_tb/dut/u_uart_rx/state
add wave -radix unsigned /apb_uart_tb/dut/u_uart_rx/tick_cnt
add wave -radix unsigned /apb_uart_tb/dut/u_uart_rx/bit_cnt
add wave -radix hex /apb_uart_tb/dut/u_uart_rx/shift_reg
add wave /apb_uart_tb/dut/u_uart_rx/rxd_s
add wave -radix hex /apb_uart_tb/dut/u_uart_rx/rx_data
add wave /apb_uart_tb/dut/u_uart_rx/rx_valid
add wave /apb_uart_tb/dut/u_uart_rx/rx_busy
add wave /apb_uart_tb/dut/u_uart_rx/frame_error

# Run simulation
run -all

# Zoom to fit all waveforms
wave zoom full
