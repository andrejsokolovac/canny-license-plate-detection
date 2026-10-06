`ifndef CANNY_AGENT_SV
`define CANNY_AGENT_SV


class canny_agent extends uvm_agent;

  `uvm_component_utils(canny_agent)


  canny_config cfg;


  canny_sequencer sequencer;
  canny_driver    driver;
  canny_monitor   monitor;


  function new(
    string name = "canny_agent",
    uvm_component parent = null
  );

    super.new(name, parent);

  endfunction

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
        "CANNY_AGENT",
        "Canny configuration was not found."
      )

    end


    if (
      cfg == null
    ) begin

      `uvm_fatal(
        "CANNY_AGENT",
        "Received canny_config object is null."
      )

    end


    // Prosledjujemo istu konfiguraciju driveru i monitoru.
    // Ovo obezbedjuje da obe komponente koriste isti vif,
    // dimenzije slike, pragove i golden vektore.

    uvm_config_db#(canny_config)::set(
      this,
      "driver",
      "cfg",
      cfg
    );


    uvm_config_db#(canny_config)::set(
      this,
      "monitor",
      "cfg",
      cfg
    );


    sequencer =
      canny_sequencer::type_id::create(
        "sequencer",
        this
      );


    driver =
      canny_driver::type_id::create(
        "driver",
        this
      );


    monitor =
      canny_monitor::type_id::create(
        "monitor",
        this
      );


    if (
      sequencer == null
    ) begin

      `uvm_fatal(
        "CANNY_AGENT",
        "Failed to create Canny sequencer."
      )

    end


    if (
      driver == null
    ) begin

      `uvm_fatal(
        "CANNY_AGENT",
        "Failed to create Canny driver."
      )

    end


    if (
      monitor == null
    ) begin

      `uvm_fatal(
        "CANNY_AGENT",
        "Failed to create Canny monitor."
      )

    end


    `uvm_info(
      "CANNY_AGENT",
      {
        "Canny agent build phase completed: ",
        "sequencer, driver and monitor were created."
      },
      UVM_LOW
    )

  endfunction


  // ==========================================================
  // Connect phase
  //
  // Monitor analysis port ce kasnije biti povezan sa:
  //
  //   scoreboard
  //   coverage
  //
  // unutar canny_env.sv.
  // ==========================================================

  virtual function void connect_phase(
    uvm_phase phase
  );

    super.connect_phase(phase);


    driver.seq_item_port.connect(
      sequencer.seq_item_export
    );


    `uvm_info(
      "CANNY_AGENT",
      "Driver and sequencer connected. Monitor is active.",
      UVM_LOW
    )

  endfunction

endclass

`endif
