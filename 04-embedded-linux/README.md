# Embedded Linux Integration of the Canny Edge Detection Accelerator

This directory contains the fourth development stage of the license plate detection system: integration of the Canny Edge Detection accelerator into an Embedded Linux system running on a Digilent Zybo board.

The VHDL accelerator developed and verified in the previous stages is accessed from the ARM processing system through a Linux platform driver, character device interfaces, and a user-space C application.

## Overview

The Embedded Linux implementation provides the complete software stack required to control the FPGA accelerator from Linux.

The integration includes:

- FPGA bitstream loading;
- device tree configuration;
- Linux platform driver;
- AXI4-Lite control-register access;
- AXI4-Full image-memory access;
- character device interfaces;
- user-space C application;
- SystemC reference-result comparison;
- automated end-to-end execution using a shell script.

## System Architecture

The system combines:

- the ARM processing system running Embedded Linux;
- the programmable logic containing the Canny accelerator;
- AXI4-Lite for control and status communication;
- AXI4-Full for input-image and output-image transfer;
- BRAM-based storage inside the accelerator.

The processor writes a grayscale image to the accelerator memory, configures the processing parameters, starts the accelerator, waits for completion, and reads the generated edge image.

## Device Tree

The device tree describes the Canny accelerator and its memory-mapped resources.

It defines:

- the AXI4-Lite register region;
- the AXI4-Full memory region;
- the compatible string used by the Linux platform driver.

During driver initialization, these resources are obtained from the device tree and mapped into the kernel virtual address space.

## Linux Platform Driver

The Linux platform driver provides access to the Canny accelerator from user space.

Its main responsibilities include:

- matching the accelerator through the device tree;
- mapping AXI4-Lite and AXI4-Full address regions;
- registering character devices;
- configuring accelerator registers;
- transferring grayscale image data;
- starting hardware processing;
- reading the ready status;
- retrieving the final edge image.

## Character Device Interfaces

The driver exposes separate character device interfaces for:

- accelerator control and configuration;
- input grayscale image transfer;
- output edge-image retrieval.

These interfaces allow the user-space application to communicate with the accelerator using standard Linux file operations.

## User-Space Application

The user-space C application performs the complete accelerator-control flow:

1. Opens the Canny character devices.
2. Loads the grayscale input image.
3. Transfers the input image to the FPGA accelerator.
4. Configures image dimensions and threshold values.
5. Starts the hardware accelerator.
6. Waits for processing to complete.
7. Reads the final edge image.
8. Stores the hardware result.
9. Compares the output with SystemC-generated reference vectors.

## Automated Execution

The `run_canny.sh` script automates the complete execution flow.

Depending on the system configuration, the script performs operations such as:

- loading the FPGA bitstream;
- loading the kernel module;
- checking the created character devices;
- starting the user-space application;
- displaying the verification result;
- cleaning up loaded modules and temporary resources.

## Directory Structure

```text
04-embedded-linux/
├── app/            # User-space C application and build files
├── bitstream/      # FPGA configuration files
├── data/           # Input image and SystemC reference data
├── device_tree/    # Canny accelerator device tree configuration
├── driver/         # Linux platform driver and Makefile
├── run_canny.sh    # Automated end-to-end execution script
└── README.md
