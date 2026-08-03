`ifndef CANNY_SEQ_ITEM_SV
`define CANNY_SEQ_ITEM_SV

import uvm_pkg::*;
`include "uvm_macros.svh"


// ============================================================
// Tip transakcije koju Canny sekvenca šalje driver-u
// ============================================================

typedef enum {
  AXI_LITE_WRITE,
  AXI_LITE_READ,
  AXI_FULL_WRITE_BURST,
  AXI_FULL_READ_BURST,
  START_PROCESSING,
  WAIT_READY
} canny_trans_type_t;


// ============================================================
// Canny sequence item
//
// Ovaj objekat samo opisuje jednu zahtevanu operaciju.
// Ne upravlja direktno AXI signalima - to ?e raditi driver.
// ============================================================

class canny_seq_item extends uvm_sequence_item;

  // Vrsta zahtevane operacije.
  rand canny_trans_type_t trans_type;


  // ==========================================================
  // Opšta adresa i podatak
  //
  // Za AXI-Lite driver koristi addr[4:0].
  // Za AXI-Full driver koristi addr[18:0].
  // ==========================================================

  rand bit [31:0] addr;
  rand bit [31:0] data;


  // ==========================================================
  // AXI-Full burst
  //
  // burst_len predstavlja broj 32-bitnih beat-ova:
  //   1   -> ARLEN/AWLEN = 0
  //   256 -> ARLEN/AWLEN = 255
  // ==========================================================

  rand int unsigned burst_len;


  // Podaci koje sekvenca šalje driver-u pri upisu slike.
  rand bit [31:0] burst_data[];


  // Podaci koje driver vra?a nakon AXI-Full ?itanja.
  bit [31:0] read_burst_data[];


  // Podatak koji driver vra?a nakon AXI-Lite ?itanja.
  bit [31:0] read_data;


  // ==========================================================
  // Ograni?enje AXI burst dužine
  // ==========================================================

  constraint valid_burst_len_c {
    if (
      trans_type inside {
        AXI_FULL_WRITE_BURST,
        AXI_FULL_READ_BURST
      }
    ) {
      burst_len inside {[1:256]};
    }
  }


  // ==========================================================
  // UVM factory registracija
  // ==========================================================

  `uvm_object_utils_begin(canny_seq_item)

    `uvm_field_enum(
      canny_trans_type_t,
      trans_type,
      UVM_ALL_ON
    )

    `uvm_field_int(
      addr,
      UVM_ALL_ON
    )

    `uvm_field_int(
      data,
      UVM_ALL_ON
    )

    `uvm_field_int(
      burst_len,
      UVM_ALL_ON
    )

    `uvm_field_array_int(
      burst_data,
      UVM_ALL_ON
    )

    `uvm_field_array_int(
      read_burst_data,
      UVM_ALL_ON
    )

    `uvm_field_int(
      read_data,
      UVM_ALL_ON
    )

  `uvm_object_utils_end


  // ==========================================================
  // Konstruktor
  // ==========================================================

  function new(
    input string name = "canny_seq_item"
  );

    super.new(name);

  endfunction

endclass

`endif