`ifndef CANNY_MONITOR_SV
`define CANNY_MONITOR_SV


class canny_monitor extends uvm_monitor;

  `uvm_component_utils(canny_monitor)


  canny_config cfg;

  virtual canny_if vif;


  uvm_analysis_port #(canny_seq_item) item_collected_port;


  function new(
    string name = "canny_monitor",
    uvm_component parent = null
  );

    super.new(
      name,
      parent
    );


    item_collected_port =
      new(
        "item_collected_port",
        this
      );

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
        "CANNY_MON",
        "Canny configuration was not found."
      )

    end


    if (
      cfg == null
    ) begin

      `uvm_fatal(
        "CANNY_MON",
        "Received canny_config object is null."
      )

    end


    vif =
      cfg.vif;


    if (
      vif == null
    ) begin

      `uvm_fatal(
        "CANNY_MON",
        "Virtual interface inside canny_config is null."
      )

    end


    `uvm_info(
      "CANNY_MON",
      "Canny monitor build phase completed.",
      UVM_LOW
    )

  endfunction


  // ==========================================================
  // Run phase
  //
  // Monitor the AXI-Full read channel.
  //
  // The current driver supports single-word reads with one active
  // transaction and no multiple outstanding read requests.
  //
  // Because of mixed-language SystemVerilog/VHDL scheduling,
  // ARREADY may become visible after the clock edge on which the
  // DUT accepted the address. The monitor therefore captures ARADDR
  // when ARVALID is first observed and keeps it until read completion.
  // ==========================================================

  virtual task run_phase(
    uvm_phase phase
  );

    canny_seq_item tr;

    bit [18:0] current_read_addr;

    bit read_address_valid;


    current_read_addr =
      '0;

    read_address_valid =
      1'b0;


    wait (
      vif.rst_n === 1'b1
    );


    `uvm_info(
      "CANNY_MON",
      "Reset released. Canny monitor is active.",
      UVM_LOW
    )


    forever begin

      @(posedge vif.clk);


      // Allow mixed-language VHDL signal updates to settle
      // before sampling AXI signals.

      #1ps;


      // ------------------------------------------------------
      // Reset
      // ------------------------------------------------------

      if (
        vif.rst_n !== 1'b1
      ) begin

        current_read_addr =
          '0;

        read_address_valid =
          1'b0;

      end
      else begin

        // ----------------------------------------------------
        // AXI-Full read address
        //
        // ARADDR remains stable while ARVALID is asserted.
        // Capture it on the first observed ARVALID cycle.
        // ----------------------------------------------------

        if (
          vif.s01_axi_arvalid === 1'b1 &&
          read_address_valid  === 1'b0
        ) begin

          current_read_addr =
            vif.s01_axi_araddr;


          read_address_valid =
            1'b1;

        end


        // ----------------------------------------------------
        // AXI-Full read data handshake
        // ----------------------------------------------------

        if (
          vif.s01_axi_rvalid === 1'b1 &&
          vif.s01_axi_rready === 1'b1
        ) begin

          if (
            read_address_valid === 1'b0
          ) begin

            `uvm_warning(
              "CANNY_MON",
              {
                "AXI-Full read data was observed without ",
                "a previously captured read address."
              }
            )

          end
          else begin

            tr =
              canny_seq_item::type_id::create(
                "tr"
              );


            if (
              tr == null
            ) begin

              `uvm_fatal(
                "CANNY_MON",
                "Failed to create monitored canny_seq_item."
              )

            end


            tr.trans_type =
              AXI_FULL_READ_BURST;


            tr.addr =
              current_read_addr;


            tr.data =
              vif.s01_axi_rdata;


            tr.read_data =
              vif.s01_axi_rdata;


            tr.burst_len =
              1;


            tr.read_burst_data =
              new[1];


            tr.read_burst_data[0] =
              vif.s01_axi_rdata;


            item_collected_port.write(
              tr
            );


            // Single-word reads are expected to terminate with RLAST.

            if (
              vif.s01_axi_rlast === 1'b1
            ) begin

              current_read_addr =
                '0;


              read_address_valid =
                1'b0;

            end
            else begin

              // Advance the address for a multi-beat response.

              current_read_addr =
                current_read_addr + 4;

            end

          end

        end

      end

    end

  endtask

endclass

`endif