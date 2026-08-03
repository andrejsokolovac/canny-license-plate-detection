`ifndef CANNY_SEQUENCES_SV
`define CANNY_SEQUENCES_SV


class canny_base_sequence extends uvm_sequence #(canny_seq_item);

  `uvm_object_utils(canny_base_sequence)


  canny_config cfg;


  function new(
    string name = "canny_base_sequence"
  );

    super.new(name);

  endfunction

endclass


// ============================================================
// Smoke sequence
//
// 1. Check AXI-Lite configuration registers.
// 2. Write complete grayscale image.
// 3. Check six input-memory words.
// 4. Send START pulse.
// 5. Wait until READY returns to 1.
// 6. Read complete output edge image.
//
// Output words are observed by canny_monitor and forwarded to:
//
//   canny_scoreboard
//   canny_coverage
// ============================================================

class canny_smoke_sequence extends canny_base_sequence;

  `uvm_object_utils(canny_smoke_sequence)


  canny_seq_item req;


  function new(
    string name = "canny_smoke_sequence"
  );

    super.new(name);

  endfunction


  // ==========================================================
  // Write and read one AXI-Lite register
  // ==========================================================

  task check_axi_lite_register(
    input string     register_name,
    input bit [31:0] register_addr,
    input bit [31:0] expected_value
  );


    req = canny_seq_item::type_id::create(
      "axi_lite_write_req"
    );


    if (
      req == null
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        "Failed to create AXI-Lite write item."
      )

    end


    start_item(req);

    req.trans_type = AXI_LITE_WRITE;
    req.addr       = register_addr;
    req.data       = expected_value;
    req.burst_len  = 0;

    finish_item(req);


    req = canny_seq_item::type_id::create(
      "axi_lite_read_req"
    );


    if (
      req == null
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        "Failed to create AXI-Lite read item."
      )

    end


    start_item(req);

    req.trans_type = AXI_LITE_READ;
    req.addr       = register_addr;
    req.data       = 32'h0000_0000;
    req.burst_len  = 0;

    finish_item(req);


    if (
      req.read_data !== expected_value
    ) begin

      `uvm_error(
        "CANNY_SEQ",
        $sformatf(
          {
            "%s readback mismatch: ",
            "addr=0x%02h ",
            "expected=0x%08h ",
            "actual=0x%08h."
          },
          register_name,
          register_addr[4:0],
          expected_value,
          req.read_data
        )
      )

    end
    else begin

      `uvm_info(
        "CANNY_SEQ",
        $sformatf(
          "%s readback PASS: value=%0d.",
          register_name,
          req.read_data
        ),
        UVM_LOW
      )

    end

  endtask


  // ==========================================================
  // Write complete grayscale image
  // ==========================================================

  task send_complete_input_image(
    input bit [31:0] base_addr,
    input bit [31:0] image_words[]
  );

    int unsigned word_index;
    int unsigned remaining_words;
    int unsigned current_burst_len;

    int unsigned burst_index;
    int unsigned total_bursts;

    int unsigned i;


    if (
      image_words.size() == 0
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        "Input image word array is empty."
      )

    end


    word_index  = 0;
    burst_index = 0;

    total_bursts =
      (image_words.size() + 255) / 256;


    `uvm_info(
      "CANNY_SEQ",
      $sformatf(
        {
          "Complete input image write started: ",
          "words=%0d bursts=%0d."
        },
        image_words.size(),
        total_bursts
      ),
      UVM_LOW
    )


    while (
      word_index < image_words.size()
    ) begin

      remaining_words =
        image_words.size() - word_index;


      if (
        remaining_words >= 256
      )
        current_burst_len = 256;
      else
        current_burst_len = remaining_words;


      req = canny_seq_item::type_id::create(
        "image_write_burst_req"
      );


      if (
        req == null
      ) begin

        `uvm_fatal(
          "CANNY_SEQ",
          "Failed to create image write burst item."
        )

      end


      start_item(req);

      req.trans_type =
        AXI_FULL_WRITE_BURST;

      req.addr =
        base_addr + word_index * 4;

      req.data =
        32'h0000_0000;

      req.burst_len =
        current_burst_len;

      req.burst_data =
        new[current_burst_len];


      for (
        i = 0;
        i < current_burst_len;
        i++
      ) begin

        req.burst_data[i] =
          image_words[word_index + i];

      end


      finish_item(req);


      word_index +=
        current_burst_len;

      burst_index++;


      if (
        (burst_index == 1) ||
        ((burst_index % 16) == 0) ||
        (burst_index == total_bursts)
      ) begin

        `uvm_info(
          "CANNY_SEQ",
          $sformatf(
            {
              "Input image progress: ",
              "burst=%0d/%0d ",
              "words=%0d/%0d."
            },
            burst_index,
            total_bursts,
            word_index,
            image_words.size()
          ),
          UVM_LOW
        )

      end

    end


    `uvm_info(
      "CANNY_SEQ",
      $sformatf(
        {
          "Complete input image write finished: ",
          "words=%0d bursts=%0d."
        },
        word_index,
        burst_index
      ),
      UVM_LOW
    )

  endtask


  // ==========================================================
  // Read and check one input-memory word
  // ==========================================================

  task check_input_word(
    input int unsigned word_index,
    inout int unsigned match_count,
    inout int unsigned mismatch_count
  );

    bit [31:0] word_addr;


    word_addr =
      word_index * 4;


    req = canny_seq_item::type_id::create(
      "input_control_read_req"
    );


    if (
      req == null
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        "Failed to create input control read item."
      )

    end


    start_item(req);

    req.trans_type =
      AXI_FULL_READ_BURST;

    req.addr =
      word_addr;

    req.data =
      32'h0000_0000;

    req.burst_len =
      1;

    finish_item(req);


    if (
      req.read_burst_data.size() != 1
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        $sformatf(
          {
            "Invalid readback size at word %0d: ",
            "size=%0d expected=1."
          },
          word_index,
          req.read_burst_data.size()
        )
      )

    end


    if (
      req.read_burst_data[0] ===
      cfg.input_words[word_index]
    ) begin

      match_count++;


      `uvm_info(
        "CANNY_SEQ",
        $sformatf(
          {
            "INPUT control readback PASS: ",
            "word=%0d ",
            "addr=0x%05h ",
            "data=0x%08h."
          },
          word_index,
          word_addr[18:0],
          req.read_burst_data[0]
        ),
        UVM_LOW
      )

    end
    else begin

      mismatch_count++;


      `uvm_error(
        "CANNY_SEQ",
        $sformatf(
          {
            "INPUT control readback mismatch: ",
            "word=%0d ",
            "addr=0x%05h ",
            "expected=0x%08h ",
            "actual=0x%08h."
          },
          word_index,
          word_addr[18:0],
          cfg.input_words[word_index],
          req.read_burst_data[0]
        )
      )

    end

  endtask


  // ==========================================================
  // Read complete output edge image
  //
  // Current Canny AXI-Full driver supports read transactions
  // with burst_len = 1.
  //
  // Therefore, 49152 individual 32-bit reads are generated:
  //
  //   first address = 0x40000
  //   last address  = 0x6FFFC
  //
  // The sequence does not compare edge pixels directly.
  //
  // Monitor captures every read word and sends it to:
  //
  //   scoreboard
  //   coverage
  // ==========================================================

  task read_complete_output_image(
    input bit [31:0] base_addr,
    input int unsigned total_words
  );

    int unsigned word_index;
    int unsigned completed_word_count;

    bit [31:0] current_addr;


    if (
      total_words == 0
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        "Requested output image read contains zero words."
      )

    end


    completed_word_count =
      0;


    `uvm_info(
      "CANNY_SEQ",
      $sformatf(
        {
          "Complete output edge image read started: ",
          "words=%0d ",
          "address_range=0x%05h..0x%05h."
        },
        total_words,
        base_addr[18:0],
        (
          base_addr +
          total_words * 4 -
          4
        )
      ),
      UVM_LOW
    )


    for (
      word_index = 0;
      word_index < total_words;
      word_index++
    ) begin

      current_addr =
        base_addr +
        word_index * 4;


      req = canny_seq_item::type_id::create(
        "output_read_req"
      );


      if (
        req == null
      ) begin

        `uvm_fatal(
          "CANNY_SEQ",
          "Failed to create output AXI-Full read item."
        )

      end


      start_item(req);

      req.trans_type =
        AXI_FULL_READ_BURST;

      req.addr =
        current_addr;

      req.data =
        32'h0000_0000;

      req.burst_len =
        1;

      finish_item(req);


      if (
        req.read_burst_data.size() != 1
      ) begin

        `uvm_fatal(
          "CANNY_SEQ",
          $sformatf(
            {
              "Invalid output read size: ",
              "word=%0d addr=0x%05h ",
              "size=%0d expected=1."
            },
            word_index,
            current_addr[18:0],
            req.read_burst_data.size()
          )
        )

      end


      completed_word_count++;


      if (
        (completed_word_count == 1) ||
        ((completed_word_count % 4096) == 0) ||
        (completed_word_count == total_words)
      ) begin

        `uvm_info(
          "CANNY_SEQ",
          $sformatf(
            {
              "Output image read progress: ",
              "words=%0d/%0d ",
              "last_addr=0x%05h."
            },
            completed_word_count,
            total_words,
            current_addr[18:0]
          ),
          UVM_LOW
        )

      end

    end


    `uvm_info(
      "CANNY_SEQ",
      $sformatf(
        {
          "Complete output edge image read finished: ",
          "words=%0d/%0d."
        },
        completed_word_count,
        total_words
      ),
      UVM_LOW
    )

  endtask


  // ==========================================================
  // Smoke sequence body
  // ==========================================================

  virtual task body();

    int unsigned check_word_indices[6];

    int unsigned check_number;

    int unsigned readback_match_count;
    int unsigned readback_mismatch_count;


    if (
      cfg == null
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        "Configuration was not assigned to smoke sequence."
      )

    end


    if (
      cfg.input_words.size() != 49152
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        $sformatf(
          {
            "Unexpected input word count: ",
            "actual=%0d expected=49152."
          },
          cfg.input_words.size()
        )
      )

    end


    `uvm_info(
      "CANNY_SEQ",
      "Canny smoke sequence started.",
      UVM_LOW
    )


    // ========================================================
    // AXI-Lite configuration
    // ========================================================

    check_axi_lite_register(
      "ROWS",
      32'h0000_0000,
      cfg.rows
    );


    check_axi_lite_register(
      "COLS",
      32'h0000_0004,
      cfg.cols
    );


    check_axi_lite_register(
      "LOW threshold",
      32'h0000_0008,
      cfg.low_threshold
    );


    check_axi_lite_register(
      "HIGH threshold",
      32'h0000_000C,
      cfg.high_threshold
    );


    `uvm_info(
      "CANNY_SEQ",
      "All AXI-Lite configuration register checks passed.",
      UVM_LOW
    )


    // ========================================================
    // Complete grayscale input image
    // ========================================================

    send_complete_input_image(
      32'h0000_0000,
      cfg.input_words
    );


    // ========================================================
    // Control readback
    // ========================================================

    check_word_indices[0] = 0;
    check_word_indices[1] = 255;
    check_word_indices[2] = 256;
    check_word_indices[3] = 24575;
    check_word_indices[4] = 24576;
    check_word_indices[5] = 49151;


    readback_match_count    = 0;
    readback_mismatch_count = 0;


    `uvm_info(
      "CANNY_SEQ",
      "Complete input image control readback started.",
      UVM_LOW
    )


    for (
      check_number = 0;
      check_number < 6;
      check_number++
    ) begin

      check_input_word(
        check_word_indices[check_number],
        readback_match_count,
        readback_mismatch_count
      );

    end


    if (
      readback_mismatch_count == 0
    ) begin

      `uvm_info(
        "CANNY_SEQ",
        $sformatf(
          {
            "Complete input image control readback PASS: ",
            "%0d/6 words matched."
          },
          readback_match_count
        ),
        UVM_LOW
      )

    end
    else begin

      `uvm_error(
        "CANNY_SEQ",
        $sformatf(
          {
            "Complete input image control readback FAILED: ",
            "matched=%0d mismatched=%0d."
          },
          readback_match_count,
          readback_mismatch_count
        )
      )

    end


    // ========================================================
    // START
    // ========================================================

    req = canny_seq_item::type_id::create(
      "start_processing_req"
    );


    if (
      req == null
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        "Failed to create START_PROCESSING item."
      )

    end


    start_item(req);

    req.trans_type =
      START_PROCESSING;

    req.addr =
      32'h0000_0010;

    req.data =
      32'h0000_0001;

    req.burst_len =
      0;

    finish_item(req);


    `uvm_info(
      "CANNY_SEQ",
      "START_PROCESSING transaction completed.",
      UVM_LOW
    )


    // ========================================================
    // WAIT READY
    // ========================================================

    req = canny_seq_item::type_id::create(
      "wait_ready_req"
    );


    if (
      req == null
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        "Failed to create WAIT_READY item."
      )

    end


    start_item(req);

    req.trans_type =
      WAIT_READY;

    req.addr =
      32'h0000_0014;

    req.data =
      32'h0000_0000;

    req.burst_len =
      0;

    finish_item(req);


    if (
      req.read_data[0] !== 1'b1
    ) begin

      `uvm_error(
        "CANNY_SEQ",
        $sformatf(
          {
            "WAIT_READY finished with invalid value: ",
            "READY=0x%08h."
          },
          req.read_data
        )
      )

    end
    else begin

      `uvm_info(
        "CANNY_SEQ",
        $sformatf(
          {
            "WAIT_READY PASS: ",
            "READY=0x%08h."
          },
          req.read_data
        ),
        UVM_LOW
      )

    end


    // ========================================================
    // Complete output edge image read
    // ========================================================

    read_complete_output_image(
      32'h0004_0000,
      cfg.input_words.size()
    );


    `uvm_info(
      "CANNY_SEQ",
      {
        "Canny processing and complete output image read ",
        "finished. Scoreboard will report the final result."
      },
      UVM_LOW
    )


    `uvm_info(
      "CANNY_SEQ",
      "Canny smoke sequence finished.",
      UVM_LOW
    )

  endtask

endclass


// ============================================================
// Nominal sequence
// ============================================================

class canny_nominal_sequence extends canny_base_sequence;

  `uvm_object_utils(canny_nominal_sequence)


  canny_seq_item req;


  function new(
    string name = "canny_nominal_sequence"
  );

    super.new(name);

  endfunction


  task send_image_bursts(
    input bit [31:0] base_addr,
    input bit [31:0] image_words[]
  );

    int unsigned word_index;
    int unsigned remaining_words;
    int unsigned current_burst_len;

    int unsigned i;


    word_index = 0;


    while (
      word_index < image_words.size()
    ) begin

      remaining_words =
        image_words.size() - word_index;


      if (
        remaining_words >= 256
      )
        current_burst_len = 256;
      else
        current_burst_len = remaining_words;


      req = canny_seq_item::type_id::create(
        "write_burst_req"
      );


      if (
        req == null
      ) begin

        `uvm_fatal(
          "CANNY_SEQ",
          "Failed to create AXI-Full write item."
        )

      end


      start_item(req);

      req.trans_type =
        AXI_FULL_WRITE_BURST;

      req.addr =
        base_addr + word_index * 4;

      req.burst_len =
        current_burst_len;

      req.burst_data =
        new[current_burst_len];


      for (
        i = 0;
        i < current_burst_len;
        i++
      ) begin

        req.burst_data[i] =
          image_words[word_index + i];

      end


      finish_item(req);


      word_index +=
        current_burst_len;

    end

  endtask


  task read_edge_image(
    input bit [31:0] base_addr,
    input int unsigned total_words
  );

    int unsigned word_index;


    for (
      word_index = 0;
      word_index < total_words;
      word_index++
    ) begin

      req = canny_seq_item::type_id::create(
        "read_burst_req"
      );


      if (
        req == null
      ) begin

        `uvm_fatal(
          "CANNY_SEQ",
          "Failed to create AXI-Full read item."
        )

      end


      start_item(req);

      req.trans_type =
        AXI_FULL_READ_BURST;

      req.addr =
        base_addr + word_index * 4;

      req.data =
        32'h0000_0000;

      req.burst_len =
        1;

      finish_item(req);

    end

  endtask


  virtual task body();


    if (
      cfg == null
    ) begin

      `uvm_fatal(
        "CANNY_SEQ",
        "Configuration was not assigned to nominal sequence."
      )

    end


    `uvm_info(
      "CANNY_SEQ",
      "Canny nominal sequence started.",
      UVM_LOW
    )


    req = canny_seq_item::type_id::create(
      "rows_write_req"
    );

    start_item(req);

    req.trans_type = AXI_LITE_WRITE;
    req.addr       = 32'h0000_0000;
    req.data       = cfg.rows;
    req.burst_len  = 0;

    finish_item(req);


    req = canny_seq_item::type_id::create(
      "cols_write_req"
    );

    start_item(req);

    req.trans_type = AXI_LITE_WRITE;
    req.addr       = 32'h0000_0004;
    req.data       = cfg.cols;
    req.burst_len  = 0;

    finish_item(req);


    req = canny_seq_item::type_id::create(
      "low_threshold_write_req"
    );

    start_item(req);

    req.trans_type = AXI_LITE_WRITE;
    req.addr       = 32'h0000_0008;
    req.data       = cfg.low_threshold;
    req.burst_len  = 0;

    finish_item(req);


    req = canny_seq_item::type_id::create(
      "high_threshold_write_req"
    );

    start_item(req);

    req.trans_type = AXI_LITE_WRITE;
    req.addr       = 32'h0000_000C;
    req.data       = cfg.high_threshold;
    req.burst_len  = 0;

    finish_item(req);


    send_image_bursts(
      32'h0000_0000,
      cfg.input_words
    );


    req = canny_seq_item::type_id::create(
      "start_req"
    );

    start_item(req);

    req.trans_type = START_PROCESSING;
    req.addr       = 32'h0000_0010;
    req.data       = 32'h0000_0001;
    req.burst_len  = 0;

    finish_item(req);


    req = canny_seq_item::type_id::create(
      "wait_ready_req"
    );

    start_item(req);

    req.trans_type = WAIT_READY;
    req.addr       = 32'h0000_0014;
    req.data       = 32'h0000_0000;
    req.burst_len  = 0;

    finish_item(req);


    read_edge_image(
      32'h0004_0000,
      cfg.input_words.size()
    );


    `uvm_info(
      "CANNY_SEQ",
      "Canny nominal sequence finished.",
      UVM_LOW
    )

  endtask

endclass

`endif