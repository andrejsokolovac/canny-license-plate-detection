`ifndef CANNY_ENV_PKG_SV
`define CANNY_ENV_PKG_SV

`timescale 1ns / 1ps


package canny_env_pkg;

  import uvm_pkg::*;

  `include "uvm_macros.svh"


  import canny_agent_pkg::*;
  import canny_config_pkg::*;


  // Include order follows class dependencies:
  //
  // 1. scoreboard
  // 2. coverage
  // 3. environment using both components

  `include "canny_scoreboard.sv"
  `include "canny_coverage.sv"
  `include "canny_env.sv"

endpackage

`endif