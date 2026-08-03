`timescale 1ns / 1ps

interface canny_if(input logic clk);

  // Zajedni?ki reset za oba AXI interfejsa.
  // Aktivan je na logi?koj nuli.
  logic rst_n;

  // ============================================================
  // S00_AXI - AXI4-Lite kontrolni/statusni interfejs
  // ============================================================

  // Write address kanal
  logic [4:0]  s00_axi_awaddr;
  logic [2:0]  s00_axi_awprot;
  logic        s00_axi_awvalid;
  logic        s00_axi_awready;

  // Write data kanal
  logic [31:0] s00_axi_wdata;
  logic [3:0]  s00_axi_wstrb;
  logic        s00_axi_wvalid;
  logic        s00_axi_wready;

  // Write response kanal
  logic [1:0]  s00_axi_bresp;
  logic        s00_axi_bvalid;
  logic        s00_axi_bready;

  // Read address kanal
  logic [4:0]  s00_axi_araddr;
  logic [2:0]  s00_axi_arprot;
  logic        s00_axi_arvalid;
  logic        s00_axi_arready;

  // Read data kanal
  logic [31:0] s00_axi_rdata;
  logic [1:0]  s00_axi_rresp;
  logic        s00_axi_rvalid;
  logic        s00_axi_rready;

  // ============================================================
  // S01_AXI - AXI4-Full interfejs za prenos slika
  // ============================================================

  // Write address kanal
  logic [0:0]  s01_axi_awid;
  logic [18:0] s01_axi_awaddr;
  logic [7:0]  s01_axi_awlen;
  logic [2:0]  s01_axi_awsize;
  logic [1:0]  s01_axi_awburst;
  logic        s01_axi_awlock;
  logic [3:0]  s01_axi_awcache;
  logic [2:0]  s01_axi_awprot;
  logic [3:0]  s01_axi_awqos;
  logic [3:0]  s01_axi_awregion;
  logic [0:0]  s01_axi_awuser;
  logic        s01_axi_awvalid;
  logic        s01_axi_awready;

  // Write data kanal
  logic [31:0] s01_axi_wdata;
  logic [3:0]  s01_axi_wstrb;
  logic        s01_axi_wlast;
  logic [0:0]  s01_axi_wuser;
  logic        s01_axi_wvalid;
  logic        s01_axi_wready;

  // Write response kanal
  logic [0:0]  s01_axi_bid;
  logic [1:0]  s01_axi_bresp;
  logic [0:0]  s01_axi_buser;
  logic        s01_axi_bvalid;
  logic        s01_axi_bready;

  // Read address kanal
  logic [0:0]  s01_axi_arid;
  logic [18:0] s01_axi_araddr;
  logic [7:0]  s01_axi_arlen;
  logic [2:0]  s01_axi_arsize;
  logic [1:0]  s01_axi_arburst;
  logic        s01_axi_arlock;
  logic [3:0]  s01_axi_arcache;
  logic [2:0]  s01_axi_arprot;
  logic [3:0]  s01_axi_arqos;
  logic [3:0]  s01_axi_arregion;
  logic [0:0]  s01_axi_aruser;
  logic        s01_axi_arvalid;
  logic        s01_axi_arready;

  // Read data kanal
  logic [0:0]  s01_axi_rid;
  logic [31:0] s01_axi_rdata;
  logic [1:0]  s01_axi_rresp;
  logic        s01_axi_rlast;
  logic [0:0]  s01_axi_ruser;
  logic        s01_axi_rvalid;
  logic        s01_axi_rready;

endinterface
