library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rw_96x8_sync is
  port (
    clock    : in  std_logic;
    address  : in  std_logic_vector(7 downto 0);
    write    : in  std_logic;
    data_in  : in  std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0)
  );
end entity rw_96x8_sync;

architecture rtl of rw_96x8_sync is
  type rw_type is array (128 to 223) of std_logic_vector(7 downto 0);
  signal RW : rw_type := (others => x"00");
  signal EN : std_logic;
begin

  enable : process (address)
  begin
    if ((to_integer(unsigned(address)) >= 128) and
        (to_integer(unsigned(address)) <= 223)) then
      EN <= '1';
    else
      EN <= '0';
    end if;
  end process;

  memory : process (clock)
  begin
    if (clock'event and clock = '1') then
      if (EN = '1' and write = '1') then
        RW(to_integer(unsigned(address))) <= data_in;
      elsif (EN = '1' and write = '0') then
        data_out <= RW(to_integer(unsigned(address)));
      end if;
    end if;
  end process;

end architecture rtl;
