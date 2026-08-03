# SystemC Virtual Platform for License Plate Detection

This directory contains the first development stage of the FPGA-based license plate detection system.

A SystemC TLM 2.0 virtual platform was developed to model the interaction between the processor, shared memory, interconnect, and the Canny Edge Detection accelerator before the RTL implementation.

## Overview

The original license plate detection algorithm was prototyped using Python and OpenCV and later adapted to C++.

The system was partitioned into:

- a software component responsible for image loading, accelerator control, result retrieval, contour analysis, and license plate localization;
- a hardware-oriented SystemC component responsible for Canny Edge Detection.

The virtual platform models the complete data flow from loading the input image to retrieving the processed edge image.

## Architecture

The platform consists of four main SystemC modules:

### CPU

The CPU module:

- loads the input image using OpenCV;
- prepares the grayscale image for processing;
- writes image pixels to the shared BRAM;
- configures the accelerator through memory-mapped registers;
- sends the start command;
- waits for processing to complete;
- reads the resulting edge image;
- performs contour analysis and license plate localization.

### Interconnect

The Interconnect module:

- receives TLM transactions from the CPU;
- decodes memory-mapped addresses;
- routes transactions to the BRAM or the Canny accelerator;
- models communication latency using SystemC time annotations.

### BRAM

The BRAM module models the shared memory used for:

- input grayscale image storage;
- communication between the CPU and accelerator;
- storage of the final edge-detection result.

The CPU accesses the BRAM through the Interconnect, while the accelerator uses a separate direct TLM connection.

### Canny Accelerator

The hardware-oriented SystemC module implements the main stages of Canny Edge Detection:

- Gaussian filtering;
- Sobel gradient calculation;
- gradient magnitude and direction calculation;
- non-maximum suppression;
- double thresholding;
- hysteresis.

Fixed-width SystemC integer types are used to model hardware-oriented signal and register widths.

## Communication

Communication between modules is implemented using TLM 2.0 blocking transport transactions.

The platform includes:

- memory-mapped register access;
- address-based transaction routing;
- annotated transaction delays using `sc_time`;
- event-driven CPU-accelerator synchronization;
- start and completion signaling.

## Processing Flow

1. The CPU loads and prepares the input image.
2. The image is transferred to BRAM through TLM write transactions.
3. The CPU writes the image dimensions and start command to the accelerator.
4. The accelerator reads the input pixels from BRAM.
5. Canny Edge Detection is performed.
6. The edge image is written back to BRAM.
7. The CPU reads the result and performs contour analysis.
8. The detected license plate region is marked on the original image.

## Directory Structure

```text
01-systemc-virtual-platform/
├── c++_function/       # Initial C/C++ algorithm implementation
├── data/               # Input images and reference data
├── mixed_simulation/   # Mixed SystemC/VHDL simulation files
├── spec/               # Project specification and documentation
├── vp/                 # SystemC virtual platform source code
└── README.md
