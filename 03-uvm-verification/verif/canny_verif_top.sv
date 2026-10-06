`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

import canny_test_pkg::*;

module canny_verif_top;

  // ============================================================
  // Clock generation
  // 50 MHz verification clock (20 ns period).
  // ============================================================

  logic clk;

  initial begin
    clk = 1'b0;

    forever begin
      #10ns;
      clk = ~clk;
    end
  end


  // ============================================================
  // Canny AXI interface
  // ============================================================

  canny_if vif(clk);


  // ============================================================
  // Reset generation
  // Zajednicki reset za AXI-Lite i AXI-Full
  // Aktivan je na logickoj nuli
  // ============================================================

  initial begin
    vif.rst_n = 1'b0;

    repeat (5)
      @(posedge clk);

    vif.rst_n = 1'b1;
  end


  // ============================================================
  // Canny AXI DUT
  // ============================================================

  axi_full_image_v1_0 #(

    // Canny image parameters
    .IMG_WIDTH  (512),
    .IMG_HEIGHT (384),
    .BRAM_SIZE  (196608),
    .ADDR_WIDTH (18),

    // AXI4-Lite parameters
    .C_S00_AXI_DATA_WIDTH (32),
    .C_S00_AXI_ADDR_WIDTH (5),

    // AXI4-Full parameters
    .C_S01_AXI_ID_WIDTH     (1),
    .C_S01_AXI_DATA_WIDTH   (32),
    .C_S01_AXI_ADDR_WIDTH   (19),

    // USER port widths are set to 1 so that they can be
    // connected to SystemVerilog one-bit signals.
    .C_S01_AXI_AWUSER_WIDTH (1),
    .C_S01_AXI_ARUSER_WIDTH (1),
    .C_S01_AXI_WUSER_WIDTH  (1),
    .C_S01_AXI_RUSER_WIDTH  (1),
    .C_S01_AXI_BUSER_WIDTH  (1)

  ) dut (

    // ==========================================================
    // S00_AXI - AXI4-Lite
    // ==========================================================

    .s00_axi_aclk    (clk),
    .s00_axi_aresetn (vif.rst_n),

    // Write address channel
    .s00_axi_awaddr  (vif.s00_axi_awaddr),
    .s00_axi_awprot  (vif.s00_axi_awprot),
    .s00_axi_awvalid (vif.s00_axi_awvalid),
    .s00_axi_awready (vif.s00_axi_awready),

    // Write data channel
    .s00_axi_wdata   (vif.s00_axi_wdata),
    .s00_axi_wstrb   (vif.s00_axi_wstrb),
    .s00_axi_wvalid  (vif.s00_axi_wvalid),
    .s00_axi_wready  (vif.s00_axi_wready),

    // Write response channel
    .s00_axi_bresp   (vif.s00_axi_bresp),
    .s00_axi_bvalid  (vif.s00_axi_bvalid),
    .s00_axi_bready  (vif.s00_axi_bready),

    // Read address channel
    .s00_axi_araddr  (vif.s00_axi_araddr),
    .s00_axi_arprot  (vif.s00_axi_arprot),
    .s00_axi_arvalid (vif.s00_axi_arvalid),
    .s00_axi_arready (vif.s00_axi_arready),

    // Read data channel
    .s00_axi_rdata   (vif.s00_axi_rdata),
    .s00_axi_rresp   (vif.s00_axi_rresp),
    .s00_axi_rvalid  (vif.s00_axi_rvalid),
    .s00_axi_rready  (vif.s00_axi_rready),


    // ==========================================================
    // S01_AXI - AXI4-Full
    // ==========================================================

    .s01_axi_aclk     (clk),
    .s01_axi_aresetn  (vif.rst_n),

    // Write address channel
    .s01_axi_awid     (vif.s01_axi_awid),
    .s01_axi_awaddr   (vif.s01_axi_awaddr),
    .s01_axi_awlen    (vif.s01_axi_awlen),
    .s01_axi_awsize   (vif.s01_axi_awsize),
    .s01_axi_awburst  (vif.s01_axi_awburst),
    .s01_axi_awlock   (vif.s01_axi_awlock),
    .s01_axi_awcache  (vif.s01_axi_awcache),
    .s01_axi_awprot   (vif.s01_axi_awprot),
    .s01_axi_awqos    (vif.s01_axi_awqos),
    .s01_axi_awregion (vif.s01_axi_awregion),
    .s01_axi_awuser   (vif.s01_axi_awuser),
    .s01_axi_awvalid  (vif.s01_axi_awvalid),
    .s01_axi_awready  (vif.s01_axi_awready),

    // Write data channel
    .s01_axi_wdata    (vif.s01_axi_wdata),
    .s01_axi_wstrb    (vif.s01_axi_wstrb),
    .s01_axi_wlast    (vif.s01_axi_wlast),
    .s01_axi_wuser    (vif.s01_axi_wuser),
    .s01_axi_wvalid   (vif.s01_axi_wvalid),
    .s01_axi_wready   (vif.s01_axi_wready),

    // Write response channel
    .s01_axi_bid      (vif.s01_axi_bid),
    .s01_axi_bresp    (vif.s01_axi_bresp),
    .s01_axi_buser    (vif.s01_axi_buser),
    .s01_axi_bvalid   (vif.s01_axi_bvalid),
    .s01_axi_bready   (vif.s01_axi_bready),

    // Read address channel
    .s01_axi_arid     (vif.s01_axi_arid),
    .s01_axi_araddr   (vif.s01_axi_araddr),
    .s01_axi_arlen    (vif.s01_axi_arlen),
    .s01_axi_arsize   (vif.s01_axi_arsize),
    .s01_axi_arburst  (vif.s01_axi_arburst),
    .s01_axi_arlock   (vif.s01_axi_arlock),
    .s01_axi_arcache  (vif.s01_axi_arcache),
    .s01_axi_arprot   (vif.s01_axi_arprot),
    .s01_axi_arqos    (vif.s01_axi_arqos),
    .s01_axi_arregion (vif.s01_axi_arregion),
    .s01_axi_aruser   (vif.s01_axi_aruser),
    .s01_axi_arvalid  (vif.s01_axi_arvalid),
    .s01_axi_arready  (vif.s01_axi_arready),

    // Read data channel
    .s01_axi_rid      (vif.s01_axi_rid),
    .s01_axi_rdata    (vif.s01_axi_rdata),
    .s01_axi_rresp    (vif.s01_axi_rresp),
    .s01_axi_rlast    (vif.s01_axi_rlast),
    .s01_axi_ruser    (vif.s01_axi_ruser),
    .s01_axi_rvalid   (vif.s01_axi_rvalid),
    .s01_axi_rready   (vif.s01_axi_rready)

  );


  // ============================================================
  // Initial AXI values
  // Initialize AXI master signals to inactive values.
  // The UVM driver controls them during simulation.
  // ============================================================

  initial begin

    // ----------------------------------------------------------
    // AXI4-Lite defaults
    // ----------------------------------------------------------

    vif.s00_axi_awaddr  = '0;
    vif.s00_axi_awprot  = '0;
    vif.s00_axi_awvalid = 1'b0;

    vif.s00_axi_wdata   = '0;
    vif.s00_axi_wstrb   = '0;
    vif.s00_axi_wvalid  = 1'b0;

    vif.s00_axi_bready  = 1'b0;

    vif.s00_axi_araddr  = '0;
    vif.s00_axi_arprot  = '0;
    vif.s00_axi_arvalid = 1'b0;

    vif.s00_axi_rready  = 1'b0;


    // ----------------------------------------------------------
    // AXI4-Full write defaults
    // ----------------------------------------------------------

    vif.s01_axi_awid     = '0;
    vif.s01_axi_awaddr   = '0;
    vif.s01_axi_awlen    = '0;
    vif.s01_axi_awsize   = '0;
    vif.s01_axi_awburst  = '0;
    vif.s01_axi_awlock   = 1'b0;
    vif.s01_axi_awcache  = '0;
    vif.s01_axi_awprot   = '0;
    vif.s01_axi_awqos    = '0;
    vif.s01_axi_awregion = '0;
    vif.s01_axi_awuser   = '0;
    vif.s01_axi_awvalid  = 1'b0;

    vif.s01_axi_wdata    = '0;
    vif.s01_axi_wstrb    = '0;
    vif.s01_axi_wlast    = 1'b0;
    vif.s01_axi_wuser    = '0;
    vif.s01_axi_wvalid   = 1'b0;

    vif.s01_axi_bready   = 1'b0;


    // ----------------------------------------------------------
    // AXI4-Full read defaults
    // ----------------------------------------------------------

    vif.s01_axi_arid     = '0;
    vif.s01_axi_araddr   = '0;
    vif.s01_axi_arlen    = '0;
    vif.s01_axi_arsize   = '0;
    vif.s01_axi_arburst  = '0;
    vif.s01_axi_arlock   = 1'b0;
    vif.s01_axi_arcache  = '0;
    vif.s01_axi_arprot   = '0;
    vif.s01_axi_arqos    = '0;
    vif.s01_axi_arregion = '0;
    vif.s01_axi_aruser   = '0;
    vif.s01_axi_arvalid  = 1'b0;

    vif.s01_axi_rready   = 1'b0;

  end


  // ============================================================
  // UVM start
  //
  // Select the test with +UVM_TESTNAME=<test_name>.
  // ============================================================

  initial begin

    uvm_config_db#(virtual canny_if)::set(
      null,
      "*",
      "vif",
      vif
    );

    run_test();

  end

endmodule