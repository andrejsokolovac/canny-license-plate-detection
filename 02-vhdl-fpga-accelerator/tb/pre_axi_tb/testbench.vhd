library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity tb_top is
end tb_top;

architecture Behavioral of tb_top is

    constant WIDTH_TB      : integer := 8;
    constant BRAM_SIZE_TB  : integer := 196608;
    constant ADDR_WIDTH_TB : integer := 18;

    constant TEST_ROWS : integer := 384;
    constant TEST_COLS : integer := 512;
    constant TOTAL_PIXELS : integer := TEST_ROWS * TEST_COLS;

    constant GRAY_FILE_PATH : string := "C:\Users\Machi\Desktop\PSDS_PROJECT\input_images\grayscale_full.txt";
    constant EDGE_FILE_PATH : string := "C:\Users\Machi\Desktop\PSDS_PROJECT\input_images\final_edge_full.txt";

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal start : std_logic := '0';
    signal ready : std_logic;

    signal rows : std_logic_vector(8 downto 0) := (others => '0');
    signal cols : std_logic_vector(9 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- TB -> INPUT BRAM
    --------------------------------------------------------------------
    signal tb_input_en   : std_logic := '0';
    signal tb_input_we   : std_logic := '0';
    signal tb_input_addr : std_logic_vector(ADDR_WIDTH_TB-1 downto 0) := (others => '0');
    signal tb_input_din  : std_logic_vector(7 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- TB -> GAUSS BRAM
    --------------------------------------------------------------------
    signal tb_gauss_en   : std_logic := '0';
    signal tb_gauss_addr : std_logic_vector(ADDR_WIDTH_TB-1 downto 0) := (others => '0');
    signal tb_gauss_dout : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- TB -> MAG BRAM
    --------------------------------------------------------------------
    signal tb_mag_en   : std_logic := '0';
    signal tb_mag_addr : std_logic_vector(ADDR_WIDTH_TB-1 downto 0) := (others => '0');
    signal tb_mag_dout : std_logic_vector(15 downto 0);

    --------------------------------------------------------------------
    -- TB -> DIR BRAM
    --------------------------------------------------------------------
    signal tb_dir_en   : std_logic := '0';
    signal tb_dir_addr : std_logic_vector(ADDR_WIDTH_TB-1 downto 0) := (others => '0');
    signal tb_dir_dout : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- TB -> NMS BRAM
    --------------------------------------------------------------------
    signal tb_nms_en   : std_logic := '0';
    signal tb_nms_addr : std_logic_vector(ADDR_WIDTH_TB-1 downto 0) := (others => '0');
    signal tb_nms_dout : std_logic_vector(15 downto 0);

    --------------------------------------------------------------------
    -- TB -> THRESH BRAM
    --------------------------------------------------------------------
    signal tb_thresh_en   : std_logic := '0';
    signal tb_thresh_addr : std_logic_vector(ADDR_WIDTH_TB-1 downto 0) := (others => '0');
    signal tb_thresh_dout : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- TB -> EDGE BRAM
    --------------------------------------------------------------------
    signal tb_edge_en   : std_logic := '0';
    signal tb_edge_addr : std_logic_vector(ADDR_WIDTH_TB-1 downto 0) := (others => '0');
    signal tb_edge_dout : std_logic_vector(7 downto 0);

    type int_mem_t is array (0 to TOTAL_PIXELS-1) of integer;

begin

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    uut : entity work.top
        generic map (
            WIDTH      => WIDTH_TB,
            BRAM_SIZE  => BRAM_SIZE_TB,
            ADDR_WIDTH => ADDR_WIDTH_TB
        )
        port map (
            clk   => clk,
            reset => reset,
            start => start,
            ready => ready,

            rows => rows,
            cols => cols,

            tb_input_en   => tb_input_en,
            tb_input_we   => tb_input_we,
            tb_input_addr => tb_input_addr,
            tb_input_din  => tb_input_din,

            tb_gauss_en   => tb_gauss_en,
            tb_gauss_addr => tb_gauss_addr,
            tb_gauss_dout => tb_gauss_dout,

            tb_mag_en     => tb_mag_en,
            tb_mag_addr   => tb_mag_addr,
            tb_mag_dout   => tb_mag_dout,

            tb_dir_en     => tb_dir_en,
            tb_dir_addr   => tb_dir_addr,
            tb_dir_dout   => tb_dir_dout,

            tb_nms_en     => tb_nms_en,
            tb_nms_addr   => tb_nms_addr,
            tb_nms_dout   => tb_nms_dout,

            tb_thresh_en   => tb_thresh_en,
            tb_thresh_addr => tb_thresh_addr,
            tb_thresh_dout => tb_thresh_dout,

            tb_edge_en   => tb_edge_en,
            tb_edge_addr => tb_edge_addr,
            tb_edge_dout => tb_edge_dout
        );

    --------------------------------------------------------------------
    -- CLOCK
    --------------------------------------------------------------------
    clk <= not clk after 10 ns;

    --------------------------------------------------------------------
    -- STIMULUS + FILE LOAD + COMPARE
    --------------------------------------------------------------------
    stim_proc : process
        file gray_file : text;
        file edge_file : text;

        variable gray_line : line;
        variable edge_line : line;

        variable gray_val : integer;
        variable edge_val : integer;

        variable expected_edge : int_mem_t;

        variable addr_int : integer;
        variable got_val  : integer;

        variable match_count    : integer := 0;
        variable mismatch_count : integer := 0;

        variable first_mismatch_found : boolean := false;
        variable first_mismatch_addr  : integer := -1;
        variable first_expected       : integer := -1;
        variable first_got            : integer := -1;
    begin
        ----------------------------------------------------------------
        -- RESET
        ----------------------------------------------------------------
        wait for 50 ns;
        reset <= '0';

        rows <= std_logic_vector(to_unsigned(TEST_ROWS, 9));
        cols <= std_logic_vector(to_unsigned(TEST_COLS, 10));

        wait for 20 ns;

        ----------------------------------------------------------------
        -- LOAD GRAYSCALE TXT AND WRITE TO INPUT BRAM
        ----------------------------------------------------------------
        file_open(gray_file, GRAY_FILE_PATH, read_mode);

        tb_input_en <= '1';
        tb_input_we <= '1';

        for addr in 0 to TOTAL_PIXELS - 1 loop
            readline(gray_file, gray_line);
            read(gray_line, gray_val);

            tb_input_addr <= std_logic_vector(to_unsigned(addr, ADDR_WIDTH_TB));
            tb_input_din  <= std_logic_vector(to_unsigned(gray_val, 8));

            wait until rising_edge(clk);
        end loop;

        file_close(gray_file);

        tb_input_en   <= '0';
        tb_input_we   <= '0';
        tb_input_addr <= (others => '0');
        tb_input_din  <= (others => '0');

        wait for 40 ns;

        ----------------------------------------------------------------
        -- LOAD REFERENCE EDGE IMAGE INTO LOCAL MEMORY
        ----------------------------------------------------------------
        file_open(edge_file, EDGE_FILE_PATH, read_mode);

        for addr in 0 to TOTAL_PIXELS - 1 loop
            readline(edge_file, edge_line);
            read(edge_line, edge_val);
            expected_edge(addr) := edge_val;
        end loop;

        file_close(edge_file);

        ----------------------------------------------------------------
        -- START pulse
        ----------------------------------------------------------------
        start <= '1';
        wait for 40 ns;
        start <= '0';

        ----------------------------------------------------------------
        -- Wait for the IP to start
        ----------------------------------------------------------------
        while ready /= '0' loop
            wait until rising_edge(clk);
        end loop;

        ----------------------------------------------------------------
        -- Wait for the IP to finish
        ----------------------------------------------------------------
        while ready /= '1' loop
            wait until rising_edge(clk);
        end loop;

        wait until rising_edge(clk);
        wait until rising_edge(clk);

        ----------------------------------------------------------------
        -- COMPARE EDGE BRAM AGAINST final_edge_36x36.txt
        -- valid region after hysteresis:
        -- i = 5..30
        -- j = 5..30
        -- total 26x26 = 676
        ----------------------------------------------------------------
        tb_edge_en <= '1';

        for i in 5 to TEST_ROWS - 6 loop
            for j in 5 to TEST_COLS - 6 loop
        --for i in 4 to TEST_ROWS - 5 loop
            --for j in 4 to TEST_COLS - 5 loop           
            
                addr_int := i * TEST_COLS + j;

                tb_edge_addr <= std_logic_vector(to_unsigned(addr_int, ADDR_WIDTH_TB));
                wait until rising_edge(clk);
                wait until rising_edge(clk);

                got_val := to_integer(unsigned(tb_edge_dout));

                if got_val = expected_edge(addr_int) then
                    match_count := match_count + 1;
                else
                    mismatch_count := mismatch_count + 1;

                    if not first_mismatch_found then
                        first_mismatch_found := true;
                        first_mismatch_addr  := addr_int;
                        first_expected       := expected_edge(addr_int);
                        first_got            := got_val;
                    end if;
                end if;
            end loop;
        end loop;

        tb_edge_en   <= '0';
        tb_edge_addr <= (others => '0');

        ----------------------------------------------------------------
        -- REPORT
        ----------------------------------------------------------------
        report "==========================================";
        report "FINAL EDGE CHECK FINISHED";
        report "MATCHES    = " & integer'image(match_count);
        report "MISMATCHES = " & integer'image(mismatch_count);

        if first_mismatch_found then
            report "FIRST MISMATCH AT ADDR = " & integer'image(first_mismatch_addr);
            report "EXPECTED = " & integer'image(first_expected);
            report "GOT      = " & integer'image(first_got);
        else
            report "NO MISMATCHES DETECTED.";
        end if;

        report "==========================================";

        wait for 100 ns;
        assert false report "SIMULATION DONE" severity failure;
    end process;

end Behavioral;