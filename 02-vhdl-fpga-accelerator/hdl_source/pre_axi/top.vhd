library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    generic (
  
        WIDTH      : integer := 8;
        BRAM_SIZE  : integer := 196608;
        ADDR_WIDTH : integer := 18
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;
        start : in std_logic;
        ready : out std_logic;

        rows : in std_logic_vector(8 downto 0);
        cols : in std_logic_vector(9 downto 0);

        ----------------------------------------------------------------
        -- TB kontrola INPUT BRAM
        ----------------------------------------------------------------
        tb_input_en   : in std_logic;
        tb_input_we   : in std_logic;
        tb_input_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        tb_input_din  : in std_logic_vector(7 downto 0);

        ----------------------------------------------------------------
        -- TB ?itanje GAUSS BRAM
        ----------------------------------------------------------------
        tb_gauss_en   : in std_logic;
        tb_gauss_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        tb_gauss_dout : out std_logic_vector(7 downto 0);

        ----------------------------------------------------------------
        -- TB ?itanje MAG BRAM
        ----------------------------------------------------------------
        tb_mag_en   : in std_logic;
        tb_mag_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        tb_mag_dout : out std_logic_vector(15 downto 0);

        ----------------------------------------------------------------
        -- TB ?itanje DIR BRAM
        ----------------------------------------------------------------
        tb_dir_en   : in std_logic;
        tb_dir_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        tb_dir_dout : out std_logic_vector(7 downto 0);

        ----------------------------------------------------------------
        -- TB ?itanje NMS BRAM
        ----------------------------------------------------------------
        tb_nms_en   : in std_logic;
        tb_nms_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        tb_nms_dout : out std_logic_vector(15 downto 0);

        ----------------------------------------------------------------
        -- TB ?itanje THRESH BRAM
        ----------------------------------------------------------------
        tb_thresh_en   : in std_logic;
        tb_thresh_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        tb_thresh_dout : out std_logic_vector(7 downto 0);

        ----------------------------------------------------------------
        -- TB ?itanje EDGE BRAM
        ----------------------------------------------------------------
        tb_edge_en   : in std_logic;
        tb_edge_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        tb_edge_dout : out std_logic_vector(7 downto 0)
    );
end top;

architecture Behavioral of top is

    --------------------------------------------------------------------
    -- INPUT BRAM signals
    --------------------------------------------------------------------
    signal input_ena, input_wea : std_logic;
    signal input_addra : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal input_dia, input_doa : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- GAUSS BRAM signals
    --------------------------------------------------------------------
    signal gauss_ena, gauss_wea : std_logic;
    signal gauss_addra : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal gauss_dia, gauss_doa : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- MAG BRAM signals
    --------------------------------------------------------------------
    signal mag_ena, mag_wea : std_logic;
    signal mag_addra : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal mag_dia, mag_doa : std_logic_vector(15 downto 0);

    --------------------------------------------------------------------
    -- DIR BRAM signals
    --------------------------------------------------------------------
    signal dir_ena, dir_wea : std_logic;
    signal dir_addra : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal dir_dia, dir_doa : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- NMS BRAM signals
    --------------------------------------------------------------------
    signal nms_ena, nms_wea : std_logic;
    signal nms_addra : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal nms_dia, nms_doa : std_logic_vector(15 downto 0);

    --------------------------------------------------------------------
    -- THRESH BRAM signals
    --------------------------------------------------------------------
    signal thresh_ena, thresh_wea : std_logic;
    signal thresh_addra : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal thresh_dia, thresh_doa : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- EDGE BRAM signals
    --------------------------------------------------------------------
    signal edge_ena, edge_wea : std_logic;
    signal edge_addra : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal edge_dia, edge_doa : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- MUX signals
    --------------------------------------------------------------------
    signal input_en_mux, input_we_mux : std_logic;
    signal input_addr_mux : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal input_din_mux  : std_logic_vector(7 downto 0);

    signal gauss_en_mux, gauss_we_mux : std_logic;
    signal gauss_addr_mux : std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal mag_en_mux, mag_we_mux : std_logic;
    signal mag_addr_mux : std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal dir_en_mux, dir_we_mux : std_logic;
    signal dir_addr_mux : std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal nms_en_mux, nms_we_mux : std_logic;
    signal nms_addr_mux : std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal thresh_en_mux, thresh_we_mux : std_logic;
    signal thresh_addr_mux : std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal edge_en_mux, edge_we_mux : std_logic;
    signal edge_addr_mux : std_logic_vector(ADDR_WIDTH-1 downto 0);

begin

    --------------------------------------------------------------------
    -- INPUT MUX
    --------------------------------------------------------------------
    input_en_mux   <= tb_input_en   when tb_input_en = '1' else input_ena;
    input_we_mux   <= tb_input_we   when tb_input_en = '1' else input_wea;
    input_addr_mux <= tb_input_addr when tb_input_en = '1' else input_addra;
    input_din_mux  <= tb_input_din  when tb_input_en = '1' else input_dia;

    --------------------------------------------------------------------
    -- GAUSS MUX
    --------------------------------------------------------------------
    gauss_en_mux   <= tb_gauss_en when tb_gauss_en = '1' else gauss_ena;
    gauss_we_mux   <= gauss_wea;
    gauss_addr_mux <= tb_gauss_addr when tb_gauss_en = '1' else gauss_addra;

    --------------------------------------------------------------------
    -- MAG MUX
    --------------------------------------------------------------------
    mag_en_mux   <= tb_mag_en when tb_mag_en = '1' else mag_ena;
    mag_we_mux   <= mag_wea;
    mag_addr_mux <= tb_mag_addr when tb_mag_en = '1' else mag_addra;

    --------------------------------------------------------------------
    -- DIR MUX
    --------------------------------------------------------------------
    dir_en_mux   <= tb_dir_en when tb_dir_en = '1' else dir_ena;
    dir_we_mux   <= dir_wea;
    dir_addr_mux <= tb_dir_addr when tb_dir_en = '1' else dir_addra;

    --------------------------------------------------------------------
    -- NMS MUX
    --------------------------------------------------------------------
    nms_en_mux   <= tb_nms_en when tb_nms_en = '1' else nms_ena;
    nms_we_mux   <= nms_wea;
    nms_addr_mux <= tb_nms_addr when tb_nms_en = '1' else nms_addra;

    --------------------------------------------------------------------
    -- THRESH MUX
    --------------------------------------------------------------------
    thresh_en_mux   <= tb_thresh_en when tb_thresh_en = '1' else thresh_ena;
    thresh_we_mux   <= thresh_wea;
    thresh_addr_mux <= tb_thresh_addr when tb_thresh_en = '1' else thresh_addra;

    --------------------------------------------------------------------
    -- EDGE MUX
    --------------------------------------------------------------------
    edge_en_mux   <= tb_edge_en when tb_edge_en = '1' else edge_ena;
    edge_we_mux   <= edge_wea;
    edge_addr_mux <= tb_edge_addr when tb_edge_en = '1' else edge_addra;

    --------------------------------------------------------------------
    -- INPUT BRAM
    --------------------------------------------------------------------
    input_bram: entity work.bram
        generic map (
            WIDTH => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => '0',
            resetb => '0',

            ena => input_en_mux,
            enb => '0',
            wea => input_we_mux,
            web => '0',

            addra => input_addr_mux,
            addrb => (others => '0'),

            dia => input_din_mux,
            dib => (others => '0'),

            doa => input_doa,
            dob => open
        );

    --------------------------------------------------------------------
    -- GAUSS BRAM
    --------------------------------------------------------------------
    gauss_bram: entity work.bram
        generic map (
            WIDTH => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => '0',
            resetb => '0',

            ena => gauss_en_mux,
            enb => '0',
            wea => gauss_we_mux,
            web => '0',

            addra => gauss_addr_mux,
            addrb => (others => '0'),

            dia => gauss_dia,
            dib => (others => '0'),

            doa => gauss_doa,
            dob => open
        );

    --------------------------------------------------------------------
    -- MAG BRAM
    --------------------------------------------------------------------
    mag_bram: entity work.bram
        generic map (
            WIDTH => 16,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => '0',
            resetb => '0',

            ena => mag_en_mux,
            enb => '0',
            wea => mag_we_mux,
            web => '0',

            addra => mag_addr_mux,
            addrb => (others => '0'),

            dia => mag_dia,
            dib => (others => '0'),

            doa => mag_doa,
            dob => open
        );

    --------------------------------------------------------------------
    -- DIR BRAM
    --------------------------------------------------------------------
    dir_bram: entity work.bram
        generic map (
            WIDTH => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => '0',
            resetb => '0',

            ena => dir_en_mux,
            enb => '0',
            wea => dir_we_mux,
            web => '0',

            addra => dir_addr_mux,
            addrb => (others => '0'),

            dia => dir_dia,
            dib => (others => '0'),

            doa => dir_doa,
            dob => open
        );

    --------------------------------------------------------------------
    -- NMS BRAM
    --------------------------------------------------------------------
    nms_bram: entity work.bram
        generic map (
            WIDTH => 16,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => '0',
            resetb => '0',

            ena => nms_en_mux,
            enb => '0',
            wea => nms_we_mux,
            web => '0',

            addra => nms_addr_mux,
            addrb => (others => '0'),

            dia => nms_dia,
            dib => (others => '0'),

            doa => nms_doa,
            dob => open
        );

    --------------------------------------------------------------------
    -- THRESH BRAM
    --------------------------------------------------------------------
    thresh_bram: entity work.bram
        generic map (
            WIDTH => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => '0',
            resetb => '0',

            ena => thresh_en_mux,
            enb => '0',
            wea => thresh_we_mux,
            web => '0',

            addra => thresh_addr_mux,
            addrb => (others => '0'),

            dia => thresh_dia,
            dib => (others => '0'),

            doa => thresh_doa,
            dob => open
        );

    --------------------------------------------------------------------
    -- EDGE BRAM
    --------------------------------------------------------------------
    edge_bram: entity work.bram
        generic map (
            WIDTH => 8,
            BRAM_SIZE => BRAM_SIZE
        )
        port map (
            clka   => clk,
            clkb   => clk,
            reseta => '0',
            resetb => '0',

            ena => edge_en_mux,
            enb => '0',
            wea => edge_we_mux,
            web => '0',

            addra => edge_addr_mux,
            addrb => (others => '0'),

            dia => edge_dia,
            dib => (others => '0'),

            doa => edge_doa,
            dob => open
        );

    --------------------------------------------------------------------
    -- IP
    --------------------------------------------------------------------
    uut: entity work.ip
        generic map (
            IMG_WIDTH  => 512,
            IMG_HEIGHT => 384,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk   => clk,
            reset => reset,
            start => start,
            ready => ready,
            rows  => rows,
            cols  => cols,

            input_ena   => input_ena,
            input_wea   => input_wea,
            input_addra => input_addra,
            input_dia   => input_dia,
            input_doa   => input_doa,

            gauss_ena   => gauss_ena,
            gauss_wea   => gauss_wea,
            gauss_addra => gauss_addra,
            gauss_dia   => gauss_dia,
            gauss_doa   => gauss_doa,

            mag_ena   => mag_ena,
            mag_wea   => mag_wea,
            mag_addra => mag_addra,
            mag_dia   => mag_dia,
            mag_doa   => mag_doa,

            dir_ena   => dir_ena,
            dir_wea   => dir_wea,
            dir_addra => dir_addra,
            dir_dia   => dir_dia,
            dir_doa   => dir_doa,

            nms_ena   => nms_ena,
            nms_wea   => nms_wea,
            nms_addra => nms_addra,
            nms_dia   => nms_dia,
            nms_doa   => nms_doa,

            thresh_ena   => thresh_ena,
            thresh_wea   => thresh_wea,
            thresh_addra => thresh_addra,
            thresh_dia   => thresh_dia,
            thresh_doa   => thresh_doa,

            edge_ena   => edge_ena,
            edge_wea   => edge_wea,
            edge_addra => edge_addra,
            edge_dia   => edge_dia,
            edge_doa   => edge_doa
        );

    --------------------------------------------------------------------
    -- TB izlazi
    --------------------------------------------------------------------
    tb_gauss_dout  <= gauss_doa;
    tb_mag_dout    <= mag_doa;
    tb_dir_dout    <= dir_doa;
    tb_nms_dout    <= nms_doa;
    tb_thresh_dout <= thresh_doa;
    tb_edge_dout   <= edge_doa;

end Behavioral;