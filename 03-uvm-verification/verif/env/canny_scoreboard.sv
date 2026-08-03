`ifndef CANNY_SCOREBOARD_SV
`define CANNY_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import canny_agent_pkg::*;
import canny_config_pkg::*;


// ============================================================
// Canny scoreboard
//
// Struktura prati kolegin lbp_scoreboard:
//
//   uvm_scoreboard
//   uvm_analysis_imp
//   cfg iz config_db
//   write() za proveru
//   report_phase() za zavrsni rezultat
//
// Canny-specific behavior:
//
//   - ignorise AXI-Full citanja ulazne memorije
//   - prihvata citanja od izlazne baze 0x40000
//   - raspakuje 4 piksela iz jedne 32-bitne reci
//   - poredi samo validnu zonu slike
//   - detektuje duple i nedostajuce izlazne reci
// ============================================================

class canny_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(canny_scoreboard)


  // Monitor salje canny_seq_item transakcije na ovaj export.

  uvm_analysis_imp #(
    canny_seq_item,
    canny_scoreboard
  ) item_collected_export;


  canny_config cfg;


  // ==========================================================
  // Canny memory map
  // ==========================================================

  localparam bit [31:0] OUTPUT_BASE_ADDR =
    32'h0004_0000;


  // ==========================================================
  // Validna zona za 512 x 384 automobilsku sliku
  //
  // Redovi:
  //   5 .. 378
  //
  // Kolone:
  //   5 .. 506
  //
  // Broj piksela:
  //   374 x 502 = 187748
  // ==========================================================

  localparam int unsigned VALID_ROW_MIN = 5;
  localparam int unsigned VALID_ROW_MAX = 378;

  localparam int unsigned VALID_COL_MIN = 5;
  localparam int unsigned VALID_COL_MAX = 506;


  // ==========================================================
  // Ocekivane velicine
  // ==========================================================

  int unsigned total_pixel_count;
  int unsigned expected_word_count;
  int unsigned expected_valid_pixel_count;

  bit [31:0] output_last_word_addr;


  // ==========================================================
  // Pracenje primljenih reci
  //
  // Jedan bit za svaku od 49152 izlazne reci.
  // Koristi se za detekciju:
  //
  //   - duplih citanja
  //   - nedostajucih citanja
  // ==========================================================

  bit seen_output_word[];


  // ==========================================================
  // Brojaci
  // ==========================================================

  int unsigned output_word_count;

  int unsigned received_pixel_count;
  int unsigned compared_pixel_count;
  int unsigned ignored_border_pixel_count;

  int unsigned pixel_match_count;
  int unsigned pixel_mismatch_count;

  int unsigned duplicate_word_count;
  int unsigned invalid_address_count;

  int unsigned printed_mismatch_count;


  // Ogranicavamo detaljan ispis da log ne bi imao
  // hiljade UVM_ERROR poruka ukoliko postoji sistemska greska.

  localparam int unsigned MAX_PRINTED_MISMATCHES = 20;


  function new(
    string name = "canny_scoreboard",
    uvm_component parent = null
  );

    super.new(name, parent);


    item_collected_export =
      new(
        "item_collected_export",
        this
      );


    output_word_count          = 0;

    received_pixel_count       = 0;
    compared_pixel_count       = 0;
    ignored_border_pixel_count = 0;

    pixel_match_count          = 0;
    pixel_mismatch_count       = 0;

    duplicate_word_count       = 0;
    invalid_address_count      = 0;

    printed_mismatch_count     = 0;

  endfunction


  // ==========================================================
  // Build phase
  // ==========================================================

  virtual function void build_phase(
    uvm_phase phase
  );

    int unsigned i;


    super.build_phase(phase);


    if (
      !uvm_config_db#(canny_config)::get(
        this,
        "",
        "cfg",
        cfg
      )
    ) begin

      `uvm_fatal(
        "CANNY_SB",
        "Canny configuration was not found."
      )

    end


    if (
      cfg == null
    ) begin

      `uvm_fatal(
        "CANNY_SB",
        "Received canny_config object is null."
      )

    end


    total_pixel_count =
      cfg.rows * cfg.cols;


    expected_word_count =
      (total_pixel_count + 3) / 4;


    expected_valid_pixel_count =
      (
        VALID_ROW_MAX -
        VALID_ROW_MIN +
        1
      ) *
      (
        VALID_COL_MAX -
        VALID_COL_MIN +
        1
      );


    if (
      cfg.expected_pixels.size() !=
      total_pixel_count
    ) begin

      `uvm_fatal(
        "CANNY_SB",
        $sformatf(
          {
            "Invalid expected pixel array size: ",
            "actual=%0d expected=%0d."
          },
          cfg.expected_pixels.size(),
          total_pixel_count
        )
      )

    end


    output_last_word_addr =
      OUTPUT_BASE_ADDR +
      expected_word_count * 4 -
      4;


    seen_output_word =
      new[expected_word_count];


    for (
      i = 0;
      i < expected_word_count;
      i++
    ) begin

      seen_output_word[i] =
        1'b0;

    end


    `uvm_info(
      "CANNY_SB",
      $sformatf(
        {
          "Canny scoreboard build completed: ",
          "pixels=%0d words=%0d ",
          "valid_pixels=%0d ",
          "output_range=0x%05h..0x%05h."
        },
        total_pixel_count,
        expected_word_count,
        expected_valid_pixel_count,
        OUTPUT_BASE_ADDR,
        output_last_word_addr
      ),
      UVM_LOW
    )

  endfunction


  // ==========================================================
  // Write
  //
  // Poziva se svaki put kada monitor prosledi jednu procitanu
  // AXI-Full 32-bitnu rec.
  // ==========================================================

  virtual function void write(
    canny_seq_item tr
  );

    int unsigned word_index;
    int unsigned pixel_index;

    int unsigned row_index;
    int unsigned col_index;

    int unsigned byte_lane;

    bit [7:0] dut_pixel;
    bit [7:0] expected_pixel;


    // --------------------------------------------------------
    // Scoreboard obradjuje samo AXI-Full read transakcije.
    // --------------------------------------------------------

    if (
      tr.trans_type !=
      AXI_FULL_READ_BURST
    ) begin

      return;

    end


    // --------------------------------------------------------
    // Ignorisemo kontrolna citanja ulazne grayscale memorije.
    //
    // Input memory:
    //   0x00000 .. 0x2FFFC
    //
    // Output memory:
    //   0x40000 .. 0x6FFFC
    // --------------------------------------------------------

    if (
      tr.addr < OUTPUT_BASE_ADDR
    ) begin

      return;

    end


    // --------------------------------------------------------
    // Provera izlaznog adresnog opsega.
    // --------------------------------------------------------

    if (
      tr.addr > output_last_word_addr
    ) begin

      invalid_address_count++;


      `uvm_error(
        "CANNY_SB",
        $sformatf(
          {
            "Output read address is outside expected range: ",
            "addr=0x%08h expected=0x%08h..0x%08h."
          },
          tr.addr,
          OUTPUT_BASE_ADDR,
          output_last_word_addr
        )
      )


      return;

    end


    // --------------------------------------------------------
    // AXI adresa mora biti poravnata na 4 bajta.
    // --------------------------------------------------------

    if (
      (
        tr.addr -
        OUTPUT_BASE_ADDR
      ) % 4 != 0
    ) begin

      invalid_address_count++;


      `uvm_error(
        "CANNY_SB",
        $sformatf(
          {
            "Unaligned output word address: ",
            "addr=0x%08h."
          },
          tr.addr
        )
      )


      return;

    end


    // --------------------------------------------------------
    // Izracunavanje indeksa 32-bitne reci.
    // --------------------------------------------------------

    word_index =
      (
        tr.addr -
        OUTPUT_BASE_ADDR
      ) >> 2;


    if (
      word_index >=
      expected_word_count
    ) begin

      invalid_address_count++;


      `uvm_error(
        "CANNY_SB",
        $sformatf(
          {
            "Calculated output word index is invalid: ",
            "word=%0d expected_range=0..%0d."
          },
          word_index,
          expected_word_count - 1
        )
      )


      return;

    end


    // --------------------------------------------------------
    // Detekcija duplog citanja iste izlazne reci.
    // --------------------------------------------------------

    if (
      seen_output_word[word_index] ===
      1'b1
    ) begin

      duplicate_word_count++;


      `uvm_error(
        "CANNY_SB",
        $sformatf(
          {
            "Duplicate output word received: ",
            "word=%0d addr=0x%08h."
          },
          word_index,
          tr.addr
        )
      )


      return;

    end


    seen_output_word[word_index] =
      1'b1;


    output_word_count++;


    // --------------------------------------------------------
    // Raspakivanje jedne 32-bitne reci.
    //
    // Little-endian raspored:
    //
    //   bits  7:0  -> pixel 4*N + 0
    //   bits 15:8  -> pixel 4*N + 1
    //   bits 23:16 -> pixel 4*N + 2
    //   bits 31:24 -> pixel 4*N + 3
    // --------------------------------------------------------

    for (
      byte_lane = 0;
      byte_lane < 4;
      byte_lane++
    ) begin

      pixel_index =
        word_index * 4 +
        byte_lane;


      if (
        pixel_index >=
        total_pixel_count
      ) begin

        continue;

      end


      dut_pixel =
        tr.data[
          byte_lane * 8 +: 8
        ];


      expected_pixel =
        cfg.expected_pixels[
          pixel_index
        ];


      row_index =
        pixel_index /
        cfg.cols;


      col_index =
        pixel_index %
        cfg.cols;


      received_pixel_count++;


      // ------------------------------------------------------
      // Poredimo samo validnu zonu.
      // ------------------------------------------------------

      if (
        row_index >= VALID_ROW_MIN &&
        row_index <= VALID_ROW_MAX &&
        col_index >= VALID_COL_MIN &&
        col_index <= VALID_COL_MAX
      ) begin

        compared_pixel_count++;


        if (
          dut_pixel ===
          expected_pixel
        ) begin

          pixel_match_count++;

        end
        else begin

          pixel_mismatch_count++;


          if (
            printed_mismatch_count <
            MAX_PRINTED_MISMATCHES
          ) begin

            printed_mismatch_count++;


            `uvm_error(
              "CANNY_SB",
              $sformatf(
                {
                  "EDGE PIXEL MISMATCH: ",
                  "pixel=%0d row=%0d col=%0d ",
                  "word=%0d addr=0x%08h lane=%0d ",
                  "DUT=%0d EXPECTED=%0d."
                },
                pixel_index,
                row_index,
                col_index,
                word_index,
                tr.addr,
                byte_lane,
                dut_pixel,
                expected_pixel
              )
            )

          end

        end

      end
      else begin

        ignored_border_pixel_count++;

      end

    end


    // --------------------------------------------------------
    // Periodicni napredak na svakih 4096 reci.
    // --------------------------------------------------------

    if (
      (
        output_word_count % 4096
      ) == 0
    ) begin

      `uvm_info(
        "CANNY_SB",
        $sformatf(
          {
            "Output comparison progress: ",
            "words=%0d/%0d ",
            "compared_pixels=%0d/%0d ",
            "mismatches=%0d."
          },
          output_word_count,
          expected_word_count,
          compared_pixel_count,
          expected_valid_pixel_count,
          pixel_mismatch_count
        ),
        UVM_LOW
      )

    end

  endfunction


  // ==========================================================
  // Report phase
  // ==========================================================

  virtual function void report_phase(
    uvm_phase phase
  );

    int unsigned missing_word_count;
    int unsigned i;


    super.report_phase(phase);


    missing_word_count =
      0;


    for (
      i = 0;
      i < expected_word_count;
      i++
    ) begin

      if (
        seen_output_word[i] !==
        1'b1
      ) begin

        missing_word_count++;

      end

    end


    `uvm_info(
      "CANNY_SB",
      "==============================================",
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      "           CANNY SCOREBOARD SUMMARY",
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      "==============================================",
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      $sformatf(
        "Output words received       : %0d / %0d",
        output_word_count,
        expected_word_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      $sformatf(
        "Missing output words        : %0d",
        missing_word_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      $sformatf(
        "Duplicate output words      : %0d",
        duplicate_word_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      $sformatf(
        "Invalid output addresses    : %0d",
        invalid_address_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      "----------------------------------------------",
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      $sformatf(
        "Pixels received             : %0d / %0d",
        received_pixel_count,
        total_pixel_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      $sformatf(
        "Valid pixels compared       : %0d / %0d",
        compared_pixel_count,
        expected_valid_pixel_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      $sformatf(
        "Border pixels ignored       : %0d",
        ignored_border_pixel_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      $sformatf(
        "Pixel matches               : %0d",
        pixel_match_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      $sformatf(
        "Pixel mismatches            : %0d",
        pixel_mismatch_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SB",
      "----------------------------------------------",
      UVM_LOW
    )


    // --------------------------------------------------------
    // Nisu primljeni izlazni rezultati.
    // --------------------------------------------------------

    if (
      output_word_count == 0
    ) begin

      `uvm_error(
        "CANNY_SB",
        {
          "Scoreboard did not receive any output ",
          "AXI-Full read transaction."
        }
      )

    end


    // --------------------------------------------------------
    // Nedostaju izlazne reci.
    // --------------------------------------------------------

    if (
      missing_word_count != 0
    ) begin

      `uvm_error(
        "CANNY_SB",
        $sformatf(
          {
            "OUTPUT IMAGE INCOMPLETE: ",
            "missing_words=%0d."
          },
          missing_word_count
        )
      )

    end


    // --------------------------------------------------------
    // Broj poredjenih piksela nije ocekivan.
    // --------------------------------------------------------

    if (
      compared_pixel_count !=
      expected_valid_pixel_count
    ) begin

      `uvm_error(
        "CANNY_SB",
        $sformatf(
          {
            "VALID PIXEL COUNT MISMATCH: ",
            "actual=%0d expected=%0d."
          },
          compared_pixel_count,
          expected_valid_pixel_count
        )
      )

    end


    // --------------------------------------------------------
    // Zavrsni PASS ili FAIL.
    // --------------------------------------------------------

    if (
      output_word_count ==
        expected_word_count &&

      missing_word_count ==
        0 &&

      duplicate_word_count ==
        0 &&

      invalid_address_count ==
        0 &&

      compared_pixel_count ==
        expected_valid_pixel_count &&

      pixel_mismatch_count ==
        0
    ) begin

      `uvm_info(
        "CANNY_SB",
        "CANNY RESULT PASS: MISMATCHES = 0",
        UVM_LOW
      )

    end
    else begin

      `uvm_error(
        "CANNY_SB",
        $sformatf(
          {
            "CANNY RESULT FAIL: ",
            "MISMATCHES=%0d ",
            "MISSING_WORDS=%0d ",
            "DUPLICATE_WORDS=%0d ",
            "INVALID_ADDRESSES=%0d."
          },
          pixel_mismatch_count,
          missing_word_count,
          duplicate_word_count,
          invalid_address_count
        )
      )

    end


    `uvm_info(
      "CANNY_SB",
      "==============================================",
      UVM_LOW
    )

  endfunction

endclass

`endif