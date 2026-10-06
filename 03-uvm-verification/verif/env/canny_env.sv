`ifndef CANNY_ENV_SV
`define CANNY_ENV_SV


class canny_env extends uvm_env;

  `uvm_component_utils(canny_env)


  canny_config cfg;


  canny_agent      agent;
  canny_scoreboard scoreboard;
  canny_coverage   coverage;


  function new(
    string name = "canny_env",
    uvm_component parent = null
  );

    super.new(name, parent);

  endfunction


  virtual function void build_phase(
    uvm_phase phase
  );

    super.build_phase(phase);


    // --------------------------------------------------------
    // Retrieve shared configuration.
    // --------------------------------------------------------

    if (
      !uvm_config_db#(canny_config)::get(
        this,
        "",
        "cfg",
        cfg
      )
    ) begin

      `uvm_fatal(
        "CANNY_ENV",
        "Canny configuration was not found."
      )

    end


    if (
      cfg == null
    ) begin

      `uvm_fatal(
        "CANNY_ENV",
        "Received canny_config object is null."
      )

    end


    // --------------------------------------------------------
    // Distribute configuration to components.
    //
    // The agent forwards cfg to the driver and monitor.
    // The scoreboard uses golden edge pixels.
    // Coverage uses image dimensions and threshold values.
    // --------------------------------------------------------

    uvm_config_db#(canny_config)::set(
      this,
      "agent",
      "cfg",
      cfg
    );


    uvm_config_db#(canny_config)::set(
      this,
      "scoreboard",
      "cfg",
      cfg
    );


    uvm_config_db#(canny_config)::set(
      this,
      "coverage",
      "cfg",
      cfg
    );


    // --------------------------------------------------------
    // Create components.
    // --------------------------------------------------------

    agent =
      canny_agent::type_id::create(
        "agent",
        this
      );


    scoreboard =
      canny_scoreboard::type_id::create(
        "scoreboard",
        this
      );


    coverage =
      canny_coverage::type_id::create(
        "coverage",
        this
      );


    // --------------------------------------------------------
    // Validate created components.
    // --------------------------------------------------------

    if (
      agent == null
    ) begin

      `uvm_fatal(
        "CANNY_ENV",
        "Failed to create Canny agent."
      )

    end


    if (
      scoreboard == null
    ) begin

      `uvm_fatal(
        "CANNY_ENV",
        "Failed to create Canny scoreboard."
      )

    end


    if (
      coverage == null
    ) begin

      `uvm_fatal(
        "CANNY_ENV",
        "Failed to create Canny coverage component."
      )

    end


    `uvm_info(
      "CANNY_ENV",
      {
        "Canny environment build phase completed: ",
        "agent, scoreboard and coverage were created."
      },
      UVM_LOW
    )

  endfunction


  // ==========================================================
  // Connect phase
  //
  // Connect monitor output to both scoreboard and coverage.
  // ==========================================================

  virtual function void connect_phase(
    uvm_phase phase
  );

    super.connect_phase(phase);


    agent.monitor.item_collected_port.connect(
      scoreboard.item_collected_export
    );


    agent.monitor.item_collected_port.connect(
      coverage.analysis_export
    );


    `uvm_info(
      "CANNY_ENV",
      {
        "Monitor connected to scoreboard ",
        "and coverage component."
      },
      UVM_LOW
    )

  endfunction

endclass

`endif
