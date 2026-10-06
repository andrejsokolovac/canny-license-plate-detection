`ifndef CANNY_COVERAGE_SV
`define CANNY_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import canny_agent_pkg::*;
import canny_config_pkg::*;


class canny_coverage extends uvm_subscriber #(canny_seq_item);

  `uvm_component_utils(canny_coverage)


  canny_config cfg;


  // ==========================================================
  // Memory map
  // ==========================================================

  localparam bit [31:0] OUTPUT_BASE_ADDR =
    32'h0004_0000;


  // ==========================================================
  // Valid image region
  // ==========================================================

  localparam int unsigned VALID_ROW_MIN = 5;
  localparam int unsigned VALID_ROW_MAX = 378;

  localparam int unsigned VALID_COL_MIN = 5;
  localparam int unsigned VALID_COL_MAX = 506;


  // ==========================================================
  // Sampled values
  // ==========================================================

  int unsigned sampled_edge_value;

  int unsigned sampled_image_region;

  int unsigned sampled_row_section;

  int unsigned sampled_byte_lane;

  int unsigned sampled_output_quarter;

  int unsigned sampled_low_threshold;

  int unsigned sampled_high_threshold;

  int unsigned sampled_threshold_relation;


  // sampled_image_region:
  //
  //   0 -> border region
  //   1 -> valid region


  // sampled_row_section:
  //
  //   0 -> top third of the image
  //   1 -> middle third of the image
  //   2 -> bottom third of the image


  // sampled_output_quarter:
  //
  //   0 -> first quarter of output memory
  //   1 -> second quarter of output memory
  //   2 -> third quarter of output memory
  //   3 -> fourth quarter of output memory


  // sampled_threshold_relation:
  //
  //   0 -> LOW < HIGH
  //   1 -> LOW = HIGH
  //   2 -> LOW > HIGH


  // ==========================================================
  // Helper values and counters
  // ==========================================================

  int unsigned total_pixel_count;

  int unsigned expected_word_count;

  bit [31:0] output_last_word_addr;


  int unsigned sampled_output_word_count;

  int unsigned sampled_output_pixel_count;

  int unsigned ignored_transaction_count;

  bit thresholds_sampled;


  // ==========================================================
  // Output pixel coverage
  //
  // Canny output uses:
  //
  //   0   -> no edge
  //   127 -> weak edge
  //   255 -> strong edge
  //
  // The "other" bin captures any DUT output
  // outside the three expected classes.
  // ==========================================================

  covergroup cg_canny_output_pixel;

    option.per_instance = 1;
    option.name =
      "cg_canny_output_pixel";


    cp_edge_value:
      coverpoint sampled_edge_value {

        bins background =
          {0};

        bins weak_edge =
          {127};

        bins strong_edge =
          {255};

        bins other_values =
          default;

      }


    cp_image_region:
      coverpoint sampled_image_region {

        bins border_region =
          {0};

        bins valid_region =
          {1};

      }


    cp_row_section:
      coverpoint sampled_row_section {

        bins top_section =
          {0};

        bins middle_section =
          {1};

        bins bottom_section =
          {2};

      }


    cp_byte_lane:
      coverpoint sampled_byte_lane {

        bins lane_0 =
          {0};

        bins lane_1 =
          {1};

        bins lane_2 =
          {2};

        bins lane_3 =
          {3};

      }


    cx_edge_x_row:
      cross cp_edge_value,
            cp_row_section;

  endgroup


  // ==========================================================
  // Output address coverage
  //
  // Confirms that reads span the complete output memory,
  // rather than only its beginning.
  // ==========================================================

  covergroup cg_canny_output_address;

    option.per_instance = 1;
    option.name =
      "cg_canny_output_address";


    cp_output_quarter:
      coverpoint sampled_output_quarter {

        bins first_quarter =
          {0};

        bins second_quarter =
          {1};

        bins third_quarter =
          {2};

        bins fourth_quarter =
          {3};

      }

  endgroup


  // ==========================================================
  // Functional coverage for threshold values and their relation.
  // This covergroup is sampled once per test on the first output word.
  // ==========================================================

  covergroup cg_canny_thresholds;

    option.per_instance = 1;
    option.name =
      "cg_canny_thresholds";


    cp_low_threshold:
      coverpoint sampled_low_threshold {

        bins low_zero =
          {0};

        bins low_below_nominal =
          {[1:49]};

        bins low_nominal =
          {50};

        bins low_between_nominals =
          {[51:99]};

        bins low_high_range =
          {[100:254]};

        bins low_maximum =
          {255};

      }


    cp_high_threshold:
      coverpoint sampled_high_threshold {

        bins high_zero =
          {0};

        bins high_low_range =
          {[1:49]};

        bins high_below_nominal =
          {[50:99]};

        bins high_nominal =
          {100};

        bins high_above_nominal =
          {[101:254]};

        bins high_maximum =
          {255};

      }


    cp_threshold_relation:
      coverpoint sampled_threshold_relation {

        bins low_less_than_high =
          {0};

        bins low_equal_high =
          {1};

        bins low_greater_than_high =
          {2};

      }

  endgroup


  // ==========================================================
  // Constructor
  // ==========================================================

  function new(
    string name = "canny_coverage",
    uvm_component parent = null
  );

    super.new(
      name,
      parent
    );


    cg_canny_output_pixel =
      new();


    cg_canny_output_address =
      new();


    cg_canny_thresholds =
      new();


    sampled_output_word_count  = 0;
    sampled_output_pixel_count = 0;

    ignored_transaction_count  = 0;

    thresholds_sampled =
      1'b0;

  endfunction


  // ==========================================================
  // Build phase
  // ==========================================================

  virtual function void build_phase(
    uvm_phase phase
  );

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
        "CANNY_COV",
        "Canny configuration was not found."
      )

    end


    if (
      cfg == null
    ) begin

      `uvm_fatal(
        "CANNY_COV",
        "Received canny_config object is null."
      )

    end


    total_pixel_count =
      cfg.rows * cfg.cols;


    expected_word_count =
      (
        total_pixel_count +
        3
      ) / 4;


    output_last_word_addr =
      OUTPUT_BASE_ADDR +
      expected_word_count * 4 -
      4;


    `uvm_info(
      "CANNY_COV",
      $sformatf(
        {
          "Canny coverage build completed: ",
          "pixels=%0d words=%0d ",
          "output_range=0x%05h..0x%05h."
        },
        total_pixel_count,
        expected_word_count,
        OUTPUT_BASE_ADDR,
        output_last_word_addr
      ),
      UVM_LOW
    )

  endfunction


  // ==========================================================
  // Write
  //
  // The monitor forwards one canny_seq_item transaction for
  // each AXI-Full 32-bit word read.
  // ==========================================================

  virtual function void write(
    canny_seq_item tr
  );

    int unsigned word_index;

    int unsigned pixel_index;

    int unsigned row_index;

    int unsigned col_index;

    int unsigned byte_lane;


    // --------------------------------------------------------
    // Process AXI-Full read transactions only.
    // --------------------------------------------------------

    if (
      tr.trans_type !=
      AXI_FULL_READ_BURST
    ) begin

      ignored_transaction_count++;

      return;

    end


    // --------------------------------------------------------
    // Ignore control reads from input memory.
    // --------------------------------------------------------

    if (
      tr.addr <
      OUTPUT_BASE_ADDR
    ) begin

      ignored_transaction_count++;

      return;

    end


    // --------------------------------------------------------
    // Ignore addresses outside the output image.
    //
    // The scoreboard reports such addresses as errors.
    // The coverage component simply does not sample them.
    // --------------------------------------------------------

    if (
      tr.addr >
      output_last_word_addr
    ) begin

      ignored_transaction_count++;

      return;

    end


    // --------------------------------------------------------
    // Ignore unaligned AXI addresses.
    // --------------------------------------------------------

    if (
      (
        tr.addr -
        OUTPUT_BASE_ADDR
      ) % 4 != 0
    ) begin

      ignored_transaction_count++;

      return;

    end


    // --------------------------------------------------------
    // 32-bit output word index.
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

      ignored_transaction_count++;

      return;

    end


    sampled_output_word_count++;


    // --------------------------------------------------------
    // Output-memory quarter.
    // --------------------------------------------------------

    if (
      word_index <
      expected_word_count / 4
    ) begin

      sampled_output_quarter =
        0;

    end
    else if (
      word_index <
      expected_word_count / 2
    ) begin

      sampled_output_quarter =
        1;

    end
    else if (
      word_index <
      (
        expected_word_count *
        3
      ) / 4
    ) begin

      sampled_output_quarter =
        2;

    end
    else begin

      sampled_output_quarter =
        3;

    end


    cg_canny_output_address.sample();


    // --------------------------------------------------------
    // Threshold coverage is sampled once per test.
    // --------------------------------------------------------

    if (
      thresholds_sampled ===
      1'b0
    ) begin

      sampled_low_threshold =
        cfg.low_threshold;


      sampled_high_threshold =
        cfg.high_threshold;


      if (
        cfg.low_threshold <
        cfg.high_threshold
      ) begin

        sampled_threshold_relation =
          0;

      end
      else if (
        cfg.low_threshold ==
        cfg.high_threshold
      ) begin

        sampled_threshold_relation =
          1;

      end
      else begin

        sampled_threshold_relation =
          2;

      end


      cg_canny_thresholds.sample();


      thresholds_sampled =
        1'b1;

    end


    // --------------------------------------------------------
    // Unpack four pixels from one 32-bit word.
    //
    // Little-endian layout:
    //
    //   bits  7:0  -> lane 0
    //   bits 15:8  -> lane 1
    //   bits 23:16 -> lane 2
    //   bits 31:24 -> lane 3
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


      row_index =
        pixel_index /
        cfg.cols;


      col_index =
        pixel_index %
        cfg.cols;


      sampled_edge_value =
        tr.data[
          byte_lane * 8 +: 8
        ];


      sampled_byte_lane =
        byte_lane;


      // ------------------------------------------------------
      // Validna ili border region.
      // ------------------------------------------------------

      if (
        row_index >= VALID_ROW_MIN &&
        row_index <= VALID_ROW_MAX &&
        col_index >= VALID_COL_MIN &&
        col_index <= VALID_COL_MAX
      ) begin

        sampled_image_region =
          1;

      end
      else begin

        sampled_image_region =
          0;

      end


      // ------------------------------------------------------
      // Gornja, srednja ili bottom third of the image.
      // ------------------------------------------------------

      if (
        row_index <
        cfg.rows / 3
      ) begin

        sampled_row_section =
          0;

      end
      else if (
        row_index <
        (
          cfg.rows *
          2
        ) / 3
      ) begin

        sampled_row_section =
          1;

      end
      else begin

        sampled_row_section =
          2;

      end


      cg_canny_output_pixel.sample();


      sampled_output_pixel_count++;

    end

  endfunction


  // ==========================================================
  // Report phase
  // ==========================================================

  virtual function void report_phase(
    uvm_phase phase
  );

    real cov_output_pixel;

    real cov_output_address;

    real cov_thresholds;

    real total_cov;


    super.report_phase(phase);


    cov_output_pixel =
      cg_canny_output_pixel.get_coverage();


    cov_output_address =
      cg_canny_output_address.get_coverage();


    cov_thresholds =
      cg_canny_thresholds.get_coverage();


    total_cov =
      (
        cov_output_pixel +
        cov_output_address +
        cov_thresholds
      ) / 3.0;


    `uvm_info(
      "CANNY_COV",
      "==============================================",
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      "          CANNY FUNCTIONAL COVERAGE",
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      "==============================================",
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      $sformatf(
        "Output pixel coverage       : %0.1f%%",
        cov_output_pixel
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      $sformatf(
        "Output address coverage     : %0.1f%%",
        cov_output_address
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      $sformatf(
        "Threshold coverage          : %0.1f%%",
        cov_thresholds
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      "----------------------------------------------",
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      $sformatf(
        "Output words sampled        : %0d",
        sampled_output_word_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      $sformatf(
        "Output pixels sampled       : %0d",
        sampled_output_pixel_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      $sformatf(
        "Transactions ignored        : %0d",
        ignored_transaction_count
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      "----------------------------------------------",
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      $sformatf(
        "Total functional coverage   : %0.1f%%",
        total_cov
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_COV",
      "==============================================",
      UVM_LOW
    )


    // Coverage is not a pass/fail criterion.
    // This warning only indicates that the output image was not read.

    if (
      sampled_output_word_count == 0
    ) begin

      `uvm_warning(
        "CANNY_COV",
        {
          "No output image read transactions were sampled. ",
          "Coverage remains empty."
        }
      )

    end

  endfunction

endclass

`endif
