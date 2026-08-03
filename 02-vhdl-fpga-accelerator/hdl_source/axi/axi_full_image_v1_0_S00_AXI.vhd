library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_full_image_v1_0_S00_AXI is
    generic (
        -- Users to add parameters here

        -- User parameters ends
        -- Do not modify the parameters beyond this line

        -- Width of S_AXI data bus
        C_S_AXI_DATA_WIDTH : integer := 32;
        -- Width of S_AXI address bus
        C_S_AXI_ADDR_WIDTH : integer := 5
    );
    port (
        -- Users to add ports here

        -- Data written by AXI-Lite master. mem_subsystem will use this
        -- together with *_wr_o signals to update internal registers.
        reg_data_o : out std_logic_vector(31 downto 0);

        -- Write-enable pulses for Canny control registers
        reg_rows_wr_o           : out std_logic;
        reg_cols_wr_o           : out std_logic;
        reg_low_threshold_wr_o  : out std_logic;
        reg_high_threshold_wr_o : out std_logic;
        reg_start_wr_o          : out std_logic;

        -- Values returned from mem_subsystem to AXI-Lite read channel
        reg_rows_i           : in std_logic_vector(8 downto 0);
        reg_cols_i           : in std_logic_vector(9 downto 0);
        reg_low_threshold_i  : in std_logic_vector(7 downto 0);
        reg_high_threshold_i : in std_logic_vector(7 downto 0);
        reg_start_i          : in std_logic;
        reg_ready_i          : in std_logic;

        -- User ports ends
        -- Do not modify the ports beyond this line

        -- Global Clock Signal
        S_AXI_ACLK : in std_logic;
        -- Global Reset Signal. This Signal is Active LOW
        S_AXI_ARESETN : in std_logic;

        -- Write address issued by master, accepted by slave
        S_AXI_AWADDR : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWPROT : in std_logic_vector(2 downto 0);
        S_AXI_AWVALID : in std_logic;
        S_AXI_AWREADY : out std_logic;

        -- Write data issued by master, accepted by slave
        S_AXI_WDATA : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        S_AXI_WVALID : in std_logic;
        S_AXI_WREADY : out std_logic;

        -- Write response
        S_AXI_BRESP : out std_logic_vector(1 downto 0);
        S_AXI_BVALID : out std_logic;
        S_AXI_BREADY : in std_logic;

        -- Read address issued by master, accepted by slave
        S_AXI_ARADDR : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARPROT : in std_logic_vector(2 downto 0);
        S_AXI_ARVALID : in std_logic;
        S_AXI_ARREADY : out std_logic;

        -- Read data issued by slave
        S_AXI_RDATA : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP : out std_logic_vector(1 downto 0);
        S_AXI_RVALID : out std_logic;
        S_AXI_RREADY : in std_logic
    );
end axi_full_image_v1_0_S00_AXI;

architecture arch_imp of axi_full_image_v1_0_S00_AXI is

    --------------------------------------------------------------------
    -- AXI4-Lite internal signals
    --------------------------------------------------------------------
    signal axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_awready : std_logic;
    signal axi_wready  : std_logic;
    signal axi_bresp   : std_logic_vector(1 downto 0);
    signal axi_bvalid  : std_logic;
    signal axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_arready : std_logic;
    signal axi_rdata   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal axi_rresp   : std_logic_vector(1 downto 0);
    signal axi_rvalid  : std_logic;

    --------------------------------------------------------------------
    -- Address decoding constants
    -- For 32-bit data bus, ADDR_LSB = 2, so register addresses are:
    -- 0x00, 0x04, 0x08, 0x0C, 0x10, 0x14
    --------------------------------------------------------------------
    constant ADDR_LSB : integer := (C_S_AXI_DATA_WIDTH/32) + 1;
    constant OPT_MEM_ADDR_BITS : integer := 2;

    signal slv_reg_rden : std_logic;
    signal slv_reg_wren : std_logic;
    signal reg_data_out : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal aw_en        : std_logic;

begin

    --------------------------------------------------------------------
    -- AXI output assignments
    --------------------------------------------------------------------
    S_AXI_AWREADY <= axi_awready;
    S_AXI_WREADY  <= axi_wready;
    S_AXI_BRESP   <= axi_bresp;
    S_AXI_BVALID  <= axi_bvalid;
    S_AXI_ARREADY <= axi_arready;
    S_AXI_RDATA   <= axi_rdata;
    S_AXI_RRESP   <= axi_rresp;
    S_AXI_RVALID  <= axi_rvalid;

    --------------------------------------------------------------------
    -- Write address ready generation
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_awready <= '0';
                aw_en <= '1';
            else
                if (axi_awready = '0' and S_AXI_AWVALID = '1' and
                    S_AXI_WVALID = '1' and aw_en = '1') then

                    axi_awready <= '1';
                    aw_en <= '0';

                elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
                    aw_en <= '1';
                    axi_awready <= '0';
                else
                    axi_awready <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Write address latch
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_awaddr <= (others => '0');
            else
                if (axi_awready = '0' and S_AXI_AWVALID = '1' and
                    S_AXI_WVALID = '1' and aw_en = '1') then

                    axi_awaddr <= S_AXI_AWADDR;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Write data ready generation
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_wready <= '0';
            else
                if (axi_wready = '0' and S_AXI_WVALID = '1' and
                    S_AXI_AWVALID = '1' and aw_en = '1') then

                    axi_wready <= '1';
                else
                    axi_wready <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Write enable generation
    --------------------------------------------------------------------
    slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID;

    --------------------------------------------------------------------
    -- AXI-Lite write decoder
    --
    -- Register map:
    -- 0x00 -> rows
    -- 0x04 -> cols
    -- 0x08 -> low_threshold
    -- 0x0C -> high_threshold
    -- 0x10 -> start
    -- 0x14 -> ready, read-only
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
        variable loc_addr : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                reg_rows_wr_o           <= '0';
                reg_cols_wr_o           <= '0';
                reg_low_threshold_wr_o  <= '0';
                reg_high_threshold_wr_o <= '0';
                reg_start_wr_o          <= '0';
            else
                -- Default values: one-clock write pulses
                reg_rows_wr_o           <= '0';
                reg_cols_wr_o           <= '0';
                reg_low_threshold_wr_o  <= '0';
                reg_high_threshold_wr_o <= '0';
                reg_start_wr_o          <= '0';

                loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

                if slv_reg_wren = '1' then
                    case loc_addr is
                        when b"000" =>
                            reg_rows_wr_o <= '1';

                        when b"001" =>
                            reg_cols_wr_o <= '1';

                        when b"010" =>
                            reg_low_threshold_wr_o <= '1';

                        when b"011" =>
                            reg_high_threshold_wr_o <= '1';

                        when b"100" =>
                            reg_start_wr_o <= '1';

                        -- b"101" is ready/status and is read-only
                        when others =>
                            null;
                    end case;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Write response generation
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_bvalid <= '0';
                axi_bresp  <= "00";
            else
                if (axi_awready = '1' and S_AXI_AWVALID = '1' and
                    axi_wready = '1' and S_AXI_WVALID = '1' and
                    axi_bvalid = '0') then

                    axi_bvalid <= '1';
                    axi_bresp  <= "00"; -- OKAY

                elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
                    axi_bvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Read address ready generation and address latch
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_arready <= '0';
                axi_araddr  <= (others => '1');
            else
                if (axi_arready = '0' and S_AXI_ARVALID = '1') then
                    axi_arready <= '1';
                    axi_araddr  <= S_AXI_ARADDR;
                else
                    axi_arready <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Read valid generation
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_rvalid <= '0';
                axi_rresp  <= "00";
            else
                if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
                    axi_rvalid <= '1';
                    axi_rresp  <= "00"; -- OKAY
                elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
                    axi_rvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Read enable generation
    --------------------------------------------------------------------
    slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid);

    --------------------------------------------------------------------
    -- AXI-Lite read decoder
    --------------------------------------------------------------------
    process (
        reg_rows_i,
        reg_cols_i,
        reg_low_threshold_i,
        reg_high_threshold_i,
        reg_start_i,
        reg_ready_i,
        axi_araddr
    )
        variable loc_addr : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
    begin
        loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

        case loc_addr is
            -- 0x00 -> rows, 9 bits
            when b"000" =>
                reg_data_out <= std_logic_vector(to_unsigned(0, C_S_AXI_DATA_WIDTH - 9)) &
                                reg_rows_i;

            -- 0x04 -> cols, 10 bits
            when b"001" =>
                reg_data_out <= std_logic_vector(to_unsigned(0, C_S_AXI_DATA_WIDTH - 10)) &
                                reg_cols_i;

            -- 0x08 -> low_threshold, 8 bits
            when b"010" =>
                reg_data_out <= std_logic_vector(to_unsigned(0, C_S_AXI_DATA_WIDTH - 8)) &
                                reg_low_threshold_i;

            -- 0x0C -> high_threshold, 8 bits
            when b"011" =>
                reg_data_out <= std_logic_vector(to_unsigned(0, C_S_AXI_DATA_WIDTH - 8)) &
                                reg_high_threshold_i;

            -- 0x10 -> start, 1 bit
            when b"100" =>
                reg_data_out <= std_logic_vector(to_unsigned(0, C_S_AXI_DATA_WIDTH - 1)) &
                                reg_start_i;

            -- 0x14 -> ready, 1 bit
            when b"101" =>
                reg_data_out <= std_logic_vector(to_unsigned(0, C_S_AXI_DATA_WIDTH - 1)) &
                                reg_ready_i;

            when others =>
                reg_data_out <= (others => '0');
        end case;
    end process;

    --------------------------------------------------------------------
    -- Output read data register
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_rdata <= (others => '0');
            else
                if slv_reg_rden = '1' then
                    axi_rdata <= reg_data_out;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Register AXI write data toward memory subsystem
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                reg_data_o <= (others => '0');
            else
                reg_data_o <= S_AXI_WDATA;
            end if;
        end if;
    end process;

end arch_imp;