`ifndef CANNY_BASE_TEST_SV
`define CANNY_BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"


// ============================================================
// Bazni Canny test
//
// Test 1:
//   grayscale_full.txt
//   final_edge_full.txt
//   LOW  = 50
//   HIGH = 100
//
// Izvedene test-klase menjaju test_index kroz
// configure_test() funkciju.
// ============================================================

class canny_base_test extends uvm_test;

  `uvm_component_utils(canny_base_test)


  // Canny konfiguracioni objekat.
  canny_config cfg;

  // Canny UVM environment.
  canny_env env;

  // Virtualni interfejs postavljen iz canny_verif_top-a.
  virtual canny_if vif;


  // ==========================================================
  // Konstruktor
  // ==========================================================

  function new(
    input string name = "canny_base_test",
    input uvm_component parent = null
  );

    super.new(
      name,
      parent
    );

  endfunction


  // ==========================================================
  // Izbor test scenarija
  //
  // Bazni test koristi prvu realnu sliku.
  // ==========================================================

  virtual function void configure_test();

    cfg.test_index = 1;

    cfg.low_threshold  = 50;
    cfg.high_threshold = 100;

  endfunction


  // ==========================================================
  // Build phase
  // ==========================================================

  virtual function void build_phase(
    uvm_phase phase
  );

    super.build_phase(
      phase
    );


    `uvm_info(
      get_type_name(),
      "Canny test build phase started.",
      UVM_LOW
    )


    // --------------------------------------------------------
    // Preuzimanje virtualnog interfejsa
    // --------------------------------------------------------

    if (
      !uvm_config_db#(virtual canny_if)::get(
        this,
        "",
        "vif",
        vif
      )
    ) begin

      `uvm_fatal(
        "CANNY_TEST",
        "Virtual interface canny_if was not found in uvm_config_db."
      )

    end


    // --------------------------------------------------------
    // Kreiranje konfiguracionog objekta
    // --------------------------------------------------------

    cfg = canny_config::type_id::create(
      "cfg"
    );


    if (
      cfg == null
    ) begin

      `uvm_fatal(
        "CANNY_TEST",
        "Failed to create canny_config object."
      )

    end


    // Prosledjivanje virtualnog interfejsa konfiguraciji.

    cfg.vif = vif;


    // --------------------------------------------------------
    // Izbor konkretnog test scenarija
    //
    // canny_base_test:
    //   test_index = 1
    //   prva realna slika
    //
    // canny_image2_test:
    //   test_index = 2
    //   druga realna slika
    //
    // canny_black_test:
    //   test_index = 3
    //   potpuno crna slika
    //
    // Svi testovi koriste pragove 50/100.
    // --------------------------------------------------------

    configure_test();


    `uvm_info(
      "CANNY_TEST",
      $sformatf(
        {
          "Selected test_index=%0d, ",
          "LOW=%0d, HIGH=%0d."
        },
        cfg.test_index,
        cfg.low_threshold,
        cfg.high_threshold
      ),
      UVM_LOW
    )


    // --------------------------------------------------------
    // Ucitavanje odgovarajuce ulazne i golden slike
    // --------------------------------------------------------

    cfg.load_golden_vectors();


    // --------------------------------------------------------
    // Prosledjivanje konfiguracije svim komponentama
    // --------------------------------------------------------

    uvm_config_db#(canny_config)::set(
      this,
      "*",
      "cfg",
      cfg
    );


    // --------------------------------------------------------
    // Kreiranje Canny environmenta
    // --------------------------------------------------------

    env = canny_env::type_id::create(
      "env",
      this
    );


    if (
      env == null
    ) begin

      `uvm_fatal(
        "CANNY_TEST",
        "Failed to create canny_env."
      )

    end


    // --------------------------------------------------------
    // Informacije o konfiguraciji testa
    // --------------------------------------------------------

    `uvm_info(
      "CANNY_TEST",
      $sformatf(
        {
          "Configuration prepared: ",
          "test_index=%0d ",
          "rows=%0d cols=%0d ",
          "low_threshold=%0d high_threshold=%0d ",
          "valid rows=%0d..%0d ",
          "valid cols=%0d..%0d"
        },
        cfg.test_index,
        cfg.rows,
        cfg.cols,
        cfg.low_threshold,
        cfg.high_threshold,
        cfg.valid_row_first,
        cfg.valid_row_last,
        cfg.valid_col_first,
        cfg.valid_col_last
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_TEST",
      $sformatf(
        {
          "Arrays prepared: ",
          "input_words=%0d expected_pixels=%0d"
        },
        cfg.input_words.size(),
        cfg.expected_pixels.size()
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_TEST",
      "Canny environment was created successfully.",
      UVM_LOW
    )

  endfunction


  // ==========================================================
  // Run phase
  // ==========================================================

  virtual task run_phase(
    uvm_phase phase
  );

    canny_smoke_sequence smoke_seq;


    phase.raise_objection(
      this
    );


    `uvm_info(
      get_type_name(),
      $sformatf(
        {
          "Starting Canny smoke sequence: ",
          "test_index=%0d LOW=%0d HIGH=%0d."
        },
        cfg.test_index,
        cfg.low_threshold,
        cfg.high_threshold
      ),
      UVM_LOW
    )


    smoke_seq = canny_smoke_sequence::type_id::create(
      "smoke_seq"
    );


    if (
      smoke_seq == null
    ) begin

      `uvm_fatal(
        "CANNY_TEST",
        "Failed to create canny_smoke_sequence."
      )

    end


    // Sekvenca koristi isti konfiguracioni objekat kao test.

    smoke_seq.cfg = cfg;


    // Pokretanje sekvence na sequenceru unutar agenta.

    smoke_seq.start(
      env.agent.sequencer
    );


    `uvm_info(
      get_type_name(),
      $sformatf(
        {
          "Canny smoke sequence completed: ",
          "test_index=%0d LOW=%0d HIGH=%0d."
        },
        cfg.test_index,
        cfg.low_threshold,
        cfg.high_threshold
      ),
      UVM_LOW
    )


    // Cekanje da monitor, scoreboard i coverage obrade
    // poslednju AXI-Full procitanu rec.

    #100ns;


    phase.drop_objection(
      this
    );

  endtask

endclass


// ============================================================
// Test 2: druga realna slika
//
// Koristi:
//
//   grayscale_full2.txt
//   final_edge_full2.txt
//
// Pragovi:
//
//   LOW  = 50
//   HIGH = 100
// ============================================================

class canny_image2_test extends canny_base_test;

  `uvm_component_utils(canny_image2_test)


  function new(
    input string name = "canny_image2_test",
    input uvm_component parent = null
  );

    super.new(
      name,
      parent
    );

  endfunction


  virtual function void configure_test();

    cfg.test_index = 2;

    cfg.low_threshold  = 50;
    cfg.high_threshold = 100;

  endfunction

endclass


// ============================================================
// Test 3: potpuno crna slika
//
// Koristi:
//
//   grayscale_full_black.txt
//   final_edge_black.txt
//
// Pragovi:
//
//   LOW  = 50
//   HIGH = 100
//
// Ovaj test proverava da Canny jezgro ne generise lazne
// ivice kada su svi ulazni pikseli jednaki nuli.
// ============================================================

class canny_black_test extends canny_base_test;

  `uvm_component_utils(canny_black_test)


  function new(
    input string name = "canny_black_test",
    input uvm_component parent = null
  );

    super.new(
      name,
      parent
    );

  endfunction


  virtual function void configure_test();

    cfg.test_index = 3;

    cfg.low_threshold  = 50;
    cfg.high_threshold = 100;

  endfunction

endclass

// ============================================================
// Test 3: polu crna polu bela slika
//
// Koristi:
//
//   grayscale_full_half.txt
//   final_edge_half.txt
//
// Pragovi:
//
//   LOW  = 50
//   HIGH = 100
//
// Ovaj test proverava da Canny jezgro  
// ispravno radi odnosno pronalazi ivicu 
// ============================================================

class canny_half_test extends canny_base_test;

  `uvm_component_utils(canny_half_test)

  function new(
    input string name = "canny_half_test",
    input uvm_component parent = null
  );

    super.new(name, parent);

  endfunction

  virtual function void configure_test();

    cfg.test_index = 4;

    cfg.low_threshold  = 50;
    cfg.high_threshold = 100;

  endfunction

endclass

`endif