`ifndef CANNY_TEST_PKG_SV
`define CANNY_TEST_PKG_SV

package canny_test_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import canny_config_pkg::*;
  import canny_agent_pkg::*;
  import canny_env_pkg::*;
  import canny_seq_pkg::*;
  
  `include "tests/canny_base_test.sv"

endpackage

`endif