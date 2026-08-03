`ifndef CANNY_DRIVER_SV
`define CANNY_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"


class canny_driver extends uvm_driver #(canny_seq_item);

  `uvm_component_utils(canny_driver)


  canny_config cfg;

  virtual canny_if vif;


  function new(
    input string name = "canny_driver",
    input uvm_component parent = null
  );

    super.new(name, parent);

  endfunction


  // ==========================================================
  // Build phase
  // ==========================================================

  virtual function void build_phase(uvm_phase phase);

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
        "CANNY_DRV",
        "canny_config was not found in uvm_config_db."
      )

    end


    if (cfg == null) begin

      `uvm_fatal(
        "CANNY_DRV",
        "Received canny_config object is null."
      )

    end


    vif = cfg.vif;


    if (vif == null) begin

      `uvm_fatal(
        "CANNY_DRV",
        "Virtual interface inside canny_config is null."
      )

    end


    `uvm_info(
      "CANNY_DRV",
      "Canny driver build phase completed.",
      UVM_LOW
    )

  endfunction


  // ==========================================================
  // Run phase
  // ==========================================================

  virtual task run_phase(uvm_phase phase);

    canny_seq_item item;


    wait (vif.rst_n === 1'b1);

    @(posedge vif.clk);


    `uvm_info(
      "CANNY_DRV",
      "Reset released. Driver is ready for transactions.",
      UVM_LOW
    )


    forever begin

      seq_item_port.get_next_item(item);


      `uvm_info(
        "CANNY_DRV",
        $sformatf(
          {
            "Transaction received: type=%0d ",
            "addr=0x%08h data=0x%08h burst_len=%0d"
          },
          item.trans_type,
          item.addr,
          item.data,
          item.burst_len
        ),
        UVM_MEDIUM
      )


      case (item.trans_type)

        AXI_LITE_WRITE: begin

          axi_lite_write(
            item.addr[4:0],
            item.data
          );

        end


        AXI_LITE_READ: begin

          axi_lite_read(
            item.addr[4:0],
            item.read_data
          );

        end


        AXI_FULL_WRITE_BURST: begin

          axi_full_write_burst(
            item.addr[18:0],
            item.burst_data,
            item.burst_len
          );

        end


        AXI_FULL_READ_BURST: begin

          axi_full_read_burst(
            item.addr[18:0],
            item.read_burst_data,
            item.burst_len
          );

        end


        START_PROCESSING: begin

          start_processing(
            item.addr[4:0]
          );

        end


        WAIT_READY: begin

          wait_ready_done(
            item.addr[4:0],
            item.read_data
          );

        end


        default: begin

          `uvm_error(
            "CANNY_DRV",
            $sformatf(
              "Unsupported transaction type: %0d",
              item.trans_type
            )
          )

        end

      endcase


      seq_item_port.item_done();

    end

  endtask


  // ==========================================================
  // AXI4-Lite write
  // ==========================================================

  task axi_lite_write(
    input bit [4:0]  addr,
    input bit [31:0] data
  );


    `uvm_info(
      "CANNY_DRV",
      $sformatf(
        "AXI-Lite write started: addr=0x%02h data=0x%08h",
        addr,
        data
      ),
      UVM_LOW
    )


    @(posedge vif.clk);

    vif.s00_axi_awaddr  <= addr;
    vif.s00_axi_awprot  <= 3'b000;
    vif.s00_axi_awvalid <= 1'b1;

    vif.s00_axi_wdata   <= data;
    vif.s00_axi_wstrb   <= 4'hF;
    vif.s00_axi_wvalid  <= 1'b1;


    wait (
      vif.s00_axi_awready === 1'b1 &&
      vif.s00_axi_wready  === 1'b1
    );


    @(posedge vif.clk);

    vif.s00_axi_awvalid <= 1'b0;
    vif.s00_axi_wvalid  <= 1'b0;
    vif.s00_axi_bready  <= 1'b1;


    wait (
      vif.s00_axi_bvalid === 1'b1
    );


    if (
      vif.s00_axi_bresp != 2'b00
    ) begin

      `uvm_error(
        "CANNY_DRV",
        $sformatf(
          "AXI-Lite write returned BRESP=%02b.",
          vif.s00_axi_bresp
        )
      )

    end


    @(posedge vif.clk);

    vif.s00_axi_bready <= 1'b0;

    vif.s00_axi_awaddr <= '0;
    vif.s00_axi_awprot <= '0;

    vif.s00_axi_wdata  <= '0;
    vif.s00_axi_wstrb  <= '0;


    `uvm_info(
      "CANNY_DRV",
      $sformatf(
        "AXI-Lite write completed: addr=0x%02h data=0x%08h",
        addr,
        data
      ),
      UVM_LOW
    )

  endtask


  // ==========================================================
  // AXI4-Lite read
  // ==========================================================

  task axi_lite_read(
    input  bit [4:0]  addr,
    output bit [31:0] data
  );


    data = '0;


    `uvm_info(
      "CANNY_DRV",
      $sformatf(
        "AXI-Lite read started: addr=0x%02h",
        addr
      ),
      UVM_LOW
    )


    @(posedge vif.clk);

    vif.s00_axi_araddr  <= addr;
    vif.s00_axi_arprot  <= 3'b000;
    vif.s00_axi_arvalid <= 1'b1;


    wait (
      vif.s00_axi_arready === 1'b1
    );


    @(posedge vif.clk);

    vif.s00_axi_arvalid <= 1'b0;
    vif.s00_axi_rready  <= 1'b1;


    wait (
      vif.s00_axi_rvalid === 1'b1
    );


    data =
      vif.s00_axi_rdata;


    if (
      vif.s00_axi_rresp != 2'b00
    ) begin

      `uvm_error(
        "CANNY_DRV",
        $sformatf(
          "AXI-Lite read returned RRESP=%02b.",
          vif.s00_axi_rresp
        )
      )

    end


    @(posedge vif.clk);

    vif.s00_axi_rready <= 1'b0;

    vif.s00_axi_araddr <= '0;
    vif.s00_axi_arprot <= '0;


    `uvm_info(
      "CANNY_DRV",
      $sformatf(
        "AXI-Lite read completed: addr=0x%02h data=0x%08h",
        addr,
        data
      ),
      UVM_LOW
    )

  endtask


  // ==========================================================
  // AXI4-Lite read used only for READY polling
  //
  // Handshake is the same as in axi_lite_read(), but without
  // one log message for every poll.
  // ==========================================================

  task axi_lite_read_poll(
    input  bit [4:0]  addr,
    output bit [31:0] data
  );


    data = '0;


    @(posedge vif.clk);

    vif.s00_axi_araddr  <= addr;
    vif.s00_axi_arprot  <= 3'b000;
    vif.s00_axi_arvalid <= 1'b1;


    wait (
      vif.s00_axi_arready === 1'b1
    );


    @(posedge vif.clk);

    vif.s00_axi_arvalid <= 1'b0;
    vif.s00_axi_rready  <= 1'b1;


    wait (
      vif.s00_axi_rvalid === 1'b1
    );


    data =
      vif.s00_axi_rdata;


    if (
      vif.s00_axi_rresp != 2'b00
    ) begin

      `uvm_error(
        "CANNY_DRV",
        $sformatf(
          {
            "READY polling read returned ",
            "RRESP=%02b."
          },
          vif.s00_axi_rresp
        )
      )

    end


    @(posedge vif.clk);

    vif.s00_axi_rready <= 1'b0;

    vif.s00_axi_araddr <= '0;
    vif.s00_axi_arprot <= '0;

  endtask


  // ==========================================================
  // START processing
  //
  // Canny START register: 0x10
  //
  // The verified Canny AXI VHDL TB performs:
  //   START = 1
  //   wait 5 falling clock edges
  //   START = 0
  // ==========================================================

  task start_processing(
    input bit [4:0] start_addr
  );


    `uvm_info(
      "CANNY_DRV",
      $sformatf(
        "Canny START sequence started: addr=0x%02h.",
        start_addr
      ),
      UVM_LOW
    )


    axi_lite_write(
      start_addr,
      32'h0000_0001
    );


    repeat (5) begin

      @(negedge vif.clk);

    end


    axi_lite_write(
      start_addr,
      32'h0000_0000
    );


    `uvm_info(
      "CANNY_DRV",
      "Canny START pulse completed: 1 -> 0.",
      UVM_LOW
    )

  endtask


  // ==========================================================
  // Wait for READY
  //
  // Canny READY register: 0x14
  //
  // First wait until READY becomes 0, proving that processing
  // started. Then wait until READY returns to 1.
  //
  // Poll interval and timeout follow the Canny AXI VHDL TB:
  //   poll interval = 1000 ns
  //   max polls     = 2,000,000
  // ==========================================================

  task wait_ready_done(
    input  bit [4:0]  ready_addr,
    output bit [31:0] ready_data
  );

    int unsigned poll_count;

    bit busy_seen;


    poll_count = 0;
    busy_seen  = 1'b0;
    ready_data = '0;


    `uvm_info(
      "CANNY_DRV",
      $sformatf(
        "Waiting for Canny READY at addr=0x%02h.",
        ready_addr
      ),
      UVM_LOW
    )


    forever begin

      axi_lite_read_poll(
        ready_addr,
        ready_data
      );


      poll_count++;


      if (
        busy_seen == 1'b0
      ) begin

        if (
          ready_data[0] === 1'b0
        ) begin

          busy_seen = 1'b1;


          `uvm_info(
            "CANNY_DRV",
            $sformatf(
              {
                "Canny processing started: ",
                "READY=0 after %0d poll(s)."
              },
              poll_count
            ),
            UVM_LOW
          )

        end

      end
      else begin

        if (
          ready_data[0] === 1'b1
        ) begin

          `uvm_info(
            "CANNY_DRV",
            $sformatf(
              {
                "Canny processing completed: ",
                "READY=1 after %0d poll(s)."
              },
              poll_count
            ),
            UVM_LOW
          )


          break;

        end

      end


      if (
        poll_count >= 2_000_000
      ) begin

        `uvm_fatal(
          "CANNY_DRV",
          $sformatf(
            {
              "Timeout while waiting for READY: ",
              "polls=%0d last_value=0x%08h."
            },
            poll_count,
            ready_data
          )
        )

      end


      if (
        (poll_count % 100_000) == 0
      ) begin

        `uvm_info(
          "CANNY_DRV",
          $sformatf(
            {
              "Still waiting for READY: ",
              "polls=%0d value=0x%08h."
            },
            poll_count,
            ready_data
          ),
          UVM_LOW
        )

      end


      #1000ns;

    end


    // Two additional clocks, as stabilization before the
    // later output image read phase.

    repeat (2) begin

      @(posedge vif.clk);

    end

  endtask


  // ==========================================================
  // AXI4-Full write burst
  // ==========================================================

  task axi_full_write_burst(
    input bit [18:0] addr,
    input bit [31:0] data_array[],
    input int unsigned burst_len
  );

    int unsigned i;


    if (
      burst_len == 0 ||
      burst_len > 256
    ) begin

      `uvm_fatal(
        "CANNY_DRV",
        $sformatf(
          "Invalid AXI-Full burst length: %0d.",
          burst_len
        )
      )

    end


    if (
      data_array.size() < burst_len
    ) begin

      `uvm_fatal(
        "CANNY_DRV",
        $sformatf(
          {
            "AXI-Full data array is too small: ",
            "array_size=%0d burst_len=%0d."
          },
          data_array.size(),
          burst_len
        )
      )

    end


    `uvm_info(
      "CANNY_DRV",
      $sformatf(
        {
          "AXI-Full write burst started: ",
          "addr=0x%05h burst_len=%0d."
        },
        addr,
        burst_len
      ),
      UVM_LOW
    )


    @(negedge vif.clk);

    vif.s01_axi_awaddr   <= addr;
    vif.s01_axi_awlen    <= burst_len - 1;
    vif.s01_axi_awsize   <= 3'b010;
    vif.s01_axi_awburst  <= 2'b01;
    vif.s01_axi_awvalid  <= 1'b1;

    vif.s01_axi_awid     <= '0;
    vif.s01_axi_awlock   <= 1'b0;
    vif.s01_axi_awcache  <= '0;
    vif.s01_axi_awprot   <= '0;
    vif.s01_axi_awqos    <= '0;
    vif.s01_axi_awregion <= '0;
    vif.s01_axi_awuser   <= '0;


    wait (
      vif.s01_axi_awready === 1'b1
    );


    @(negedge vif.clk);

    vif.s01_axi_awvalid <= 1'b0;


    wait (
      vif.s01_axi_awready === 1'b0
    );


    @(negedge vif.clk);

    vif.s01_axi_bready <= 1'b0;


    for (
      i = 0;
      i < burst_len;
      i++
    ) begin

      vif.s01_axi_wdata  <= data_array[i];
      vif.s01_axi_wvalid <= 1'b1;
      vif.s01_axi_wstrb  <= 4'hF;


      if (
        i == burst_len - 1
      )
        vif.s01_axi_wlast <= 1'b1;
      else
        vif.s01_axi_wlast <= 1'b0;


      wait (
        vif.s01_axi_wready === 1'b1
      );


      @(posedge vif.clk);

      @(negedge vif.clk);

      vif.s01_axi_wvalid <= 1'b0;
      vif.s01_axi_wlast  <= 1'b0;


      @(negedge vif.clk);

    end


    wait (
      vif.s01_axi_bvalid === 1'b1
    );


    if (
      vif.s01_axi_bresp != 2'b00
    ) begin

      `uvm_error(
        "CANNY_DRV",
        $sformatf(
          "AXI-Full write returned BRESP=%02b.",
          vif.s01_axi_bresp
        )
      )

    end


    @(negedge vif.clk);

    vif.s01_axi_bready <= 1'b1;


    @(posedge vif.clk);

    @(negedge vif.clk);

    vif.s01_axi_bready <= 1'b0;


    vif.s01_axi_wdata   <= '0;
    vif.s01_axi_wvalid  <= 1'b0;
    vif.s01_axi_wstrb   <= '0;
    vif.s01_axi_wlast   <= 1'b0;

    vif.s01_axi_awaddr  <= '0;
    vif.s01_axi_awlen   <= '0;
    vif.s01_axi_awsize  <= '0;
    vif.s01_axi_awburst <= '0;
    vif.s01_axi_awvalid <= 1'b0;

    vif.s01_axi_awid     <= '0;
    vif.s01_axi_awlock   <= '0;
    vif.s01_axi_awcache  <= '0;
    vif.s01_axi_awprot   <= '0;
    vif.s01_axi_awqos    <= '0;
    vif.s01_axi_awregion <= '0;
    vif.s01_axi_awuser   <= '0;


    `uvm_info(
      "CANNY_DRV",
      $sformatf(
        {
          "AXI-Full write burst completed: ",
          "addr=0x%05h burst_len=%0d."
        },
        addr,
        burst_len
      ),
      UVM_LOW
    )

  endtask


  // ==========================================================
  // AXI4-Full single-word read
  // ==========================================================

  task axi_full_read_burst(
    input bit [18:0] addr,
    ref bit [31:0] data_array[],
    input int unsigned burst_len
  );


    if (
      burst_len != 1
    ) begin

      `uvm_fatal(
        "CANNY_DRV",
        $sformatf(
          {
            "Current AXI-Full read supports burst_len=1 only. ",
            "Received burst_len=%0d."
          },
          burst_len
        )
      )

    end


    data_array =
      new[1];

    data_array[0] =
      '0;


    `uvm_info(
      "CANNY_DRV",
      $sformatf(
        "AXI-Full read started: addr=0x%05h burst_len=1.",
        addr
      ),
      UVM_HIGH
    )


    @(negedge vif.clk);

    vif.s01_axi_arid     <= '0;
    vif.s01_axi_araddr   <= addr;
    vif.s01_axi_arlen    <= 8'd0;
    vif.s01_axi_arsize   <= 3'b010;
    vif.s01_axi_arburst  <= 2'b01;
    vif.s01_axi_arlock   <= 1'b0;
    vif.s01_axi_arcache  <= '0;
    vif.s01_axi_arprot   <= '0;
    vif.s01_axi_arqos    <= '0;
    vif.s01_axi_arregion <= '0;
    vif.s01_axi_aruser   <= '0;
    vif.s01_axi_arvalid  <= 1'b1;

    vif.s01_axi_rready   <= 1'b1;


    wait (
      vif.s01_axi_arready === 1'b1
    );


    @(negedge vif.clk);

    vif.s01_axi_arvalid <= 1'b0;


    wait (
      vif.s01_axi_arready === 1'b0
    );


    if (
      vif.s01_axi_rvalid !== 1'b1
    )
      wait (
        vif.s01_axi_rvalid === 1'b1
      );


    #1ns;


    data_array[0] =
      vif.s01_axi_rdata;


    if (
      vif.s01_axi_rresp != 2'b00
    ) begin

      `uvm_error(
        "CANNY_DRV",
        $sformatf(
          {
            "AXI-Full read returned RRESP=%02b ",
            "at addr=0x%05h."
          },
          vif.s01_axi_rresp,
          addr
        )
      )

    end


    if (
      vif.s01_axi_rlast !== 1'b1
    ) begin

      `uvm_error(
        "CANNY_DRV",
        $sformatf(
          {
            "AXI-Full single-word read did not assert RLAST ",
            "at addr=0x%05h."
          },
          addr
        )
      )

    end


    @(negedge vif.clk);

    vif.s01_axi_rready <= 1'b0;


    vif.s01_axi_arid     <= '0;
    vif.s01_axi_araddr   <= '0;
    vif.s01_axi_arlen    <= '0;
    vif.s01_axi_arsize   <= '0;
    vif.s01_axi_arburst  <= '0;
    vif.s01_axi_arlock   <= '0;
    vif.s01_axi_arcache  <= '0;
    vif.s01_axi_arprot   <= '0;
    vif.s01_axi_arqos    <= '0;
    vif.s01_axi_arregion <= '0;
    vif.s01_axi_aruser   <= '0;
    vif.s01_axi_arvalid  <= 1'b0;


    `uvm_info(
      "CANNY_DRV",
      $sformatf(
        {
          "AXI-Full read completed: ",
          "addr=0x%05h data=0x%08h."
        },
        addr,
        data_array[0]
      ),
      UVM_HIGH
    )

  endtask

endclass

`endif