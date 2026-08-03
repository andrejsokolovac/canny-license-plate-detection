library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_full_image_v1_0 is
    generic (
        -- Users to add parameters here
        IMG_WIDTH  : integer := 512;
        IMG_HEIGHT : integer := 384;
        BRAM_SIZE  : integer := 196608;
        ADDR_WIDTH : integer := 18;
        -- User parameters ends

        -- Do not modify the parameters beyond this line

        -- Parameters of Axi Slave Bus Interface S00_AXI
        C_S00_AXI_DATA_WIDTH : integer := 32;
        C_S00_AXI_ADDR_WIDTH : integer := 5;

        -- Parameters of Axi Slave Bus Interface S01_AXI
        C_S01_AXI_ID_WIDTH     : integer := 1;
        C_S01_AXI_DATA_WIDTH   : integer := 32;
        C_S01_AXI_ADDR_WIDTH   : integer := 19;
        C_S01_AXI_AWUSER_WIDTH : integer := 0;
        C_S01_AXI_ARUSER_WIDTH : integer := 0;
        C_S01_AXI_WUSER_WIDTH  : integer := 0;
        C_S01_AXI_RUSER_WIDTH  : integer := 0;
        C_S01_AXI_BUSER_WIDTH  : integer := 0
    );
    port (
        -- Users to add ports here

        -- User ports ends
        -- Do not modify the ports beyond this line

        ----------------------------------------------------------------
        -- Ports of Axi Slave Bus Interface S00_AXI
        ----------------------------------------------------------------
        s00_axi_aclk    : in std_logic;
        s00_axi_aresetn : in std_logic;
        s00_axi_awaddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_awprot  : in std_logic_vector(2 downto 0);
        s00_axi_awvalid : in std_logic;
        s00_axi_awready : out std_logic;
        s00_axi_wdata   : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_wstrb   : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
        s00_axi_wvalid  : in std_logic;
        s00_axi_wready  : out std_logic;
        s00_axi_bresp   : out std_logic_vector(1 downto 0);
        s00_axi_bvalid  : out std_logic;
        s00_axi_bready  : in std_logic;
        s00_axi_araddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_arprot  : in std_logic_vector(2 downto 0);
        s00_axi_arvalid : in std_logic;
        s00_axi_arready : out std_logic;
        s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_rresp   : out std_logic_vector(1 downto 0);
        s00_axi_rvalid  : out std_logic;
        s00_axi_rready  : in std_logic;

        ----------------------------------------------------------------
        -- Ports of Axi Slave Bus Interface S01_AXI
        ----------------------------------------------------------------
        s01_axi_aclk     : in std_logic;
        s01_axi_aresetn  : in std_logic;
        s01_axi_awid     : in std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
        s01_axi_awaddr   : in std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
        s01_axi_awlen    : in std_logic_vector(7 downto 0);
        s01_axi_awsize   : in std_logic_vector(2 downto 0);
        s01_axi_awburst  : in std_logic_vector(1 downto 0);
        s01_axi_awlock   : in std_logic;
        s01_axi_awcache  : in std_logic_vector(3 downto 0);
        s01_axi_awprot   : in std_logic_vector(2 downto 0);
        s01_axi_awqos    : in std_logic_vector(3 downto 0);
        s01_axi_awregion : in std_logic_vector(3 downto 0);
        s01_axi_awuser   : in std_logic_vector(C_S01_AXI_AWUSER_WIDTH-1 downto 0);
        s01_axi_awvalid  : in std_logic;
        s01_axi_awready  : out std_logic;
        s01_axi_wdata    : in std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
        s01_axi_wstrb    : in std_logic_vector((C_S01_AXI_DATA_WIDTH/8)-1 downto 0);
        s01_axi_wlast    : in std_logic;
        s01_axi_wuser    : in std_logic_vector(C_S01_AXI_WUSER_WIDTH-1 downto 0);
        s01_axi_wvalid   : in std_logic;
        s01_axi_wready   : out std_logic;
        s01_axi_bid      : out std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
        s01_axi_bresp    : out std_logic_vector(1 downto 0);
        s01_axi_buser    : out std_logic_vector(C_S01_AXI_BUSER_WIDTH-1 downto 0);
        s01_axi_bvalid   : out std_logic;
        s01_axi_bready   : in std_logic;
        s01_axi_arid     : in std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
        s01_axi_araddr   : in std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
        s01_axi_arlen    : in std_logic_vector(7 downto 0);
        s01_axi_arsize   : in std_logic_vector(2 downto 0);
        s01_axi_arburst  : in std_logic_vector(1 downto 0);
        s01_axi_arlock   : in std_logic;
        s01_axi_arcache  : in std_logic_vector(3 downto 0);
        s01_axi_arprot   : in std_logic_vector(2 downto 0);
        s01_axi_arqos    : in std_logic_vector(3 downto 0);
        s01_axi_arregion : in std_logic_vector(3 downto 0);
        s01_axi_aruser   : in std_logic_vector(C_S01_AXI_ARUSER_WIDTH-1 downto 0);
        s01_axi_arvalid  : in std_logic;
        s01_axi_arready  : out std_logic;
        s01_axi_rid      : out std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
        s01_axi_rdata    : out std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
        s01_axi_rresp    : out std_logic_vector(1 downto 0);
        s01_axi_rlast    : out std_logic;
        s01_axi_ruser    : out std_logic_vector(C_S01_AXI_RUSER_WIDTH-1 downto 0);
        s01_axi_rvalid   : out std_logic;
        s01_axi_rready   : in std_logic
    );
end axi_full_image_v1_0;

architecture arch_imp of axi_full_image_v1_0 is

    --------------------------------------------------------------------
    -- Reset
    --------------------------------------------------------------------
    signal reset_s : std_logic;

    --------------------------------------------------------------------
    -- AXI-Lite register interface signals
    --------------------------------------------------------------------
    signal reg_data_s : std_logic_vector(31 downto 0);

    signal reg_rows_wr_s           : std_logic;
    signal reg_cols_wr_s           : std_logic;
    signal reg_low_threshold_wr_s  : std_logic;
    signal reg_high_threshold_wr_s : std_logic;
    signal reg_start_wr_s          : std_logic;

    signal reg_rows_s           : std_logic_vector(8 downto 0);
    signal reg_cols_s           : std_logic_vector(9 downto 0);
    signal reg_low_threshold_s  : std_logic_vector(7 downto 0);
    signal reg_high_threshold_s : std_logic_vector(7 downto 0);
    signal reg_start_s          : std_logic;
    signal reg_ready_s          : std_logic;

    signal ready_from_ip_s : std_logic;

    --------------------------------------------------------------------
    -- AXI-Full memory interface signals
    --------------------------------------------------------------------
    signal mem_addr_s      : std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 2);
    signal mem_data_s      : std_logic_vector(31 downto 0);
    signal mem_wr_s        : std_logic;
    signal mem_read_data_s : std_logic_vector(31 downto 0);

    --------------------------------------------------------------------
    -- INPUT BRAM signals between mem_subsystem and Canny IP
    --------------------------------------------------------------------
    signal input_ena_s   : std_logic;
    signal input_wea_s   : std_logic;
    signal input_addra_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal input_dia_s   : std_logic_vector(7 downto 0);
    signal input_doa_s   : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- GAUSS BRAM signals
    --------------------------------------------------------------------
    signal gauss_ena_s   : std_logic;
    signal gauss_wea_s   : std_logic;
    signal gauss_addra_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal gauss_dia_s   : std_logic_vector(7 downto 0);
    signal gauss_doa_s   : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- MAG BRAM signals
    --------------------------------------------------------------------
    signal mag_ena_s   : std_logic;
    signal mag_wea_s   : std_logic;
    signal mag_addra_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal mag_dia_s   : std_logic_vector(15 downto 0);
    signal mag_doa_s   : std_logic_vector(15 downto 0);

    --------------------------------------------------------------------
    -- DIR BRAM signals
    --------------------------------------------------------------------
    signal dir_ena_s   : std_logic;
    signal dir_wea_s   : std_logic;
    signal dir_addra_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal dir_dia_s   : std_logic_vector(7 downto 0);
    signal dir_doa_s   : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- NMS BRAM signals
    --------------------------------------------------------------------
    signal nms_ena_s   : std_logic;
    signal nms_wea_s   : std_logic;
    signal nms_addra_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal nms_dia_s   : std_logic_vector(15 downto 0);
    signal nms_doa_s   : std_logic_vector(15 downto 0);

    --------------------------------------------------------------------
    -- THRESH BRAM signals
    --------------------------------------------------------------------
    signal thresh_ena_s   : std_logic;
    signal thresh_wea_s   : std_logic;
    signal thresh_addra_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal thresh_dia_s   : std_logic_vector(7 downto 0);
    signal thresh_doa_s   : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- EDGE BRAM signals
    --------------------------------------------------------------------
    signal edge_ena_s   : std_logic;
    signal edge_wea_s   : std_logic;
    signal edge_addra_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal edge_dia_s   : std_logic_vector(7 downto 0);
    signal edge_doa_s   : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- Component declarations
    --------------------------------------------------------------------

    component axi_full_image_v1_0_S00_AXI is
        generic (
            C_S_AXI_DATA_WIDTH : integer := 32;
            C_S_AXI_ADDR_WIDTH : integer := 5
        );
        port (
            reg_data_o : out std_logic_vector(31 downto 0);

            reg_rows_wr_o           : out std_logic;
            reg_cols_wr_o           : out std_logic;
            reg_low_threshold_wr_o  : out std_logic;
            reg_high_threshold_wr_o : out std_logic;
            reg_start_wr_o          : out std_logic;

            reg_rows_i           : in std_logic_vector(8 downto 0);
            reg_cols_i           : in std_logic_vector(9 downto 0);
            reg_low_threshold_i  : in std_logic_vector(7 downto 0);
            reg_high_threshold_i : in std_logic_vector(7 downto 0);
            reg_start_i          : in std_logic;
            reg_ready_i          : in std_logic;

            S_AXI_ACLK    : in std_logic;
            S_AXI_ARESETN : in std_logic;
            S_AXI_AWADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
            S_AXI_AWVALID : in std_logic;
            S_AXI_AWREADY : out std_logic;
            S_AXI_WDATA   : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB   : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            S_AXI_WVALID  : in std_logic;
            S_AXI_WREADY  : out std_logic;
            S_AXI_BRESP   : out std_logic_vector(1 downto 0);
            S_AXI_BVALID  : out std_logic;
            S_AXI_BREADY  : in std_logic;
            S_AXI_ARADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_ARPROT  : in std_logic_vector(2 downto 0);
            S_AXI_ARVALID : in std_logic;
            S_AXI_ARREADY : out std_logic;
            S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP   : out std_logic_vector(1 downto 0);
            S_AXI_RVALID  : out std_logic;
            S_AXI_RREADY  : in std_logic
        );
    end component;

    component axi_full_image_v1_0_S01_AXI is
        generic (
            C_S_AXI_ID_WIDTH     : integer := 1;
            C_S_AXI_DATA_WIDTH   : integer := 32;
            C_S_AXI_ADDR_WIDTH   : integer := 19;
            C_S_AXI_AWUSER_WIDTH : integer := 0;
            C_S_AXI_ARUSER_WIDTH : integer := 0;
            C_S_AXI_WUSER_WIDTH  : integer := 0;
            C_S_AXI_RUSER_WIDTH  : integer := 0;
            C_S_AXI_BUSER_WIDTH  : integer := 0
        );
        port (
            mem_addr_o      : out std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 2);
            mem_data_o      : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            mem_wr_o        : out std_logic;
            mem_read_data_i : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

            S_AXI_ACLK     : in std_logic;
            S_AXI_ARESETN  : in std_logic;
            S_AXI_AWID     : in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
            S_AXI_AWADDR   : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_AWLEN    : in std_logic_vector(7 downto 0);
            S_AXI_AWSIZE   : in std_logic_vector(2 downto 0);
            S_AXI_AWBURST  : in std_logic_vector(1 downto 0);
            S_AXI_AWLOCK   : in std_logic;
            S_AXI_AWCACHE  : in std_logic_vector(3 downto 0);
            S_AXI_AWPROT   : in std_logic_vector(2 downto 0);
            S_AXI_AWQOS    : in std_logic_vector(3 downto 0);
            S_AXI_AWREGION : in std_logic_vector(3 downto 0);
            S_AXI_AWUSER   : in std_logic_vector(C_S_AXI_AWUSER_WIDTH-1 downto 0);
            S_AXI_AWVALID  : in std_logic;
            S_AXI_AWREADY  : out std_logic;
            S_AXI_WDATA    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            S_AXI_WLAST    : in std_logic;
            S_AXI_WUSER    : in std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);
            S_AXI_WVALID   : in std_logic;
            S_AXI_WREADY   : out std_logic;
            S_AXI_BID      : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
            S_AXI_BRESP    : out std_logic_vector(1 downto 0);
            S_AXI_BUSER    : out std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
            S_AXI_BVALID   : out std_logic;
            S_AXI_BREADY   : in std_logic;
            S_AXI_ARID     : in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
            S_AXI_ARADDR   : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_ARLEN    : in std_logic_vector(7 downto 0);
            S_AXI_ARSIZE   : in std_logic_vector(2 downto 0);
            S_AXI_ARBURST  : in std_logic_vector(1 downto 0);
            S_AXI_ARLOCK   : in std_logic;
            S_AXI_ARCACHE  : in std_logic_vector(3 downto 0);
            S_AXI_ARPROT   : in std_logic_vector(2 downto 0);
            S_AXI_ARQOS    : in std_logic_vector(3 downto 0);
            S_AXI_ARREGION : in std_logic_vector(3 downto 0);
            S_AXI_ARUSER   : in std_logic_vector(C_S_AXI_ARUSER_WIDTH-1 downto 0);
            S_AXI_ARVALID  : in std_logic;
            S_AXI_ARREADY  : out std_logic;
            S_AXI_RID      : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
            S_AXI_RDATA    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP    : out std_logic_vector(1 downto 0);
            S_AXI_RLAST    : out std_logic;
            S_AXI_RUSER    : out std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
            S_AXI_RVALID   : out std_logic;
            S_AXI_RREADY   : in std_logic
        );
    end component;

    component mem_subsystem is
        generic (
            BRAM_SIZE  : integer := 196608;
            ADDR_WIDTH : integer := 18
        );
        port (
            clk   : in std_logic;
            reset : in std_logic;

            reg_data_i : in std_logic_vector(31 downto 0);

            reg_rows_wr_i           : in std_logic;
            reg_cols_wr_i           : in std_logic;
            reg_low_threshold_wr_i  : in std_logic;
            reg_high_threshold_wr_i : in std_logic;
            reg_start_wr_i          : in std_logic;

            reg_rows_o           : out std_logic_vector(8 downto 0);
            reg_cols_o           : out std_logic_vector(9 downto 0);
            reg_low_threshold_o  : out std_logic_vector(7 downto 0);
            reg_high_threshold_o : out std_logic_vector(7 downto 0);
            reg_start_o          : out std_logic;

            ready_i : in std_logic;
            ready_o : out std_logic;

            mem_addr_i      : in std_logic_vector(16 downto 0);
            mem_data_i      : in std_logic_vector(31 downto 0);
            mem_wr_i        : in std_logic;
            mem_read_data_o : out std_logic_vector(31 downto 0);

            input_ena_i   : in std_logic;
            input_wea_i   : in std_logic;
            input_addra_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            input_dia_i   : in std_logic_vector(7 downto 0);
            input_doa_o   : out std_logic_vector(7 downto 0);

            gauss_ena_i   : in std_logic;
            gauss_wea_i   : in std_logic;
            gauss_addra_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            gauss_dia_i   : in std_logic_vector(7 downto 0);
            gauss_doa_o   : out std_logic_vector(7 downto 0);

            mag_ena_i   : in std_logic;
            mag_wea_i   : in std_logic;
            mag_addra_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            mag_dia_i   : in std_logic_vector(15 downto 0);
            mag_doa_o   : out std_logic_vector(15 downto 0);

            dir_ena_i   : in std_logic;
            dir_wea_i   : in std_logic;
            dir_addra_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            dir_dia_i   : in std_logic_vector(7 downto 0);
            dir_doa_o   : out std_logic_vector(7 downto 0);

            nms_ena_i   : in std_logic;
            nms_wea_i   : in std_logic;
            nms_addra_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            nms_dia_i   : in std_logic_vector(15 downto 0);
            nms_doa_o   : out std_logic_vector(15 downto 0);

            thresh_ena_i   : in std_logic;
            thresh_wea_i   : in std_logic;
            thresh_addra_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            thresh_dia_i   : in std_logic_vector(7 downto 0);
            thresh_doa_o   : out std_logic_vector(7 downto 0);

            edge_ena_i   : in std_logic;
            edge_wea_i   : in std_logic;
            edge_addra_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            edge_dia_i   : in std_logic_vector(7 downto 0);
            edge_doa_o   : out std_logic_vector(7 downto 0)
        );
    end component;

    component ip is
        generic (
            IMG_WIDTH  : integer := 512;
            IMG_HEIGHT : integer := 384;
            ADDR_WIDTH : integer := 18
        );
        port (
            clk   : in std_logic;
            reset : in std_logic;
            start : in std_logic;
            ready : out std_logic;

            rows : in std_logic_vector(8 downto 0);
            cols : in std_logic_vector(9 downto 0);

            low_threshold_i  : in std_logic_vector(7 downto 0);
            high_threshold_i : in std_logic_vector(7 downto 0);

            input_ena   : out std_logic;
            input_wea   : out std_logic;
            input_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
            input_dia   : out std_logic_vector(7 downto 0);
            input_doa   : in std_logic_vector(7 downto 0);

            gauss_ena   : out std_logic;
            gauss_wea   : out std_logic;
            gauss_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
            gauss_dia   : out std_logic_vector(7 downto 0);
            gauss_doa   : in std_logic_vector(7 downto 0);

            mag_ena   : out std_logic;
            mag_wea   : out std_logic;
            mag_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
            mag_dia   : out std_logic_vector(15 downto 0);
            mag_doa   : in std_logic_vector(15 downto 0);

            dir_ena   : out std_logic;
            dir_wea   : out std_logic;
            dir_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
            dir_dia   : out std_logic_vector(7 downto 0);
            dir_doa   : in std_logic_vector(7 downto 0);

            nms_ena   : out std_logic;
            nms_wea   : out std_logic;
            nms_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
            nms_dia   : out std_logic_vector(15 downto 0);
            nms_doa   : in std_logic_vector(15 downto 0);

            thresh_ena   : out std_logic;
            thresh_wea   : out std_logic;
            thresh_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
            thresh_dia   : out std_logic_vector(7 downto 0);
            thresh_doa   : in std_logic_vector(7 downto 0);

            edge_ena   : out std_logic;
            edge_wea   : out std_logic;
            edge_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
            edge_dia   : out std_logic_vector(7 downto 0);
            edge_doa   : in std_logic_vector(7 downto 0)
        );
    end component;

begin

    --------------------------------------------------------------------
    -- Active-low AXI reset to active-high internal reset
    --------------------------------------------------------------------
    reset_s <= not s00_axi_aresetn;

    --------------------------------------------------------------------
    -- AXI-Lite controller instance
    --------------------------------------------------------------------
    canny_axi_v1_0_S00_AXI_inst : axi_full_image_v1_0_S00_AXI
        generic map (
            C_S_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH
        )
        port map (
            reg_data_o => reg_data_s,

            reg_rows_wr_o           => reg_rows_wr_s,
            reg_cols_wr_o           => reg_cols_wr_s,
            reg_low_threshold_wr_o  => reg_low_threshold_wr_s,
            reg_high_threshold_wr_o => reg_high_threshold_wr_s,
            reg_start_wr_o          => reg_start_wr_s,

            reg_rows_i           => reg_rows_s,
            reg_cols_i           => reg_cols_s,
            reg_low_threshold_i  => reg_low_threshold_s,
            reg_high_threshold_i => reg_high_threshold_s,
            reg_start_i          => reg_start_s,
            reg_ready_i          => reg_ready_s,

            S_AXI_ACLK    => s00_axi_aclk,
            S_AXI_ARESETN => s00_axi_aresetn,
            S_AXI_AWADDR  => s00_axi_awaddr,
            S_AXI_AWPROT  => s00_axi_awprot,
            S_AXI_AWVALID => s00_axi_awvalid,
            S_AXI_AWREADY => s00_axi_awready,
            S_AXI_WDATA   => s00_axi_wdata,
            S_AXI_WSTRB   => s00_axi_wstrb,
            S_AXI_WVALID  => s00_axi_wvalid,
            S_AXI_WREADY  => s00_axi_wready,
            S_AXI_BRESP   => s00_axi_bresp,
            S_AXI_BVALID  => s00_axi_bvalid,
            S_AXI_BREADY  => s00_axi_bready,
            S_AXI_ARADDR  => s00_axi_araddr,
            S_AXI_ARPROT  => s00_axi_arprot,
            S_AXI_ARVALID => s00_axi_arvalid,
            S_AXI_ARREADY => s00_axi_arready,
            S_AXI_RDATA   => s00_axi_rdata,
            S_AXI_RRESP   => s00_axi_rresp,
            S_AXI_RVALID  => s00_axi_rvalid,
            S_AXI_RREADY  => s00_axi_rready
        );

    --------------------------------------------------------------------
    -- AXI-Full controller instance
    --------------------------------------------------------------------
    canny_axi_v1_0_S01_AXI_inst : axi_full_image_v1_0_S01_AXI
        generic map (
            C_S_AXI_ID_WIDTH     => C_S01_AXI_ID_WIDTH,
            C_S_AXI_DATA_WIDTH   => C_S01_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH   => C_S01_AXI_ADDR_WIDTH,
            C_S_AXI_AWUSER_WIDTH => C_S01_AXI_AWUSER_WIDTH,
            C_S_AXI_ARUSER_WIDTH => C_S01_AXI_ARUSER_WIDTH,
            C_S_AXI_WUSER_WIDTH  => C_S01_AXI_WUSER_WIDTH,
            C_S_AXI_RUSER_WIDTH  => C_S01_AXI_RUSER_WIDTH,
            C_S_AXI_BUSER_WIDTH  => C_S01_AXI_BUSER_WIDTH
        )
        port map (
            mem_addr_o      => mem_addr_s,
            mem_data_o      => mem_data_s,
            mem_wr_o        => mem_wr_s,
            mem_read_data_i => mem_read_data_s,

            S_AXI_ACLK     => s01_axi_aclk,
            S_AXI_ARESETN  => s01_axi_aresetn,
            S_AXI_AWID     => s01_axi_awid,
            S_AXI_AWADDR   => s01_axi_awaddr,
            S_AXI_AWLEN    => s01_axi_awlen,
            S_AXI_AWSIZE   => s01_axi_awsize,
            S_AXI_AWBURST  => s01_axi_awburst,
            S_AXI_AWLOCK   => s01_axi_awlock,
            S_AXI_AWCACHE  => s01_axi_awcache,
            S_AXI_AWPROT   => s01_axi_awprot,
            S_AXI_AWQOS    => s01_axi_awqos,
            S_AXI_AWREGION => s01_axi_awregion,
            S_AXI_AWUSER   => s01_axi_awuser,
            S_AXI_AWVALID  => s01_axi_awvalid,
            S_AXI_AWREADY  => s01_axi_awready,
            S_AXI_WDATA    => s01_axi_wdata,
            S_AXI_WSTRB    => s01_axi_wstrb,
            S_AXI_WLAST    => s01_axi_wlast,
            S_AXI_WUSER    => s01_axi_wuser,
            S_AXI_WVALID   => s01_axi_wvalid,
            S_AXI_WREADY   => s01_axi_wready,
            S_AXI_BID      => s01_axi_bid,
            S_AXI_BRESP    => s01_axi_bresp,
            S_AXI_BUSER    => s01_axi_buser,
            S_AXI_BVALID   => s01_axi_bvalid,
            S_AXI_BREADY   => s01_axi_bready,
            S_AXI_ARID     => s01_axi_arid,
            S_AXI_ARADDR   => s01_axi_araddr,
            S_AXI_ARLEN    => s01_axi_arlen,
            S_AXI_ARSIZE   => s01_axi_arsize,
            S_AXI_ARBURST  => s01_axi_arburst,
            S_AXI_ARLOCK   => s01_axi_arlock,
            S_AXI_ARCACHE  => s01_axi_arcache,
            S_AXI_ARPROT   => s01_axi_arprot,
            S_AXI_ARQOS    => s01_axi_arqos,
            S_AXI_ARREGION => s01_axi_arregion,
            S_AXI_ARUSER   => s01_axi_aruser,
            S_AXI_ARVALID  => s01_axi_arvalid,
            S_AXI_ARREADY  => s01_axi_arready,
            S_AXI_RID      => s01_axi_rid,
            S_AXI_RDATA    => s01_axi_rdata,
            S_AXI_RRESP    => s01_axi_rresp,
            S_AXI_RLAST    => s01_axi_rlast,
            S_AXI_RUSER    => s01_axi_ruser,
            S_AXI_RVALID   => s01_axi_rvalid,
            S_AXI_RREADY   => s01_axi_rready
        );

    --------------------------------------------------------------------
    -- Memory subsystem instance
    --------------------------------------------------------------------
    memory_subsystem_inst : mem_subsystem
        generic map (
            BRAM_SIZE  => BRAM_SIZE,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk   => s00_axi_aclk,
            reset => reset_s,

            reg_data_i => reg_data_s,

            reg_rows_wr_i           => reg_rows_wr_s,
            reg_cols_wr_i           => reg_cols_wr_s,
            reg_low_threshold_wr_i  => reg_low_threshold_wr_s,
            reg_high_threshold_wr_i => reg_high_threshold_wr_s,
            reg_start_wr_i          => reg_start_wr_s,

            reg_rows_o           => reg_rows_s,
            reg_cols_o           => reg_cols_s,
            reg_low_threshold_o  => reg_low_threshold_s,
            reg_high_threshold_o => reg_high_threshold_s,
            reg_start_o          => reg_start_s,

            ready_i => ready_from_ip_s,
            ready_o => reg_ready_s,

            mem_addr_i      => mem_addr_s,
            mem_data_i      => mem_data_s,
            mem_wr_i        => mem_wr_s,
            mem_read_data_o => mem_read_data_s,

            input_ena_i   => input_ena_s,
            input_wea_i   => input_wea_s,
            input_addra_i => input_addra_s,
            input_dia_i   => input_dia_s,
            input_doa_o   => input_doa_s,

            gauss_ena_i   => gauss_ena_s,
            gauss_wea_i   => gauss_wea_s,
            gauss_addra_i => gauss_addra_s,
            gauss_dia_i   => gauss_dia_s,
            gauss_doa_o   => gauss_doa_s,

            mag_ena_i   => mag_ena_s,
            mag_wea_i   => mag_wea_s,
            mag_addra_i => mag_addra_s,
            mag_dia_i   => mag_dia_s,
            mag_doa_o   => mag_doa_s,

            dir_ena_i   => dir_ena_s,
            dir_wea_i   => dir_wea_s,
            dir_addra_i => dir_addra_s,
            dir_dia_i   => dir_dia_s,
            dir_doa_o   => dir_doa_s,

            nms_ena_i   => nms_ena_s,
            nms_wea_i   => nms_wea_s,
            nms_addra_i => nms_addra_s,
            nms_dia_i   => nms_dia_s,
            nms_doa_o   => nms_doa_s,

            thresh_ena_i   => thresh_ena_s,
            thresh_wea_i   => thresh_wea_s,
            thresh_addra_i => thresh_addra_s,
            thresh_dia_i   => thresh_dia_s,
            thresh_doa_o   => thresh_doa_s,

            edge_ena_i   => edge_ena_s,
            edge_wea_i   => edge_wea_s,
            edge_addra_i => edge_addra_s,
            edge_dia_i   => edge_dia_s,
            edge_doa_o   => edge_doa_s
        );

    --------------------------------------------------------------------
    -- Canny algorithm instance
    --------------------------------------------------------------------
    canny_algorithm_inst : ip
        generic map (
            IMG_WIDTH  => IMG_WIDTH,
            IMG_HEIGHT => IMG_HEIGHT,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk   => s00_axi_aclk,
            reset => reset_s,
            start => reg_start_s,
            ready => ready_from_ip_s,

            rows => reg_rows_s,
            cols => reg_cols_s,

            low_threshold_i  => reg_low_threshold_s,
            high_threshold_i => reg_high_threshold_s,

            input_ena   => input_ena_s,
            input_wea   => input_wea_s,
            input_addra => input_addra_s,
            input_dia   => input_dia_s,
            input_doa   => input_doa_s,

            gauss_ena   => gauss_ena_s,
            gauss_wea   => gauss_wea_s,
            gauss_addra => gauss_addra_s,
            gauss_dia   => gauss_dia_s,
            gauss_doa   => gauss_doa_s,

            mag_ena   => mag_ena_s,
            mag_wea   => mag_wea_s,
            mag_addra => mag_addra_s,
            mag_dia   => mag_dia_s,
            mag_doa   => mag_doa_s,

            dir_ena   => dir_ena_s,
            dir_wea   => dir_wea_s,
            dir_addra => dir_addra_s,
            dir_dia   => dir_dia_s,
            dir_doa   => dir_doa_s,

            nms_ena   => nms_ena_s,
            nms_wea   => nms_wea_s,
            nms_addra => nms_addra_s,
            nms_dia   => nms_dia_s,
            nms_doa   => nms_doa_s,

            thresh_ena   => thresh_ena_s,
            thresh_wea   => thresh_wea_s,
            thresh_addra => thresh_addra_s,
            thresh_dia   => thresh_dia_s,
            thresh_doa   => thresh_doa_s,

            edge_ena   => edge_ena_s,
            edge_wea   => edge_wea_s,
            edge_addra => edge_addra_s,
            edge_dia   => edge_dia_s,
            edge_doa   => edge_doa_s
        );

end arch_imp;