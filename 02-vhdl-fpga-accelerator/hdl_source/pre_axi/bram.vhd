library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;

entity bram is
    generic (
        WIDTH      : integer := 8;
        --BRAM_SIZE  : integer := 307200  -- broj memorijskih lokacija
        BRAM_SIZE  : integer := 196608  -- broj memorijskih lokacija
    );
    port (
        clka  : in  std_logic;
        clkb  : in  std_logic;
        reseta : in std_logic;
        resetb : in std_logic;

        ena   : in  std_logic;
        enb   : in  std_logic;
        wea   : in  std_logic;
        web   : in  std_logic;

        addra : in  std_logic_vector(integer(ceil(log2(real(BRAM_SIZE)))) - 1 downto 0); --ceil zaokruzuje na visu cifru npr 16.2 = 17
        addrb : in  std_logic_vector(integer(ceil(log2(real(BRAM_SIZE)))) - 1 downto 0);

        dia   : in  std_logic_vector(WIDTH - 1 downto 0);
        dib   : in  std_logic_vector(WIDTH - 1 downto 0);

        doa   : out std_logic_vector(WIDTH - 1 downto 0);
        dob   : out std_logic_vector(WIDTH - 1 downto 0)
    );
end bram;

architecture Behavioral of bram is
    type ram_type is array (0 to BRAM_SIZE - 1) of std_logic_vector(WIDTH - 1 downto 0);
 --  shared variable RAM : ram_type;
   shared variable RAM : ram_type := (others => (others => '0'));

begin

    process(clka)
    begin
        if rising_edge(clka) then
            if ena = '1' then
                doa <= RAM(to_integer(unsigned(addra)));
            end if;
            if wea = '1' then
                RAM(to_integer(unsigned(addra))) := dia;
            end if;
        end if;
    end process;

process(clkb)
    begin
        if rising_edge(clkb) then
            if enb = '1' then
                dob <= RAM(to_integer(unsigned(addrb)));
            end if;
            if web = '1' then
                RAM(to_integer(unsigned(addrb))) := dib;
            end if;
        end if;
    end process;


end Behavioral;