# FPGA-Based License Plate Detection System

Hardware/software co-design project for license plate detection using a custom Canny Edge Detection accelerator implemented on a Xilinx Zynq platform.

The project follows the complete development flow from high-level system modeling to FPGA implementation, verification, bare-metal control, and Embedded Linux integration.

## Project Overview

The original license plate detection algorithm was prototyped using Python and OpenCV and later adapted to C++. Performance analysis identified the Canny Edge Detection stage as a suitable candidate for hardware acceleration due to its deterministic and pixel-oriented processing flow.

The complete system is divided into software and hardware components:

- The hardware accelerator performs Canny Edge Detection.
- The processor controls the accelerator, transfers image data, retrieves the result, and performs further image analysis.
- AXI4-Lite is used for control and status communication.
- AXI4-Full is used for grayscale image transfer and edge-result readback.
- BRAM memories store the input image, intermediate processing results, and final edge image.

## Development Flow

### 1. SystemC Virtual Platform

A TLM 2.0 virtual platform was developed to model the system architecture before RTL implementation.

The platform includes:

- CPU
- Interconnect
- BRAM
- Custom Canny accelerator

It implements memory-mapped communication, address-based transaction routing, SystemC timing annotations, and event-driven CPU-accelerator synchronization.

[Open SystemC Virtual Platform](./01-systemc-virtual-platform)

### 2. VHDL FPGA Accelerator

The Canny algorithm was transferred from the SystemC model to a VHDL RTL implementation.

This stage includes:

- Multi-stage FSM-based Canny processing
- BRAM-based memory subsystem
- AXI4-Lite control and status registers
- AXI4-Full image transfer
- VHDL testbench
- Vivado IP packaging scripts
- Vitis bare-metal application

[Open VHDL FPGA Accelerator](./02-vhdl-fpga-accelerator)

### 3. UVM Verification

A SystemVerilog/UVM verification environment was developed for the VHDL Canny accelerator.

The environment includes:

- Agent
- Driver
- Sequencer
- Monitor
- Scoreboard
- Functional coverage
- AXI4-Lite and AXI4-Full sequences
- SystemC-generated golden reference vectors
- Automated Tcl regression and coverage reporting

[Open UVM Verification](./03-uvm-verification)

### 4. Embedded Linux Integration

The accelerator was integrated into an Embedded Linux system running on a Digilent Zybo board.

This stage includes:

- Linux platform driver
- Device tree configuration
- Character device interfaces
- User-space C application
- Bitstream loading
- Kernel module integration
- Automated end-to-end execution using a shell script

[Open Embedded Linux Integration](./04-embedded-linux)

## Target Platform

- Digilent Zybo
- Xilinx Zynq-7000 SoC
- ARM Processing System and FPGA Programmable Logic

## Main Technologies

- C and C++
- SystemC and TLM 2.0
- VHDL
- SystemVerilog and UVM
- Embedded Linux
- Linux platform drivers
- Device tree
- AXI4-Lite and AXI4-Full
- BRAM
- Tcl and shell scripting
- Vivado
- Vitis
- Git

## Repository Structure

```text
canny-license-plate-detection/
├── 01-systemc-virtual-platform/
├── 02-vhdl-fpga-accelerator/
├── 03-uvm-verification/
├── 04-embedded-linux/
└── README.md

