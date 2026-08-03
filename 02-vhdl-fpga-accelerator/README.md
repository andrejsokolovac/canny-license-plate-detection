# VHDL FPGA Canny Edge Detection Accelerator

This directory contains the second development stage of the license plate detection system: the RTL implementation and FPGA integration of the Canny Edge Detection accelerator.

The hardware-oriented SystemC model from the previous stage was transferred to VHDL and implemented as a custom FPGA IP core for a Xilinx Zynq platform.

## Overview

The Canny Edge Detection algorithm was redesigned at the RTL level using:

- finite-state machines;
- counters and registers;
- BRAM-based image storage;
- sequential processing of image pixels and local neighborhoods.

Software loops from the C/SystemC implementation were replaced with FSM-controlled operations for memory access, arithmetic processing, and result storage.

The implementation includes both the original VHDL design and the AXI-connected IP core used for communication with the ARM processing system.

## Canny Processing Pipeline

The VHDL accelerator implements the following processing stages:

1. Gaussian filtering
2. Sobel gradient calculation
3. Gradient magnitude and direction calculation
4. Non-maximum suppression
5. Double thresholding
6. Hysteresis
7. Final edge-image generation

A multi-stage FSM controls pixel traversal, neighborhood reads, arithmetic operations, and data transfers between the processing stages.

## Memory Subsystem

The design uses separate BRAM memories for:

- input grayscale image;
- Gaussian-filtered image;
- gradient magnitude;
- gradient direction;
- non-maximum suppression result;
- threshold result;
- final edge image.

This organization separates intermediate processing results and enables controlled access by the Canny accelerator and the processor-side interface.

## AXI Interfaces

The packaged Canny IP core contains two AXI slave interfaces.

### AXI4-Lite

AXI4-Lite is used for control, configuration, and status registers:

- image rows;
- image columns;
- low threshold;
- high threshold;
- start;
- ready.

The processor configures the accelerator, starts processing, and monitors the ready status through these registers.

### AXI4-Full

AXI4-Full is used for high-throughput image transfer.

Four consecutive 8-bit grayscale pixels are packed into one 32-bit AXI data word. The same organization is used when reading the final edge image from the IP memory space.

## RTL Verification

The VHDL testbench performs the complete accelerator flow:

1. Loads the grayscale input image.
2. Transfers the image through the AXI4-Full interface.
3. Configures rows, columns, thresholds, and start through AXI4-Lite.
4. Waits for the ready signal.
5. Reads the final edge image.
6. Compares the result with SystemC-generated reference data.

The comparison is performed pixel by pixel within the valid image-processing region.

## Vivado Integration

The design was packaged as a reusable custom IP core and integrated into a Zynq processing-system design in Vivado.

The complete system includes:

- Zynq Processing System;
- AXI interconnect;
- Canny Edge Detection IP core;
- AXI4-Lite control interface;
- AXI4-Full image-memory interface;
- reset and clock infrastructure.

Tcl scripts are provided for project creation and IP packaging.

## Vitis Bare-Metal Application

A bare-metal C application was developed in Vitis to control and test the implemented accelerator.

The application:

- packs four grayscale pixels into each 32-bit word;
- writes the input image through AXI4-Full;
- configures the accelerator through AXI4-Lite;
- performs the start/ready handshake;
- reads the final edge image;
- measures image-transfer, hardware-processing, and result-retrieval times;
- calculates IP-only and end-to-end system performance.

## Directory Structure

```text
02-vhdl-fpga-accelerator/
├── hdl_source/   # VHDL RTL, memory subsystem, and AXI IP source files
├── script/       # Vivado Tcl scripts for project creation and IP packaging
├── software/     # Vitis bare-metal application
├── tb/           # VHDL testbench, input data, and reference vectors
└── README.md
