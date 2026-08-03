# Canny License Plate Detection Accelerator

Hardware/software co-design project for license plate detection using a Canny Edge Detection accelerator on a Xilinx Zynq platform.

## Project Structure

- `01-systemc-virtual-platform` – SystemC TLM 2.0 virtual platform
- `02-vhdl-fpga-accelerator` – VHDL implementation, AXI interfaces, and bare-metal application
- `03-uvm-verification` – SystemVerilog/UVM verification environment
- `04-embedded-linux` – Linux platform driver, device tree, user-space application, and execution script
