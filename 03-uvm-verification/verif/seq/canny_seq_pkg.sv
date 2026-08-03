`ifndef CANNY_SEQ_PKG_SV
`define CANNY_SEQ_PKG_SV

package canny_seq_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import canny_config_pkg::*;
  import canny_agent_pkg::*;

  `include "seq/canny_sequences.sv"

endpackage

`endif