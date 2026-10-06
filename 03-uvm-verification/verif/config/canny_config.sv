`ifndef CANNY_CONFIG_SV
`define CANNY_CONFIG_SV

import uvm_pkg::*;
`include "uvm_macros.svh"


// ============================================================
// Shared configuration and golden-vector data for Canny UVM tests.
// ============================================================

class canny_config extends uvm_object;

  // Virtualni interfejs koji koriste UVM komponente.
  virtual canny_if vif;


  // ==========================================================
  // Canny konfiguracioni parametri
  // ==========================================================

  int unsigned rows;
  int unsigned cols;

  int unsigned low_threshold;
  int unsigned high_threshold;

  int unsigned test_index;


  // ==========================================================
  // Validna zona koja se poredi u scoreboard-u
  //
  // Za sliku 384 x 512:
  //   redovi  = 5 ... 378
  //   kolone  = 5 ... 506
  // ==========================================================

  int unsigned valid_row_first;
  int unsigned valid_row_last;

  int unsigned valid_col_first;
  int unsigned valid_col_last;


  // ==========================================================
  // Putanje do TXT fajlova
  // ==========================================================

  string golden_dir;

  string input_image_path;
  string golden_edge_path;


  // ==========================================================
  // Velicina slike
  //
  // 512 x 384 = 196608 piksela
  // 4 piksela po jednoj 32-bitnoj AXI reci
  // 196608 / 4 = 49152 reci
  // ==========================================================

  localparam int unsigned IMG_PIXELS = 196608;
  localparam int unsigned IMG_WORDS  = 49152;


  // Ulazna grayscale slika spakovana u 32-bitne AXI reci.
  bit [31:0] input_words[];

  // Ocekivani SystemC rezultat, piksel po piksel.
  bit [7:0] expected_pixels[];


  // ==========================================================
  // UVM factory registracija
  // ==========================================================

  `uvm_object_utils_begin(canny_config)

    `uvm_field_int(rows,           UVM_ALL_ON)
    `uvm_field_int(cols,           UVM_ALL_ON)

    `uvm_field_int(low_threshold,  UVM_ALL_ON)
    `uvm_field_int(high_threshold, UVM_ALL_ON)

    `uvm_field_int(test_index, UVM_ALL_ON)

    `uvm_field_int(valid_row_first, UVM_ALL_ON)
    `uvm_field_int(valid_row_last,  UVM_ALL_ON)
    `uvm_field_int(valid_col_first, UVM_ALL_ON)
    `uvm_field_int(valid_col_last,  UVM_ALL_ON)

    `uvm_field_string(golden_dir,       UVM_ALL_ON)
    `uvm_field_string(input_image_path, UVM_ALL_ON)
    `uvm_field_string(golden_edge_path, UVM_ALL_ON)

  `uvm_object_utils_end


  // ==========================================================
  // Konstruktor
  // ==========================================================

  function new(
    input string name = "canny_config"
  );

    super.new(name);


    rows = 384;
    cols = 512;


    low_threshold  = 50;
    high_threshold = 100;


    // Podrazumevano se bira prva realna slika.
    test_index = 1;


    valid_row_first = 5;
    valid_row_last  = rows - 6;

    valid_col_first = 5;
    valid_col_last  = cols - 6;


    // XSim se pokrece iz:
    //
    // canny_verification.sim/sim_1/behav/xsim
    //
    // Cetiri nivoa iznad nalazi se glavni projektni folder.

    golden_dir =
      "../../../../golden_vectors/";


    input_image_path =
      "";

    golden_edge_path =
      "";


    input_words =
      new[IMG_WORDS];

    expected_pixels =
      new[IMG_PIXELS];

  endfunction


  // ==========================================================
  // Izbor TXT fajlova na osnovu test_index vrednosti
  // ==========================================================

  function void set_paths_from_test_index();

    case (
      test_index
    )

      // ------------------------------------------------------
      // Test 1:
      // prva realna slika
      // ------------------------------------------------------

      1: begin

        input_image_path = {
          golden_dir,
          "grayscale_full.txt"
        };


        golden_edge_path = {
          golden_dir,
          "final_edge_full.txt"
        };

      end


      // ------------------------------------------------------
      // Test 2:
      // druga realna slika
      // ------------------------------------------------------

      2: begin

        input_image_path = {
          golden_dir,
          "grayscale_full2.txt"
        };


        golden_edge_path = {
          golden_dir,
          "final_edge_full2.txt"
        };

      end


      // ------------------------------------------------------
      // Test 3:
      // potpuno crna slika
      // ------------------------------------------------------

      3: begin

        input_image_path = {
          golden_dir,
          "grayscale_full_black.txt"
        };


        golden_edge_path = {
          golden_dir,
          "final_edge_full_black.txt"
        };

      end


      // ------------------------------------------------------
      // Test 4:
      // leva polovina crna, desna polovina bela
      // ------------------------------------------------------

      4: begin

        input_image_path = {
          golden_dir,
          "grayscale_full_half.txt"
        };


        golden_edge_path = {
          golden_dir,
          "final_edge_full_half.txt"
        };

      end


      // ------------------------------------------------------
      // Nepodrzan test indeks
      // ------------------------------------------------------

      default: begin

        `uvm_fatal(
          "CANNY_CFG",
          $sformatf(
            {
              "Unsupported Canny test_index=%0d. ",
              "Supported values are 1, 2, 3 and 4."
            },
            test_index
          )
        )

      end

    endcase


    `uvm_info(
      "CANNY_CFG",
      $sformatf(
        "Selected test_index=%0d.",
        test_index
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_CFG",
      $sformatf(
        "Input image: %s",
        input_image_path
      ),
      UVM_LOW
    )


    `uvm_info(
      "CANNY_CFG",
      $sformatf(
        "Golden edge image: %s",
        golden_edge_path
      ),
      UVM_LOW
    )

  endfunction


  // ==========================================================
  // Ucitavanje ulazne i golden slike
  // ==========================================================

  function void load_golden_vectors();

    set_paths_from_test_index();

    load_input_image();
    load_golden_edge();

  endfunction


  // ==========================================================
  // Ucitavanje grayscale slike
  //
  // Cetiri uzastopna piksela se pakuju u jednu AXI rec:
  //
  //   pixel 0 -> bits  7:0
  //   pixel 1 -> bits 15:8
  //   pixel 2 -> bits 23:16
  //   pixel 3 -> bits 31:24
  // ==========================================================

  function void load_input_image();

    int fd;
    int status;

    int value;

    int pixel_idx;
    int word_idx;
    int byte_idx;

    int extra_status;
    int extra_value;


    fd =
      $fopen(
        input_image_path,
        "r"
      );


    if (
      fd == 0
    ) begin

      `uvm_fatal(
        "CANNY_CFG",
        $sformatf(
          "Cannot open input image file: %s",
          input_image_path
        )
      )

    end


    // Ocisti AXI reci pre pakovanja ulazne slike.

    for (
      word_idx = 0;
      word_idx < IMG_WORDS;
      word_idx++
    ) begin

      input_words[word_idx] =
        32'd0;

    end


    for (
      pixel_idx = 0;
      pixel_idx < IMG_PIXELS;
      pixel_idx++
    ) begin

      status =
        $fscanf(
          fd,
          "%d\n",
          value
        );


      if (
        status != 1
      ) begin

        `uvm_fatal(
          "CANNY_CFG",
          $sformatf(
            {
              "Invalid input image format at pixel %0d ",
              "in file: %s"
            },
            pixel_idx,
            input_image_path
          )
        )

      end


      if (
        (value < 0) ||
        (value > 255)
      ) begin

        `uvm_fatal(
          "CANNY_CFG",
          $sformatf(
            {
              "Input pixel outside range 0-255. ",
              "Pixel=%0d value=%0d file=%s"
            },
            pixel_idx,
            value,
            input_image_path
          )
        )

      end


      word_idx =
        pixel_idx / 4;

      byte_idx =
        pixel_idx % 4;


      input_words[word_idx][8*byte_idx +: 8] =
        value[7:0];

    end


    // Provera da fajl nema vise od 196608 vrednosti.

    extra_status =
      $fscanf(
        fd,
        "%d\n",
        extra_value
      );


    if (
      extra_status == 1
    ) begin

      `uvm_fatal(
        "CANNY_CFG",
        $sformatf(
          "Input image file contains more than %0d pixels: %s",
          IMG_PIXELS,
          input_image_path
        )
      )

    end


    $fclose(fd);


    `uvm_info(
      "CANNY_CFG",
      $sformatf(
        "Loaded %0d grayscale pixels into %0d AXI words.",
        IMG_PIXELS,
        IMG_WORDS
      ),
      UVM_LOW
    )

  endfunction


  // ==========================================================
  // Ucitavanje SystemC golden edge slike
  //
  // Golden rezultat se cuva kao niz pojedinacnih 8-bitnih
  // piksela jer ih scoreboard poredi piksel po piksel.
  // ==========================================================

  function void load_golden_edge();

    int fd;
    int status;

    int value;
    int pixel_idx;

    int extra_status;
    int extra_value;


    fd =
      $fopen(
        golden_edge_path,
        "r"
      );


    if (
      fd == 0
    ) begin

      `uvm_fatal(
        "CANNY_CFG",
        $sformatf(
          "Cannot open golden edge file: %s",
          golden_edge_path
        )
      )

    end


    for (
      pixel_idx = 0;
      pixel_idx < IMG_PIXELS;
      pixel_idx++
    ) begin

      status =
        $fscanf(
          fd,
          "%d\n",
          value
        );


      if (
        status != 1
      ) begin

        `uvm_fatal(
          "CANNY_CFG",
          $sformatf(
            {
              "Invalid golden edge format at pixel %0d ",
              "in file: %s"
            },
            pixel_idx,
            golden_edge_path
          )
        )

      end


      if (
        (value < 0) ||
        (value > 255)
      ) begin

        `uvm_fatal(
          "CANNY_CFG",
          $sformatf(
            {
              "Golden pixel outside range 0-255. ",
              "Pixel=%0d value=%0d file=%s"
            },
            pixel_idx,
            value,
            golden_edge_path
          )
        )

      end


      expected_pixels[pixel_idx] =
        value[7:0];

    end


    // Provera da fajl nema vise od 196608 vrednosti.

    extra_status =
      $fscanf(
        fd,
        "%d\n",
        extra_value
      );


    if (
      extra_status == 1
    ) begin

      `uvm_fatal(
        "CANNY_CFG",
        $sformatf(
          "Golden edge file contains more than %0d pixels: %s",
          IMG_PIXELS,
          golden_edge_path
        )
      )

    end


    $fclose(fd);


    `uvm_info(
      "CANNY_CFG",
      $sformatf(
        "Loaded %0d expected Canny edge pixels.",
        IMG_PIXELS
      ),
      UVM_LOW
    )

  endfunction

endclass

`endif
