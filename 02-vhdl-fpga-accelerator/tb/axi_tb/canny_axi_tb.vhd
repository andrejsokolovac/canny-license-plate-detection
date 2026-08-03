library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

entity canny_axi_tb is
end entity;

architecture tb_arch of canny_axi_tb is

    --------------------------------------------------------------------
    -- Image / Canny constants
    --------------------------------------------------------------------
    constant IMG_ROWS_C   : integer := 384;
    constant IMG_COLS_C   : integer := 512;
    constant IMAGE_SIZE_C : integer := IMG_ROWS_C * IMG_COLS_C; -- 196608 pixels
    constant WORD_COUNT_C : integer := IMAGE_SIZE_C / 4;        -- 49152 words

    --------------------------------------------------------------------
    -- Thresholds are configurable from CPU / AXI-Lite
    --------------------------------------------------------------------
    constant LOW_THRESHOLD_C  : integer := 50;
    constant HIGH_THRESHOLD_C : integer := 100;

    --------------------------------------------------------------------
    -- File paths
    --------------------------------------------------------------------
    file grayscale_file : text open read_mode is
        "C:/Users/Machi/Desktop/PSDS_PROJECT/input_images/grayscale_full.txt";

    file expected_edge_file : text open read_mode is
        "C:/Users/Machi/Desktop/PSDS_PROJECT/input_images/final_edge_full.txt";

    --------------------------------------------------------------------
    -- AXI-Lite register map
    --------------------------------------------------------------------
    constant ROWS_REG_ADDR_C           : integer := 16#00#;
    constant COLS_REG_ADDR_C           : integer := 16#04#;
    constant LOW_THRESHOLD_REG_ADDR_C  : integer := 16#08#;
    constant HIGH_THRESHOLD_REG_ADDR_C : integer := 16#0C#;
    constant START_REG_ADDR_C          : integer := 16#10#;
    constant READY_REG_ADDR_C          : integer := 16#14#;

    --------------------------------------------------------------------
    -- AXI-Full memory map
    --------------------------------------------------------------------
    constant INPUT_IMAGE_BASE_ADDR_C : integer := 16#00000#;
    constant EDGE_IMAGE_BASE_ADDR_C  : integer := 16#40000#;

    constant BURST_LEN_C : integer := 256;

    --------------------------------------------------------------------
    -- AXI constants
    --------------------------------------------------------------------
    constant C_S00_AXI_DATA_WIDTH_C : integer := 32;
    constant C_S00_AXI_ADDR_WIDTH_C : integer := 5;

    constant C_S01_AXI_ID_WIDTH_C     : integer := 1;
    constant C_S01_AXI_DATA_WIDTH_C   : integer := 32;
    constant C_S01_AXI_ADDR_WIDTH_C   : integer := 19;

    -- In simulation we use width 1 to avoid null-vector issues.
    constant C_S01_AXI_AWUSER_WIDTH_C : integer := 1;
    constant C_S01_AXI_ARUSER_WIDTH_C : integer := 1;
    constant C_S01_AXI_WUSER_WIDTH_C  : integer := 1;
    constant C_S01_AXI_RUSER_WIDTH_C  : integer := 1;
    constant C_S01_AXI_BUSER_WIDTH_C  : integer := 1;

    --------------------------------------------------------------------
    -- Clock
    --------------------------------------------------------------------
    signal clk_s : std_logic := '0';

    --------------------------------------------------------------------
    -- AXI-Lite signals
    --------------------------------------------------------------------
    signal s00_axi_aclk_s    : std_logic := '0';
    signal s00_axi_aresetn_s : std_logic := '1';

    signal s00_axi_awaddr_s  : std_logic_vector(C_S00_AXI_ADDR_WIDTH_C-1 downto 0) := (others => '0');
    signal s00_axi_awprot_s  : std_logic_vector(2 downto 0) := (others => '0');
    signal s00_axi_awvalid_s : std_logic := '0';
    signal s00_axi_awready_s : std_logic;

    signal s00_axi_wdata_s   : std_logic_vector(C_S00_AXI_DATA_WIDTH_C-1 downto 0) := (others => '0');
    signal s00_axi_wstrb_s   : std_logic_vector((C_S00_AXI_DATA_WIDTH_C/8)-1 downto 0) := (others => '0');
    signal s00_axi_wvalid_s  : std_logic := '0';
    signal s00_axi_wready_s  : std_logic;

    signal s00_axi_bresp_s   : std_logic_vector(1 downto 0);
    signal s00_axi_bvalid_s  : std_logic;
    signal s00_axi_bready_s  : std_logic := '0';

    signal s00_axi_araddr_s  : std_logic_vector(C_S00_AXI_ADDR_WIDTH_C-1 downto 0) := (others => '0');
    signal s00_axi_arprot_s  : std_logic_vector(2 downto 0) := (others => '0');
    signal s00_axi_arvalid_s : std_logic := '0';
    signal s00_axi_arready_s : std_logic;

    signal s00_axi_rdata_s   : std_logic_vector(C_S00_AXI_DATA_WIDTH_C-1 downto 0);
    signal s00_axi_rresp_s   : std_logic_vector(1 downto 0);
    signal s00_axi_rvalid_s  : std_logic;
    signal s00_axi_rready_s  : std_logic := '0';

    --------------------------------------------------------------------
    -- AXI-Full signals
    --------------------------------------------------------------------
    signal s01_axi_aclk_s    : std_logic := '0';
    signal s01_axi_aresetn_s : std_logic := '1';

    signal s01_axi_awid_s     : std_logic_vector(C_S01_AXI_ID_WIDTH_C-1 downto 0) := (others => '0');
    signal s01_axi_awaddr_s   : std_logic_vector(C_S01_AXI_ADDR_WIDTH_C-1 downto 0) := (others => '0');
    signal s01_axi_awlen_s    : std_logic_vector(7 downto 0) := (others => '0');
    signal s01_axi_awsize_s   : std_logic_vector(2 downto 0) := (others => '0');
    signal s01_axi_awburst_s  : std_logic_vector(1 downto 0) := (others => '0');
    signal s01_axi_awlock_s   : std_logic := '0';
    signal s01_axi_awcache_s  : std_logic_vector(3 downto 0) := (others => '0');
    signal s01_axi_awprot_s   : std_logic_vector(2 downto 0) := (others => '0');
    signal s01_axi_awqos_s    : std_logic_vector(3 downto 0) := (others => '0');
    signal s01_axi_awregion_s : std_logic_vector(3 downto 0) := (others => '0');
    signal s01_axi_awuser_s   : std_logic_vector(C_S01_AXI_AWUSER_WIDTH_C-1 downto 0) := (others => '0');
    signal s01_axi_awvalid_s  : std_logic := '0';
    signal s01_axi_awready_s  : std_logic;

    signal s01_axi_wdata_s   : std_logic_vector(C_S01_AXI_DATA_WIDTH_C-1 downto 0) := (others => '0');
    signal s01_axi_wstrb_s   : std_logic_vector((C_S01_AXI_DATA_WIDTH_C/8)-1 downto 0) := (others => '0');
    signal s01_axi_wlast_s   : std_logic := '0';
    signal s01_axi_wuser_s   : std_logic_vector(C_S01_AXI_WUSER_WIDTH_C-1 downto 0) := (others => '0');
    signal s01_axi_wvalid_s  : std_logic := '0';
    signal s01_axi_wready_s  : std_logic;

    signal s01_axi_bid_s    : std_logic_vector(C_S01_AXI_ID_WIDTH_C-1 downto 0);
    signal s01_axi_bresp_s  : std_logic_vector(1 downto 0);
    signal s01_axi_buser_s  : std_logic_vector(C_S01_AXI_BUSER_WIDTH_C-1 downto 0);
    signal s01_axi_bvalid_s : std_logic;
    signal s01_axi_bready_s : std_logic := '0';

    signal s01_axi_arid_s     : std_logic_vector(C_S01_AXI_ID_WIDTH_C-1 downto 0) := (others => '0');
    signal s01_axi_araddr_s   : std_logic_vector(C_S01_AXI_ADDR_WIDTH_C-1 downto 0) := (others => '0');
    signal s01_axi_arlen_s    : std_logic_vector(7 downto 0) := (others => '0');
    signal s01_axi_arsize_s   : std_logic_vector(2 downto 0) := (others => '0');
    signal s01_axi_arburst_s  : std_logic_vector(1 downto 0) := (others => '0');
    signal s01_axi_arlock_s   : std_logic := '0';
    signal s01_axi_arcache_s  : std_logic_vector(3 downto 0) := (others => '0');
    signal s01_axi_arprot_s   : std_logic_vector(2 downto 0) := (others => '0');
    signal s01_axi_arqos_s    : std_logic_vector(3 downto 0) := (others => '0');
    signal s01_axi_arregion_s : std_logic_vector(3 downto 0) := (others => '0');
    signal s01_axi_aruser_s   : std_logic_vector(C_S01_AXI_ARUSER_WIDTH_C-1 downto 0) := (others => '0');
    signal s01_axi_arvalid_s  : std_logic := '0';
    signal s01_axi_arready_s  : std_logic;

    signal s01_axi_rid_s    : std_logic_vector(C_S01_AXI_ID_WIDTH_C-1 downto 0);
    signal s01_axi_rdata_s  : std_logic_vector(C_S01_AXI_DATA_WIDTH_C-1 downto 0);
    signal s01_axi_rresp_s  : std_logic_vector(1 downto 0);
    signal s01_axi_rlast_s  : std_logic;
    signal s01_axi_ruser_s  : std_logic_vector(C_S01_AXI_RUSER_WIDTH_C-1 downto 0);
    signal s01_axi_rvalid_s : std_logic;
    signal s01_axi_rready_s : std_logic := '0';

    --------------------------------------------------------------------
    -- Image arrays, packed 4 pixels per 32-bit word
    --------------------------------------------------------------------
    type image_word_array_t is array (0 to WORD_COUNT_C-1) of std_logic_vector(31 downto 0);

    signal input_image_32b_s   : image_word_array_t := (others => (others => '0'));
    signal expected_edge_32b_s : image_word_array_t := (others => (others => '0'));

    signal images_loaded_s : std_logic := '0';

begin

    --------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------
    clk_gen : process
    begin
        clk_s <= '0', '1' after 10 ns;
        wait for 20 ns;
    end process;

    s00_axi_aclk_s <= clk_s;
    s01_axi_aclk_s <= clk_s;

    --------------------------------------------------------------------
    -- Load decimal pixel files and pack 4 pixels into one 32-bit word
    --------------------------------------------------------------------
    load_images : process
        variable gray_line : line;
        variable edge_line : line;
        variable gray_val  : integer;
        variable edge_val  : integer;
        variable word_v    : std_logic_vector(31 downto 0);
    begin
        report "Loading grayscale_full.txt and final_edge_full.txt...";

        for i in 0 to WORD_COUNT_C-1 loop
            word_v := (others => '0');

            for j in 0 to 3 loop
                readline(grayscale_file, gray_line);
                read(gray_line, gray_val);
                word_v(j*8 + 7 downto j*8) := std_logic_vector(to_unsigned(gray_val, 8));
            end loop;

            input_image_32b_s(i) <= word_v;
        end loop;

        for i in 0 to WORD_COUNT_C-1 loop
            word_v := (others => '0');

            for j in 0 to 3 loop
                readline(expected_edge_file, edge_line);
                read(edge_line, edge_val);
                word_v(j*8 + 7 downto j*8) := std_logic_vector(to_unsigned(edge_val, 8));
            end loop;

            expected_edge_32b_s(i) <= word_v;
        end loop;

        images_loaded_s <= '1';
        report "Image loading finished.";
        wait;
    end process;

    --------------------------------------------------------------------
    -- Main stimulus
    --------------------------------------------------------------------
    stimulus_generator : process
        variable read_data_v      : std_logic_vector(31 downto 0);
        variable edge_word_v      : std_logic_vector(31 downto 0);
        variable input_word_v     : std_logic_vector(31 downto 0);

        variable mismatch_count_v : integer := 0;
        variable match_count_v    : integer := 0;
        variable valid_count_v    : integer := 0;
        variable timeout_count_v  : integer := 0;

        variable input_mismatch_count_v : integer := 0;
        variable input_match_count_v    : integer := 0;

        variable transfer_size_v  : integer;
        variable burst_count_v    : integer;
        variable remaining_v      : integer;
        variable data_index_v     : integer;

        variable pix_addr_v       : integer := 0;
        variable row_v            : integer := 0;
        variable col_v            : integer := 0;
        variable got_pix_v        : std_logic_vector(7 downto 0);
        variable exp_pix_v        : std_logic_vector(7 downto 0);

    begin
        report "Start Canny AXI TB.";

        ----------------------------------------------------------------
        -- Wait until files are loaded
        ----------------------------------------------------------------
        wait until images_loaded_s = '1';
        wait for 100 ns;

        ----------------------------------------------------------------
        -- Reset AXI-Lite and AXI-Full
        ----------------------------------------------------------------
        report "Resetting DUT...";

        s00_axi_aresetn_s <= '0';
        s01_axi_aresetn_s <= '0';

        for i in 1 to 5 loop
            wait until falling_edge(clk_s);
        end loop;

        s00_axi_aresetn_s <= '1';
        s01_axi_aresetn_s <= '1';

        for i in 1 to 5 loop
            wait until falling_edge(clk_s);
        end loop;

        ----------------------------------------------------------------
        -- AXI-Lite: rows
        ----------------------------------------------------------------
        report "Writing AXI-Lite configuration registers...";

        wait until falling_edge(clk_s);
        s00_axi_awaddr_s  <= std_logic_vector(to_unsigned(ROWS_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_C));
        s00_axi_awvalid_s <= '1';
        s00_axi_wdata_s   <= std_logic_vector(to_unsigned(IMG_ROWS_C, C_S00_AXI_DATA_WIDTH_C));
        s00_axi_wvalid_s  <= '1';
        s00_axi_wstrb_s   <= "1111";
        s00_axi_bready_s  <= '1';

        wait until s00_axi_awready_s = '1';
        wait until s00_axi_awready_s = '0';
        wait until falling_edge(clk_s);

        s00_axi_awaddr_s  <= (others => '0');
        s00_axi_awvalid_s <= '0';
        s00_axi_wdata_s   <= (others => '0');
        s00_axi_wvalid_s  <= '0';
        s00_axi_wstrb_s   <= "0000";

        if s00_axi_bvalid_s = '1' then
            wait until s00_axi_bvalid_s = '0';
        else
            wait until s00_axi_bvalid_s = '1';
            wait until s00_axi_bvalid_s = '0';
        end if;

        wait until falling_edge(clk_s);
        s00_axi_bready_s <= '0';

        for i in 1 to 5 loop
            wait until falling_edge(clk_s);
        end loop;

        ----------------------------------------------------------------
        -- AXI-Lite: cols
        ----------------------------------------------------------------
        wait until falling_edge(clk_s);
        s00_axi_awaddr_s  <= std_logic_vector(to_unsigned(COLS_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_C));
        s00_axi_awvalid_s <= '1';
        s00_axi_wdata_s   <= std_logic_vector(to_unsigned(IMG_COLS_C, C_S00_AXI_DATA_WIDTH_C));
        s00_axi_wvalid_s  <= '1';
        s00_axi_wstrb_s   <= "1111";
        s00_axi_bready_s  <= '1';

        wait until s00_axi_awready_s = '1';
        wait until s00_axi_awready_s = '0';
        wait until falling_edge(clk_s);

        s00_axi_awaddr_s  <= (others => '0');
        s00_axi_awvalid_s <= '0';
        s00_axi_wdata_s   <= (others => '0');
        s00_axi_wvalid_s  <= '0';
        s00_axi_wstrb_s   <= "0000";

        if s00_axi_bvalid_s = '1' then
            wait until s00_axi_bvalid_s = '0';
        else
            wait until s00_axi_bvalid_s = '1';
            wait until s00_axi_bvalid_s = '0';
        end if;

        wait until falling_edge(clk_s);
        s00_axi_bready_s <= '0';

        for i in 1 to 5 loop
            wait until falling_edge(clk_s);
        end loop;

        ----------------------------------------------------------------
        -- AXI-Lite: low threshold
        ----------------------------------------------------------------
        wait until falling_edge(clk_s);
        s00_axi_awaddr_s  <= std_logic_vector(to_unsigned(LOW_THRESHOLD_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_C));
        s00_axi_awvalid_s <= '1';
        s00_axi_wdata_s   <= std_logic_vector(to_unsigned(LOW_THRESHOLD_C, C_S00_AXI_DATA_WIDTH_C));
        s00_axi_wvalid_s  <= '1';
        s00_axi_wstrb_s   <= "1111";
        s00_axi_bready_s  <= '1';

        wait until s00_axi_awready_s = '1';
        wait until s00_axi_awready_s = '0';
        wait until falling_edge(clk_s);

        s00_axi_awaddr_s  <= (others => '0');
        s00_axi_awvalid_s <= '0';
        s00_axi_wdata_s   <= (others => '0');
        s00_axi_wvalid_s  <= '0';
        s00_axi_wstrb_s   <= "0000";

        if s00_axi_bvalid_s = '1' then
            wait until s00_axi_bvalid_s = '0';
        else
            wait until s00_axi_bvalid_s = '1';
            wait until s00_axi_bvalid_s = '0';
        end if;

        wait until falling_edge(clk_s);
        s00_axi_bready_s <= '0';

        for i in 1 to 5 loop
            wait until falling_edge(clk_s);
        end loop;

        ----------------------------------------------------------------
        -- AXI-Lite: high threshold
        ----------------------------------------------------------------
        wait until falling_edge(clk_s);
        s00_axi_awaddr_s  <= std_logic_vector(to_unsigned(HIGH_THRESHOLD_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_C));
        s00_axi_awvalid_s <= '1';
        s00_axi_wdata_s   <= std_logic_vector(to_unsigned(HIGH_THRESHOLD_C, C_S00_AXI_DATA_WIDTH_C));
        s00_axi_wvalid_s  <= '1';
        s00_axi_wstrb_s   <= "1111";
        s00_axi_bready_s  <= '1';

        wait until s00_axi_awready_s = '1';
        wait until s00_axi_awready_s = '0';
        wait until falling_edge(clk_s);

        s00_axi_awaddr_s  <= (others => '0');
        s00_axi_awvalid_s <= '0';
        s00_axi_wdata_s   <= (others => '0');
        s00_axi_wvalid_s  <= '0';
        s00_axi_wstrb_s   <= "0000";

        if s00_axi_bvalid_s = '1' then
            wait until s00_axi_bvalid_s = '0';
        else
            wait until s00_axi_bvalid_s = '1';
            wait until s00_axi_bvalid_s = '0';
        end if;

        wait until falling_edge(clk_s);
        s00_axi_bready_s <= '0';

        for i in 1 to 5 loop
            wait until falling_edge(clk_s);
        end loop;

        ----------------------------------------------------------------
        -- AXI-Full: write grayscale image to input memory
        ----------------------------------------------------------------
        report "Writing grayscale image to AXI-Full input memory...";

        transfer_size_v := WORD_COUNT_C;
        burst_count_v   := transfer_size_v / BURST_LEN_C;
        remaining_v     := transfer_size_v mod BURST_LEN_C;
        data_index_v     := 0;

        wait until falling_edge(clk_s);

        for burst_index in 0 to burst_count_v - 1 loop

            s01_axi_awaddr_s  <= std_logic_vector(to_unsigned(INPUT_IMAGE_BASE_ADDR_C + burst_index * BURST_LEN_C * 4, C_S01_AXI_ADDR_WIDTH_C));
            wait until falling_edge(clk_s);

            s01_axi_awlen_s   <= std_logic_vector(to_unsigned(BURST_LEN_C - 1, 8));
            s01_axi_awsize_s  <= "010";
            s01_axi_awburst_s <= "01";
            s01_axi_awvalid_s <= '1';

            wait until s01_axi_awready_s = '1';
            wait until falling_edge(clk_s);
            s01_axi_awvalid_s <= '0';
            wait until s01_axi_awready_s = '0';
            wait until falling_edge(clk_s);

            for i in 0 to BURST_LEN_C - 1 loop
                s01_axi_wdata_s  <= input_image_32b_s(data_index_v);
                s01_axi_wvalid_s <= '1';
                s01_axi_wstrb_s  <= "1111";
                s01_axi_bready_s <= '1';

                if i = BURST_LEN_C - 1 then
                    s01_axi_wlast_s <= '1';
                else
                    s01_axi_wlast_s <= '0';
                end if;

                wait until falling_edge(clk_s);

                s01_axi_wvalid_s <= '0';
                s01_axi_wlast_s  <= '0';

                data_index_v := data_index_v + 1;
            end loop;

            if s01_axi_bvalid_s = '1' then
                wait until s01_axi_bvalid_s = '0';
            else
                wait until s01_axi_bvalid_s = '1';
                wait until s01_axi_bvalid_s = '0';
            end if;

            wait until falling_edge(clk_s);
            s01_axi_bready_s <= '0';

        end loop;

        if remaining_v > 0 then

            s01_axi_awaddr_s <= std_logic_vector(to_unsigned(INPUT_IMAGE_BASE_ADDR_C + burst_count_v * BURST_LEN_C * 4, C_S01_AXI_ADDR_WIDTH_C));
            wait until falling_edge(clk_s);

            s01_axi_awlen_s   <= std_logic_vector(to_unsigned(remaining_v - 1, 8));
            s01_axi_awsize_s  <= "010";
            s01_axi_awburst_s <= "01";
            s01_axi_awvalid_s <= '1';

            wait until s01_axi_awready_s = '1';
            wait until falling_edge(clk_s);
            s01_axi_awvalid_s <= '0';
            wait until s01_axi_awready_s = '0';
            wait until falling_edge(clk_s);

            for i in 0 to remaining_v - 1 loop
                s01_axi_wdata_s  <= input_image_32b_s(data_index_v);
                s01_axi_wvalid_s <= '1';
                s01_axi_wstrb_s  <= "1111";
                s01_axi_bready_s <= '1';

                if i = remaining_v - 1 then
                    s01_axi_wlast_s <= '1';
                else
                    s01_axi_wlast_s <= '0';
                end if;

                wait until falling_edge(clk_s);

                s01_axi_wvalid_s <= '0';
                s01_axi_wlast_s  <= '0';

                data_index_v := data_index_v + 1;
            end loop;

            if s01_axi_bvalid_s = '1' then
                wait until s01_axi_bvalid_s = '0';
            else
                wait until s01_axi_bvalid_s = '1';
                wait until s01_axi_bvalid_s = '0';
            end if;

            wait until falling_edge(clk_s);
            s01_axi_bready_s <= '0';

        end if;

        wait until falling_edge(clk_s);

        s01_axi_wdata_s   <= (others => '0');
        s01_axi_wvalid_s  <= '0';
        s01_axi_wstrb_s   <= "0000";
        s01_axi_wlast_s   <= '0';
        s01_axi_awaddr_s  <= (others => '0');
        s01_axi_awlen_s   <= (others => '0');
        s01_axi_awburst_s <= "00";
        s01_axi_awvalid_s <= '0';
        s01_axi_bready_s  <= '0';

        report "Input image write finished.";

        for i in 1 to 10 loop
            wait until falling_edge(clk_s);
        end loop;

        ----------------------------------------------------------------
        -- AXI-Full input readback check before starting Canny
        ----------------------------------------------------------------
        --report "Reading back INPUT image from AXI-Full memory...";

        --input_mismatch_count_v := 0;
        --input_match_count_v    := 0;

        --for word_index in 0 to WORD_COUNT_C - 1 loop

            --wait until falling_edge(clk_s);

            --s01_axi_araddr_s  <= std_logic_vector(to_unsigned(INPUT_IMAGE_BASE_ADDR_C + word_index * 4, C_S01_AXI_ADDR_WIDTH_C));
            --s01_axi_arlen_s   <= std_logic_vector(to_unsigned(0, 8));
            --s01_axi_arsize_s  <= "010";
            --s01_axi_arburst_s <= "01";
            --s01_axi_arvalid_s <= '1';
            --s01_axi_rready_s  <= '1';

            --wait until s01_axi_arready_s = '1';
            --wait until falling_edge(clk_s);
            --s01_axi_arvalid_s <= '0';
            --wait until s01_axi_arready_s = '0';

            --if s01_axi_rvalid_s = '0' then
                --wait until s01_axi_rvalid_s = '1';
            --end if;

            --wait for 1 ns;
            --input_word_v := s01_axi_rdata_s;

            --wait until falling_edge(clk_s);
            --s01_axi_rready_s <= '0';

            --if input_word_v = input_image_32b_s(word_index) then
                --input_match_count_v := input_match_count_v + 4;
            --else
                --input_mismatch_count_v := input_mismatch_count_v + 4;

                --if input_mismatch_count_v <= 40 then
                    --report "INPUT READBACK MISMATCH word=" & integer'image(word_index) &
                           --" got_b0=" & integer'image(to_integer(unsigned(input_word_v(7 downto 0)))) &
                           --" exp_b0=" & integer'image(to_integer(unsigned(input_image_32b_s(word_index)(7 downto 0)))) &
                           --" got_b1=" & integer'image(to_integer(unsigned(input_word_v(15 downto 8)))) &
                           --" exp_b1=" & integer'image(to_integer(unsigned(input_image_32b_s(word_index)(15 downto 8)))) &
                           --" got_b2=" & integer'image(to_integer(unsigned(input_word_v(23 downto 16)))) &
                           --" exp_b2=" & integer'image(to_integer(unsigned(input_image_32b_s(word_index)(23 downto 16)))) &
                           --" got_b3=" & integer'image(to_integer(unsigned(input_word_v(31 downto 24)))) &
                           --" exp_b3=" & integer'image(to_integer(unsigned(input_image_32b_s(word_index)(31 downto 24))));
               --end if;
            --end if;

        --end loop;

        --report "INPUT READBACK CHECK FINISHED";
        --report "INPUT MATCHED PIXELS    = " & integer'image(input_match_count_v);
        --report "INPUT MISMATCHED PIXELS = " & integer'image(input_mismatch_count_v);

        --if input_mismatch_count_v /= 0 then
            --assert false report "TEST FAILED: AXI-Full input readback has mismatches." severity failure;
        --else
            --report "INPUT READBACK PASSED: grayscale image is correctly written through AXI-Full.";
        --end if;

        --for i in 1 to 10 loop
            --wait until falling_edge(clk_s);
        --end loop;

        ----------------------------------------------------------------
        -- AXI-Lite: start = 1
        ----------------------------------------------------------------
        report "Starting Canny IP...";

        wait until falling_edge(clk_s);
        s00_axi_awaddr_s  <= std_logic_vector(to_unsigned(START_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_C));
        s00_axi_awvalid_s <= '1';
        s00_axi_wdata_s   <= std_logic_vector(to_unsigned(1, C_S00_AXI_DATA_WIDTH_C));
        s00_axi_wvalid_s  <= '1';
        s00_axi_wstrb_s   <= "1111";
        s00_axi_bready_s  <= '1';

        wait until s00_axi_awready_s = '1';
        wait until s00_axi_awready_s = '0';
        wait until falling_edge(clk_s);

        s00_axi_awaddr_s  <= (others => '0');
        s00_axi_awvalid_s <= '0';
        s00_axi_wdata_s   <= (others => '0');
        s00_axi_wvalid_s  <= '0';
        s00_axi_wstrb_s   <= "0000";

        if s00_axi_bvalid_s = '1' then
            wait until s00_axi_bvalid_s = '0';
        else
            wait until s00_axi_bvalid_s = '1';
            wait until s00_axi_bvalid_s = '0';
        end if;

        wait until falling_edge(clk_s);
        s00_axi_bready_s <= '0';

        for i in 1 to 5 loop
            wait until falling_edge(clk_s);
        end loop;

        ----------------------------------------------------------------
        -- AXI-Lite: start = 0
        ----------------------------------------------------------------
        wait until falling_edge(clk_s);
        s00_axi_awaddr_s  <= std_logic_vector(to_unsigned(START_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_C));
        s00_axi_awvalid_s <= '1';
        s00_axi_wdata_s   <= std_logic_vector(to_unsigned(0, C_S00_AXI_DATA_WIDTH_C));
        s00_axi_wvalid_s  <= '1';
        s00_axi_wstrb_s   <= "1111";
        s00_axi_bready_s  <= '1';

        wait until s00_axi_awready_s = '1';
        wait until s00_axi_awready_s = '0';
        wait until falling_edge(clk_s);

        s00_axi_awaddr_s  <= (others => '0');
        s00_axi_awvalid_s <= '0';
        s00_axi_wdata_s   <= (others => '0');
        s00_axi_wvalid_s  <= '0';
        s00_axi_wstrb_s   <= "0000";

        if s00_axi_bvalid_s = '1' then
            wait until s00_axi_bvalid_s = '0';
        else
            wait until s00_axi_bvalid_s = '1';
            wait until s00_axi_bvalid_s = '0';
        end if;

        wait until falling_edge(clk_s);
        s00_axi_bready_s <= '0';

        ----------------------------------------------------------------
        -- Poll ready register
        ----------------------------------------------------------------
        report "Waiting for Canny IP ready...";

        timeout_count_v := 0;

        loop
            wait until falling_edge(clk_s);

            s00_axi_araddr_s  <= std_logic_vector(to_unsigned(READY_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_C));
            s00_axi_arvalid_s <= '1';
            s00_axi_rready_s  <= '1';

            wait until s00_axi_arready_s = '1';
            wait until s00_axi_arready_s = '0';
            wait until falling_edge(clk_s);

            if s00_axi_rvalid_s = '0' then
                wait until s00_axi_rvalid_s = '1';
            end if;

            wait for 1 ns;
            read_data_v := s00_axi_rdata_s;

            s00_axi_araddr_s  <= (others => '0');
            s00_axi_arvalid_s <= '0';
            s00_axi_rready_s  <= '0';

            if read_data_v(0) = '1' then
                report "Canny IP finished.";
                exit;
            end if;

            timeout_count_v := timeout_count_v + 1;

            if timeout_count_v = 2000000 then
                assert false report "Timeout: ready did not become 1." severity failure;
            end if;

            wait for 1000 ns;
        end loop;

        ----------------------------------------------------------------
        -- Read EDGE output and compare only valid Canny zone
        ----------------------------------------------------------------
        report "Reading EDGE output and comparing VALID ZONE with final_edge_full.txt...";

        mismatch_count_v := 0;
        match_count_v    := 0;
        valid_count_v    := 0;

        for word_index in 0 to WORD_COUNT_C - 1 loop

            wait until falling_edge(clk_s);

            s01_axi_araddr_s  <= std_logic_vector(to_unsigned(EDGE_IMAGE_BASE_ADDR_C + word_index * 4, C_S01_AXI_ADDR_WIDTH_C));
            s01_axi_arlen_s   <= std_logic_vector(to_unsigned(0, 8));
            s01_axi_arsize_s  <= "010";
            s01_axi_arburst_s <= "01";
            s01_axi_arvalid_s <= '1';
            s01_axi_rready_s  <= '1';

            wait until s01_axi_arready_s = '1';
            wait until falling_edge(clk_s);
            s01_axi_arvalid_s <= '0';
            wait until s01_axi_arready_s = '0';

            if s01_axi_rvalid_s = '0' then
                wait until s01_axi_rvalid_s = '1';
            end if;

            wait for 1 ns;
            edge_word_v := s01_axi_rdata_s;

            wait until falling_edge(clk_s);
            s01_axi_rready_s <= '0';

            for byte_index in 0 to 3 loop

                pix_addr_v := word_index * 4 + byte_index;
                row_v      := pix_addr_v / IMG_COLS_C;
                col_v      := pix_addr_v mod IMG_COLS_C;

                --if (row_v >= 4) and (row_v <= IMG_ROWS_C - 5) and
                   --(col_v >= 4) and (col_v <= IMG_COLS_C - 5) then
                if (row_v >= 5) and (row_v <= IMG_ROWS_C - 6) and
                   (col_v >= 5) and (col_v <= IMG_COLS_C - 6) then   

                    valid_count_v := valid_count_v + 1;

                    got_pix_v := edge_word_v(byte_index*8 + 7 downto byte_index*8);
                    exp_pix_v := expected_edge_32b_s(word_index)(byte_index*8 + 7 downto byte_index*8);

                    if got_pix_v = exp_pix_v then
                        match_count_v := match_count_v + 1;
                    else
                        mismatch_count_v := mismatch_count_v + 1;

                        if mismatch_count_v <= 40 then
                            report "MISMATCH pixel row=" & integer'image(row_v) &
                                   " col=" & integer'image(col_v) &
                                   " got=" & integer'image(to_integer(unsigned(got_pix_v))) &
                                   " expected=" & integer'image(to_integer(unsigned(exp_pix_v)));
                        end if;
                    end if;

                end if;

            end loop;

        end loop;

        report "VALID ZONE EDGE CHECK FINISHED";
        report "VALID PIXELS COUNTED  = " & integer'image(valid_count_v);
        report "VALID PIXELS EXPECTED = " & integer'image((IMG_ROWS_C - 10) * (IMG_COLS_C - 10));
        report "MATCHED PIXELS        = " & integer'image(match_count_v);
        report "MISMATCHED PIXELS     = " & integer'image(mismatch_count_v);

        if mismatch_count_v = 0 then
            report "TEST PASSED: VALID ZONE edge output matches expected image.";
        else
            assert false report "TEST FAILED: VALID ZONE edge output has mismatches." severity failure;
        end if;

        wait;
    end process;

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    canny_axi_dut : entity work.axi_full_image_v1_0
        generic map (
            IMG_WIDTH  => IMG_COLS_C,
            IMG_HEIGHT => IMG_ROWS_C,
            BRAM_SIZE  => 196608,
            ADDR_WIDTH => 18,

            C_S00_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH_C,
            C_S00_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH_C,

            C_S01_AXI_ID_WIDTH     => C_S01_AXI_ID_WIDTH_C,
            C_S01_AXI_DATA_WIDTH   => C_S01_AXI_DATA_WIDTH_C,
            C_S01_AXI_ADDR_WIDTH   => C_S01_AXI_ADDR_WIDTH_C,
            C_S01_AXI_AWUSER_WIDTH => C_S01_AXI_AWUSER_WIDTH_C,
            C_S01_AXI_ARUSER_WIDTH => C_S01_AXI_ARUSER_WIDTH_C,
            C_S01_AXI_WUSER_WIDTH  => C_S01_AXI_WUSER_WIDTH_C,
            C_S01_AXI_RUSER_WIDTH  => C_S01_AXI_RUSER_WIDTH_C,
            C_S01_AXI_BUSER_WIDTH  => C_S01_AXI_BUSER_WIDTH_C
        )
        port map (
            ----------------------------------------------------------------
            -- AXI-Lite
            ----------------------------------------------------------------
            s00_axi_aclk    => s00_axi_aclk_s,
            s00_axi_aresetn => s00_axi_aresetn_s,
            s00_axi_awaddr  => s00_axi_awaddr_s,
            s00_axi_awprot  => s00_axi_awprot_s,
            s00_axi_awvalid => s00_axi_awvalid_s,
            s00_axi_awready => s00_axi_awready_s,
            s00_axi_wdata   => s00_axi_wdata_s,
            s00_axi_wstrb   => s00_axi_wstrb_s,
            s00_axi_wvalid  => s00_axi_wvalid_s,
            s00_axi_wready  => s00_axi_wready_s,
            s00_axi_bresp   => s00_axi_bresp_s,
            s00_axi_bvalid  => s00_axi_bvalid_s,
            s00_axi_bready  => s00_axi_bready_s,
            s00_axi_araddr  => s00_axi_araddr_s,
            s00_axi_arprot  => s00_axi_arprot_s,
            s00_axi_arvalid => s00_axi_arvalid_s,
            s00_axi_arready => s00_axi_arready_s,
            s00_axi_rdata   => s00_axi_rdata_s,
            s00_axi_rresp   => s00_axi_rresp_s,
            s00_axi_rvalid  => s00_axi_rvalid_s,
            s00_axi_rready  => s00_axi_rready_s,

            ----------------------------------------------------------------
            -- AXI-Full
            ----------------------------------------------------------------
            s01_axi_aclk     => s01_axi_aclk_s,
            s01_axi_aresetn  => s01_axi_aresetn_s,
            s01_axi_awid     => s01_axi_awid_s,
            s01_axi_awaddr   => s01_axi_awaddr_s,
            s01_axi_awlen    => s01_axi_awlen_s,
            s01_axi_awsize   => s01_axi_awsize_s,
            s01_axi_awburst  => s01_axi_awburst_s,
            s01_axi_awlock   => s01_axi_awlock_s,
            s01_axi_awcache  => s01_axi_awcache_s,
            s01_axi_awprot   => s01_axi_awprot_s,
            s01_axi_awqos    => s01_axi_awqos_s,
            s01_axi_awregion => s01_axi_awregion_s,
            s01_axi_awuser   => s01_axi_awuser_s,
            s01_axi_awvalid  => s01_axi_awvalid_s,
            s01_axi_awready  => s01_axi_awready_s,
            s01_axi_wdata    => s01_axi_wdata_s,
            s01_axi_wstrb    => s01_axi_wstrb_s,
            s01_axi_wlast    => s01_axi_wlast_s,
            s01_axi_wuser    => s01_axi_wuser_s,
            s01_axi_wvalid   => s01_axi_wvalid_s,
            s01_axi_wready   => s01_axi_wready_s,
            s01_axi_bid      => s01_axi_bid_s,
            s01_axi_bresp    => s01_axi_bresp_s,
            s01_axi_buser    => s01_axi_buser_s,
            s01_axi_bvalid   => s01_axi_bvalid_s,
            s01_axi_bready   => s01_axi_bready_s,
            s01_axi_arid     => s01_axi_arid_s,
            s01_axi_araddr   => s01_axi_araddr_s,
            s01_axi_arlen    => s01_axi_arlen_s,
            s01_axi_arsize   => s01_axi_arsize_s,
            s01_axi_arburst  => s01_axi_arburst_s,
            s01_axi_arlock   => s01_axi_arlock_s,
            s01_axi_arcache  => s01_axi_arcache_s,
            s01_axi_arprot   => s01_axi_arprot_s,
            s01_axi_arqos    => s01_axi_arqos_s,
            s01_axi_arregion => s01_axi_arregion_s,
            s01_axi_aruser   => s01_axi_aruser_s,
            s01_axi_arvalid  => s01_axi_arvalid_s,
            s01_axi_arready  => s01_axi_arready_s,
            s01_axi_rid      => s01_axi_rid_s,
            s01_axi_rdata    => s01_axi_rdata_s,
            s01_axi_rresp    => s01_axi_rresp_s,
            s01_axi_rlast    => s01_axi_rlast_s,
            s01_axi_ruser    => s01_axi_ruser_s,
            s01_axi_rvalid   => s01_axi_rvalid_s,
            s01_axi_rready   => s01_axi_rready_s
        );

end architecture;