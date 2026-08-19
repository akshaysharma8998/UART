# APB UART Controller IP Core

## Overview
This repository contains a complete, synthesizable APB-compatible Universal Asynchronous Receiver-Transmitter (UART) controller IP core designed in Verilog HDL. The core implements a highly modular RTL architecture enabling robust serial communication, equipped with an integrated APB slave interface for seamless integration into AMBA APB-based SoC architectures.

## Architecture
The design is modular and compartmentalized into four main functional blocks:
- **APB Slave Interface**: Handles read and write transactions with the AMBA APB bus, exposing control, status, and data registers.
- **Baud Rate Generator**: Synthesizes the required timing ticks for reliable UART TX and RX operations, derived from the system clock frequency.
- **UART Transmitter (TX)**: Serializes parallel data and transmits it along with the appropriate start and stop bits.
- **UART Receiver (RX)**: Validates incoming streams via oversampling, reliably detects the start bit, deserializes the bitstream, and flags the APB host upon successful reception.

## Directory Structure
- `rtl/`: Contains all synthesizable Verilog HDL source files.
- `tb/`: Contains the self-checking testbench used for comprehensive design verification.
- `sim/`: ModelSim configuration scripts (`.do` files) to easily run testbenches.
- `quartus/`: Synthesis project structure and scripts for Intel/Altera Quartus Prime.

## Verification & Synthesis
A comprehensive, self-checking testbench validates data transmission and reception reliability across extensive test cases (including mixed back-to-back TX/RX flows). The design is fully synthesizable and targeted for modern FPGA toolchains implementations.

- **To run simulation**: Run `vsim -do sim/run_sim.do` in the ModelSim command line.
- **To synthesize**: Open the `.qpf` inside the `quartus` directory via Intel Quartus Prime.
