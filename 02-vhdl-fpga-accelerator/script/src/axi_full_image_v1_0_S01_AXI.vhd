library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_full_image_v1_0_S01_AXI is
    generic (
        -- Users to add parameters here

        -- User parameters ends
        -- Do not modify the parameters beyond this line

        -- Width of ID for write address, write data, read address and read data
        C_S_AXI_ID_WIDTH : integer := 1;

        -- Width of S_AXI data bus
        C_S_AXI_DATA_WIDTH : integer := 32;

        -- Width of S_AXI address bus
        -- 19 bits => 2^19 bytes = 512 KB address space
        C_S_AXI_ADDR_WIDTH : integer := 19;

        -- Width of optional user defined signal in write address channel
        C_S_AXI_AWUSER_WIDTH : integer := 0;

        -- Width of optional user defined signal in read address channel
        C_S_AXI_ARUSER_WIDTH : integer := 0;

        -- Width of optional user defined signal in write data channel
        C_S_AXI_WUSER_WIDTH : integer := 0;

        -- Width of optional user defined signal in read data channel
        C_S_AXI_RUSER_WIDTH : integer := 0;

        -- Width of optional user defined signal in write response channel
        C_S_AXI_BUSER_WIDTH : integer := 0
    );
    port (
        -- Users to add ports here

        ----------------------------------------------------------------
        -- Simple memory interface toward mem_subsystem
        ----------------------------------------------------------------
        mem_addr_o      : out std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 2);
        mem_data_o      : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        mem_wr_o        : out std_logic;
        mem_read_data_i : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

        -- User ports ends
        -- Do not modify the ports beyond this line

        -- Global Clock Signal
        S_AXI_ACLK : in std_logic;

        -- Global Reset Signal. This Signal is Active LOW
        S_AXI_ARESETN : in std_logic;

        -- Write Address ID
        S_AXI_AWID : in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);

        -- Write address
        S_AXI_AWADDR : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);

        -- Burst length. The burst length gives the exact number of transfers in a burst
        S_AXI_AWLEN : in std_logic_vector(7 downto 0);

        -- Burst size. This signal indicates the size of each transfer in the burst
        S_AXI_AWSIZE : in std_logic_vector(2 downto 0);

        -- Burst type
        S_AXI_AWBURST : in std_logic_vector(1 downto 0);

        -- Lock type
        S_AXI_AWLOCK : in std_logic;

        -- Memory type
        S_AXI_AWCACHE : in std_logic_vector(3 downto 0);

        -- Protection type
        S_AXI_AWPROT : in std_logic_vector(2 downto 0);

        -- Quality of Service
        S_AXI_AWQOS : in std_logic_vector(3 downto 0);

        -- Region identifier
        S_AXI_AWREGION : in std_logic_vector(3 downto 0);

        -- Optional User-defined signal in the write address channel
        S_AXI_AWUSER : in std_logic_vector(C_S_AXI_AWUSER_WIDTH-1 downto 0);

        -- Write address valid
        S_AXI_AWVALID : in std_logic;

        -- Write address ready
        S_AXI_AWREADY : out std_logic;

        -- Write Data
        S_AXI_WDATA : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

        -- Write strobes
        S_AXI_WSTRB : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);

        -- Write last
        S_AXI_WLAST : in std_logic;

        -- Optional User-defined signal in the write data channel
        S_AXI_WUSER : in std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);

        -- Write valid
        S_AXI_WVALID : in std_logic;

        -- Write ready
        S_AXI_WREADY : out std_logic;

        -- Response ID tag
        S_AXI_BID : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);

        -- Write response
        S_AXI_BRESP : out std_logic_vector(1 downto 0);

        -- Optional User-defined signal in the write response channel
        S_AXI_BUSER : out std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);

        -- Write response valid
        S_AXI_BVALID : out std_logic;

        -- Response ready
        S_AXI_BREADY : in std_logic;

        -- Read address ID
        S_AXI_ARID : in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);

        -- Read address
        S_AXI_ARADDR : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);

        -- Burst length
        S_AXI_ARLEN : in std_logic_vector(7 downto 0);

        -- Burst size
        S_AXI_ARSIZE : in std_logic_vector(2 downto 0);

        -- Burst type
        S_AXI_ARBURST : in std_logic_vector(1 downto 0);

        -- Lock type
        S_AXI_ARLOCK : in std_logic;

        -- Memory type
        S_AXI_ARCACHE : in std_logic_vector(3 downto 0);

        -- Protection type
        S_AXI_ARPROT : in std_logic_vector(2 downto 0);

        -- Quality of Service
        S_AXI_ARQOS : in std_logic_vector(3 downto 0);

        -- Region identifier
        S_AXI_ARREGION : in std_logic_vector(3 downto 0);

        -- Optional User-defined signal in the read address channel
        S_AXI_ARUSER : in std_logic_vector(C_S_AXI_ARUSER_WIDTH-1 downto 0);

        -- Read address valid
        S_AXI_ARVALID : in std_logic;

        -- Read address ready
        S_AXI_ARREADY : out std_logic;

        -- Read ID tag
        S_AXI_RID : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);

        -- Read Data
        S_AXI_RDATA : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

        -- Read response
        S_AXI_RRESP : out std_logic_vector(1 downto 0);

        -- Read last
        S_AXI_RLAST : out std_logic;

        -- Optional User-defined signal in the read data channel
        S_AXI_RUSER : out std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);

        -- Read valid
        S_AXI_RVALID : out std_logic;

        -- Read ready
        S_AXI_RREADY : in std_logic
    );
end axi_full_image_v1_0_S01_AXI;

architecture arch_imp of axi_full_image_v1_0_S01_AXI is

    --------------------------------------------------------------------
    -- AXI4-Full internal signals
    --------------------------------------------------------------------
    signal axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_awready : std_logic;
    signal axi_wready  : std_logic;
    signal axi_bresp   : std_logic_vector(1 downto 0);
    signal axi_buser   : std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
    signal axi_bvalid  : std_logic;

    signal axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal axi_arready : std_logic;
    signal axi_rdata   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal axi_rresp   : std_logic_vector(1 downto 0);
    signal axi_rlast   : std_logic;
    signal axi_ruser   : std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
    signal axi_rvalid  : std_logic;

    signal aw_wrap_en : std_logic;
    signal ar_wrap_en : std_logic;
    signal aw_wrap_size : integer;
    signal ar_wrap_size : integer;

    signal axi_awv_awr_flag : std_logic;
    signal axi_arv_arr_flag : std_logic;

    signal axi_awlen_cntr : std_logic_vector(7 downto 0);
    signal axi_arlen_cntr : std_logic_vector(7 downto 0);

    signal axi_arburst : std_logic_vector(1 downto 0);
    signal axi_awburst : std_logic_vector(1 downto 0);
    signal axi_arlen   : std_logic_vector(7 downto 0);
    signal axi_awlen   : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- Addressing
    -- ADDR_LSB = 2 for 32-bit data bus, because AXI address is byte-based.
    -- mem_addr_o is word-based address: AXI address bits 18 downto 2.
    --------------------------------------------------------------------
    constant ADDR_LSB : integer := (C_S_AXI_DATA_WIDTH/32) + 1;
    constant low : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- Helper flag used to cleanly finish write burst
    --------------------------------------------------------------------
    signal wlast_seen : std_logic := '0';

begin

    --------------------------------------------------------------------
    -- AXI output assignments
    --------------------------------------------------------------------
    S_AXI_AWREADY <= axi_awready;
    S_AXI_WREADY  <= axi_wready;
    S_AXI_BRESP   <= axi_bresp;
    S_AXI_BUSER   <= axi_buser;
    S_AXI_BVALID  <= axi_bvalid;

    S_AXI_ARREADY <= axi_arready;
    S_AXI_RDATA   <= axi_rdata;
    S_AXI_RRESP   <= axi_rresp;
    S_AXI_RLAST   <= axi_rlast;
    S_AXI_RUSER   <= axi_ruser;
    S_AXI_RVALID  <= axi_rvalid;

    S_AXI_BID <= S_AXI_AWID;
    S_AXI_RID <= S_AXI_ARID;

    --------------------------------------------------------------------
    -- Wrap calculations
    --------------------------------------------------------------------
    aw_wrap_size <= ((C_S_AXI_DATA_WIDTH)/8 * to_integer(unsigned(axi_awlen)));
    ar_wrap_size <= ((C_S_AXI_DATA_WIDTH)/8 * to_integer(unsigned(axi_arlen)));

    aw_wrap_en <= '1' when
        (((axi_awaddr and std_logic_vector(to_unsigned(aw_wrap_size, C_S_AXI_ADDR_WIDTH))) xor
          std_logic_vector(to_unsigned(aw_wrap_size, C_S_AXI_ADDR_WIDTH))) = low)
        else '0';

    ar_wrap_en <= '1' when
        (((axi_araddr and std_logic_vector(to_unsigned(ar_wrap_size, C_S_AXI_ADDR_WIDTH))) xor
          std_logic_vector(to_unsigned(ar_wrap_size, C_S_AXI_ADDR_WIDTH))) = low)
        else '0';

    --------------------------------------------------------------------
    -- Write address ready generation
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_awready <= '0';
                axi_awv_awr_flag <= '0';
                wlast_seen <= '0';
            else
                if (axi_awready = '0' and S_AXI_AWVALID = '1' and
                    axi_awv_awr_flag = '0' and axi_arv_arr_flag = '0') then

                    axi_awv_awr_flag <= '1';
                    axi_awready <= '1';

                elsif wlast_seen = '1' then
                    axi_awv_awr_flag <= '0';
                    wlast_seen <= '0';

                elsif (S_AXI_WLAST = '1' and S_AXI_WVALID = '1' and axi_wready = '1') then
                    wlast_seen <= '1';
                    axi_awready <= '0';

                else
                    axi_awready <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Write address latch and burst address increment
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_awaddr <= (others => '0');
                axi_awburst <= (others => '0');
                axi_awlen <= (others => '0');
                axi_awlen_cntr <= (others => '0');
            else
                if (axi_awready = '0' and S_AXI_AWVALID = '1' and
                    axi_awv_awr_flag = '0') then

                    axi_awaddr <= S_AXI_AWADDR(C_S_AXI_ADDR_WIDTH-1 downto 0);
                    axi_awlen_cntr <= (others => '0');
                    axi_awburst <= S_AXI_AWBURST;
                    axi_awlen <= S_AXI_AWLEN;

                elsif ((axi_awlen_cntr <= axi_awlen) and
                       axi_wready = '1' and S_AXI_WVALID = '1') then

                    axi_awlen_cntr <= std_logic_vector(unsigned(axi_awlen_cntr) + 1);

                    case axi_awburst is
                        when "00" =>
                            -- FIXED burst
                            axi_awaddr <= axi_awaddr;

                        when "01" =>
                            -- INCR burst, 32-bit aligned
                            axi_awaddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB) <=
                                std_logic_vector(unsigned(axi_awaddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB)) + 1);
                            axi_awaddr(ADDR_LSB-1 downto 0) <= (others => '0');

                        when "10" =>
                            -- WRAP burst
                            if aw_wrap_en = '1' then
                                axi_awaddr <= std_logic_vector(unsigned(axi_awaddr) -
                                               to_unsigned(aw_wrap_size, C_S_AXI_ADDR_WIDTH));
                            else
                                axi_awaddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB) <=
                                    std_logic_vector(unsigned(axi_awaddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB)) + 1);
                                axi_awaddr(ADDR_LSB-1 downto 0) <= (others => '0');
                            end if;

                        when others =>
                            -- Reserved, treat as INCR
                            axi_awaddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB) <=
                                std_logic_vector(unsigned(axi_awaddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB)) + 1);
                            axi_awaddr(ADDR_LSB-1 downto 0) <= (others => '0');
                    end case;
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
                if (axi_wready = '0' and axi_awv_awr_flag = '1') then
                    axi_wready <= '1';
                elsif (S_AXI_WLAST = '1' and axi_wready = '1') then
                    axi_wready <= '0';
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
                axi_buser  <= (others => '0');
            else
                if (axi_awv_awr_flag = '1' and axi_wready = '1' and
                    S_AXI_WVALID = '1' and axi_bvalid = '0' and
                    S_AXI_WLAST = '1') then

                    axi_bvalid <= '1';
                    axi_bresp  <= "00"; -- OKAY

                elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
                    axi_bvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Read address ready generation
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_arready <= '0';
                axi_arv_arr_flag <= '0';
            else
                if (axi_arready = '0' and S_AXI_ARVALID = '1' and
                    axi_awv_awr_flag = '0' and axi_arv_arr_flag = '0') then

                    axi_arready <= '1';
                    axi_arv_arr_flag <= '1';

                elsif (axi_rvalid = '1' and S_AXI_RREADY = '1' and
                       axi_arlen_cntr = axi_arlen) then

                    axi_arv_arr_flag <= '0';

                else
                    axi_arready <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Read address latch and burst address increment
    --------------------------------------------------------------------
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_araddr <= (others => '0');
                axi_arburst <= (others => '0');
                axi_arlen <= (others => '0');
                axi_arlen_cntr <= (others => '0');
                axi_rlast <= '0';
                axi_ruser <= (others => '0');
            else
                if (axi_arready = '0' and S_AXI_ARVALID = '1' and
                    axi_arv_arr_flag = '0') then

                    axi_araddr <= S_AXI_ARADDR(C_S_AXI_ADDR_WIDTH-1 downto 0);
                    axi_arlen_cntr <= (others => '0');
                    axi_rlast <= '0';
                    axi_arburst <= S_AXI_ARBURST;
                    axi_arlen <= S_AXI_ARLEN;

                elsif ((axi_arlen_cntr <= axi_arlen) and
                       axi_rvalid = '1' and S_AXI_RREADY = '1') then

                    axi_arlen_cntr <= std_logic_vector(unsigned(axi_arlen_cntr) + 1);
                    axi_rlast <= '0';

                    case axi_arburst is
                        when "00" =>
                            -- FIXED burst
                            axi_araddr <= axi_araddr;

                        when "01" =>
                            -- INCR burst, 32-bit aligned
                            axi_araddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB) <=
                                std_logic_vector(unsigned(axi_araddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB)) + 1);
                            axi_araddr(ADDR_LSB-1 downto 0) <= (others => '0');

                        when "10" =>
                            -- WRAP burst
                            if ar_wrap_en = '1' then
                                axi_araddr <= std_logic_vector(unsigned(axi_araddr) -
                                               to_unsigned(ar_wrap_size, C_S_AXI_ADDR_WIDTH));
                            else
                                axi_araddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB) <=
                                    std_logic_vector(unsigned(axi_araddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB)) + 1);
                                axi_araddr(ADDR_LSB-1 downto 0) <= (others => '0');
                            end if;

                        when others =>
                            -- Reserved, treat as INCR
                            axi_araddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB) <=
                                std_logic_vector(unsigned(axi_araddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB)) + 1);
                            axi_araddr(ADDR_LSB-1 downto 0) <= (others => '0');
                    end case;

                elsif ((axi_arlen_cntr = axi_arlen) and axi_rlast = '0' and
                       axi_arv_arr_flag = '1') then

                    axi_rlast <= '1';

                elsif (S_AXI_RREADY = '1') then
                    axi_rlast <= '0';
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
                if (axi_arv_arr_flag = '1' and axi_rvalid = '0') then
                    axi_rvalid <= '1';
                    axi_rresp  <= "00"; -- OKAY
                elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
                    axi_rvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Simple memory interface toward mem_subsystem
    --
    -- mem_addr_o is word-based:
    -- AXI byte address 0x00000 -> mem_addr_o 0
    -- AXI byte address 0x00004 -> mem_addr_o 1
    -- etc.
    --------------------------------------------------------------------
    mem_wr_o <= axi_wready and S_AXI_WVALID and axi_awv_awr_flag;

    mem_addr_o <= axi_araddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB)
                  when axi_arv_arr_flag = '1' else
                  axi_awaddr(C_S_AXI_ADDR_WIDTH-1 downto ADDR_LSB)
                  when axi_awv_awr_flag = '1' else
                  (others => '0');

    mem_data_o <= S_AXI_WDATA;

    --------------------------------------------------------------------
    -- Read data from mem_subsystem
    --------------------------------------------------------------------
    process (mem_read_data_i, axi_rvalid)
    begin
        if axi_rvalid = '1' then
            axi_rdata <= mem_read_data_i;
        else
            axi_rdata <= (others => '0');
        end if;
    end process;

end arch_imp;