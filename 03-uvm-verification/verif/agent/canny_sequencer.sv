`ifndef CANNY_SEQUENCER_SV
`define CANNY_SEQUENCER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"


// ============================================================
// Canny transaction sequencer.
// ============================================================

class canny_sequencer extends uvm_sequencer #(canny_seq_item);

  `uvm_component_utils(canny_sequencer)


  function new(
    input string name = "canny_sequencer",
    input uvm_component parent = null
  );

    super.new(name, parent);

  endfunction

endclass

`endif