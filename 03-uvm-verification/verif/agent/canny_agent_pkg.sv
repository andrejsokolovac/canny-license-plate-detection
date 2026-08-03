`ifndef CANNY_AGENT_PKG_SV
`define CANNY_AGENT_PKG_SV

`timescale 1ns / 1ps


package canny_agent_pkg;

  import uvm_pkg::*;

  `include "uvm_macros.svh"


  import canny_config_pkg::*;


  // Redosled je vazan:
  //
  // 1. sequence item
  // 2. driver
  // 3. sequencer
  // 4. monitor
  // 5. agent

  `include "canny_seq_item.sv"
  `include "canny_driver.sv"
  `include "canny_sequencer.sv"
  `include "canny_monitor.sv"
  `include "canny_agent.sv"

endpackage

`endif