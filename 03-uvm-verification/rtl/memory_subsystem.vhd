library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mem_subsystem is 
    generic (
        BRAM_SIZE  : integer := 196608;
        ADDR_WIDTH : integer := 18
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;

        ----------------------------------------------------------------
        -- AXI-Lite register interface
        ----------------------------------------------------------------
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

        ----------------------------------------------------------------
        -- AXI-Full memory interface
        -- mem_addr_i is word address, because S01_AXI removed bits [1:0]
        -- input image region: mem_addr_i(16) = '0'
        -- edge output region: mem_addr_i(16) = '1'
        ----------------------------------------------------------------
        mem_addr_i      : in  std_logic_vector(16 downto 0);
        mem_data_i      : in  std_logic_vector(31 downto 0);
        mem_wr_i        : in  std_logic;
        mem_read_data_o : out std_logic_vector(31 downto 0);

        ----------------------------------------------------------------
        -- Canny IP memory interface
        ----------------------------------------------------------------
        input_ena_i   : in  std_logic;
        input_wea_i   : in  std_logic;
        input_addra_i : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        input_dia_i   : in  std_logic_vector(7 downto 0);
        input_doa_o   : out std_logic_vector(7 downto 0);

        gauss_ena_i   : in  std_logic;
        gauss_wea_i   : in  std_logic;
        gauss_addra_i : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        gauss_dia_i   : in  std_logic_vector(7 downto 0);
        gauss_doa_o   : out std_logic_vector(7 downto 0);

        mag_ena_i   : in  std_logic;
        mag_wea_i   : in  std_logic;
        mag_addra_i : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        mag_dia_i   : in  std_logic_vector(15 downto 0);
        mag_doa_o   : out std_logic_vector(15 downto 0);

        dir_ena_i   : in  std_logic;
        dir_wea_i   : in  std_logic;
        dir_addra_i : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        dir_dia_i   : in  std_logic_vector(7 downto 0);
        dir_doa_o   : out std_logic_vector(7 downto 0);

        nms_ena_i   : in  std_logic;
        nms_wea_i   : in  std_logic;
        nms_addra_i : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        nms_dia_i   : in  std_logic_vector(15 downto 0);
        nms_doa_o   : out std_logic_vector(15 downto 0);

        thresh_ena_i   : in  std_logic;
        thresh_wea_i   : in  std_logic;
        thresh_addra_i : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        thresh_dia_i   : in  std_logic_vector(7 downto 0);
        thresh_doa_o   : out std_logic_vector(7 downto 0);

        edge_ena_i   : in  std_logic;
        edge_wea_i   : in  std_logic;
        edge_addra_i : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        edge_dia_i   : in  std_logic_vector(7 downto 0);
        edge_doa_o   : out std_logic_vector(7 downto 0)
    );
end mem_subsystem;

architecture struct of mem_subsystem is

    --------------------------------------------------------------------
    -- AXI-Lite registers
    --------------------------------------------------------------------
    signal rows_s           : std_logic_vector(8 downto 0) := (others => '0');
    signal cols_s           : std_logic_vector(9 downto 0) := (others => '0');
    signal low_threshold_s  : std_logic_vector(7 downto 0) := (others => '0');
    signal high_threshold_s : std_logic_vector(7 downto 0) := (others => '0');
    signal start_s          : std_logic := '0';
    signal ready_s          : std_logic := '0';

    --------------------------------------------------------------------
    -- AXI-Full address decode
    --------------------------------------------------------------------
    signal input_axi_en_s : std_logic;
    signal edge_axi_en_s  : std_logic;

    --------------------------------------------------------------------
    -- Helper signals for BRAM port maps
    --------------------------------------------------------------------
    signal input_axi_addr_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal input_ip_addr_s  : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal input_axi_we_s   : std_logic;

    signal edge_axi_addr_s  : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal edge_ip_addr_s   : std_logic_vector(ADDR_WIDTH-1 downto 0);

    --------------------------------------------------------------------
    -- INPUT image BRAM is 32-bit wide for AXI-Full packed writes.
    -- Canny IP reads one 8-bit pixel selected by input_addra_i(1 downto 0).
    --------------------------------------------------------------------
    signal input_axi_word_dout_s : std_logic_vector(31 downto 0);
    signal input_ip_word_dout_s  : std_logic_vector(31 downto 0);

    --------------------------------------------------------------------
    -- EDGE output is stored as four 8-bit lane BRAMs.
    -- Canny IP writes one byte lane, AXI-Full reads packed 32-bit word.
    --------------------------------------------------------------------
    signal edge_axi_byte0_s : std_logic_vector(7 downto 0);
    signal edge_axi_byte1_s : std_logic_vector(7 downto 0);
    signal edge_axi_byte2_s : std_logic_vector(7 downto 0);
    signal edge_axi_byte3_s : std_logic_vector(7 downto 0);

    signal edge_ip_byte0_s : std_logic_vector(7 downto 0);
    signal edge_ip_byte1_s : std_logic_vector(7 downto 0);
    signal edge_ip_byte2_s : std_logic_vector(7 downto 0);
    signal edge_ip_byte3_s : std_logic_vector(7 downto 0);

    signal edge_we_lane0_s : std_logic;
    signal edge_we_lane1_s : std_logic;
    signal edge_we_lane2_s : std_logic;
    signal edge_we_lane3_s : std_logic;

begin

    --------------------------------------------------------------------
    -- Register outputs
    --------------------------------------------------------------------
    reg_rows_o           <= rows_s;
    reg_cols_o           <= cols_s;
    reg_low_threshold_o  <= low_threshold_s;
    reg_high_threshold_o <= high_threshold_s;
    reg_start_o          <= start_s;
    ready_o              <= ready_s;

    --------------------------------------------------------------------
    -- AXI-Full memory map
    --
    -- AXI byte address 0x00000 - 0x3FFFF:
    --   mem_addr_i(16) = '0' -> input image, packed 4 pixels per word
    --
    -- AXI byte address 0x40000 - 0x7FFFF:
    --   mem_addr_i(16) = '1' -> edge output, packed 4 pixels per word
    --------------------------------------------------------------------
    input_axi_en_s <= '1' when mem_addr_i(16) = '0' else '0';
    edge_axi_en_s  <= '1' when mem_addr_i(16) = '1' else '0';

    --------------------------------------------------------------------
    -- Helper assignments for BRAM port maps
    --------------------------------------------------------------------
    --input_axi_addr_s <= "000" & mem_addr_i(15 downto 0);
    --input_ip_addr_s  <= "00"  & input_addra_i(ADDR_WIDTH-1 downto 2);
    --input_axi_we_s   <= mem_wr_i when input_axi_en_s = '1' else '0';

    --edge_axi_addr_s <= "000" & mem_addr_i(15 downto 0);
    --edge_ip_addr_s  <= "00"  & edge_addra_i(ADDR_WIDTH-1 downto 2);
    
    input_axi_addr_s <= std_logic_vector(resize(unsigned(mem_addr_i(15 downto 0)), ADDR_WIDTH));
    input_ip_addr_s  <= std_logic_vector(resize(unsigned(input_addra_i(ADDR_WIDTH-1 downto 2)), ADDR_WIDTH));
    input_axi_we_s   <= mem_wr_i when input_axi_en_s = '1' else '0'; 
    edge_axi_addr_s <= std_logic_vector(resize(unsigned(mem_addr_i(15 downto 0)), ADDR_WIDTH));
    edge_ip_addr_s  <= std_logic_vector(resize(unsigned(edge_addra_i(ADDR_WIDTH-1 downto 2)), ADDR_WIDTH));

    --------------------------------------------------------------------
    -- AXI-Full read data mux
    --------------------------------------------------------------------
    mem_read_data_o <= edge_axi_byte3_s & edge_axi_byte2_s & edge_axi_byte1_s & edge_axi_byte0_s
                       when mem_addr_i(16) = '1' else
                       input_axi_word_dout_s;

    --------------------------------------------------------------------
    -- ROWS register
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rows_s <= (others => '0');
            elsif reg_rows_wr_i = '1' then
                rows_s <= reg_data_i(8 downto 0);
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- COLS register
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                cols_s <= (others => '0');
            elsif reg_cols_wr_i = '1' then
                cols_s <= reg_data_i(9 downto 0);
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- LOW THRESHOLD register
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                low_threshold_s <= (others => '0');
            elsif reg_low_threshold_wr_i = '1' then
                low_threshold_s <= reg_data_i(7 downto 0);
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- HIGH THRESHOLD register
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                high_threshold_s <= (others => '0');
            elsif reg_high_threshold_wr_i = '1' then
                high_threshold_s <= reg_data_i(7 downto 0);
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- START register
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                start_s <= '0';
            elsif reg_start_wr_i = '1' then
                start_s <= reg_data_i(0);
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- READY/status register
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                ready_s <= '0';
            else
                ready_s <= ready_i;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- INPUT BRAM
    -- Port A: AXI-Full write/read, 32-bit packed pixels
    -- Port B: Canny IP read, selected byte from 32-bit word
    --------------------------------------------------------------------
    input_bram : entity work.bram
        generic map (
            WIDTH     => 32,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => reset,
            resetb => reset,

            ena => input_axi_en_s,
            enb => input_ena_i,

            wea => input_axi_we_s,
            web => '0',

            addra => input_axi_addr_s,
            addrb => input_ip_addr_s,

            dia => mem_data_i,
            dib => (others => '0'),

            doa => input_axi_word_dout_s,
            dob => input_ip_word_dout_s
        );

    process(input_addra_i, input_ip_word_dout_s)
    begin
        case input_addra_i(1 downto 0) is
            when "00" =>
                input_doa_o <= input_ip_word_dout_s(7 downto 0);
            when "01" =>
                input_doa_o <= input_ip_word_dout_s(15 downto 8);
            when "10" =>
                input_doa_o <= input_ip_word_dout_s(23 downto 16);
            when others =>
                input_doa_o <= input_ip_word_dout_s(31 downto 24);
        end case;
    end process;

    --------------------------------------------------------------------
    -- GAUSS BRAM
    --------------------------------------------------------------------
    gauss_bram : entity work.bram
        generic map (
            WIDTH     => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => reset,
            resetb => reset,

            ena => gauss_ena_i,
            enb => '0',

            wea => gauss_wea_i,
            web => '0',

            addra => gauss_addra_i,
            addrb => (others => '0'),

            dia => gauss_dia_i,
            dib => (others => '0'),

            doa => gauss_doa_o,
            dob => open
        );

    --------------------------------------------------------------------
    -- MAG BRAM
    --------------------------------------------------------------------
    mag_bram : entity work.bram
        generic map (
            WIDTH     => 16,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => reset,
            resetb => reset,

            ena => mag_ena_i,
            enb => '0',

            wea => mag_wea_i,
            web => '0',

            addra => mag_addra_i,
            addrb => (others => '0'),

            dia => mag_dia_i,
            dib => (others => '0'),

            doa => mag_doa_o,
            dob => open
        );

    --------------------------------------------------------------------
    -- DIR BRAM
    --------------------------------------------------------------------
    dir_bram : entity work.bram
        generic map (
            WIDTH     => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => reset,
            resetb => reset,

            ena => dir_ena_i,
            enb => '0',

            wea => dir_wea_i,
            web => '0',

            addra => dir_addra_i,
            addrb => (others => '0'),

            dia => dir_dia_i,
            dib => (others => '0'),

            doa => dir_doa_o,
            dob => open
        );

    --------------------------------------------------------------------
    -- NMS BRAM
    --------------------------------------------------------------------
    nms_bram : entity work.bram
        generic map (
            WIDTH     => 16,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => reset,
            resetb => reset,

            ena => nms_ena_i,
            enb => '0',

            wea => nms_wea_i,
            web => '0',

            addra => nms_addra_i,
            addrb => (others => '0'),

            dia => nms_dia_i,
            dib => (others => '0'),

            doa => nms_doa_o,
            dob => open
        );

    --------------------------------------------------------------------
    -- THRESH BRAM
    --------------------------------------------------------------------
    thresh_bram : entity work.bram
        generic map (
            WIDTH     => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => reset,
            resetb => reset,

            ena => thresh_ena_i,
            enb => '0',

            wea => thresh_wea_i,
            web => '0',

            addra => thresh_addra_i,
            addrb => (others => '0'),

            dia => thresh_dia_i,
            dib => (others => '0'),

            doa => thresh_doa_o,
            dob => open
        );

    --------------------------------------------------------------------
    -- EDGE BRAM, lane 0
    -- Port A: AXI-Full read
    -- Port B: Canny IP read/write for pixels where edge_addra_i(1 downto 0)="00"
    --------------------------------------------------------------------
    edge_we_lane0_s <= edge_wea_i when edge_addra_i(1 downto 0) = "00" else '0';

    edge_bram_lane0 : entity work.bram
        generic map (
            WIDTH     => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => reset,
            resetb => reset,

            ena => edge_axi_en_s,
            enb => edge_ena_i,

            wea => '0',
            web => edge_we_lane0_s,

            addra => edge_axi_addr_s,
            addrb => edge_ip_addr_s,

            dia => (others => '0'),
            dib => edge_dia_i,

            doa => edge_axi_byte0_s,
            dob => edge_ip_byte0_s
        );

    --------------------------------------------------------------------
    -- EDGE BRAM, lane 1
    --------------------------------------------------------------------
    edge_we_lane1_s <= edge_wea_i when edge_addra_i(1 downto 0) = "01" else '0';

    edge_bram_lane1 : entity work.bram
        generic map (
            WIDTH     => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => reset,
            resetb => reset,

            ena => edge_axi_en_s,
            enb => edge_ena_i,

            wea => '0',
            web => edge_we_lane1_s,

            addra => edge_axi_addr_s,
            addrb => edge_ip_addr_s,

            dia => (others => '0'),
            dib => edge_dia_i,

            doa => edge_axi_byte1_s,
            dob => edge_ip_byte1_s
        );

    --------------------------------------------------------------------
    -- EDGE BRAM, lane 2
    --------------------------------------------------------------------
    edge_we_lane2_s <= edge_wea_i when edge_addra_i(1 downto 0) = "10" else '0';

    edge_bram_lane2 : entity work.bram
        generic map (
            WIDTH     => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => reset,
            resetb => reset,

            ena => edge_axi_en_s,
            enb => edge_ena_i,

            wea => '0',
            web => edge_we_lane2_s,

            addra => edge_axi_addr_s,
            addrb => edge_ip_addr_s,

            dia => (others => '0'),
            dib => edge_dia_i,

            doa => edge_axi_byte2_s,
            dob => edge_ip_byte2_s
        );

    --------------------------------------------------------------------
    -- EDGE BRAM, lane 3
    --------------------------------------------------------------------
    edge_we_lane3_s <= edge_wea_i when edge_addra_i(1 downto 0) = "11" else '0';

    edge_bram_lane3 : entity work.bram
        generic map (
            WIDTH     => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => reset,
            resetb => reset,

            ena => edge_axi_en_s,
            enb => edge_ena_i,

            wea => '0',
            web => edge_we_lane3_s,

            addra => edge_axi_addr_s,
            addrb => edge_ip_addr_s,

            dia => (others => '0'),
            dib => edge_dia_i,

            doa => edge_axi_byte3_s,
            dob => edge_ip_byte3_s
        );

    --------------------------------------------------------------------
    -- EDGE byte select toward Canny IP
    --------------------------------------------------------------------
    process(edge_addra_i, edge_ip_byte0_s, edge_ip_byte1_s, edge_ip_byte2_s, edge_ip_byte3_s)
    begin
        case edge_addra_i(1 downto 0) is
            when "00" =>
                edge_doa_o <= edge_ip_byte0_s;
            when "01" =>
                edge_doa_o <= edge_ip_byte1_s;
            when "10" =>
                edge_doa_o <= edge_ip_byte2_s;
            when others =>
                edge_doa_o <= edge_ip_byte3_s;
        end case;
    end process;

end struct;